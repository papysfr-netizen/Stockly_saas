// lib/services/sale_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_method.dart';
import 'accounting_journal_service.dart';

class SaleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Enregistre une vente et génère immédiatement les pièces comptables associées
  Future<void> processSaleTransaction({
    required String entrepriseId,
    required String customerName,
    required double amountExclTax,
    required double taxRate,
    required PaymentMethod paymentMethod,
    required double costOfGoodsSold,
    required List<Map<String, dynamic>> items,
    double amountPaid = 0.0,
    double creditAmount = 0.0,
  }) async {
    final batch = _firestore.batch();
    final saleId = _firestore
        .collection('entreprises')
        .doc(entrepriseId)
        .collection('ventes')
        .doc()
        .id;
    final now = DateTime.now();
    final invoiceRef = 'FAC-${now.millisecondsSinceEpoch.toString().substring(5)}';

    // 1. Document de vente dans Firestore
    final saleDocRef = _firestore
        .collection('entreprises')
        .doc(entrepriseId)
        .collection('ventes')
        .doc(saleId);

    batch.set(saleDocRef, {
      'id': saleId,
      'entrepriseId': entrepriseId,
      'invoiceRef': invoiceRef,
      'customerName': customerName,
      'amountExclTax': amountExclTax,
      'taxRate': taxRate,
      'totalTTC': amountExclTax * (1 + taxRate),
      'amountPaid': amountPaid,
      'creditAmount': creditAmount,
      'paymentMethod': paymentMethod.name,
      'items': items,
      'createdAt': Timestamp.fromDate(now),
    });

    // 2. Création de la dette client (créance) si solde à crédit
    if (creditAmount > 0) {
      final detteDocRef = _firestore
          .collection('entreprises')
          .doc(entrepriseId)
          .collection('dettes')
          .doc();

      batch.set(detteDocRef, {
        'id': detteDocRef.id,
        'entrepriseId': entrepriseId,
        'nomTiers': customerName,
        'numeroFacture': invoiceRef,
        'montantInitial': creditAmount,
        'acomptePaye': 0.0,
        'montantReste': creditAmount,
        'type': 'client',
        'statut': 'non_paye',
        'note': 'Créance issue de la vente $invoiceRef',
        'dateCreation': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
        'comptabilise': true,
      });
    }

    // 3. Génération des écritures comptables (Vente + Sortie de stock CUMP)
    final journalEntries = AccountingJournalService.generateSaleEntries(
      entrepriseId: entrepriseId,
      transactionId: saleId,
      date: now,
      invoiceRef: invoiceRef,
      customerName: customerName,
      amountExclTax: amountExclTax,
      taxRate: taxRate,
      paymentMethod: paymentMethod,
      costOfGoodsSold: costOfGoodsSold,
      amountPaid: amountPaid,
      creditAmount: creditAmount,
    );

    // 4. Ajout des pièces comptables au même batch
    for (var entry in journalEntries) {
      final journalDocRef = _firestore
          .collection('entreprises')
          .doc(entrepriseId)
          .collection('ecritures_comptables')
          .doc(entry.id);

      batch.set(journalDocRef, entry.toFirestore());
    }

    // Validation atomique de la transaction (Vente + Dette + Comptabilité)
    await batch.commit();
  }
}