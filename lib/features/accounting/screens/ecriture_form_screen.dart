import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import aligné sur la structure du module comptabilité
import 'package:stockly_saas/features/accounting/models/journal_entry.dart';

class JournalLineInput {
  TextEditingController accountCodeController;
  TextEditingController accountLabelController;
  TextEditingController debitController;
  TextEditingController creditController;

  JournalLineInput({
    String accountCode = '',
    String accountLabel = '',
    String debit = '',
    String credit = '',
  })  : accountCodeController = TextEditingController(text: accountCode),
        accountLabelController = TextEditingController(text: accountLabel),
        debitController = TextEditingController(text: debit),
        creditController = TextEditingController(text: credit);

  double get debitValue =>
      double.tryParse(debitController.text.replaceAll(',', '.')) ?? 0.0;
  double get creditValue =>
      double.tryParse(creditController.text.replaceAll(',', '.')) ?? 0.0;

  void dispose() {
    accountCodeController.dispose();
    accountLabelController.dispose();
    debitController.dispose();
    creditController.dispose();
  }
}

class EcritureFormScreen extends StatefulWidget {
  final String entrepriseId;
  final JournalEntry? entryToEdit;

  const EcritureFormScreen({
    super.key,
    required this.entrepriseId,
    this.entryToEdit,
  });

  @override
  State<EcritureFormScreen> createState() => _EcritureFormScreenState();
}

class _EcritureFormScreenState extends State<EcritureFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  late String _selectedJournal;
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();

  final List<JournalLineInput> _lines = [];

  final List<String> _journals = [
    'VT - Journal des Ventes',
    'AC - Journal des Achats',
    'BQ - Journal de Banque',
    'CA - Journal de Caisse',
    'OD - Opérations Diverses',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.entryToEdit?.date ?? DateTime.now();
    _selectedJournal = widget.entryToEdit?.journalCode ?? _journals.first;
    _referenceController.text = widget.entryToEdit?.reference ?? '';
    _labelController.text = widget.entryToEdit?.description ?? '';

    if (widget.entryToEdit != null && widget.entryToEdit!.lines.isNotEmpty) {
      for (var line in widget.entryToEdit!.lines) {
        _lines.add(JournalLineInput(
          accountCode: line.accountCode,
          accountLabel: line.accountLabel,
          debit: line.debit > 0 ? line.debit.toStringAsFixed(2) : '',
          credit: line.credit > 0 ? line.credit.toStringAsFixed(2) : '',
        ));
      }
    } else {
      _lines.add(JournalLineInput());
      _lines.add(JournalLineInput());
    }
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _labelController.dispose();
    for (var line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  double get _totalDebit =>
      _lines.fold(0.0, (sum, line) => sum + line.debitValue);

  double get _totalCredit =>
      _lines.fold(0.0, (sum, line) => sum + line.creditValue);

  double get _difference => (_totalDebit - _totalCredit).abs();
  bool get _isBalanced => _difference < 0.001 && _totalDebit > 0;

  void _addLine() {
    setState(() {
      _lines.add(JournalLineInput());
    });
  }

  void _removeLine(int index) {
    if (_lines.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une écriture doit comporter au moins 2 lignes.'),
        ),
      );
      return;
    }
    setState(() {
      final removed = _lines.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveEntry() {
    if (!_formKey.currentState!.validate()) return;

    if (!_isBalanced) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            _totalDebit == 0
                ? 'Veuillez saisir au moins un montant Débit/Crédit.'
                : 'L\'écriture n\'est pas équilibrée (Écart : ${_difference.toStringAsFixed(2)}).',
          ),
        ),
      );
      return;
    }

    final entryLines = _lines.map((line) {
      return JournalEntryLine(
        accountCode: line.accountCodeController.text.trim(),
        accountLabel: line.accountLabelController.text.trim(),
        debit: line.debitValue,
        credit: line.creditValue,
      );
    }).toList();

    final newEntry = JournalEntry(
      id: widget.entryToEdit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      entrepriseId: widget.entrepriseId,
      date: _selectedDate,
      journalCode: _selectedJournal,
      reference: _referenceController.text.trim(),
      description: _labelController.text.trim(),
      lines: entryLines,
    );

    Navigator.pop(context, newEntry);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entryToEdit == null
            ? 'Nouvelle Écriture'
            : 'Modifier Écriture'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveEntry,
            tooltip: 'Enregistrer',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date d\'écriture',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedJournal,
                          decoration: const InputDecoration(
                            labelText: 'Journal',
                            border: OutlineInputBorder(),
                          ),
                          items: _journals
                              .map((j) =>
                                  DropdownMenuItem(value: j, child: Text(j)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedJournal = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _referenceController,
                          decoration: const InputDecoration(
                            labelText: 'N° Pièce / Réf.',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Obligatoire' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _labelController,
                          decoration: const InputDecoration(
                            labelText: 'Libellé de la pièce',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Obligatoire' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lignes d\'écriture',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      TextButton.icon(
                        onPressed: _addLine,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter une ligne'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._lines.asMap().entries.map((entry) {
                    final index = entry.key;
                    final line = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  child: Text('${index + 1}',
                                      style: const TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: line.accountCodeController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Compte SYSCOHADA',
                                      hintText: 'ex: 601100',
                                      isDense: true,
                                    ),
                                    validator: (v) =>
                                        v == null || v.isEmpty ? 'Requis' : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: line.accountLabelController,
                                    decoration: const InputDecoration(
                                      labelText: 'Intitulé du compte',
                                      hintText: 'ex: Achats de marchandises',
                                      isDense: true,
                                    ),
                                    validator: (v) =>
                                        v == null || v.isEmpty ? 'Requis' : null,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () => _removeLine(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: line.debitController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*[\.,]?\d*')),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Débit',
                                      suffixText: 'FCFA',
                                      isDense: true,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: line.creditController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*[\.,]?\d*')),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Crédit',
                                      suffixText: 'FCFA',
                                      isDense: true,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Débit: ${_totalDebit.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Total Crédit: ${_totalCredit.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Chip(
                      avatar: Icon(
                        _isBalanced
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        _isBalanced
                            ? 'Équilibré'
                            : 'Écart: ${_difference.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor:
                          _isBalanced ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}