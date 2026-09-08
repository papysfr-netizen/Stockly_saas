// lib/screens/accounting_reports_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';
import '../services/accounting_report_service.dart';
import '../services/pdf_export_service.dart';

class AccountingReportsScreen extends StatefulWidget {
  final String entrepriseNom;
  final List<JournalEntry> entries;

  const AccountingReportsScreen({
    super.key,
    required this.entrepriseNom,
    required this.entries,
  });

  @override
  State<AccountingReportsScreen> createState() => _AccountingReportsScreenState();
}

class _AccountingReportsScreenState extends State<AccountingReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _exportCurrentTabPdf({
    required List<AccountBalance> trialBalance,
    required IncomeStatementReport incomeStatement,
    required BalanceSheetReport balanceSheet,
  }) {
    switch (_tabController.index) {
      case 0:
        PdfExportService.printTrialBalance(
          entrepriseNom: widget.entrepriseNom,
          balances: trialBalance,
        );
        break;
      case 1:
        PdfExportService.printIncomeStatement(
          entrepriseNom: widget.entrepriseNom,
          report: incomeStatement,
        );
        break;
      case 2:
        PdfExportService.printBalanceSheet(
          entrepriseNom: widget.entrepriseNom,
          report: balanceSheet,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final trialBalance = AccountingReportService.calculateTrialBalance(widget.entries);
    final incomeStatement = AccountingReportService.calculateIncomeStatement(widget.entries);
    final balanceSheet = AccountingReportService.calculateBalanceSheet(widget.entries);

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports Financiers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Imprimer / Exporter le PDF',
            onPressed: () => _exportCurrentTabPdf(
              trialBalance: trialBalance,
              incomeStatement: incomeStatement,
              balanceSheet: balanceSheet,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Balance', icon: Icon(Icons.table_chart_outlined)),
            Tab(text: 'Résultat', icon: Icon(Icons.analytics_outlined)),
            Tab(text: 'Bilan', icon: Icon(Icons.account_balance_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Balance Générale
          _buildTrialBalanceTab(trialBalance, colorScheme),

          // 2. Compte de Résultat
          _buildIncomeStatementTab(incomeStatement, colorScheme),

          // 3. Bilan Comptable
          _buildBalanceSheetTab(balanceSheet, colorScheme),
        ],
      ),
    );
  }

  // --- ONGLET 1 : BALANCE GÉNÉRALE ---
  Widget _buildTrialBalanceTab(List<AccountBalance> balances, ColorScheme colorScheme) {
    if (balances.isEmpty) {
      return const Center(child: Text('Aucune écriture enregistrée pour générer la balance.'));
    }

    final totalDebit = balances.fold(0.0, (s, b) => s + b.totalDebit);
    final totalCredit = balances.fold(0.0, (s, b) => s + b.totalCredit);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(colorScheme.primaryContainer),
                columns: const [
                  DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Intitulé', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Débit', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Crédit', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Solde Débiteur', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                  DataColumn(label: Text('Solde Créditeur', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                ],
                rows: balances.map((b) {
                  return DataRow(
                    cells: [
                      DataCell(Text(b.accountCode, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(b.accountLabel)),
                      DataCell(Text(_currencyFormat.format(b.totalDebit))),
                      DataCell(Text(_currencyFormat.format(b.totalCredit))),
                      DataCell(Text(b.isDebtor ? _currencyFormat.format(b.debitBalance) : '-')),
                      DataCell(Text(b.isCreditor ? _currencyFormat.format(b.creditBalance) : '-')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          color: colorScheme.surfaceContainerHighest,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAUX GÉNÉRAUX', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                'D: ${_currencyFormat.format(totalDebit)} | C: ${_currencyFormat.format(totalCredit)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- ONGLET 2 : COMPTE DE RÉSULTAT ---
  Widget _buildIncomeStatementTab(IncomeStatementReport report, ColorScheme colorScheme) {
    final resultColor = report.isBenefice ? Colors.green : Colors.red;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Carte Résultat Net
        Card(
          color: resultColor.withValues(alpha: 0.1),
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: resultColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.isBenefice ? 'RÉSULTAT NET : BÉNÉFICE' : 'RÉSULTAT NET : PERTE',
                      style: TextStyle(fontWeight: FontWeight.bold, color: resultColor, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text('Exercice SYSCOHADA', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                Text(
                  _currencyFormat.format(report.resultatNet.abs()),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: resultColor),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Produits (Classe 7)
        Text('PRODUITS (CLASSE 7)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildAccountTable(report.produits, isProduct: true),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Total Produits: ${_currencyFormat.format(report.totalProduits)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Charges (Classe 6)
        Text('CHARGES (CLASSE 6)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildAccountTable(report.charges, isProduct: false),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Total Charges: ${_currencyFormat.format(report.totalCharges)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  // --- ONGLET 3 : BILAN COMPTABLE ---
  Widget _buildBalanceSheetTab(BalanceSheetReport report, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Indicateur d'équilibre du bilan
        Card(
          color: report.isBalanced ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(
                  report.isBalanced ? Icons.check_circle : Icons.error_outline,
                  color: report.isBalanced ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    report.isBalanced
                        ? 'Bilan Équilibré (Actif = Passif)'
                        : 'Écart de Bilan détecté ! Vérifiez la saisie des écritures.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: report.isBalanced ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ACTIF
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ACTIF (Emplois)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const Divider(),
                  ...report.actif.map((b) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('${b.accountCode} - ${b.accountLabel}'),
                        trailing: Text(_currencyFormat.format(b.debitBalance)),
                      )),
                  const Divider(),
                  Text(
                    'TOTAL ACTIF: ${_currencyFormat.format(report.totalActif)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // PASSIF
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PASSIF (Ressources)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const Divider(),
                  ...report.passif.map((b) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('${b.accountCode} - ${b.accountLabel}'),
                        trailing: Text(_currencyFormat.format(b.creditBalance)),
                      )),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('130000 - Résultat Net de l\'exercice', style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text(
                      _currencyFormat.format(report.resultatExercice),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: report.resultatExercice >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  const Divider(),
                  Text(
                    'TOTAL PASSIF: ${_currencyFormat.format(report.totalPassif)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountTable(List<AccountBalance> items, {required bool isProduct}) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('Aucun compte répertorié.', style: TextStyle(fontStyle: FontStyle.italic)),
      );
    }

    return Column(
      children: items.map((b) {
        final amount = isProduct ? (b.totalCredit - b.totalDebit) : (b.totalDebit - b.totalCredit);
        return Card(
          margin: const EdgeInsets.only(bottom: 6.0),
          child: ListTile(
            dense: true,
            title: Text('${b.accountCode} - ${b.accountLabel}'),
            trailing: Text(
              _currencyFormat.format(amount),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }
}