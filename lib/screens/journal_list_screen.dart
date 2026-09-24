// lib/screens/journal_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stockly_saas/features/accounting/models/journal_entry.dart';
import 'package:stockly_saas/features/accounting/services/accounting_journal_service.dart';
import 'ecriture_form_screen.dart';

class JournalListScreen extends StatefulWidget {
  final String entrepriseId;
  final String entrepriseNom;

  const JournalListScreen({
    super.key,
    required this.entrepriseId,
    required this.entrepriseNom,
  });

  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> {
  final AccountingJournalService _journalService = AccountingJournalService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 2,
  );

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<JournalEntry> _applyFilters(List<JournalEntry> entries) {
    return entries.where((entry) {
      // Filtre par recherche textuelle (Réf, description, comptes)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesRef = entry.reference.toLowerCase().contains(q);
        final matchesDesc = entry.description.toLowerCase().contains(q);
        final matchesAccount = entry.lines.any(
          (l) =>
              l.accountCode.contains(q) ||
              l.accountLabel.toLowerCase().contains(q),
        );
        if (!matchesRef && !matchesDesc && !matchesAccount) return false;
      }

      // Filtre par plage de dates
      if (_selectedDateRange != null) {
        if (entry.date.isBefore(_selectedDateRange!.start) ||
            entry.date.isAfter(_selectedDateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedDateRange = null;
    });
  }

  Future<void> _confirmDelete(JournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer la pièce "${entry.reference}" (${entry.description}) ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Suppression de la pièce dans Firestore
      await _journalService.saveJournalEntry(
        entry,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Écriture supprimée avec succès.')),
        );
      }
    }
  }

  void _openEcritureForm([JournalEntry? entryToEdit]) async {
    final newEntry = await Navigator.push<JournalEntry>(
      context,
      MaterialPageRoute(
        builder: (context) => EcritureFormScreen(
          entrepriseId: widget.entrepriseId,
          entryToEdit: entryToEdit,
        ),
      ),
    );

    if (newEntry != null) {
      // Attribution de l'entrepriseId si absent
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
          const SnackBar(content: Text('Écriture comptable enregistrée.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Général'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exporter le Journal en PDF',
            onPressed: () {
              // Impression via le service PDF
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEcritureForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle Écriture'),
      ),
      body: Column(
        children: [
          // Barre de recherche et de filtres
          Container(
            padding: const EdgeInsets.all(12.0),
            color: colorScheme.surfaceContainerLow,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par référence, libellé ou compte...',
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
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDateRange,
                        icon: const Icon(Icons.date_range, size: 18),
                        label: Text(
                          _selectedDateRange == null
                              ? 'Toutes les dates'
                              : '${_dateFormat.format(_selectedDateRange!.start)} - ${_dateFormat.format(_selectedDateRange!.end)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty || _selectedDateRange != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.filter_alt_off),
                        tooltip: 'Réinitialiser les filtres',
                        onPressed: _clearFilters,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Liste des écritures streamed depuis Firestore
          Expanded(
            child: StreamBuilder<List<JournalEntry>>(
              stream: _journalService.streamEcritures(widget.entrepriseId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erreur de chargement : ${snapshot.error}'),
                  );
                }

                final rawEntries = snapshot.data ?? [];
                final filteredEntries = _applyFilters(rawEntries);

                if (filteredEntries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 64, color: colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          rawEntries.isEmpty
                              ? 'Aucune écriture enregistrée'
                              : 'Aucun résultat pour cette recherche',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: filteredEntries.length,
                  itemBuilder: (context, index) {
                    final entry = filteredEntries[index];
                    return _JournalEntryCard(
                      entry: entry,
                      currencyFormat: _currencyFormat,
                      dateFormat: _dateFormat,
                      onEdit: () => _openEcritureForm(entry),
                      onDelete: () => _confirmDelete(entry),
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

/// Carte réutilisable pour afficher une pièce du journal avec accordéon
class _JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _JournalEntryCard({
    required this.entry,
    required this.currencyFormat,
    required this.dateFormat,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final totalDebit = entry.lines.fold(0.0, (s, l) => s + l.debit);
    final totalCredit = entry.lines.fold(0.0, (s, l) => s + l.credit);
    final isBalanced = (totalDebit - totalCredit).abs() < 0.01;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isBalanced ? colorScheme.outlineVariant : colorScheme.error,
        ),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(Icons.receipt, color: colorScheme.onPrimaryContainer),
        ),
        title: Text(
          'Réf: ${entry.reference}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${dateFormat.format(entry.date)} • ${entry.description.isNotEmpty ? entry.description : entry.label}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currencyFormat.format(totalDebit),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tableau des lignes de débit/crédit
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(3),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(2),
                  },
                  border: TableBorder.all(
                    color: colorScheme.outlineVariant,
                    width: 0.5,
                  ),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Text('Compte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Text('Intitulé', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Text('Débit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right),
                        ),
                        Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Text('Crédit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                    ...entry.lines.map((line) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(line.accountCode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(line.accountLabel, style: const TextStyle(fontSize: 12)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(
                              line.debit > 0 ? currencyFormat.format(line.debit) : '-',
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(
                              line.credit > 0 ? currencyFormat.format(line.credit) : '-',
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!isBalanced)
                      Chip(
                        avatar: const Icon(Icons.warning, color: Colors.white, size: 16),
                        label: const Text('Déséquilibré', style: TextStyle(color: Colors.white, fontSize: 11)),
                        backgroundColor: colorScheme.error,
                      )
                    else
                      const SizedBox.shrink(),
                    Row(
                      children: [
                        IconButton.outlined(
                          icon: const Icon(Icons.edit, size: 18),
                          tooltip: 'Modifier',
                          onPressed: onEdit,
                        ),
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          tooltip: 'Supprimer',
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}