// lib/features/accounting/screens/journal_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:stockly_saas/features/accounting/models/journal_entry.dart';
import 'package:stockly_saas/features/accounting/services/accounting_journal_service.dart';
import 'package:stockly_saas/core/services/pdf_export_service.dart';

class JournalScreen extends StatefulWidget {
  final String entrepriseId;

  const JournalScreen({
    super.key,
    required this.entrepriseId,
  });

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final AccountingJournalService _journalService = AccountingJournalService();
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 2,
  );

  String _searchQuery = '';
  bool _isCleaning = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Déclenche le nettoyage/migration des anciennes données non structurées
  Future<void> _handleCleanAndMigrate() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nettoyage du journal'),
        content: const Text(
          'Cette action va supprimer les anciennes écritures obsolètes '
          'ne respectant pas la structure par lignes. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Nettoyer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (!mounted || confirm != true) return;

    setState(() => _isCleaning = true);

    try {
      final count =
          await _journalService.cleanAndMigrateEcritures(widget.entrepriseId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count écriture(s) obsolète(s) supprimée(s).'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du nettoyage : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCleaning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Comptable'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: 'Nettoyer / Migrer le journal',
            onPressed: _isCleaning ? null : _handleCleanAndMigrate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par référence, libellé...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase().trim()),
            ),
          ),

          // Flux temps réel des écritures comptables
          Expanded(
            child: StreamBuilder<List<JournalEntry>>(
              stream: _journalService.streamEcritures(widget.entrepriseId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Erreur de chargement : ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final entries = snapshot.data ?? [];

                // Filtrage selon la recherche
                final filteredEntries = entries.where((entry) {
                  if (_searchQuery.isEmpty) return true;
                  return entry.reference
                          .toLowerCase()
                          .contains(_searchQuery) ||
                      entry.description.toLowerCase().contains(_searchQuery) ||
                      entry.lines.any((l) =>
                          l.accountCode.contains(_searchQuery) ||
                          l.accountLabel.toLowerCase().contains(_searchQuery));
                }).toList();

                if (filteredEntries.isEmpty) {
                  return const Center(
                    child: Text('Aucune écriture comptable trouvée.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredEntries.length,
                  itemBuilder: (context, index) {
                    final entry = filteredEntries[index];
                    return _JournalEntryCard(
                      entry: entry,
                      currencyFormat: _currencyFormat,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte d'affichage d'une pièce comptable
class _JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final NumberFormat currencyFormat;

  const _JournalEntryCard({
    required this.entry,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la pièce comptable
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        entry.reference,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!entry.isBalanced)
                      Tooltip(
                        message: 'Pièce déséquilibrée',
                        child: Icon(Icons.warning_amber_rounded,
                            color: Colors.orange.shade800),
                      ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      dateFormat.format(entry.date),
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.print_outlined, size: 20),
                      tooltip: 'Imprimer la pièce comptable',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => PdfExportService.printJournalEntry(entry),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Libellé de la pièce
            Text(
              entry.description,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const Divider(height: 16),

            // Tableau des lignes Débit / Crédit
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.2), // Compte
                1: FlexColumnWidth(2.5), // Intitulé
                2: FlexColumnWidth(1.8), // Débit
                3: FlexColumnWidth(1.8), // Crédit
              },
              children: [
                // En-tête du tableau
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Text('Compte',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Text('Intitulé',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Text('Débit',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Text('Crédit',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),

                // Lignes comptables
                ...entry.lines.map((line) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text(
                          line.accountCode,
                          style: const TextStyle(
                              fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text(
                          line.accountLabel,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text(
                          line.debit > 0
                              ? currencyFormat.format(line.debit)
                              : '-',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: line.debit > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text(
                          line.credit > 0
                              ? currencyFormat.format(line.credit)
                              : '-',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: line.credit > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  );
                }),

                // Ligne de Total
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(color: Colors.grey.shade300, width: 1)),
                  ),
                  children: [
                    const Padding(padding: EdgeInsets.all(6.0)),
                    const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Text(
                        'Total',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        currencyFormat.format(entry.totalDebit),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.blue),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        currencyFormat.format(entry.totalCredit),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}