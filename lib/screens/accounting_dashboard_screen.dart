// lib/screens/accounting_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/journal_provider.dart';
import '../services/csv_export_service.dart';
import '../services/excel_export_service.dart';
import 'add_journal_entry_screen.dart';
import 'balance_screen.dart';
import 'balance_sheet_screen.dart';
import 'income_statement_screen.dart';
import 'journal_screen.dart';

class AccountingDashboardScreen extends ConsumerWidget {
  final String entrepriseId;

  const AccountingDashboardScreen({
    super.key,
    required this.entrepriseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalAsync = ref.watch(journalEntriesStreamProvider(entrepriseId));
    final trialBalance = ref.watch(trialBalanceProvider(entrepriseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comptabilité & Finance'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: 'Exporter',
            onSelected: (value) async {
              final entries = journalAsync.value ?? [];
              if (value == 'csv') {
                await CsvExportService.exportAndShareJournal(entries);
              } else if (value == 'excel') {
                await ExcelExportService.exportAndShareExcel(
                  entries: entries,
                  balances: trialBalance,
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Exporter vers Excel (.xlsx)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Exporter vers CSV'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildNavCard(
              context,
              title: 'Journal Comptable',
              subtitle: 'Flux des écritures Débit/Crédit',
              icon: Icons.menu_book,
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JournalScreen(entrepriseId: entrepriseId),
                ),
              ),
            ),
            _buildNavCard(
              context,
              title: 'Balance des Comptes',
              subtitle: 'Soldes par classe SYSCOHADA',
              icon: Icons.account_balance,
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BalanceScreen(entrepriseId: entrepriseId),
                ),
              ),
            ),
            _buildNavCard(
              context,
              title: 'Compte de Résultat',
              subtitle: 'Bénéfices & Perte (6 vs 7)',
              icon: Icons.pie_chart,
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      IncomeStatementScreen(entrepriseId: entrepriseId),
                ),
              ),
            ),
            _buildNavCard(
              context,
              title: 'Bilan Comptable',
              subtitle: 'Actif & Passif (Classes 1 à 5)',
              icon: Icons.account_balance_wallet,
              color: Colors.indigo,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      BalanceSheetScreen(entrepriseId: entrepriseId),
                ),
              ),
            ),
            _buildNavCard(
              context,
              title: 'Saisie Opération (OD)',
              subtitle: 'Ajout manuel d\'écritures',
              icon: Icons.post_add,
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AddJournalEntryScreen(entrepriseId: entrepriseId),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}