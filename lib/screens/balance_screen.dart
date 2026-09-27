// lib/screens/balance_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stockly_saas/features/accounting/models/journal_entry.dart';
import 'package:stockly_saas/features/accounting/services/accounting_journal_service.dart';
import '../core/services/accounting_report_service.dart';

class BalanceScreen extends StatelessWidget {
  final String entrepriseId;

  const BalanceScreen({
    super.key,
    required this.entrepriseId,
  });

  @override
  Widget build(BuildContext context) {
    final journalService = AccountingJournalService();
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Balance des Comptes (SYSCOHADA)'),
      ),
      body: StreamBuilder<List<JournalEntry>>(
        stream: journalService.streamEcritures(entrepriseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }

          final entries = snapshot.data ?? [];
          final balances = AccountingReportService.calculateTrialBalance(entries);

          if (balances.isEmpty) {
            return const Center(
              child: Text('Aucune donnée comptable disponible pour la balance.'),
            );
          }

          final grandTotalDebit =
              balances.fold<double>(0.0, (acc, b) => acc + b.totalDebit);
          final grandTotalCredit =
              balances.fold<double>(0.0, (acc, b) => acc + b.totalCredit);

          return Column(
            children: [
              // Résumé global Top Bar
              Container(
                color: Colors.blue.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem('Total Débit', grandTotalDebit, currencyFormat),
                    _buildSummaryItem('Total Crédit', grandTotalCredit, currencyFormat),
                    _buildSummaryItem(
                      'Équilibre',
                      grandTotalDebit - grandTotalCredit,
                      currencyFormat,
                      isBalanceCheck: true,
                    ),
                  ],
                ),
              ),

              // Tableau de la balance
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(Colors.grey.shade200),
                      columns: const [
                        DataColumn(
                          label: Text('Compte', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text('Intitulé', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text('Total Débit', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text('Total Crédit', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text('Solde Débiteur', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text('Solde Créditeur', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                      rows: balances.map((b) {
                        final net = b.netBalance;
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                b.accountCode,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            DataCell(Text(b.accountLabel)),
                            DataCell(Text(currencyFormat.format(b.totalDebit))),
                            DataCell(Text(currencyFormat.format(b.totalCredit))),
                            DataCell(
                              Text(
                                net > 0 ? currencyFormat.format(net) : '-',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                net < 0 ? currencyFormat.format(net.abs()) : '-',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    double amount,
    NumberFormat format, {
    bool isBalanceCheck = false,
  }) {
    final isOk = isBalanceCheck ? amount.abs() < 0.01 : true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          isBalanceCheck
              ? (isOk ? 'ÉQUILIBRÉ' : 'DÉSÉQUILIBRÉ')
              : format.format(amount),
          style: TextStyle(
            color: isBalanceCheck
                ? (isOk ? Colors.greenAccent : Colors.orangeAccent)
                : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}