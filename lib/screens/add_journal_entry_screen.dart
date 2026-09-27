// lib/screens/add_journal_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:stockly_saas/features/accounting/models/journal_entry.dart';
import 'package:stockly_saas/features/accounting/services/accounting_journal_service.dart';

class AddJournalEntryScreen extends StatefulWidget {
  final String entrepriseId;

  const AddJournalEntryScreen({
    super.key,
    required this.entrepriseId,
  });

  @override
  State<AddJournalEntryScreen> createState() => _AddJournalEntryScreenState();
}

class _AddJournalEntryScreenState extends State<AddJournalEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final AccountingJournalService _journalService = AccountingJournalService();

  final TextEditingController _refController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  final List<_LineDraft> _lines = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _addNewLine();
    _addNewLine();
  }

  @override
  void dispose() {
    _refController.dispose();
    _descController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  void _addNewLine() {
    setState(() {
      _lines.add(_LineDraft());
    });
  }

  void _removeLine(int index) {
    if (_lines.length <= 2) return;
    setState(() {
      final removed = _lines.removeAt(index);
      removed.dispose();
    });
  }

  double get _totalDebit => _lines.fold(
      0.0, (sum, l) => sum + (double.tryParse(l.debitCtrl.text) ?? 0.0));
  double get _totalCredit => _lines.fold(
      0.0, (sum, l) => sum + (double.tryParse(l.creditCtrl.text) ?? 0.0));
  bool get _isBalanced =>
      (_totalDebit - _totalCredit).abs() < 0.001 && _totalDebit > 0;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isBalanced) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'L\'écriture doit être équilibrée (Total Débit = Total Crédit)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final parsedLines = _lines.map((l) {
        final code = l.codeCtrl.text.trim();
        return JournalLine(
          accountCode: code,
          accountLabel: l.labelCtrl.text.trim().isNotEmpty
              ? l.labelCtrl.text.trim()
              : JournalEntry.getAccountLabel(code),
          debit: double.tryParse(l.debitCtrl.text) ?? 0.0,
          credit: double.tryParse(l.creditCtrl.text) ?? 0.0,
        );
      }).toList();

      final now = DateTime.now();
      final entry = JournalEntry(
        id: 'JE-OD-${now.millisecondsSinceEpoch}',
        entrepriseId: widget.entrepriseId,
        date: _selectedDate,
        reference: _refController.text.trim(),
        description: _descController.text.trim(),
        lines: parsedLines,
      );

      await _journalService.saveJournalEntry(entry);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Écriture enregistrée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Écriture Manuelle'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _refController,
                          decoration: const InputDecoration(
                            labelText: 'Référence (ex: OD-001)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Champ requis'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Libellé de l\'opération',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Lignes d\'écriture :',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),

                  ..._lines.asMap().entries.map((entry) {
                    final index = entry.key;
                    final line = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 90,
                              child: TextFormField(
                                controller: line.codeCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'N° Compte',
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (code) {
                                  if (line.labelCtrl.text.isEmpty) {
                                    line.labelCtrl.text =
                                        JournalEntry.getAccountLabel(code);
                                  }
                                  setState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: line.labelCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Intitulé',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                controller: line.debitCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Débit',
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                controller: line.creditCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Crédit',
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.red),
                              onPressed: () => _removeLine(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  TextButton.icon(
                    onPressed: _addNewLine,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une ligne'),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Débit: ${_totalDebit.toStringAsFixed(2)} | Crédit: ${_totalCredit.toStringAsFixed(2)}',
                      ),
                      Text(
                        _isBalanced ? 'Équilibré ✓' : 'Non équilibré ✗',
                        style: TextStyle(
                          color: _isBalanced ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: (_isSaving || !_isBalanced) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enregistrer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineDraft {
  final codeCtrl = TextEditingController();
  final labelCtrl = TextEditingController();
  final debitCtrl = TextEditingController(text: '0');
  final creditCtrl = TextEditingController(text: '0');

  void dispose() {
    codeCtrl.dispose();
    labelCtrl.dispose();
    debitCtrl.dispose();
    creditCtrl.dispose();
  }
}