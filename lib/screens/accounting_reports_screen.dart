// lib/screens/accounting_reports_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stockly_saas/features/accounting/models/journal_entry.dart';
import 'package:stockly_saas/core/services/accounting_report_service.dart';
import 'package:stockly_saas/core/services/pdf_export_service.dart';
import 'package:stockly_saas/core/providers/currency_provider.dart';

class AccountingReportsScreen extends ConsumerStatefulWidget {
  final String entrepriseNom;
  final List<JournalEntry> entries;

  const AccountingReportsScreen({
    super.key,
    required this.entrepriseNom,
    required this.entries,
  });

  @override
  ConsumerState<AccountingReportsScreen> createState() => _AccountingReportsScreenState();
}

class _AccountingReportsScreenState extends ConsumerState<AccountingReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    // Récupération dynamique et propre de la devise active avec .toString()
    final currencyCode = ref.watch(currencyProvider).toString();
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: currencyCode,
      decimalDigits: 2,
    );

    final trialBalance = AccountingReportService.calculateTrialBalance(widget.entries);
    final incomeStatement = AccountingReportService.calculateIncomeStatement(widget.entries);
    final balanceSheet = AccountingReportService.calculateBalanceSheet(widget.entries);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Rapports Financiers - ${widget.entrepriseNom}'),
        backgroundColor: const Color(0xFF1E293B), // Bleu nuit professionnel
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
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
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange.shade800,
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
          _buildTrialBalanceTab(trialBalance, currencyFormat),

          // 2. Compte de Résultat
          _buildIncomeStatementTab(incomeStatement, currencyFormat),

          // 3. Bilan Comptable
          _buildBalanceSheetTab(balanceSheet, currencyFormat),
        ],
      ),
    );
  }

  // --- ONGLET 1 : BALANCE GÉNÉRALE ---
  Widget _buildTrialBalanceTab(List<AccountBalance> balances, NumberFormat currencyFormat) {
    if (balances.isEmpty) {
      return const Center(child: Text('Aucune écriture enregistrée pour générer la balance.', style: TextStyle(color: Colors.grey)));
    }

    final totalDebit = balances.fold(0.0, (s, b) => s + b.totalDebit);
    final totalCredit = balances.fold(0.0, (s, b) => s + b.totalCredit);

    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFF1E293B).withValues(alpha: 0.05)),
                  columns: const [
                    DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                    DataColumn(label: Text('Intitulé', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                    DataColumn(label: Text('Débit', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))), numeric: true),
                    DataColumn(label: Text('Crédit', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))), numeric: true),
                    DataColumn(label: Text('Solde Débiteur', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))), numeric: true),
                    DataColumn(label: Text('Solde Créditeur', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))), numeric: true),
                  ],
                  rows: balances.map((b) {
                    return DataRow(
                      cells: [
                        DataCell(Text(b.accountCode, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(b.accountLabel)),
                        DataCell(Text(currencyFormat.format(b.totalDebit))),
                        DataCell(Text(currencyFormat.format(b.totalCredit))),
                        DataCell(Text(b.isDebtor ? currencyFormat.format(b.debitBalance) : '-')),
                        DataCell(Text(b.isCreditor ? currencyFormat.format(b.creditBalance) : '-')),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          color: const Color(0xFF1E293B),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAUX GÉNÉRAUX', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              Text(
                'D: ${currencyFormat.format(totalDebit)} | C: ${currencyFormat.format(totalCredit)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- ONGLET 2 : COMPTE DE RÉSULTAT ---
  Widget _buildIncomeStatementTab(IncomeStatementReport report, NumberFormat currencyFormat) {
    final isBenefice = report.isBenefice;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Carte Résultat Net avec le bandeau orange vif caractéristique de l'app
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isBenefice ? 'RÉSULTAT NET (BÉNÉFICE NET)' : 'RÉSULTAT NET (PERTE NETTE)',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white24,
                      radius: 18,
                      child: Icon(
                        isBenefice ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currencyFormat.format(report.resultatNet.abs()),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isBenefice ? 'Votre entreprise est bénéficiaire !' : 'Votre entreprise est déficitaire',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Produits (Classe 7)
        _buildSectionBox(
          title: 'PRODUITS (Classe 7)',
          items: report.produits,
          totalText: 'Total Produits: ${currencyFormat.format(report.totalProduits)}',
          headerColor: Colors.green.shade800,
          currencyFormat: currencyFormat,
          isProduct: true,
        ),
        const SizedBox(height: 16),

        // Charges (Classe 6)
        _buildSectionBox(
          title: 'CHARGES (Classe 6)',
          items: report.charges,
          totalText: 'Total Charges: ${currencyFormat.format(report.totalCharges)}',
          headerColor: Colors.red.shade800,
          currencyFormat: currencyFormat,
          isProduct: false,
        ),
      ],
    );
  }

  // --- ONGLET 3 : BILAN COMPTABLE ---
  Widget _buildBalanceSheetTab(BalanceSheetReport report, NumberFormat currencyFormat) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Indicateur d'équilibre du bilan
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: report.isBalanced ? Colors.green.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: report.isBalanced ? Colors.green : Colors.orange),
          ),
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
                    color: report.isBalanced ? Colors.green.shade800 : Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Section Actif et Passif sous forme de cartes épurées
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ACTIF
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ACTIF (Emplois)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const Divider(),
                    if (report.actif.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Aucun compte d\'actif.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    ...report.actif.map((b) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('${b.accountCode} - ${b.accountLabel}', style: const TextStyle(fontSize: 12)),
                          trailing: Text(currencyFormat.format(b.debitBalance), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        )),
                    const Divider(),
                    Text(
                      'TOTAL ACTIF:\n${currencyFormat.format(report.totalActif)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // PASSIF
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PASSIF (Ressources)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const Divider(),
                    if (report.passif.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Aucun compte de passif.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    ...report.passif.map((b) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('${b.accountCode} - ${b.accountLabel}', style: const TextStyle(fontSize: 12)),
                          trailing: Text(currencyFormat.format(b.creditBalance), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        )),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('13 - Résultat Net', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      trailing: Text(
                        currencyFormat.format(report.resultatExercice),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: report.resultatExercice >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    const Divider(),
                    Text(
                      'TOTAL PASSIF:\n${currencyFormat.format(report.totalPassif)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionBox({
    required String title,
    required List<AccountBalance> items,
    required String totalText,
    required Color headerColor,
    required NumberFormat currencyFormat,
    required bool isProduct,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: headerColor, fontSize: 14)),
                Text(
                  totalText.split(': ')[1],
                  style: TextStyle(fontWeight: FontWeight.bold, color: headerColor, fontSize: 14),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Aucun compte enregistré.', style: TextStyle(color: Colors.grey, fontSize: 13)),
            )
          else
            ...items.map((b) {
              final amount = isProduct ? (b.totalCredit - b.totalDebit) : (b.totalDebit - b.totalCredit);
              return ListTile(
                dense: true,
                title: Text('${b.accountCode} - ${b.accountLabel}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                trailing: Text(
                  currencyFormat.format(amount),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              );
            }),
        ],
      ),
    );
  }
}