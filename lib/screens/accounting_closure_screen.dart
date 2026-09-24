// lib/screens/accounting_closure_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stockly_saas/features/accounting/models/journal_entry.dart';
import 'package:stockly_saas/core/services/accounting_closure_service.dart';
import 'package:stockly_saas/features/accounting/services/accounting_journal_service.dart';
import 'package:stockly_saas/core/services/accounting_report_service.dart';
class AccountingClosureScreen extends StatefulWidget {
  final String entrepriseId;
  final String entrepriseNom;
  final List<JournalEntry> entries;

  const AccountingClosureScreen({
    super.key,
    required this.entrepriseId,
    required this.entrepriseNom,
    required this.entries,
  });

  @override
  State<AccountingClosureScreen> createState() => _AccountingClosureScreenState();
}

class _AccountingClosureScreenState extends State<AccountingClosureScreen> {
  final AccountingJournalService _journalService = AccountingJournalService();
  int _selectedYear = DateTime.now().year;
  bool _isSaving = false;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 2,
  );

  List<JournalEntry> get _filteredEntriesForYear {
    return widget.entries.where((e) => e.date.year == _selectedYear).toList();
  }

  Future<void> _executeClosure(JournalEntry closureEntry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clôture de l\'exercice $_selectedYear'),
        content: const Text(
          'Cette action va solder l\'ensemble des comptes de produits (Classe 7) et de charges (Classe 6) '
          'et enregistrer l\'écriture de résultat dans le journal comptable.\n\nSouhaitez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Valider la Clôture'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isSaving = true);
      try {
        await _journalService.saveJournalEntry(closureEntry);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exercice $_selectedYear clôturé avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la clôture : $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final yearEntries = _filteredEntriesForYear;
    final incomeReport = AccountingReportService.calculateIncomeStatement(yearEntries);

    final closureDate = DateTime(_selectedYear, 12, 31);
    final closureEntry = yearEntries.isNotEmpty
        ? AccountingClosureService.generateClosureEntry(
            entrepriseId: widget.entrepriseId,
            closureDate: closureDate,
            entriesOfYear: yearEntries,
          )
        : null;

    final currentYear = DateTime.now().year;
    final availableYears = List.generate(5, (index) => currentYear - index);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clôture d\'Exercice SYSCOHADA'),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Sélection de l'année comptable
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Exercice Comptable :',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        DropdownButton<int>(
                          value: _selectedYear,
                          items: availableYears
                              .map((y) => DropdownMenuItem(
                                    value: y,
                                    child: Text('Année $y', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedYear = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Synthèse du Résultat à solder
                Card(
                  color: incomeReport.isBenefice
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: incomeReport.isBenefice ? Colors.green : Colors.red,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Synthèse de l\'exercice $_selectedYear',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Produits (Classe 7) :'),
                            Text(
                              _currencyFormat.format(incomeReport.totalProduits),
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Charges (Classe 6) :'),
                            Text(
                              _currencyFormat.format(incomeReport.totalCharges),
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              incomeReport.isBenefice ? 'RÉSULTAT (BÉNÉFICE) :' : 'RÉSULTAT (PERTE) :',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _currencyFormat.format(incomeReport.resultatNet.abs()),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: incomeReport.isBenefice ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Prévisualisation de la pièce de clôture
                Text(
                  'Aperçu de la Pièce de Clôture',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                if (closureEntry == null || yearEntries.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'Aucune écriture enregistrée pour cet exercice.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                  )
                else ...[
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(3),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(2),
                    },
                    border: TableBorder.all(color: colorScheme.outlineVariant, width: 0.5),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest),
                        children: const [
                          Padding(padding: EdgeInsets.all(6.0), child: Text('Compte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(6.0), child: Text('Libellé', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(6.0), child: Text('Débit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                          Padding(padding: EdgeInsets.all(6.0), child: Text('Crédit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                        ],
                      ),
                      ...closureEntry.lines.map((line) {
                        return TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(6.0), child: Text(line.accountCode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                            Padding(padding: const EdgeInsets.all(6.0), child: Text(line.accountLabel, style: const TextStyle(fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(6.0), child: Text(line.debit > 0 ? _currencyFormat.format(line.debit) : '-', style: const TextStyle(fontSize: 11), textAlign: TextAlign.right)),
                            Padding(padding: const EdgeInsets.all(6.0), child: Text(line.credit > 0 ? _currencyFormat.format(line.credit) : '-', style: const TextStyle(fontSize: 11), textAlign: TextAlign.right)),
                          ],
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _executeClosure(closureEntry),
                    icon: const Icon(Icons.lock_clock),
                    label: Text('Générer et Enregistrer la Clôture $_selectedYear'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}