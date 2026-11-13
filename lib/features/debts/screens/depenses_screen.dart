// 🌙 mode sombre automatique
// lib/features/debts/screens/depenses_screen.dart

import 'package:flutter/material.dart';
import 'package:stockly_saas/features/boutiques/boutique_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/depense.dart';
import '../../../core/providers/currency_provider.dart';
import '../../../core/providers/depense_provider.dart';
import '../../../core/providers/user_role_provider.dart';
import '../../../core/services/report_export_service.dart';
import 'package:stockly_saas/l10n/app_localizations.dart';

/// Nom affiché d'une catégorie (la valeur enregistrée reste en français)
String _nomCategorie(AppLocalizations t, String cat) {
  switch (cat) {
    case 'Toutes':
      return t.depCatAll;
    case 'Loyer':
      return t.depCatRent;
    case 'Salaires':
      return t.depCatSalaries;
    case 'Électricité & Eau':
      return t.depCatUtilities;
    case 'Transport / Carburant':
      return t.depCatTransport;
    case 'Taxes & Impôts':
      return t.depCatTaxes;
    case 'Maintenance / Réparation':
      return t.depCatMaintenance;
    case 'Marketing / Pub':
      return t.depCatMarketing;
    case 'Autre':
      return t.depCatOther;
    default:
      return cat;
  }
}

class DepensesScreen extends ConsumerStatefulWidget {
  const DepensesScreen({super.key});

  @override
  ConsumerState<DepensesScreen> createState() => _DepensesScreenState();
}

class _DepensesScreenState extends ConsumerState<DepensesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _categorieFiltre = 'Toutes';
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _categories = [
    'Toutes',
    'Loyer',
    'Salaires',
    'Électricité & Eau',
    'Transport / Carburant',
    'Taxes & Impôts',
    'Maintenance / Réparation',
    'Marketing / Pub',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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

  /// 🏬 La dépense appartient-elle à la boutique affichée ? (sans boutique = principale)
  bool _dansBoutique(Depense d) {
    final choisie = ref.read(boutiqueActiveProvider);
    if (choisie == null) return true;
    return (d.boutiqueId.isEmpty ? 'principale' : d.boutiqueId) == choisie;
  }

  List<Depense> _filtrerDepenses(List<Depense> depenses) {
    return depenses.where((d) {
      final matchCat = _categorieFiltre == 'Toutes' || d.categorie == _categorieFiltre;
      final matchQuery = _searchQuery.isEmpty ||
          d.titre.toLowerCase().contains(_searchQuery) ||
          (d.note?.toLowerCase().contains(_searchQuery) ?? false) ||
          d.categorie.toLowerCase().contains(_searchQuery);
      return matchCat && matchQuery && _dansBoutique(d);
    }).toList();
  }

  /// Ouvre le formulaire : vide pour un ajout, pré-rempli pour une modification.
  void _ouvrirFormulaire({
    required String entrepriseId,
    required String userNom,
    Depense? depenseExistante,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1F26) : Colors.white, // 🌙
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AjoutDepenseBottomSheet(
        categories: _categories.where((c) => c != 'Toutes').toList(),
        entrepriseId: entrepriseId,
        userNom: userNom,
        getCategoryIcon: _getCategoryIcon,
        depenseExistante: depenseExistante,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final depensesAsync = ref.watch(depensesStreamProvider);
    final currency = ref.watch(currencyProvider);
    final profile = ref.watch(userProfileProvider).value;
    final entrepriseId = profile?.entrepriseId ?? '';
    final userNom = profile?.nom ?? '';
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF121418) : Colors.grey.shade100,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: t.depSearchHint,
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
              )
            : Text(
                t.depTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orangeAccent,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          tabs: [
            Tab(text: t.depTabAll),
            Tab(text: t.depTabByCat),
          ],
        ),
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
            tooltip: t.depExport,
            onSelected: (value) async {
              final depenses = depensesAsync.value ?? [];
              final depensesFiltrees = _filtrerDepenses(depenses);

              final enTetes = [
                t.depColDate,
                t.depColTitle,
                t.depColCategory,
                t.depColAmount,
                t.depColAuthor,
                t.depColNote,
              ];
              final lignes = depensesFiltrees.map((d) {
                return [
                  DateFormat('dd/MM/yyyy HH:mm').format(d.date),
                  d.titre,
                  _nomCategorie(t, d.categorie),
                  '${d.montant.toStringAsFixed(2)} ${currency.activeCurrency}',
                  d.enregistrePar ?? '',
                  d.note ?? '',
                ];
              }).toList();

              if (value == 'excel') {
                await ReportExportService.exporterExcel(
                  titreRapport: 'Rapport_Depenses',
                  enTetes: enTetes,
                  lignes: lignes,
                );
              } else if (value == 'pdf') {
                await ReportExportService.exporterPDF(
                  titreRapport: t.depReportTitle,
                  nomBoutique: 'Nguli',
                  enTetes: enTetes,
                  lignes: lignes,
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    const Icon(Icons.table_chart_rounded, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(t.depToExcel),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(t.depPrintPdf),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: depensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(t.errorPrefix('$err'))),
        data: (depenses) {
          final depensesFiltrees = _filtrerDepenses(depenses);
          final totalDepenses = depensesFiltrees.fold<double>(
            0.0,
            (sum, item) => sum + item.montant,
          );

          return Column(
            children: [
              // ================= CARTE DE RÉSUMÉ PRINCIPALE =================
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1F26) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tabController.index == 0
                                ? t.depTotalAll
                                : t.depTotalFor(_nomCategorie(t, _categorieFiltre)),
                            style: TextStyle(
                              color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade800,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Colors.white24,
                                  radius: 18,
                                  child: Icon(
                                    Icons.arrow_downward_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    '${totalDepenses.toStringAsFixed(2)} ${currency.activeCurrency}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_tabController.index == 1) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final isSelected = _categorieFiltre == cat;
                            return ChoiceChip(
                              label: Text(_nomCategorie(t, cat)),
                              selected: isSelected,
                              selectedColor: Colors.orange.shade800,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                                fontWeight: FontWeight.w500,
                              ),
                              onSelected: (_) => setState(() => _categorieFiltre = cat),
                            );
                          },
                        ),
                      ),
                    ],
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
                            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? t.depNoResult(_searchQuery)
                                  : t.depNone,
                              style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!), fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: depensesFiltrees.length,
                        itemBuilder: (context, index) {
                          final depense = depensesFiltrees[index];

                          return Card(
                            elevation: 1.5,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          depense.titre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '-${depense.montant.toStringAsFixed(2)} ${currency.activeCurrency}',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.indigo.withValues(alpha: 0.16) : Colors.indigo[50]!,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _nomCategorie(t, depense.categorie),
                                          style: TextStyle(
                                            color: Theme.of(context).brightness == Brightness.dark ? Colors.indigo.shade100 : Colors.indigo.shade900,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        DateFormat('dd/MM/yyyy • HH:mm').format(depense.date),
                                        style: TextStyle(fontSize: 12, color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!)),
                                      ),
                                    ],
                                  ),
                                  if (depense.note != null && depense.note!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      t.depNote(depense.note ?? ''),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                        color: (Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[700]!),
                                      ),
                                    ),
                                  ],
                                  if (profile?.role.isOwner == true) ...[
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // ---- NOUVEAU : bouton Modifier ----
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.indigo.shade400,
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                          ),
                                          icon: const Icon(Icons.edit_outlined, size: 18),
                                          label: Text(t.depEdit, style: const TextStyle(fontSize: 12)),
                                          onPressed: () => _ouvrirFormulaire(
                                            entrepriseId: entrepriseId,
                                            userNom: userNom,
                                            depenseExistante: depense,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red.shade400,
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                          ),
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                          label: Text(t.depDelete, style: const TextStyle(fontSize: 12)),
                                          onPressed: () => _confirmerSuppression(context, depense.id),
                                        ),
                                      ],
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
        backgroundColor: const Color(0xFF1E293B),
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          t.depAdd,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _ouvrirFormulaire(
          entrepriseId: entrepriseId,
          userNom: userNom,
        ),
      ),
    );
  }

  void _confirmerSuppression(BuildContext context, String depenseId) {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t.depDeleteTitle),
        content: Text(t.depDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              await ref.read(depenseRepositoryProvider).supprimerDepense(depenseId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(t.depDelete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ================= FORMULAIRE : NOUVELLE DÉPENSE / MODIFICATION =================
class _AjoutDepenseBottomSheet extends ConsumerStatefulWidget {
  final List<String> categories;
  final String entrepriseId;
  final String userNom;
  final IconData Function(String) getCategoryIcon;

  /// Si renseignée : on modifie cette dépense au lieu d'en créer une.
  final Depense? depenseExistante;

  const _AjoutDepenseBottomSheet({
    required this.categories,
    required this.entrepriseId,
    required this.userNom,
    required this.getCategoryIcon,
    this.depenseExistante,
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
  late List<String> _categoriesAffichees;
  DateTime _dateSelectionnee = DateTime.now();
  bool _isLoading = false;

  bool get _estModification => widget.depenseExistante != null;

  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _categoriesAffichees = List<String>.from(widget.categories);
    _categorieSelectionnee = widget.categories.first;

    final existante = widget.depenseExistante;
    if (existante != null) {
      _titreController.text = existante.titre;
      _montantController.text = existante.montant == existante.montant.roundToDouble()
          ? existante.montant.toInt().toString()
          : existante.montant.toString();
      _noteController.text = existante.note ?? '';
      _dateSelectionnee = existante.date;

      // Une ancienne catégorie absente de la liste est conservée telle quelle.
      if (!_categoriesAffichees.contains(existante.categorie)) {
        _categoriesAffichees.add(existante.categorie);
      }
      _categorieSelectionnee = existante.categorie;
    }
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

    final parseableMontant = _montantController.text.trim().replaceAll(',', '.');
    final montant = double.tryParse(parseableMontant);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final t = _t;

    if (montant == null || montant <= 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(t.depInvalidAmount)),
      );
      return;
    }

    setState(() => _isLoading = true);

    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
    final repo = ref.read(depenseRepositoryProvider);

    try {
      final existante = widget.depenseExistante;

      if (existante != null) {
        // ---- MODIFICATION : même id, même auteur, même moyen de paiement ----
        final modifiee = existante.copyWith(
          entrepriseId: existante.entrepriseId.isNotEmpty
              ? existante.entrepriseId
              : widget.entrepriseId,
          titre: _titreController.text.trim(),
          montant: montant,
          categorie: _categorieSelectionnee,
          date: _dateSelectionnee,
          note: note,
        );
        await repo.modifierDepense(modifiee);
      } else {
        // ---- AJOUT ----
        final nouvelleDepense = Depense(
          id: '',
          entrepriseId: widget.entrepriseId,
          titre: _titreController.text.trim(),
          montant: montant,
          categorie: _categorieSelectionnee,
          date: _dateSelectionnee,
          note: note,
          enregistrePar: widget.userNom,
          // 🏬 boutique de la dépense
          boutiqueId: ref.read(boutiqueActiveProvider) ?? 'principale',
        );
        await repo.ajouterDepense(nouvelleDepense);
      }

      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(_estModification ? t.depEdited : t.depSaved),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(t.depSaveError('$e')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _choisirDate() async {
    final maintenant = DateTime.now();
    final finAujourdhui =
        DateTime(maintenant.year, maintenant.month, maintenant.day, 23, 59);
    final initiale =
        _dateSelectionnee.isAfter(finAujourdhui) ? maintenant : _dateSelectionnee;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initiale,
      firstDate: DateTime(2020),
      lastDate: finAujourdhui,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade800,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        // On garde l'heure d'origine (sinon elle repasse à minuit).
        _dateSelectionnee = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _dateSelectionnee.hour,
          _dateSelectionnee.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
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
              Text(
                _estModification ? t.depFormEdit : t.depFormNew,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titreController,
                validator: (val) => (val == null || val.trim().isEmpty) ? t.depReasonRequired : null,
                decoration: InputDecoration(
                  labelText: t.depReasonLabel,
                  hintText: t.depReasonHint,
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montantController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return t.depAmountRequired;
                  final parsed = double.tryParse(val.trim().replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return t.depAmountInvalid;
                  return null;
                },
                decoration: InputDecoration(
                  labelText: t.depColAmount,
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t.depCategoryLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _categoriesAffichees.map((cat) {
                  final isSelected = _categorieSelectionnee == cat;
                  return ChoiceChip(
                    avatar: Icon(
                      widget.getCategoryIcon(cat),
                      size: 16,
                      color: isSelected ? Colors.white : Colors.orange.shade800,
                    ),
                    label: Text(_nomCategorie(t, cat)),
                    selected: isSelected,
                    selectedColor: Colors.orange.shade800,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
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
                onTap: _choisirDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: Colors.orange.shade800, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        t.depDate(DateFormat('dd/MM/yyyy').format(_dateSelectionnee)),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: t.depNoteLabel,
                  prefixIcon: const Icon(Icons.note_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _soumettre,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _estModification
                              ? t.depSaveChanges
                              : t.depSaveExpense,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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