// lib/services/accounting_closure_service.dart

import 'package:stockly_saas/features/accounting/models/journal_entry.dart';
import 'package:stockly_saas/core/services/accounting_report_service.dart';

class AccountingClosureService {
  /// Génère l'écriture de clôture d'exercice (Solder la classe 6 et la classe 7)
  static JournalEntry generateClosureEntry({
    required String entrepriseId,
    required DateTime closureDate,
    required List<JournalEntry> entriesOfYear,
  }) {
    final incomeReport = AccountingReportService.calculateIncomeStatement(entriesOfYear);
    final lines = <JournalEntryLine>[];

    // 1. Solder les comptes de Produits (Classe 7) en les débitant
    for (var productBalance in incomeReport.produits) {
      final netProductAmount = productBalance.totalCredit - productBalance.totalDebit;
      if (netProductAmount > 0) {
        lines.add(
          JournalEntryLine(
            accountCode: productBalance.accountCode,
            accountLabel: 'Solder ${productBalance.accountLabel}',
            debit: netProductAmount,
            credit: 0.0,
          ),
        );
      }
    }

    // 2. Solder les comptes de Charges (Classe 6) en les créditant
    for (var chargeBalance in incomeReport.charges) {
      final netChargeAmount = chargeBalance.totalDebit - chargeBalance.totalCredit;
      if (netChargeAmount > 0) {
        lines.add(
          JournalEntryLine(
            accountCode: chargeBalance.accountCode,
            accountLabel: 'Solder ${chargeBalance.accountLabel}',
            debit: 0.0,
            credit: netChargeAmount,
          ),
        );
      }
    }

    // 3. Virement du solde dans le compte de résultat de l'exercice (Classe 13)
    final netResult = incomeReport.resultatNet;
    if (netResult >= 0) {
      // Bénéfice : Crédit du compte 130100
      lines.add(
        JournalEntryLine(
          accountCode: '130100',
          accountLabel: 'Résultat en instance d\'affectation (Bénéfice)',
          debit: 0.0,
          credit: netResult,
        ),
      );
    } else {
      // Perte : Débit du compte 130900
      lines.add(
        JournalEntryLine(
          accountCode: '130900',
          accountLabel: 'Résultat en instance d\'affectation (Perte)',
          debit: netResult.abs(),
          credit: 0.0,
        ),
      );
    }

    return JournalEntry(
      id: 'JE-CLOTURE-${closureDate.year}',
      entrepriseId: entrepriseId,
      date: closureDate,
      journalCode: 'OD',
      reference: 'CLOTURE-${closureDate.year}',
      description: 'Opération de clôture de l\'exercice comptable ${closureDate.year}',
      lines: lines,
    );
  }
}