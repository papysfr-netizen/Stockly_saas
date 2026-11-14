import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockly_saas/core/providers/cart_provider.dart';
import 'package:stockly_saas/core/utils/payment_calculator.dart';
import 'package:stockly_saas/features/ventes/vente_service.dart';

// Taux : 2000 FC = 1 $
const taux = 2000.0;
final maintenant = Timestamp.fromDate(DateTime(2026, 11, 14, 10, 30));

const chemise = CartItem(id: 'p1', nom: 'Chemise', prix: 10, quantite: 2, stock: 20);
const jean = CartItem(id: 'p2', nom: 'Jean', prix: 25, quantite: 1, stock: 5);

NouvelleVente vente({
  List<CartItem> panier = const [chemise, jean], // total 45 $
  double usd = 0,
  double fc = 0,
  String nom = '',
  String tel = '',
  double solde = 0,
  double soldeAvant = 0,
  String methode = 'Cash',
  String boutique = 'principale',
  bool apresCloture = false,
}) {
  final total = panier.fold<double>(0, (s, i) => s + i.totalPrice);
  return NouvelleVente(
    entrepriseId: 'ent1',
    userId: 'u1',
    vendeurNom: 'Jean',
    boutiqueId: boutique,
    nomSaisi: nom,
    telephone: tel,
    panier: panier,
    total: total,
    paiement: PaymentResult(
      totalUSD: (total - solde).clamp(0, double.infinity).toDouble(),
      paidUSD: usd,
      paidLocal: fc,
      localRate: taux,
    ),
    soldeUtilise: solde,
    soldeAvant: soldeAvant,
    methodePaiement: methode,
    prixAchat: const {'p1': 6, 'p2': 15},
    apresCloture: apresCloture,
  );
}

PlanVente preparer(NouvelleVente v) => VenteService.preparer(
      v,
      venteId: 'abcdefghij123',
      ecritureId: 'ecr1',
      creanceId: 'cre1',
      maintenant: maintenant,
    );

/// L'écriture comptable doit toujours être équilibrée (débits = crédits)
void expectEquilibree(Map<String, dynamic> ecriture) {
  final lignes = (ecriture['lines'] as List).cast<Map<String, dynamic>>();
  final debit = lignes.fold<double>(0, (s, l) => s + (l['debit'] as num));
  final credit = lignes.fold<double>(0, (s, l) => s + (l['credit'] as num));
  expect(debit, closeTo(credit, 0.0001), reason: 'écriture déséquilibrée : $lignes');
}

void main() {
  group('Vente payée comptant', () {
    test('payée en dollars : vente, écriture, coût, stock, pas de créance', () {
      final p = preparer(vente(usd: 50)); // 5 $ de monnaie
      expect(p.vente['montantTotal'], 45);
      expect(p.vente['statutPaiement'], 'Payé');
      expect(p.vente['resteAPayer'], 0);
      expect(p.vente['monnaieRendueUSD'], closeTo(5, 0.0001));
      expect(p.vente['nomClient'], 'Client Divers');
      expect(p.numeroFacture, 'ABCDEFGH');
      expect(p.verseCaisse, 45);
      expect(p.creance, isNull);
      expectEquilibree(p.ecritureVente);
      // Coût : 2 × 6 + 1 × 15 = 27 $
      expect(p.coutMarchandises, 27);
      expectEquilibree(p.ecritureCout!);
      expect(p.stock.map((s) => '${s.produitId}:${s.quantite}'), ['p1:2', 'p2:1']);
    });

    test('paiement mixte : 20 \$ + 50 000 FC (= 25 \$)', () {
      final p = preparer(vente(usd: 20, fc: 50000));
      expect(p.vente['statutPaiement'], 'Payé');
      expect(p.vente['montantPayeUSD'], 20);
      expect(p.vente['montantPayeLocal'], 50000);
      expect(p.vente['tauxEchange'], taux);
      expect(p.reste, 0);
      expectEquilibree(p.ecritureVente);
    });

    test('à un centime près : payé, écriture toujours équilibrée', () {
      final p = preparer(vente(usd: 44.995));
      expect(p.vente['statutPaiement'], 'Payé');
      expect(p.reste, 0);
      expect(p.creance, isNull);
      expectEquilibree(p.ecritureVente);
    });

    test('Mobile Money : compte de trésorerie 572000', () {
      final p = preparer(vente(usd: 45, methode: 'Mobile Money'));
      final lignes = (p.ecritureVente['lines'] as List).cast<Map<String, dynamic>>();
      expect(lignes.first['accountCode'], '572000');
      expect(p.vente['methodePaiement'], 'Mobile Money');
    });
  });

  group('Vente à crédit', () {
    test('acompte : créance du reste, historique du paiement', () {
      final p = preparer(vente(usd: 15, nom: 'Mama Neema', tel: '0991234567'));
      expect(p.vente['statutPaiement'], 'Acompte');
      expect(p.reste, 30);
      expect(p.creance!['montantReste'], 30);
      expect(p.creance!['acomptePaye'], 15);
      expect(p.creance!['statut'], 'partiel');
      expect(p.creance!['telephone'], '0991234567');
      expect((p.creance!['paiements'] as List).length, 1);
      expectEquilibree(p.ecritureVente);
    });

    test('dette totale : statut « Dette », pas d\'historique de paiement', () {
      final p = preparer(vente(nom: 'Mama Neema', tel: '0991234567'));
      expect(p.vente['statutPaiement'], 'Dette');
      expect(p.creance!['statut'], 'non_paye');
      expect(p.creance!.containsKey('paiements'), isFalse);
      expectEquilibree(p.ecritureVente);
    });

    test('crédit refusé sans nom, ou sans téléphone', () {
      expect(VenteService.verifierCredit(vente(usd: 10, tel: '0991234567')), ProblemeCredit.nomManquant);
      expect(VenteService.verifierCredit(vente(usd: 10, nom: 'Client divers', tel: '0991234567')),
          ProblemeCredit.nomManquant);
      expect(VenteService.verifierCredit(vente(usd: 10, nom: 'Mama Neema', tel: '0812')),
          ProblemeCredit.telephoneManquant);
      expect(VenteService.verifierCredit(vente(usd: 10, nom: 'Mama Neema', tel: '0991234567')), isNull);
      // Payé en entier : ni nom ni téléphone nécessaires
      expect(VenteService.verifierCredit(vente(usd: 45)), isNull);
    });
  });

  group('Compte client et boutiques', () {
    test('payé en partie par le compte client', () {
      // 20 $ pris sur le compte, 25 $ en espèces
      final p = preparer(vente(usd: 25, solde: 20, soldeAvant: 50, nom: 'Paul', tel: '0991234567'));
      expect(p.vente['montantCompteClient'], 20);
      expect(p.vente['methodePaiement'], 'Cash + Compte client');
      expect(p.verseCaisse, 25);
      expect(p.reste, 0);
      expectEquilibree(p.ecritureVente);
    });

    test('tout payé par le compte client', () {
      final p = preparer(vente(solde: 45, soldeAvant: 60, nom: 'Paul', tel: '0991234567'));
      expect(p.vente['methodePaiement'], 'Compte client');
      expect(p.verseCaisse, 0);
      expect(p.reste, 0);
      expectEquilibree(p.ecritureVente);
    });

    test('boutique et vente après la clôture enregistrées', () {
      final p = preparer(vente(usd: 45, boutique: 'b2', apresCloture: true));
      expect(p.vente['boutiqueId'], 'b2');
      expect(p.ecritureVente['boutiqueId'], 'b2');
      expect(p.vente['apresCloture'], isTrue);
      expect(preparer(vente(usd: 45)).vente.containsKey('apresCloture'), isFalse);
    });

    test('remise accordée enregistrée', () {
      const remise = CartItem(id: 'p1', nom: 'Chemise', prix: 8, prixNormal: 10, quantite: 2, stock: 20);
      final p = preparer(vente(panier: const [remise], usd: 16));
      expect(p.vente['remiseTotale'], 4);
    });

    test('produit sans prix d\'achat : pas d\'écriture de coût', () {
      const inconnu = CartItem(id: 'p9', nom: 'Sac', prix: 5, quantite: 1, stock: 3);
      final p = preparer(vente(panier: const [inconnu], usd: 5));
      expect(p.coutMarchandises, 0);
      expect(p.ecritureCout, isNull);
    });
  });
}
