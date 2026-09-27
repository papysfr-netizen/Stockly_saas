// test/accounting_journal_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:stockly_saas/core/models/payment_method.dart';
import 'package:stockly_saas/features/accounting/services/accounting_journal_service.dart';
import 'package:stockly_saas/core/services/accounting_report_service.dart';

void main() {
  group('Tests de génération des écritures de vente SYSCOHADA', () {
    test('Vente au comptant avec TVA (18%) doit être parfaitement équilibrée', () {
      final entries = AccountingJournalService.generateSaleEntries(
        entrepriseId: 'ENT-001',
        transactionId: 'TX-1001',
        date: DateTime.now(),
        invoiceRef: 'FAC-2025-001',
        customerName: 'Client Alpha',
        amountExclTax: 100000.0,
        taxRate: 0.18,
        paymentMethod: PaymentMethod.cash,
        costOfGoodsSold: 60000.0,
      );

      expect(entries.length, equals(2)); // 1 écriture de vente + 1 écriture de sortie de stock

      // Vente
      final saleEntry = entries[0];
      final totalDebit = saleEntry.lines.fold(0.0, (s, l) => s + l.debit);
      final totalCredit = saleEntry.lines.fold(0.0, (s, l) => s + l.credit);

      expect(totalDebit, equals(118000.0)); // 100,000 + 18,000 TVA
      expect(totalCredit, equals(118000.0));
      expect(totalDebit, equals(totalCredit)); // Respect de la partie double

      // Sortie de stock (CUMP)
      final stockEntry = entries[1];
      expect(stockEntry.lines[0].accountCode, equals('603100')); // Débit variation stock
      expect(stockEntry.lines[1].accountCode, equals('311000')); // Crédit stock marchandises
      expect(stockEntry.lines[0].debit, equals(60000.0));
    });

    test('Vente à crédit doit imputer le compte client 411000', () {
      final entries = AccountingJournalService.generateSaleEntries(
        entrepriseId: 'ENT-001',
        transactionId: 'TX-1002',
        date: DateTime.now(),
        invoiceRef: 'FAC-2025-002',
        customerName: 'Client Beta',
        amountExclTax: 50000.0,
        taxRate: 0.0,
        paymentMethod: PaymentMethod.credit,
        costOfGoodsSold: 0.0,
      );

      final saleLines = entries[0].lines;
      final clientLine = saleLines.firstWhere((l) => l.accountCode == '411000');

      expect(clientLine.debit, equals(50000.0));
    });
  });

  group('Tests du Compte de Résultat et Bilan', () {
    test('Calcul correct du Bénéfice Net sur un jeu de test', () {
      final saleEntries = AccountingJournalService.generateSaleEntries(
        entrepriseId: 'ENT-001',
        transactionId: 'TX-1003',
        date: DateTime.now(),
        invoiceRef: 'FAC-003',
        customerName: 'Client Gamma',
        amountExclTax: 200000.0,
        taxRate: 0.0,
        paymentMethod: PaymentMethod.cash,
        costOfGoodsSold: 120000.0,
      );

      final report = AccountingReportService.calculateIncomeStatement(saleEntries);

      expect(report.totalProduits, equals(200000.0)); // Ventes (701000)
      expect(report.totalCharges, equals(120000.0));  // Variation stock (603100)
      expect(report.resultatNet, equals(80000.0));    // Bénéfice
      expect(report.isBenefice, isTrue);
    });
  });
}