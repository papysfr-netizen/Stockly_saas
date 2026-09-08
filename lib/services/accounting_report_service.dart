// lib/services/accounting_report_service.dart

import '../models/journal_entry.dart';

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

  /// Solde net orienté Débit (Positif = Solde Débiteur, Négatif = Solde Créditeur)
  double get netBalance => totalDebit - totalCredit;

  /// Solde Débiteur net (0.0 si le compte est créditeur)
  double get debitBalance => isDebtor ? (totalDebit - totalCredit) : 0.0;

  /// Solde Créditeur net (0.0 si le compte est débiteur)
  double get creditBalance => isCreditor ? (totalCredit - totalDebit) : 0.0;

  bool get isDebtor => totalDebit > totalCredit;
  bool get isCreditor => totalCredit > totalDebit;
  bool get isBalanced => totalDebit == totalCredit;
}

/// Modèle pour le Compte de Résultat (SYSCOHADA)
class IncomeStatementReport {
  final List<AccountBalance> charges; // Classe 6
  final List<AccountBalance> produits; // Classe 7

  const IncomeStatementReport({
    required this.charges,
    required this.produits,
  });

  /// Total Charges (Net Débit - Crédit)
  double get totalCharges => charges.fold(
        0.0,
        (sum, item) => sum + (item.totalDebit - item.totalCredit),
      );

  /// Total Produits (Net Crédit - Débit)
  double get totalProduits => produits.fold(
        0.0,
        (sum, item) => sum + (item.totalCredit - item.totalDebit),
      );

  /// Résultat Net de l'exercice
  double get resultatNet => totalProduits - totalCharges;
  bool get isBenefice => resultatNet >= 0;
}

/// Modèle synthétique pour le Bilan (Actif vs Passif)
class BalanceSheetReport {
  final List<AccountBalance> actif; // Classes 2, 3, 4 (débit), 5 (débit)
  final List<AccountBalance> passif; // Classes 1, 4 (crédit), 5 (crédit)
  final double resultatExercice;

  const BalanceSheetReport({
    required this.actif,
    required this.passif,
    required this.resultatExercice,
  });

  /// Total Actif (Somme des soldes débiteurs des comptes du bilan)
  double get totalActif =>
      actif.fold(0.0, (sum, item) => sum + item.debitBalance);

  /// Total Passif (Somme des soldes créditeurs + Résultat de l'exercice)
  double get totalPassif =>
      passif.fold(0.0, (sum, item) => sum + item.creditBalance) +
      resultatExercice;

  /// Vérifie l'équilibre fondamental du bilan (Actif = Passif)
  bool get isBalanced => (totalActif - totalPassif).abs() < 0.01;
}

class AccountingReportService {
  /// Génère la balance générale de tous les comptes
  static List<AccountBalance> calculateTrialBalance(
    List<JournalEntry> entries,
  ) {
    final Map<String, AccountBalance> balances = {};

    for (final entry in entries) {
      for (final line in entry.lines) {
        if (line.accountCode.isEmpty) continue;

        final account = balances.putIfAbsent(
          line.accountCode,
          () => AccountBalance(
            accountCode: line.accountCode,
            accountLabel: line.accountLabel,
          ),
        );

        account.totalDebit += line.debit;
        account.totalCredit += line.credit;
      }
    }

    final result = balances.values.toList();
    result.sort((a, b) => a.accountCode.compareTo(b.accountCode));
    return result;
  }

  /// Génère le Compte de Résultat (Classe 6 & Classe 7)
  static IncomeStatementReport calculateIncomeStatement(
    List<JournalEntry> entries,
  ) {
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
  static BalanceSheetReport calculateBalanceSheet(
    List<JournalEntry> entries,
  ) {
    final trialBalance = calculateTrialBalance(entries);
    final incomeStatement = calculateIncomeStatement(entries);

    final actif = <AccountBalance>[];
    final passif = <AccountBalance>[];

    for (final b in trialBalance) {
      if (b.accountCode.isEmpty) continue;

      final classCode = b.accountCode[0];

      // Exclure la sous-classe 13 (Résultat de l'exercice) pour éviter le double comptage
      if (b.accountCode.startsWith('13')) continue;

      // Seuls les comptes de bilan (Classes 1 à 5)
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