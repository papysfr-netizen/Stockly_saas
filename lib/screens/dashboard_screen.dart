// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';
import '../services/accounting_journal_service.dart';
import '../services/accounting_report_service.dart';
import 'accounting_reports_screen.dart';
import 'ecriture_form_screen.dart';
import 'journal_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String entrepriseId;
  final String entrepriseNom;

  const DashboardScreen({
    super.key,
    required this.entrepriseId,
    required this.entrepriseNom,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AccountingJournalService _journalService = AccountingJournalService();

  static final _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  void _navigateToNewEntry() async {
    final newEntry = await Navigator.push<JournalEntry>(
      context,
      MaterialPageRoute(
        builder: (context) => EcritureFormScreen(
          entrepriseId: widget.entrepriseId,
        ),
      ),
    );

    if (newEntry != null && mounted) {
      final entryWithCompany = JournalEntry(
        id: newEntry.id,
        entrepriseId: widget.entrepriseId,
        date: newEntry.date,
        journalCode: newEntry.journalCode,
        reference: newEntry.reference,
        description: newEntry.description,
        lines: newEntry.lines,
        montantEncaisse: newEntry.montantEncaisse,
      );

      await _journalService.saveJournalEntry(entryWithCompany);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Écriture enregistrée avec succès.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entrepriseNom.isEmpty ? 'Tableau de Bord' : widget.entrepriseNom),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Rapports financiers',
            onPressed: () {
              // Navigue vers les rapports en passant les écritures chargées
            },
          ),
        ],
      ),
      body: StreamBuilder<List<JournalEntry>>(
        stream: _journalService.streamEcritures(widget.entrepriseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data ?? [];
          final incomeReport = AccountingReportService.calculateIncomeStatement(entries);
          final trialBalance = AccountingReportService.calculateTrialBalance(entries);

          // Calcul de la Trésorerie globale (Comptes Classe 5: Banque, Caisse, Mobile Money)
          final tresorerieAccounts = trialBalance.where((b) => b.accountCode.startsWith('5'));
          final totalTresorerie = tresorerieAccounts.fold(
            0.0,
            (sum, b) => sum + (b.totalDebit - b.totalCredit),
          );

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // En-tête de bienvenue
                Text(
                  'Aperçu financier SYSCOHADA',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 12),

                // Grille d'Indicateurs Clés (KPI)
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.4,
                  children: [
                    _KpiCard(
                      title: 'Trésorerie Dispon.',
                      amount: _currencyFormat.format(totalTresorerie),
                      icon: Icons.account_balance_wallet_outlined,
                      color: totalTresorerie >= 0 ? Colors.blue : Colors.deepOrange,
                    ),
                    _KpiCard(
                      title: 'Chiffre d\'Affaires',
                      amount: _currencyFormat.format(incomeReport.totalProduits),
                      icon: Icons.trending_up,
                      color: Colors.green,
                    ),
                    _KpiCard(
                      title: 'Total Charges',
                      amount: _currencyFormat.format(incomeReport.totalCharges),
                      icon: Icons.trending_down,
                      color: Colors.redAccent,
                    ),
                    _KpiCard(
                      title: 'Résultat Net',
                      amount: _currencyFormat.format(incomeReport.resultatNet.abs()),
                      subtitle: incomeReport.isBenefice ? 'Bénéfice' : 'Perte',
                      icon: incomeReport.isBenefice ? Icons.arrow_upward : Icons.arrow_downward,
                      color: incomeReport.isBenefice ? Colors.teal : Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Raccourcis d'actions
                Text(
                  'Actions rapides',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Saisir Écriture',
                        icon: Icons.edit_note_outlined,
                        color: colorScheme.primary,
                        onPressed: _navigateToNewEntry,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        label: 'Journal Général',
                        icon: Icons.menu_book_outlined,
                        color: colorScheme.secondary,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JournalListScreen(
                                entrepriseId: widget.entrepriseId,
                                entrepriseNom: widget.entrepriseNom,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        label: 'États Financiers',
                        icon: Icons.pie_chart_outline,
                        color: colorScheme.tertiary,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AccountingReportsScreen(
                                entrepriseNom: widget.entrepriseNom,
                                entries: entries,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Dernières écritures enregistrées
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dernières opérations',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JournalListScreen(
                              entrepriseId: widget.entrepriseId,
                              entrepriseNom: widget.entrepriseNom,
                            ),
                          ),
                        );
                      },
                      child: const Text('Tout voir'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (entries.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'Aucune opération enregistrée pour le moment.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                  )
                else
                  ...entries.take(5).map((entry) {
                    final totalAmount = entry.lines.fold(0.0, (s, l) => s + l.debit);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.receipt_outlined, size: 20),
                        ),
                        title: Text(
                          entry.reference,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${_dateFormat.format(entry.date)} • ${entry.description}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          _currencyFormat.format(totalAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Carte représentant un KPI financier
class _KpiCard extends StatelessWidget {
  final String title;
  final String amount;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.amount,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    amount,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 10, color: color),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton d'action rapide sous forme de carte
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}