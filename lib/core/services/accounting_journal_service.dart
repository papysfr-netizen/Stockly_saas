import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockly_saas/core/models/payment_method.dart';
import 'package:stockly_saas/features/accounting/models/journal_entry.dart';

/// Service centralisé de génération, nettoyage et synchronisation du journal comptable SYSCOHADA
class AccountingJournalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Flux en temps réel des écritures comptables d'une entreprise
  Stream<List<JournalEntry>> streamEcritures(String entrepriseId) {
    if (entrepriseId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('entreprises')
        .doc(entrepriseId)
        .collection('ecritures_comptables')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JournalEntry.fromFirestore(doc))
            .toList());
  }

  /// Sauvegarde une écriture comptable unique
  Future<void> saveJournalEntry(JournalEntry entry) async {
    if (entry.entrepriseId.isEmpty) return;

    await _firestore
        .collection('entreprises')
        .doc(entry.entrepriseId)
        .collection('ecritures_comptables')
        .doc(entry.id)
        .set(entry.toFirestore());
  }

  /// Sauvegarde un lot d'écritures en respectant le plafond de 400 opérations par batch Firestore
  Future<void> saveJournalEntries(List<JournalEntry> entries) async {
    if (entries.isEmpty) return;

    WriteBatch batch = _firestore.batch();
    int opCount = 0;

    for (var entry in entries) {
      if (entry.entrepriseId.isEmpty) continue;

      final docRef = _firestore
          .collection('entreprises')
          .doc(entry.entrepriseId)
          .collection('ecritures_comptables')
          .doc(entry.id);

      batch.set(docRef, entry.toFirestore());
      opCount++;

      if (opCount >= 400) {
        await batch.commit();
        batch = _firestore.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) {
      await batch.commit();
    }
  }

  /// Enregistrement d'une écriture manuelle / Opération Diverse (OD)
  Future<void> enregistrerEcritureManuelle({
    required String entrepriseId,
    required String description,
    required DateTime date,
    required List<Map<String, dynamic>> lines,
  }) async {
    if (entrepriseId.isEmpty) return;

    final docRef = _firestore
        .collection('entreprises')
        .doc(entrepriseId)
        .collection('ecritures_comptables')
        .doc();

    await docRef.set({
      'id': docRef.id,
      'entrepriseId': entrepriseId,
      'description': description,
      'date': Timestamp.fromDate(date),
      'reference': 'OD-${docRef.id.substring(0, 6).toUpperCase()}',
      'lines': lines,
    });
  }

  /// Nettoyage des anciennes collections/schémas obsolètes ou corrompus
  Future<int> cleanAndMigrateEcritures(String entrepriseId) async {
    if (entrepriseId.isEmpty) return 0;

    int cleanedCount = 0;

    // 1. Purge de l'ancienne sous-collection plate 'journal'
    final oldJournalRef = _firestore
        .collection('entreprises')
        .doc(entrepriseId)
        .collection('journal');
    
    final oldJournalSnap = await oldJournalRef.get();
    if (oldJournalSnap.docs.isNotEmpty) {
      WriteBatch oldBatch = _firestore.batch();
      int batchCount = 0;
      for (var doc in oldJournalSnap.docs) {
        oldBatch.delete(doc.reference);
        cleanedCount++;
        batchCount++;
        if (batchCount >= 400) {
          await oldBatch.commit();
          oldBatch = _firestore.batch();
          batchCount = 0;
        }
      }
      if (batchCount > 0) await oldBatch.commit();
    }

    // 2. Nettoyage des documents sans 'lines' ou avec d'anciens champs plats
    final ecrituresRef = _firestore
        .collection('entreprises')
        .doc(entrepriseId)
        .collection('ecritures_comptables');

    final querySnapshot = await ecrituresRef.get();

    WriteBatch batch = _firestore.batch();
    int operationCount = 0;

    for (var doc in querySnapshot.docs) {
      final data = doc.data();

      final hasFlatFields =
          data.containsKey('compteDebit') || data.containsKey('compteCredit');
      final hasNoLines =
          data['lines'] == null || (data['lines'] as List).isEmpty;

      if (hasFlatFields || hasNoLines) {
        batch.delete(doc.reference);
        cleanedCount++;
        operationCount++;

        if (operationCount >= 400) {
          await batch.commit();
          batch = _firestore.batch();
          operationCount = 0;
        }
      }
    }

    if (operationCount > 0) {
      await batch.commit();
    }

    return cleanedCount;
  }

  /// Obtenir le code de compte de trésorerie selon le mode de paiement
  static String getAccountCodeForPayment(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return '571000';
      case PaymentMethod.bank:
      case PaymentMethod.bankTransfer:
      case PaymentMethod.check:
        return '521000';
      case PaymentMethod.mobileMoney:
        return '572000';
      case PaymentMethod.credit:
        return '411000';
    }
  }

  /// Résolution dynamique des libellés par préfixe de classe du plan SYSCOHADA
  static String getAccountLabel(String code) {
    if (code.startsWith('571')) return 'Caisse Principale';
    if (code.startsWith('521')) return 'Banque';
    if (code.startsWith('572')) return 'Caisse Mobile Money';
    if (code.startsWith('411')) return 'Clients (Créances)';
    if (code.startsWith('419')) return 'Clients - Avances & Acomptes';
    if (code.startsWith('401')) return 'Fournisseurs (Dettes)';
    if (code.startsWith('443')) return 'TVA facturée sur ventes';
    if (code.startsWith('445')) return 'TVA récupérable sur achats';
    if (code.startsWith('601')) return 'Achats de marchandises';
    if (code.startsWith('603')) return 'Variation des stocks';
    if (code.startsWith('311')) return 'Stock de marchandises';
    if (code.startsWith('701')) return 'Ventes de marchandises';
    if (code.startsWith('658')) return 'Charges diverses';
    return 'Compte $code';
  }

  /// Génération automatique des pièces comptables de vente
  static List<JournalEntry> generateSaleEntries({
    required String entrepriseId,
    required String transactionId,
    required DateTime date,
    required String invoiceRef,
    required String customerName,
    required double amountExclTax,
    required double taxRate,
    required PaymentMethod paymentMethod,
    required double costOfGoodsSold,
    double amountPaid = 0.0,
    double creditAmount = 0.0,
  }) {
    final taxAmount = amountExclTax * taxRate;
    final totalAmountTTC = amountExclTax + taxAmount;
    final entries = <JournalEntry>[];
    final saleLines = <JournalLine>[];

    double effectivePaid = amountPaid;
    double effectiveCredit = creditAmount;

    if (effectivePaid == 0.0 && effectiveCredit == 0.0) {
      if (paymentMethod == PaymentMethod.credit) {
        effectiveCredit = totalAmountTTC;
      } else {
        effectivePaid = totalAmountTTC;
      }
    } else if (effectivePaid > 0.0 &&
        (effectivePaid + effectiveCredit) < totalAmountTTC) {
      effectiveCredit = totalAmountTTC - effectivePaid;
    }

    if (effectivePaid > 0.0) {
      final paidCode = getAccountCodeForPayment(paymentMethod);
      saleLines.add(
        JournalLine(
          accountCode: paidCode,
          accountLabel: getAccountLabel(paidCode),
          debit: effectivePaid,
          credit: 0.0,
        ),
      );
    }

    if (effectiveCredit > 0.0) {
      saleLines.add(
        JournalLine(
          accountCode: '411000',
          accountLabel: 'Client (Créance) - $customerName',
          debit: effectiveCredit,
          credit: 0.0,
        ),
      );
    }

    saleLines.add(
      JournalLine(
        accountCode: '701000',
        accountLabel: getAccountLabel('701000'),
        debit: 0.0,
        credit: amountExclTax,
      ),
    );

    if (taxAmount > 0.0) {
      saleLines.add(
        JournalLine(
          accountCode: '443100',
          accountLabel: getAccountLabel('443100'),
          debit: 0.0,
          credit: taxAmount,
        ),
      );
    }

    entries.add(
      JournalEntry(
        id: 'JE-SAL-$transactionId',
        entrepriseId: entrepriseId,
        date: date,
        reference: invoiceRef,
        description: 'Facture de vente - $customerName',
        lines: saleLines,
        montantEncaisse: effectivePaid,
      ),
    );

    if (costOfGoodsSold > 0.0) {
      entries.add(
        JournalEntry(
          id: 'JE-STK-OUT-$transactionId',
          entrepriseId: entrepriseId,
          date: date,
          reference: invoiceRef,
          description: 'Sortie de stock (CUMP) pour $invoiceRef',
          lines: [
            JournalLine(
              accountCode: '603100',
              accountLabel: getAccountLabel('603100'),
              debit: costOfGoodsSold,
              credit: 0.0,
            ),
            JournalLine(
              accountCode: '311000',
              accountLabel: getAccountLabel('311000'),
              debit: 0.0,
              credit: costOfGoodsSold,
            ),
          ],
        ),
      );
    }

    return entries;
  }

  /// Génération automatique des pièces comptables d'achat
  static List<JournalEntry> generatePurchaseEntries({
    required String entrepriseId,
    required String transactionId,
    required DateTime date,
    required String invoiceRef,
    required String supplierName,
    required double amountExclTax,
    required double taxRate,
    required PaymentMethod paymentMethod,
    double amountPaid = 0.0,
    double creditAmount = 0.0,
    bool updateInventory = true,
  }) {
    final taxAmount = amountExclTax * taxRate;
    final totalAmountTTC = amountExclTax + taxAmount;
    final entries = <JournalEntry>[];
    final purchaseLines = <JournalLine>[];

    purchaseLines.add(
      JournalLine(
        accountCode: '601000',
        accountLabel: getAccountLabel('601000'),
        debit: amountExclTax,
        credit: 0.0,
      ),
    );

    if (taxAmount > 0.0) {
      purchaseLines.add(
        JournalLine(
          accountCode: '445200',
          accountLabel: getAccountLabel('445200'),
          debit: taxAmount,
          credit: 0.0,
        ),
      );
    }

    double effectivePaid = amountPaid;
    double effectiveCredit = creditAmount;

    if (effectivePaid == 0.0 && effectiveCredit == 0.0) {
      if (paymentMethod == PaymentMethod.credit) {
        effectiveCredit = totalAmountTTC;
      } else {
        effectivePaid = totalAmountTTC;
      }
    } else if (effectivePaid > 0.0 &&
        (effectivePaid + effectiveCredit) < totalAmountTTC) {
      effectiveCredit = totalAmountTTC - effectivePaid;
    }

    if (effectivePaid > 0.0) {
      final paidCode = getAccountCodeForPayment(paymentMethod);
      purchaseLines.add(
        JournalLine(
          accountCode: paidCode,
          accountLabel: getAccountLabel(paidCode),
          debit: 0.0,
          credit: effectivePaid,
        ),
      );
    }

    if (effectiveCredit > 0.0) {
      purchaseLines.add(
        JournalLine(
          accountCode: '401000',
          accountLabel: 'Fournisseur (Dette) - $supplierName',
          debit: 0.0,
          credit: effectiveCredit,
        ),
      );
    }

    entries.add(
      JournalEntry(
        id: 'JE-PUR-$transactionId',
        entrepriseId: entrepriseId,
        date: date,
        reference: invoiceRef,
        description: 'Facture d\'achat - $supplierName',
        lines: purchaseLines,
        montantEncaisse: effectivePaid,
      ),
    );

    if (updateInventory && amountExclTax > 0.0) {
      entries.add(
        JournalEntry(
          id: 'JE-STK-IN-$transactionId',
          entrepriseId: entrepriseId,
          date: date,
          reference: invoiceRef,
          description: 'Entrée en stock de marchandises pour $invoiceRef',
          lines: [
            JournalLine(
              accountCode: '311000',
              accountLabel: getAccountLabel('311000'),
              debit: amountExclTax,
              credit: 0.0,
            ),
            JournalLine(
              accountCode: '603100',
              accountLabel: getAccountLabel('603100'),
              debit: 0.0,
              credit: amountExclTax,
            ),
          ],
        ),
      );
    }

    return entries;
  }
}