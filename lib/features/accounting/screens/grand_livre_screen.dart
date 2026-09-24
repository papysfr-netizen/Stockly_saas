// lib/features/accounting/presentation/screens/grand_livre_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:stockly_saas/features/accounting/models/journal_entry.dart';
import 'package:stockly_saas/features/accounting/services/accounting_journal_service.dart';
import 'package:stockly_saas/features/accounting/services/accounting_pdf_service.dart';

class GrandLivreRow {
  final DateTime date;
  final String reference;
  final String description;
  final double debit;
  final double credit;
  final double soldeCumule;

  const GrandLivreRow({
    required this.date,
    required this.reference,
    required this.description,
    required this.debit,
    required this.credit,
    required this.soldeCumule,
  });
}

class GrandLivreScreen extends StatefulWidget {
  final String entrepriseId;

  const GrandLivreScreen({super.key, required this.entrepriseId});

  @override
  State<GrandLivreScreen> createState() => _GrandLivreScreenState();
}

class _GrandLivreScreenState extends State<GrandLivreScreen> {
  final AccountingJournalService _journalService = AccountingJournalService();
  String _selectedAccount = '571000';

  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, 1, 1),
    end: DateTime.now(),
  );

  final List<String> _accountCodes = const [
    '571000',
    '521000',
    '572000',
    '411000',
    '401000',
    '601000',
    '603100',
    '701000',
    '311000',
    '443100',
    '445200',
  ];

  Future<String> _getNomEntreprise() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('entreprises')
          .doc(widget.entrepriseId)
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data()?['nom'] ?? doc.data()?['name'] ?? 'Stockly Entreprise';
      }
    } catch (_) {}
    return 'Stockly Entreprise';
  }

  List<GrandLivreRow> _processLedgerRows(List<JournalEntry> allEntries) {
    final filteredEntries = allEntries.where((entry) {
      return entry.date
              .isAfter(_dateRange.start.subtract(const Duration(days: 1))) &&
          entry.date.isBefore(_dateRange.end.add(const Duration(days: 1)));
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final List<GrandLivreRow> rows = [];
    double runningBalance = 0.0;

    for (final entry in filteredEntries) {
      for (final line in entry.lines) {
        if (line.accountCode == _selectedAccount) {
          runningBalance += (line.debit - line.credit);

          rows.add(
            GrandLivreRow(
              date: entry.date,
              reference: entry.reference,
              description: entry.description,
              debit: line.debit,
              credit: line.credit,
              soldeCumule: runningBalance,
            ),
          );
        }
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grand Livre des Comptes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exporter / Imprimer le Grand Livre',
            onPressed: () async {
              final entries = await _journalService
                  .streamEcritures(widget.entrepriseId)
                  .first;
              
              if (!mounted) return;

              final rows = _processLedgerRows(entries);

              if (rows.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Aucune donnée à exporter pour ce compte.'),
                  ),
                );
                return;
              }

              final totalDebit = rows.fold(0.0, (totalSum, item) => totalSum + item.debit);
              final totalCredit = rows.fold(0.0, (totalSum, item) => totalSum + item.credit);
              final soldeFinal = totalDebit - totalCredit;
              
              final nomEntreprise = await _getNomEntreprise();

              if (!mounted) return;

              await GrandLivrePdfService.imprimerOuExporterGrandLivre(
                nomEntreprise: nomEntreprise,
                selectedAccount: _selectedAccount,
                dateRange: _dateRange,
                rows: rows,
                totalDebit: totalDebit,
                totalCredit: totalCredit,
                soldeFinal: soldeFinal,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DropdownButton<String>(
                      value: _selectedAccount,
                      items: _accountCodes.map((code) {
                        return DropdownMenuItem<String>(
                          value: code,
                          child: Text(
                            '$code - ${AccountingJournalService.getAccountLabel(code)}',
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedAccount = val);
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        '${DateFormat('dd/MM/yyyy').format(_dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange.end)}',
                      ),
                      onPressed: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          initialDateRange: _dateRange,
                        );
                        if (range != null && mounted) {
                          setState(() => _dateRange = range);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<JournalEntry>>(
                stream: _journalService.streamEcritures(widget.entrepriseId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur : ${snapshot.error}'));
                  }

                  final entries = snapshot.data ?? [];
                  final rows = _processLedgerRows(entries);

                  if (rows.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucune écriture enregistrée pour ce compte sur cette période.',
                      ),
                    );
                  }

                  final totalDebit =
                      rows.fold(0.0, (totalSum, item) => totalSum + item.debit);
                  final totalCredit =
                      rows.fold(0.0, (totalSum, item) => totalSum + item.credit);
                  final soldeFinal = totalDebit - totalCredit;

                  return Column(
                    children: [
                      Row(
                        children: [
                          _buildBadge(
                            'Total Débit',
                            '${totalDebit.toStringAsFixed(2)} \$',
                            Colors.green,
                          ),
                          const SizedBox(width: 8),
                          _buildBadge(
                            'Total Crédit',
                            '${totalCredit.toStringAsFixed(2)} \$',
                            Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          _buildBadge(
                            'Solde Final',
                            '${soldeFinal.abs().toStringAsFixed(2)} \$ ${soldeFinal >= 0 ? "(D)" : "(C)"}',
                            soldeFinal >= 0 ? Colors.blue : Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Card(
                          elevation: 2,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Date')),
                                  DataColumn(label: Text('Référence')),
                                  DataColumn(label: Text('Libellé')),
                                  DataColumn(label: Text('Débit')),
                                  DataColumn(label: Text('Crédit')),
                                  DataColumn(label: Text('Solde Cumulé')),
                                ],
                                rows: rows.map((row) {
                                  return DataRow(cells: [
                                    DataCell(
                                      Text(
                                        DateFormat('dd/MM/yyyy')
                                            .format(row.date),
                                      ),
                                    ),
                                    DataCell(Text(row.reference)),
                                    DataCell(Text(row.description)),
                                    DataCell(
                                      Text(
                                        row.debit > 0
                                            ? '${row.debit.toStringAsFixed(2)} \$'
                                            : '-',
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        row.credit > 0
                                            ? '${row.credit.toStringAsFixed(2)} \$'
                                            : '-',
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '${row.soldeCumule.toStringAsFixed(2)} \$',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: row.soldeCumule >= 0
                                              ? Colors.black
                                              : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}