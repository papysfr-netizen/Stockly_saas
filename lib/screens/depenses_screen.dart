import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/depense.dart';
import '../providers/depense_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/user_role_provider.dart';
import '../services/report_export_service.dart';

class DepensesScreen extends ConsumerStatefulWidget {
  const DepensesScreen({super.key});

  @override
  ConsumerState<DepensesScreen> createState() => _DepensesScreenState();
}

class _DepensesScreenState extends ConsumerState<DepensesScreen> {
  String _categorieFiltre = 'Toutes';
  String _periodeFiltre = 'Ce mois'; // 'Aujourd'hui', 'Cette semaine', 'Ce mois', 'Toutes'
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Loyer',
    'Salaires',
    'Électricité & Eau',
    'Transport / Carburant',
    'Taxes & Impôts',
    'Maintenance / Réparation',
    'Marketing / Pub',
    'Autre',
  ];

  final List<String> _periodes = [
    'Ce mois',
    'Aujourd\'hui',
    'Cette semaine',
    'Toutes',
  ];

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

  bool _correspondAPeriode(DateTime date) {
    final now = DateTime.now();
    final dateZero = DateTime(date.year, date.month, date.day);
    final nowZero = DateTime(now.year, now.month, now.day);

    switch (_periodeFiltre) {
      case 'Aujourd\'hui':
        return dateZero.isAtSameMomentAs(nowZero);
      case 'Cette semaine':
        final debutSemaine = nowZero.subtract(Duration(days: nowZero.weekday - 1));
        return dateZero.isAfter(debutSemaine.subtract(const Duration(days: 1)));
      case 'Ce mois':
        return date.year == now.year && date.month == now.month;
      case 'Toutes':
      default:
        return true;
    }
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
              final depensesFiltrees = depenses.where((d) {
                final matchCat = _categorieFiltre == 'Toutes' || d.categorie == _categorieFiltre;
                final matchPeriode = _correspondAPeriode(d.date);
                final matchQuery = _searchQuery.isEmpty ||
                    d.titre.toLowerCase().contains(_searchQuery) ||
                    (d.note?.toLowerCase().contains(_searchQuery) ?? false);
                return matchCat && matchPeriode && matchQuery;
              }).toList();

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
                  titreRapport: 'Rapport des Charges ($_categorieFiltre - $_periodeFiltre)',
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
          // Filtrage dynamique combiné
          final depensesFiltrees = depenses.where((d) {
            final matchCat = _categorieFiltre == 'Toutes' || d.categorie == _categorieFiltre;
            final matchPeriode = _correspondAPeriode(d.date);
            final matchQuery = _searchQuery.isEmpty ||
                d.titre.toLowerCase().contains(_searchQuery) ||
                (d.note?.toLowerCase().contains(_searchQuery) ?? false);
            return matchCat && matchPeriode && matchQuery;
          }).toList();

          final totalDepenses = depensesFiltrees.fold<double>(
            0.0,
            (sum, item) => sum + item.montant,
          );

          return Column(
            children: [
              // ================= DASHBOARD & FILTRES DYNAMIQUES =================
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
                  children: [
                    // Sélecteur de Période (Pills)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _periodes.map((p) {
                          final isSelected = _periodeFiltre == p;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              label: Text(p),
                              selected: isSelected,
                              selectedColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.redAccent.shade700 : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              onSelected: (_) {
                                setState(() => _periodeFiltre = p);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Montant Animé
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
                        key: ValueKey<String>('$totalDepenses-$_periodeFiltre-$_categorieFiltre'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Barre de catégories déroulante
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: toutesLesCategories.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = toutesLesCategories[index];
                          final isSelected = _categorieFiltre == category;

                          return FilterChip(
                            avatar: category == 'Toutes'
                                ? null
                                : Icon(
                                    _getCategoryIcon(category),
                                    size: 16,
                                    color: isSelected ? Colors.redAccent.shade700 : Colors.white,
                                  ),
                            label: Text(category),
                            selected: isSelected,
                            selectedColor: Colors.white,
                            checkmarkColor: Colors.redAccent.shade700,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.redAccent.shade700 : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            onSelected: (_) {
                              setState(() => _categorieFiltre = category);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // ================= LISTE DYNAMIQUE DES DÉPENSES =================
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
        onPressed: () => _afficherBottomSheetAjoutDepense(
          context,
          profile?.entrepriseId ?? '',
          profile?.nom ?? '',
        ),
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

  // ================= MODAL BOTTOM SHEET INTERACTIF & DYNAMIQUE =================
  void _afficherBottomSheetAjoutDepense(BuildContext context, String entrepriseId, String userNom) {
    final titreController = TextEditingController();
    final montantController = TextEditingController();
    final noteController = TextEditingController();
    String categorieSelectionnee = _categories.first;
    DateTime dateSelectionnee = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barre visuelle de drag
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

                    // Champ Motif
                    TextField(
                      controller: titreController,
                      decoration: InputDecoration(
                        labelText: 'Motif / Titre',
                        hintText: 'ex: Loyer, Électricité...',
                        prefixIcon: const Icon(Icons.edit_note_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Champ Montant
                    TextField(
                      controller: montantController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Montant',
                        prefixIcon: const Icon(Icons.attach_money_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sélecteur de Catégorie sous forme de Puces Visuelles
                    const Text(
                      'Catégorie de Charge',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _categories.map((cat) {
                        final isSelected = categorieSelectionnee == cat;
                        return ChoiceChip(
                          avatar: Icon(
                            _getCategoryIcon(cat),
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
                              setStateModal(() => categorieSelectionnee = cat);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Sélecteur de Date dynamique
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: ctx,
                          initialDate: dateSelectionnee,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          setStateModal(() {
                            dateSelectionnee = DateTime(
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
                              'Date : ${DateFormat('dd/MM/yyyy').format(dateSelectionnee)}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Champ Note
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: 'Note / Remarque (facultatif)',
                        prefixIcon: const Icon(Icons.notes_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bouton Enregistrer
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final double? montant = double.tryParse(montantController.text);
                          if (titreController.text.isNotEmpty && montant != null && montant > 0) {
                            final nouvelleDepense = Depense(
                              id: '',
                              entrepriseId: entrepriseId,
                              titre: titreController.text.trim(),
                              montant: montant,
                              categorie: categorieSelectionnee,
                              date: dateSelectionnee,
                              note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                              enregistrePar: userNom,
                            );

                            await ref.read(depenseRepositoryProvider).ajouterDepense(nouvelleDepense);

                            if (ctx.mounted) Navigator.pop(ctx);
                          }
                        },
                        child: const Text(
                          'Enregistrer la Dépense',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}