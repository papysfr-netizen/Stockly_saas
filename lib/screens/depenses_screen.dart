import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/models/depense.dart';
import '../core/providers/currency_provider.dart';
import '../core/providers/depense_provider.dart';
import '../core/providers/user_role_provider.dart';
import '../core/services/report_export_service.dart';

class DepensesScreen extends ConsumerStatefulWidget {
  const DepensesScreen({super.key});

  @override
  ConsumerState<DepensesScreen> createState() => _DepensesScreenState();
}

class _DepensesScreenState extends ConsumerState<DepensesScreen> {
  String _categorieFiltre = 'Toutes';
  int _selectedPeriodeIndex = 0;
  DateTime? _customSelectedDate;
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _categories = [
    'Loyer',
    'Salaires',
    'Électricité & Eau',
    'Transport / Carburant',
    'Taxes & Impôts',
    'Maintenance / Réparation',
    'Marketing / Pub',
    'Autre',
  ];

  /// Génère les 8 éléments de navigation :
  /// Index 0 : AUJOURD'HUI
  /// Index 1 : HIER
  /// Index 2..6 : Les 5 jours précédents (soit 7 jours au total)
  /// Index 7 : Icône Calendrier (8ème élément)
  List<Map<String, dynamic>> _getBeSoccerTabs() {
    final now = DateTime.now();
    final formatter = DateFormat('EEE. d MMM', 'fr_FR');

    List<Map<String, dynamic>> tabs = [
      {
        'label': 'AUJOURD\'HUI',
        'type': 'Aujourd\'hui',
        'date': now,
        'isCalendar': false,
      },
      {
        'label': 'HIER',
        'type': 'Hier',
        'date': now.subtract(const Duration(days: 1)),
        'isCalendar': false,
      },
    ];

    // Ajout des 5 jours précédents (J-2 à J-6) pour faire 7 jours au total
    for (int i = 2; i <= 6; i++) {
      final date = now.subtract(Duration(days: i));
      tabs.add({
        'label': formatter.format(date).toUpperCase(),
        'type': 'DateSpecifique',
        'date': date,
        'isCalendar': false,
      });
    }

    // 8ème position : Icône Calendrier
    final customLabel = _customSelectedDate != null
        ? DateFormat('dd/MM/yyyy').format(_customSelectedDate!)
        : '';

    tabs.add({
      'label': customLabel,
      'type': 'CustomDate',
      'date': _customSelectedDate,
      'isCalendar': true,
    });

    return tabs;
  }

  IconData _getCategoryIcon(String categorie) {
    switch (categorie) {
      case 'Loyer':
        return Icons.home_work_rounded;
      case 'Salaires':
        return Icons.badge_rounded;
      case 'Électricité & Eau':
        return Icons.bolt_rounded;
      case 'Transport / Carburant':
        return Icons.directions_car_rounded;
      case 'Taxes & Impôts':
        return Icons.account_balance_rounded;
      case 'Maintenance / Réparation':
        return Icons.build_rounded;
      case 'Marketing / Pub':
        return Icons.campaign_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  bool _correspondAPeriode(DateTime date, Map<String, dynamic> tab) {
    final now = DateTime.now();
    final dateZero = DateTime(date.year, date.month, date.day);
    final nowZero = DateTime(now.year, now.month, now.day);
    final type = tab['type'] as String;

    switch (type) {
      case 'Aujourd\'hui':
        return dateZero.isAtSameMomentAs(nowZero);
      case 'Hier':
        final hierZero = nowZero.subtract(const Duration(days: 1));
        return dateZero.isAtSameMomentAs(hierZero);
      case 'DateSpecifique':
        final targetDate = tab['date'] as DateTime;
        final targetZero = DateTime(targetDate.year, targetDate.month, targetDate.day);
        return dateZero.isAtSameMomentAs(targetZero);
      case 'CustomDate':
        if (_customSelectedDate == null) return true;
        final customZero = DateTime(
          _customSelectedDate!.year,
          _customSelectedDate!.month,
          _customSelectedDate!.day,
        );
        return dateZero.isAtSameMomentAs(customZero);
      default:
        return true;
    }
  }

  List<Depense> _filtrerDepenses(List<Depense> depenses, Map<String, dynamic> tabActif) {
    return depenses.where((d) {
      final matchCat = _categorieFiltre == 'Toutes' || d.categorie == _categorieFiltre;
      final matchPeriode = _correspondAPeriode(d.date, tabActif);
      final matchQuery = _searchQuery.isEmpty ||
          d.titre.toLowerCase().contains(_searchQuery) ||
          (d.note?.toLowerCase().contains(_searchQuery) ?? false);
      return matchCat && matchPeriode && matchQuery;
    }).toList();
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return 'Aujourd\'hui • ${DateFormat('HH:mm').format(date)}';
    } else if (checkDate == yesterday) {
      return 'Hier • ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('dd/MM/yyyy • HH:mm').format(date);
    }
  }

  Future<void> _ouvrirDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customSelectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.redAccent.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customSelectedDate = picked;
        _selectedPeriodeIndex = 7;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final depensesAsync = ref.watch(depensesStreamProvider);
    final currency = ref.watch(currencyProvider);
    final profile = ref.watch(userProfileProvider).value;

    final tabs = _getBeSoccerTabs();
    if (_selectedPeriodeIndex >= tabs.length) {
      _selectedPeriodeIndex = 0;
    }
    final tabActif = tabs[_selectedPeriodeIndex];
    final toutesLesCategories = ['Toutes', ..._categories];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Rechercher une dépense...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
              )
            : const Text('Charges & Dépenses', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Exporter',
            onSelected: (value) async {
              final depenses = depensesAsync.value ?? [];
              final depensesFiltrees = _filtrerDepenses(depenses, tabActif);

              final enTetes = ['Date', 'Titre / Motif', 'Catégorie', 'Montant', 'Auteur', 'Note'];
              final lignes = depensesFiltrees.map((d) {
                return [
                  DateFormat('dd/MM/yyyy HH:mm').format(d.date),
                  d.titre,
                  d.categorie,
                  '${d.montant.toStringAsFixed(2)} ${currency.activeCurrency}',
                  d.enregistrePar,
                  d.note ?? '',
                ];
              }).toList();

              if (value == 'excel') {
                await ReportExportService.exporterExcel(
                  titreRapport: 'Rapport_Depenses_${_categorieFiltre.replaceAll(' ', '_')}',
                  enTetes: enTetes,
                  lignes: lignes,
                );
              } else if (value == 'pdf') {
                await ReportExportService.exporterPDF(
                  titreRapport: 'Rapport des Charges ($_categorieFiltre - ${tabActif['label'].isEmpty ? 'Sur mesure' : tabActif['label']})',
                  nomBoutique: 'Stockly Pro',
                  enTetes: enTetes,
                  lignes: lignes,
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_rounded, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Exporter vers Excel'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Imprimer / PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: depensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur : $err')),
        data: (depenses) {
          final depensesFiltrees = _filtrerDepenses(depenses, tabActif);

          final totalDepenses = depensesFiltrees.fold<double>(
            0.0,
            (sum, item) => sum + item.montant,
          );

          return Column(
            children: [
              // ================= BARRE DES 8 ONGLETS (7 JOURS + CALENDRIER) =================
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.redAccent.shade700,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.shade700.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: tabs.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final item = tabs[index];
                          final isSelected = _selectedPeriodeIndex == index;
                          final isCalendar = item['isCalendar'] as bool;
                          final hasLabel = (item['label'] as String).isNotEmpty;

                          return InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              if (isCalendar) {
                                _ouvrirDatePicker();
                              } else {
                                setState(() {
                                  _selectedPeriodeIndex = index;
                                });
                              }
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: isSelected ? 0.85 : 0.4),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isCalendar) ...[
                                        const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 16),
                                        if (hasLabel) const SizedBox(width: 6),
                                      ],
                                      if (hasLabel)
                                        Text(
                                          item['label'],
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            fontSize: 12,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 3,
                                  width: isSelected ? 24 : 0,
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent.shade400,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Affichage du total
                    const Text(
                      'Total des Dépenses',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                      child: Text(
                        '${totalDepenses.toStringAsFixed(2)} ${currency.activeCurrency}',
                        key: ValueKey<String>('$totalDepenses-$_selectedPeriodeIndex-$_categorieFiltre'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filtres par Catégories
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: toutesLesCategories.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = toutesLesCategories[index];
                          final isSelected = _categorieFiltre == category;

                          return InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => setState(() => _categorieFiltre = category),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (category != 'Toutes') ...[
                                    Icon(
                                      _getCategoryIcon(category),
                                      size: 16,
                                      color: isSelected ? Colors.redAccent.shade700 : Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                  ] else if (isSelected) ...[
                                    Icon(Icons.check, size: 14, color: Colors.redAccent.shade700),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    category,
                                    style: TextStyle(
                                      color: isSelected ? Colors.redAccent.shade700 : Colors.white,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // ================= LISTE DES DÉPENSES =================
              Expanded(
                child: depensesFiltrees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Aucun résultat pour "$_searchQuery"'
                                  : 'Aucune dépense pour cette période.',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                        itemCount: depensesFiltrees.length,
                        itemBuilder: (context, index) {
                          final depense = depensesFiltrees[index];

                          return Card(
                            elevation: 1.5,
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.red.shade50,
                                child: Icon(
                                  _getCategoryIcon(depense.categorie),
                                  color: Colors.redAccent.shade700,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                depense.titre,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '${depense.categorie} • ${_formatRelativeDate(depense.date)}'
                                  '${depense.note != null && depense.note!.isNotEmpty ? '\n📝 ${depense.note}' : ''}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '-${depense.montant.toStringAsFixed(2)} ${currency.activeCurrency}',
                                    style: TextStyle(
                                      color: Colors.redAccent.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (profile?.role.isOwner == true) ...[
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade400, size: 20),
                                      onPressed: () => _confirmerSuppression(context, depense.id),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent.shade700,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Nouvelle Dépense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (ctx) => _AjoutDepenseBottomSheet(
              categories: _categories,
              entrepriseId: profile?.entrepriseId ?? '',
              userNom: profile?.nom ?? '',
              getCategoryIcon: _getCategoryIcon,
            ),
          );
        },
      ),
    );
  }

  void _confirmerSuppression(BuildContext context, String depenseId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer la dépense'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette ligne de charge ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              await ref.read(depenseRepositoryProvider).supprimerDepense(depenseId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ================= MODAL DE NOUVELLE DÉPENSE =================
class _AjoutDepenseBottomSheet extends ConsumerStatefulWidget {
  final List<String> categories;
  final String entrepriseId;
  final String userNom;
  final IconData Function(String) getCategoryIcon;

  const _AjoutDepenseBottomSheet({
    required this.categories,
    required this.entrepriseId,
    required this.userNom,
    required this.getCategoryIcon,
  });

  @override
  ConsumerState<_AjoutDepenseBottomSheet> createState() => _AjoutDepenseBottomSheetState();
}

class _AjoutDepenseBottomSheetState extends ConsumerState<_AjoutDepenseBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _montantController = TextEditingController();
  final _noteController = TextEditingController();

  late String _categorieSelectionnee;
  DateTime _dateSelectionnee = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _categorieSelectionnee = widget.categories.first;
  }

  @override
  void dispose() {
    _titreController.dispose();
    _montantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;

    final parseableMontant = _montantController.text.replaceAll(',', '.');
    final montant = double.tryParse(parseableMontant);

    if (montant == null || montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un montant valide (> 0)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nouvelleDepense = Depense(
        id: '',
        entrepriseId: widget.entrepriseId,
        titre: _titreController.text.trim(),
        montant: montant,
        categorie: _categorieSelectionnee,
        date: _dateSelectionnee,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        enregistrePar: widget.userNom,
      );

      await ref.read(depenseRepositoryProvider).ajouterDepense(nouvelleDepense);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enregistrer une Dépense',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titreController,
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Le motif est requis' : null,
                decoration: InputDecoration(
                  labelText: 'Motif / Titre',
                  hintText: 'ex: Loyer, Électricité...',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montantController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Le montant est requis';
                  final parsed = double.tryParse(val.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Montant invalide';
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Montant',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Catégorie de Charge',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.categories.map((cat) {
                  final isSelected = _categorieSelectionnee == cat;
                  return ChoiceChip(
                    avatar: Icon(
                      widget.getCategoryIcon(cat),
                      size: 16,
                      color: isSelected ? Colors.white : Colors.redAccent.shade700,
                    ),
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: Colors.redAccent.shade700,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _categorieSelectionnee = cat);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _dateSelectionnee,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _dateSelectionnee = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        DateTime.now().hour,
                        DateTime.now().minute,
                      );
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        'Date : ${DateFormat('dd/MM/yyyy').format(_dateSelectionnee)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note / Remarque (facultatif)',
                  prefixIcon: const Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _soumettre,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Enregistrer la Dépense',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}