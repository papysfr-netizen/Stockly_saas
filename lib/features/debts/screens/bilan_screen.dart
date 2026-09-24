// lib/features/accounting/services/accounting_report_service.dart

import 'package:stockly_saas/features/accounting/models/journal_entry.dart';

/// Modèle pour un compte du Grand Livre
class AccountBalance {
  final String accountCode;
  final String accountLabel;
  double totalDebit;
  double totalCredit;

  AccountBalance({
    required this.accountCode,
    required this.accountLabel,
    this.totalDebit = 0.0,
    this.totalCredit = 0.0,
  });

  /// Solde net (Positif = Solde Débiteur, Négatif = Solde Créditeur)
  double get netBalance => totalDebit - totalCredit;
  bool get isDebtor => netBalance > 0;
  bool get isCreditor => netBalance < 0;
}

/// Modèle pour le Compte de Résultat (SYSCOHADA)
class IncomeStatementReport {
  final List<AccountBalance> charges;  // Classe 6
  final List<AccountBalance> produits; // Classe 7

  IncomeStatementReport({
    required this.charges,
    required this.produits,
  });

  double get totalCharges =>
      charges.fold(0.0, (sum, item) => sum + item.netBalance);

  double get totalProduits =>
      produits.fold(0.0, (sum, item) => sum + item.netBalance.abs());

  double get resultatNet => totalProduits - totalCharges;
  bool get isBenefice => resultatNet >= 0;
}

/// Modèle synthétique pour le Bilan (Actif vs Passif)
class BalanceSheetReport {
  final List<AccountBalance> actif;  // Classes 2, 3, 4 (débit), 5 (débit)
  final List<AccountBalance> passif; // Classes 1, 4 (crédit), 5 (crédit)
  final double resultatExercice;

  BalanceSheetReport({
    required this.actif,
    required this.passif,
    required this.resultatExercice,
  });

  double get totalActif =>
      actif.fold(0.0, (sum, item) => sum + item.netBalance);

  double get totalPassif =>
      passif.fold(0.0, (sum, item) => sum + item.netBalance.abs()) + resultatExercice;

  /// Vérifie si le bilan est équilibré (Actif = Passif)
  bool get isBalanced => (totalActif - totalPassif).abs() < 0.01;
}

class AccountingReportService {
  /// Génère la balance générale de tous les comptes
  static List<AccountBalance> calculateTrialBalance(List<JournalEntry> entries) {
    final Map<String, AccountBalance> balances = {};

    for (var entry in entries) {
      for (var line in entry.lines) {
        if (!balances.containsKey(line.accountCode)) {
          balances[line.accountCode] = AccountBalance(
            accountCode: line.accountCode,
            accountLabel: line.accountLabel,
          );
        }

        balances[line.accountCode]!.totalDebit += line.debit;
        balances[line.accountCode]!.totalCredit += line.credit;
      }
    }

    final result = balances.values.toList();
    result.sort((a, b) => a.accountCode.compareTo(b.accountCode));
    return result;
  }

  /// Génère le Compte de Résultat (Classe 6 & Classe 7)
  static IncomeStatementReport calculateIncomeStatement(List<JournalEntry> entries) {
    final trialBalance = calculateTrialBalance(entries);

    final charges = trialBalance
        .where((b) => b.accountCode.startsWith('6'))
        .toList();

    final produits = trialBalance
        .where((b) => b.accountCode.startsWith('7'))
        .toList();

    return IncomeStatementReport(charges: charges, produits: produits);
  }

  /// Génère le Bilan Synthétique (Classes 1 à 5)
  static BalanceSheetReport calculateBalanceSheet(List<JournalEntry> entries) {
    final trialBalance = calculateTrialBalance(entries);
    final incomeStatement = calculateIncomeStatement(entries);

    final actif = <AccountBalance>[];
    final passif = <AccountBalance>[];

    for (var b in trialBalance) {
      final classCode = b.accountCode.substring(0, 1);
      
      // Seuls les comptes du bilan (Classes 1 à 5)
      if (['1', '2', '3', '4', '5'].contains(classCode)) {
        if (b.isDebtor) {
          actif.add(b);
        } else if (b.isCreditor) {
          passif.add(b);
        }
      }
    }

    return BalanceSheetReport(
      actif: actif,
      passif: passif,
      resultatExercice: incomeStatement.resultatNet,
    );
  }
}