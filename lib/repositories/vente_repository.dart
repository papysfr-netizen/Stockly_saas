import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dette.dart';
import '../models/journal_entry.dart';
import '../models/payment_method.dart';
import '../models/vente.dart';
import '../providers/cart_provider.dart';
import '../services/accounting_journal_service.dart';

class VenteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Isolation Multi-Tenant : /entreprises/{entrepriseId}
  DocumentReference _entrepriseRef(String entrepriseId) {
    return _firestore.collection('entreprises').doc(entrepriseId);
  }

  /// Collection des ventes de l'entreprise
  CollectionReference _ventesRef(String entrepriseId) {
    return _entrepriseRef(entrepriseId).collection('ventes');
  }

  /// Collection du stock/produits de l'entreprise
  CollectionReference _produitsRef(String entrepriseId) {
    return _entrepriseRef(entrepriseId).collection('produits');
  }

  /// Collection du journal comptable
  CollectionReference _ecrituresRef(String entrepriseId) {
    return _entrepriseRef(entrepriseId).collection('ecritures_comptables');
  }

  /// Collection des dettes/créances de l'entreprise
  CollectionReference _dettesRef(String entrepriseId) {
    return _entrepriseRef(entrepriseId).collection('dettes');
  }

  /// Enregistre une vente avec décrémentation de stock, création de créance et comptabilisation atomique
  Future<void> enregistrerVente({
    required Vente vente,
    required List<CartItem> cartItems,
    required String entrepriseId,
    required String userId,
  }) async {
    if (entrepriseId.isEmpty) {
      throw ArgumentError("L'identifiant de l'entreprise est requis.");
    }

    final batch = _firestore.batch();

    // 1. Création du document Vente dans /entreprises/{entrepriseId}/ventes
    final venteDocRef = _ventesRef(entrepriseId).doc();

    final updatedVente = vente.copyWith(
      id: venteDocRef.id,
      entrepriseId: entrepriseId,
      comptabilise: true,
    );

    final venteData = updatedVente.toFirestore();
    venteData['createdBy'] = userId;
    venteData['createdAt'] = FieldValue.serverTimestamp();

    batch.set(venteDocRef, venteData);

    // 2. Décrémentation du stock dans /entreprises/{entrepriseId}/produits
    for (final item in cartItems) {
      final produitRef = _produitsRef(entrepriseId).doc(item.id);

      batch.set(
        produitRef,
        {
          'quantite': FieldValue.increment(-item.quantite),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    final String client =
        (vente.clientNom != null && vente.clientNom!.trim().isNotEmpty)
            ? vente.clientNom!
            : 'Client Divers';

    // 3. Création de la Créance Client dans /entreprises/{entrepriseId}/dettes si vente à crédit
    if (updatedVente.resteAPayer > 0) {
      final detteDocRef = _dettesRef(entrepriseId).doc();
      final dette = Dette(
        id: detteDocRef.id,
        nomTiers: client,
        numeroFacture: venteDocRef.id,
        montantInitial: updatedVente.total,
        acomptePaye: updatedVente.montantPaye,
        montantReste: updatedVente.resteAPayer,
        type: TypeDette.client,
        statut: updatedVente.montantPaye > 0 ? 'partiel' : 'non_paye',
        note: 'Créance issue de la vente #${venteDocRef.id}',
        dateCreation: updatedVente.date,
        entrepriseId: entrepriseId,
        comptabilise: true,
      );

      batch.set(detteDocRef, dette.toFirestore());
    }

    // 4. Écriture comptable atomique SYSCOHADA Partie Double
    final ecritureRef = _ecrituresRef(entrepriseId).doc();
    final List<JournalLine> lines = [];

    // Débit : Compte de Trésorerie pour la partie encaisse
    if (vente.montantPaye > 0) {
      final codeTresorerie = AccountingJournalService.getAccountCodeForPayment(
        _parsePaymentMethod(vente.methodePaiement),
      );
      lines.add(
        JournalLine(
          accountCode: codeTresorerie,
          accountLabel: AccountingJournalService.getAccountLabel(codeTresorerie),
          debit: vente.montantPaye,
          credit: 0.0,
        ),
      );
    }

    // Débit : Créance Client (411000) pour le reste à payer
    if (vente.resteAPayer > 0) {
      lines.add(
        JournalLine(
          accountCode: '411000',
          accountLabel: 'Clients - $client',
          debit: vente.resteAPayer,
          credit: 0.0,
        ),
      );
    }

    // Crédit : Ventes de marchandises (701000) pour la valeur totale
    lines.add(
      JournalLine(
        accountCode: '701000',
        accountLabel: AccountingJournalService.getAccountLabel('701000'),
        debit: 0.0,
        credit: vente.total,
      ),
    );

    final journalEntry = JournalEntry(
      id: ecritureRef.id,
      entrepriseId: entrepriseId,
      date: vente.date,
      reference: venteDocRef.id,
      description: 'Vente - $client',
      lines: lines,
      montantEncaisse: vente.montantPaye,
    );

    batch.set(ecritureRef, journalEntry.toFirestore());

    // 5. Validation atomique de l'ensemble de la transaction
    await batch.commit();
  }

  /// Flux en temps réel de l'historique des ventes d'une entreprise
  Stream<List<Vente>> getVentes(String entrepriseId) {
    if (entrepriseId.isEmpty) return Stream.value([]);

    return _ventesRef(entrepriseId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Vente.fromDocument(doc))
          .toList();
    });
  }

  /// Flux en temps réel des créances clients actives (resteAPayer > 0)
  Stream<List<Vente>> getDettes(String entrepriseId) {
    if (entrepriseId.isEmpty) return Stream.value([]);

    return _ventesRef(entrepriseId)
        .where('resteAPayer', isGreaterThan: 0)
        .orderBy('resteAPayer', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Vente.fromDocument(doc))
          .toList();
    });
  }

  /// Règlement atomique d'une créance client (Acompte ou Solde)
  Future<void> reglerDette({
    required String entrepriseId,
    required String venteId,
    required double montantAcompte,
    required String userId,
    PaymentMethod paymentMethod = PaymentMethod.cash,
  }) async {
    if (entrepriseId.isEmpty || venteId.isEmpty || montantAcompte <= 0) return;

    final venteDocRef = _ventesRef(entrepriseId).doc(venteId);
    final snapshot = await venteDocRef.get();

    if (!snapshot.exists) {
      throw Exception('Vente introuvable');
    }

    final vente = Vente.fromDocument(snapshot);
    final String client =
        (vente.clientNom != null && vente.clientNom!.isNotEmpty)
            ? vente.clientNom!
            : 'Client Divers';

    final double nouveauMontantPaye = vente.montantPaye + montantAcompte;
    final double nouveauReste = vente.total - nouveauMontantPaye;
    final double resteFinal = nouveauReste < 0 ? 0.0 : nouveauReste;
    final String nouveauStatut = resteFinal <= 0 ? 'Payé' : 'Acompte';

    final batch = _firestore.batch();

    // 1. Mise à jour du document Vente
    batch.set(
      venteDocRef,
      {
        'montantPaye': nouveauMontantPaye,
        'resteAPayer': resteFinal,
        'statutPaiement': nouveauStatut,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': userId,
      },
      SetOptions(merge: true),
    );

    // 2. Mise à jour synchronisée dans la sous-collection 'dettes'
    final detteQuery = await _dettesRef(entrepriseId)
        .where('numeroFacture', isEqualTo: venteId)
        .get();

    for (final doc in detteQuery.docs) {
      batch.update(doc.reference, {
        'acomptePaye': nouveauMontantPaye,
        'montantReste': resteFinal,
        'statut': resteFinal <= 0 ? 'paye' : 'partiel',
        'dernierPaiement': FieldValue.serverTimestamp(),
      });
    }

    // 3. Écriture comptable de règlement : Débit Trésorerie / Crédit Client (411000)
    final ecritureRef = _ecrituresRef(entrepriseId).doc();
    final codeTresorerie = AccountingJournalService.getAccountCodeForPayment(paymentMethod);

    final journalEntry = JournalEntry(
      id: ecritureRef.id,
      entrepriseId: entrepriseId,
      date: DateTime.now(),
      reference: venteId,
      description: 'Règlement créance - $client',
      lines: [
        JournalLine(
          accountCode: codeTresorerie,
          accountLabel: AccountingJournalService.getAccountLabel(codeTresorerie),
          debit: montantAcompte,
          credit: 0.0,
        ),
        JournalLine(
          accountCode: '411000',
          accountLabel: 'Clients - $client',
          debit: 0.0,
          credit: montantAcompte,
        ),
      ],
      montantEncaisse: montantAcompte,
    );

    batch.set(ecritureRef, journalEntry.toFirestore());

    await batch.commit();
  }

  /// Helper de conversion pour le mode de paiement
  PaymentMethod _parsePaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'bank':
      case 'banque':
        return PaymentMethod.bank;
      case 'mobilemoney':
      case 'mobile_money':
      case 'm-pesa':
      case 'airtel':
      case 'orange':
        return PaymentMethod.mobileMoney;
      case 'credit':
      case 'crédit':
        return PaymentMethod.credit;
      case 'cash':
      case 'caisse':
      default:
        return PaymentMethod.cash;
    }
  }
}