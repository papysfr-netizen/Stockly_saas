import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/journal_entry.dart';

enum PurchasePaymentMethod { cash, bank, credit }

class PurchaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Enregistre un achat et génère la pièce comptable SYSCOHADA associée
  Future<void> processPurchaseTransaction({
    required String entrepriseId,
    required String supplierName,
    required double amountExclTax,
    required double taxRate,
    required PurchasePaymentMethod paymentMethod,
    required String invoiceRef,
  }) async {
    final batch = _firestore.batch();
    final purchaseId = _firestore.collection('entreprises').doc(entrepriseId).collection('achats').doc().id;
    final now = DateTime.now();

    final taxAmount = amountExclTax * taxRate;
    final totalTTC = amountExclTax + taxAmount;

    // 1. Document Achat dans Firestore
    final purchaseDocRef = _firestore
        .collection('entreprises')
        .doc(entrepriseId)
        .collection('achats')
        .doc(purchaseId);

    batch.set(purchaseDocRef, {
      'id': purchaseId,
      'entrepriseId': entrepriseId,
      'invoiceRef': invoiceRef,
      'supplierName': supplierName,
      'amountExclTax': amountExclTax,
      'taxAmount': taxAmount,
      'totalTTC': totalTTC,
      'paymentMethod': paymentMethod.name,
      'createdAt': Timestamp.fromDate(now),
    });

    // 2. Détermination des comptes comptables SYSCOHADA
    String paymentAccountCode;
    String paymentAccountLabel;

    switch (paymentMethod) {
      case PurchasePaymentMethod.cash:
        paymentAccountCode = '571000';
        paymentAccountLabel = 'Caisse principale';
        break;
      case PurchasePaymentMethod.bank:
        paymentAccountCode = '521000';
        paymentAccountLabel = 'Banque locale';
        break;
      case PurchasePaymentMethod.credit:
        paymentAccountCode = '401000';
        paymentAccountLabel = 'Fournisseur - $supplierName';
        break;
    }

    final List<JournalLine> lines = [
      // Débit : Achats de marchandises (Compte 601000)
      JournalLine(
        accountCode: '601000',
        accountLabel: 'Achats de marchandises',
        debit: amountExclTax,
        credit: 0.0,
      ),
    ];

    // Débit : TVA déductible (Compte 445200) si applicable
    if (taxAmount > 0) {
      lines.add(
        JournalLine(
          accountCode: '445200',
          accountLabel: 'TVA récupérable sur achats',
          debit: taxAmount,
          credit: 0.0,
        ),
      );
    }

    // Crédit : Moyen de paiement ou Fournisseur
    lines.add(
      JournalLine(
        accountCode: paymentAccountCode,
        accountLabel: paymentAccountLabel,
        debit: 0.0,
        credit: totalTTC,
      ),
    );

    final journalEntry = JournalEntry(
      id: 'JE-ACH-${now.millisecondsSinceEpoch}',
      entrepriseId: entrepriseId,
      date: now,
      reference: invoiceRef,
      description: 'Achat de marchandises - $supplierName',
      lines: lines,
    );

    // 3. Ajout au Batch Firestore
    final journalDocRef = _firestore
        .collection('entreprises')
        .doc(entrepriseId)
        .collection('ecritures_comptables')
        .doc(journalEntry.id);

    batch.set(journalDocRef, journalEntry.toFirestore());

    await batch.commit();
  }
}