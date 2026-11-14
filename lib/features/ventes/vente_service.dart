// lib/features/ventes/vente_service.dart
//
// 🧾 ENREGISTREMENT D'UNE VENTE (séparé de l'écran de paiement)
//
//  1. `VenteService.preparer` calcule TOUT ce qui doit être écrit, sans toucher
//     à Firebase : la vente, l'écriture comptable, le coût des marchandises,
//     la créance (s'il reste à payer) et la baisse du stock.
//     → c'est cette partie qui est testée automatiquement (test/ventes/).
//  2. `VenteService.ajouterAuLot` met ces écritures dans UN lot Firestore :
//     tout est enregistré ensemble, ou rien.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:stockly_saas/core/models/payment_method.dart';
import 'package:stockly_saas/core/providers/cart_provider.dart';
import 'package:stockly_saas/core/utils/payment_calculator.dart';
import 'package:stockly_saas/features/accounting/services/accounting_journal_service.dart';
import 'package:stockly_saas/features/comptes_clients/compte_client_service.dart';

/// Nom enregistré quand le vendeur n'a pas saisi de client
const String clientDivers = 'Client Divers';

/// Pourquoi une vente à crédit est refusée
enum ProblemeCredit { nomManquant, telephoneManquant }

/// Ce que le vendeur a saisi dans la fenêtre de paiement
class NouvelleVente {
  final String entrepriseId;
  final String userId;
  final String vendeurNom;
  final String boutiqueId;

  /// Nom tapé (vide = « Client Divers »)
  final String nomSaisi;
  final String telephone;
  final List<CartItem> panier;

  /// Total de la facture (USD)
  final double total;

  /// Argent versé à la caisse ($ + FC convertis), calculé sur le reste à payer
  final PaymentResult paiement;

  /// Part payée avec le compte client (USD) et solde du compte avant la vente
  final double soldeUtilise;
  final double soldeAvant;

  /// « Cash », « Mobile Money », « Carte bancaire », « Virement »
  final String methodePaiement;

  /// 'Livré' ou 'Non livré'
  final String statutLivraison;
  final int delaiRetraitJours;
  final String motif;

  /// Prix d'achat connus (produitId → USD) pour le coût des marchandises
  final Map<String, double> prixAchat;

  /// Vente faite après la clôture de caisse du jour
  final bool apresCloture;

  const NouvelleVente({
    required this.entrepriseId,
    required this.userId,
    required this.vendeurNom,
    required this.boutiqueId,
    required this.nomSaisi,
    required this.telephone,
    required this.panier,
    required this.total,
    required this.paiement,
    this.soldeUtilise = 0,
    this.soldeAvant = 0,
    this.methodePaiement = 'Cash',
    this.statutLivraison = 'Livré',
    this.delaiRetraitJours = 7,
    this.motif = '',
    this.prixAchat = const {},
    this.apresCloture = false,
  });

  String get client => nomSaisi.trim().isEmpty ? clientDivers : nomSaisi.trim();
  bool get estLivre => statutLivraison == 'Livré';
}

/// Une baisse de stock à appliquer
class BaisseStock {
  final String produitId;
  final int quantite;
  const BaisseStock(this.produitId, this.quantite);
}

/// Tout ce qui sera écrit pour une vente
class PlanVente {
  final String venteId;
  final String numeroFacture;
  final Map<String, dynamic> vente;
  final String ecritureId;
  final Map<String, dynamic> ecritureVente;
  final Map<String, dynamic>? ecritureCout;
  final String? creanceId;
  final Map<String, dynamic>? creance;
  final List<BaisseStock> stock;

  /// Argent reçu à la caisse (sans le compte client) et reste dû (USD)
  final double verseCaisse;
  final double verseTotal;
  final double reste;
  final double coutMarchandises;
  final String methodeEnregistree;
  final DateTime finJourLimite;

  const PlanVente({
    required this.venteId,
    required this.numeroFacture,
    required this.vente,
    required this.ecritureId,
    required this.ecritureVente,
    required this.ecritureCout,
    required this.creanceId,
    required this.creance,
    required this.stock,
    required this.verseCaisse,
    required this.verseTotal,
    required this.reste,
    required this.coutMarchandises,
    required this.methodeEnregistree,
    required this.finJourLimite,
  });

  String get idEcritureCout => 'STK-$venteId';
}

class VenteService {
  VenteService._();

  static double _arrondi(double v) => (v * 100).roundToDouble() / 100;

  /// Vente à crédit : il faut un vrai nom et un téléphone (sinon impossible de relancer)
  static ProblemeCredit? verifierCredit(NouvelleVente v) {
    if (_reste(v) <= PaymentResult.tolerance) return null;
    if (v.nomSaisi.trim().isEmpty || v.client.toLowerCase() == clientDivers.toLowerCase()) {
      return ProblemeCredit.nomManquant;
    }
    if (!CompteClientService.telephoneValide(v.telephone)) return ProblemeCredit.telephoneManquant;
    return null;
  }

  /// Ce qui reste dû après la caisse et le compte client (0 si payé à 1 centime près)
  static double _reste(NouvelleVente v) {
    final p = v.paiement;
    if (p.isFullyPaid) return 0.0;
    final aPayer = (v.total - v.soldeUtilise).clamp(0.0, double.infinity);
    final r = aPayer - p.totalPaidInUSD;
    return r > 0 ? _arrondi(r) : 0.0;
  }

  static PaymentMethod moyen(String methode) {
    switch (methode.toLowerCase()) {
      case 'carte bancaire':
      case 'virement':
      case 'banque':
        return PaymentMethod.bank;
      case 'mobile money':
        return PaymentMethod.mobileMoney;
      case 'dette':
        return PaymentMethod.credit;
      default:
        return PaymentMethod.cash;
    }
  }

  /// Prépare toutes les écritures de la vente (sans rien écrire)
  static PlanVente preparer(
    NouvelleVente v, {
    required String venteId,
    required String ecritureId,
    required String creanceId,
    required Timestamp maintenant,
  }) {
    final client = v.client;
    final total = _arrondi(v.total);
    final soldeUtilise = _arrondi(v.soldeUtilise);
    final aPayer = _arrondi((total - soldeUtilise).clamp(0.0, double.infinity));
    final reste = _reste(v);
    // Ce que la caisse a réellement reçu pour la facture (sans la monnaie rendue).
    // Payé à 1 centime près : on compte la facture entière (l'écriture reste équilibrée).
    final verseCaisse = reste > 0 ? _arrondi(aPayer - reste) : aPayer;
    final verseTotal = _arrondi(verseCaisse + soldeUtilise);

    final methodeEnregistree = soldeUtilise > 0.005
        ? (verseCaisse > 0.005 ? '${v.methodePaiement} + Compte client' : 'Compte client')
        : v.methodePaiement;

    double cout = 0;
    for (final item in v.panier) {
      cout += (v.prixAchat[item.id] ?? 0.0) * item.quantite;
    }
    cout = _arrondi(cout);

    final limite = maintenant.toDate().add(Duration(days: v.delaiRetraitJours));
    final finJourLimite = DateTime(limite.year, limite.month, limite.day, 23, 59, 59);
    final numeroFacture = venteId.substring(0, venteId.length < 8 ? venteId.length : 8).toUpperCase();
    final p = v.paiement;

    // 1. La vente
    final vente = <String, dynamic>{
      'id': venteId,
      'nomClient': client,
      'telephoneClient': v.telephone,
      'montantTotal': total,
      'montantPaye': p.totalPaidInUSD + soldeUtilise,
      'montantPayeUSD': p.paidUSD,
      'montantPayeLocal': p.paidLocal,
      'montantCompteClient': soldeUtilise,
      'monnaieRendueUSD': p.changeInUSD,
      'monnaieRendueLocal': p.changeInLocal,
      'tauxEchange': p.localRate,
      'resteAPayer': reste,
      'statutPaiement': reste <= 0 ? 'Payé' : (verseTotal > 0 ? 'Acompte' : 'Dette'),
      'statutLivraison': v.statutLivraison,
      'dateLivraison': v.estLivre ? maintenant : null,
      'livrePar': v.estLivre ? v.userId : null,
      'dateLimiteLivraison': v.estLivre ? null : Timestamp.fromDate(finJourLimite),
      'methodePaiement': methodeEnregistree,
      'vendeurId': v.userId,
      'boutiqueId': v.boutiqueId,
      if (v.apresCloture) 'apresCloture': true,
      'vendeurNom': v.vendeurNom,
      'entrepriseId': v.entrepriseId,
      'comptabilise': true,
      'coutMarchandises': cout,
      'remiseTotale': v.panier.fold<double>(0.0, (s, i) => s + i.remiseTotale),
      'articles': v.panier
          .map((item) => {
                'produitId': item.id,
                'nom': item.nom,
                'prixUnitaire': item.prix,
                'prixNormal': item.prixNormal,
                'remise': item.remiseTotale,
                'prixAchat': v.prixAchat[item.id] ?? 0.0,
                'quantite': item.quantite,
                'totalItem': item.prix * item.quantite,
              })
          .toList(),
      'createdAt': maintenant,
      'date': maintenant,
    };

    // 2. Écriture comptable (SYSCOHADA) : débits = crédit des ventes
    final codeTresorerie = AccountingJournalService.getAccountCodeForPayment(moyen(v.methodePaiement));
    final lignes = <Map<String, dynamic>>[
      if (verseCaisse > 0)
        {
          'accountCode': codeTresorerie,
          'accountLabel': AccountingJournalService.getAccountLabel(codeTresorerie),
          'debit': verseCaisse,
          'credit': 0.0,
        },
      if (soldeUtilise > 0.005)
        {
          'accountCode': CompteClientService.compteAvances,
          'accountLabel': '${CompteClientService.libelleAvances} - $client',
          'debit': soldeUtilise,
          'credit': 0.0,
        },
      if (reste > 0)
        {
          'accountCode': '411000',
          'accountLabel': 'Client (Créance) - $client',
          'debit': reste,
          'credit': 0.0,
        },
      {
        'accountCode': '701000',
        'accountLabel': AccountingJournalService.getAccountLabel('701000'),
        'debit': 0.0,
        'credit': total,
      },
    ];
    final ecritureVente = <String, dynamic>{
      'id': ecritureId,
      'entrepriseId': v.entrepriseId,
      'reference': venteId,
      'description': 'Facture de vente - $client',
      'date': maintenant,
      'lines': lignes,
      'montantEncaisse': verseCaisse,
      'boutiqueId': v.boutiqueId,
    };

    // 2 bis. Coût des marchandises vendues
    final ecritureCout = cout <= 0
        ? null
        : <String, dynamic>{
            'id': 'STK-$venteId',
            'entrepriseId': v.entrepriseId,
            'reference': venteId,
            'description': 'Sortie de stock (coût des marchandises) - $client',
            'boutiqueId': v.boutiqueId,
            'date': maintenant,
            'lines': [
              {
                'accountCode': '603100',
                'accountLabel': AccountingJournalService.getAccountLabel('603100'),
                'debit': cout,
                'credit': 0.0,
              },
              {
                'accountCode': '311000',
                'accountLabel': AccountingJournalService.getAccountLabel('311000'),
                'debit': 0.0,
                'credit': cout,
              },
            ],
            'montantEncaisse': 0.0,
          };

    // 3. Créance (s'il reste à payer)
    final creance = reste <= 0
        ? null
        : <String, dynamic>{
            'id': creanceId,
            'venteId': venteId,
            'boutiqueId': v.boutiqueId,
            'numeroFacture': numeroFacture,
            'nomTiers': client,
            'nomClient': client,
            'telephone': v.telephone,
            'montantInitial': total,
            'acomptePaye': verseTotal,
            'montantReste': reste,
            'type': 'client',
            'statut': verseTotal > 0 ? 'partiel' : 'non_paye',
            'note': v.motif.trim().isNotEmpty
                ? v.motif.trim()
                : 'Créance issue de la vente #${venteId.substring(0, venteId.length < 6 ? venteId.length : 6)}',
            if (verseTotal > 0.005)
              'paiements': [
                {
                  'date': maintenant,
                  'montant': verseTotal,
                  'methode': methodeEnregistree,
                  'parNom': v.vendeurNom,
                  'parUid': v.userId,
                }
              ],
            'entrepriseId': v.entrepriseId,
            'comptabilise': true,
            'createdAt': maintenant,
            'dateCreation': maintenant,
          };

    return PlanVente(
      venteId: venteId,
      numeroFacture: numeroFacture,
      vente: vente,
      ecritureId: ecritureId,
      ecritureVente: ecritureVente,
      ecritureCout: ecritureCout,
      creanceId: creance == null ? null : creanceId,
      creance: creance,
      // 4. Stock (même si à livrer plus tard : la marchandise est réservée)
      stock: [for (final item in v.panier) BaisseStock(item.id, item.quantite)],
      verseCaisse: verseCaisse,
      verseTotal: verseTotal,
      reste: reste,
      coutMarchandises: cout,
      methodeEnregistree: methodeEnregistree,
      finJourLimite: finJourLimite,
    );
  }

  /// Met toutes les écritures de la vente dans le lot (rien n'est envoyé ici)
  static void ajouterAuLot(
    WriteBatch lot,
    FirebaseFirestore db,
    NouvelleVente v,
    PlanVente plan,
    Timestamp maintenant,
  ) {
    final ent = db.collection('entreprises').doc(v.entrepriseId);
    lot.set(ent.collection('ventes').doc(plan.venteId), plan.vente);
    lot.set(ent.collection('ecritures_comptables').doc(plan.ecritureId), plan.ecritureVente);
    final cout = plan.ecritureCout;
    if (cout != null) {
      lot.set(ent.collection('ecritures_comptables').doc(plan.idEcritureCout), cout);
    }
    final creance = plan.creance;
    if (creance != null && plan.creanceId != null) {
      lot.set(ent.collection('creances').doc(plan.creanceId), creance);
    }

    // 💰 Compte client : mouvement « Achat »
    if (v.soldeUtilise > 0.005) {
      CompteClientService.ajouterMouvement(
        lot,
        entrepriseId: v.entrepriseId,
        telephone: v.telephone,
        nom: v.client == clientDivers ? '' : v.client,
        type: 'achat',
        delta: -v.soldeUtilise,
        soldeAvant: v.soldeAvant,
        description: 'Achat facture ${plan.numeroFacture}',
        date: maintenant,
        uid: v.userId,
        parNom: v.vendeurNom,
        venteId: plan.venteId,
      );
    }

    // 📦 Stock : le total, et la boutique (la principale = total − autres boutiques)
    for (final s in plan.stock) {
      lot.update(ent.collection('produits').doc(s.produitId), {
        'quantite': FieldValue.increment(-s.quantite),
        if (v.boutiqueId != 'principale') 'stocks.${v.boutiqueId}': FieldValue.increment(-s.quantite),
        'updatedAt': maintenant,
      });
    }
  }
}
