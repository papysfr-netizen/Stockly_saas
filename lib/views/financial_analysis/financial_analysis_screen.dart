// lib/views/financial_analysis/financial_analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../core/providers/currency_provider.dart';
import '../../core/providers/user_role_provider.dart';
import '../../core/providers/depense_provider.dart';
import '../../core/services/report_export_service.dart';

import 'services/financial_calculation_service.dart';
import 'widgets/pl_row_widget.dart';
import 'widgets/details_bottom_sheet.dart';

class FinancialAnalysisScreen extends ConsumerStatefulWidget {
  const FinancialAnalysisScreen({super.key});

  @override
  ConsumerState<FinancialAnalysisScreen> createState() => _FinancialAnalysisScreenState();
}

class _FinancialAnalysisScreenState extends ConsumerState<FinancialAnalysisScreen> {
  int _selectedPeriodeIndex = 0;
  DateTimeRange? _customRange;

  // Valeurs (en USD) mémorisées pour l'export
  double _lastCA = 0.0;
  double _lastCoutAchat = 0.0;
  double _lastMargeBrute = 0.0;
  double _lastTotalDepenses = 0.0;
  double _lastBeneficeNet = 0.0;
  double _lastTaux = 1.0;
  int _lastDecimales = 2;

  String _fmtExport(double usd) => (usd * _lastTaux).toStringAsFixed(_lastDecimales);

  List<Map<String, dynamic>> _getTabs() {
    final now = DateTime.now();
    // CORRECTIF : "EEE." donnait "LUN.." (le point est déjà dans l'abréviation française)
    final formatter = DateFormat('EEE d MMM', 'fr_FR');

    List<Map<String, dynamic>> tabs = [
      {
        'label': 'AUJOURD\'HUI',
        'range': DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        ),
        'isCalendar': false,
      },
      {
        'label': 'HIER',
        'range': DateTimeRange(
          start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59).subtract(const Duration(days: 1)),
        ),
        'isCalendar': false,
      },
    ];

    for (int i = 2; i <= 6; i++) {
      final targetDay = now.subtract(Duration(days: i));
      final start = DateTime(targetDay.year, targetDay.month, targetDay.day);
      final end = DateTime(targetDay.year, targetDay.month, targetDay.day, 23, 59, 59);

      tabs.add({
        'label': formatter.format(targetDay).toUpperCase(),
        'range': DateTimeRange(start: start, end: end),
        'isCalendar': false,
      });
    }

    final customLabel = _customRange != null
        ? '${DateFormat('dd/MM').format(_customRange!.start)} - ${DateFormat('dd/MM').format(_customRange!.end)}'
        : 'Choisir une date...';

    tabs.add({
      'label': customLabel,
      'range': _customRange,
      'isCalendar': true,
    });

    return tabs;
  }

  Future<void> _ouvrirDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _customRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E293B),
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
        _customRange = DateTimeRange(
          start: picked.start,
          end: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
        );
        _selectedPeriodeIndex = 7;
      });
    }
  }

  // NOTE : le bouton "Réinitialiser les données de test" (suppression de tous
  // les produits, ventes et dépenses) a été RETIRÉ de cet écran : c'était une
  // action irréversible accessible à tout utilisateur.

  @override
  Widget build(BuildContext context) {
    final currencyState = ref.watch(currencyProvider);
    final currency = currencyState.activeCurrency;
    final activeInfo = currencyState.activeCurrencyInfo;

    // Les montants sont enregistrés en USD : on les convertit pour l'affichage
    // (avant, des USD étaient affichés avec le nom d'une autre devise).
    final double taux = activeInfo.rateToUSD > 0 ? activeInfo.rateToUSD : 1.0;
    final int decimales = taux >= 100 ? 0 : 2;
    String fmt(double usd) => (usd * taux).toStringAsFixed(decimales);

    final userProfile = ref.watch(userProfileProvider).value;
    final entrepriseId = userProfile?.entrepriseId ?? '';

    final depensesAsync = ref.watch(depensesStreamProvider);
    final tabs = _getTabs();

    if (_selectedPeriodeIndex >= tabs.length) {
      _selectedPeriodeIndex = 0;
    }

    final currentTab = tabs[_selectedPeriodeIndex];
    final dateRange = currentTab['range'] as DateTimeRange? ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );

    // CORRECTIF PRINCIPAL : la caisse enregistre dans "entreprises/{id}/...".
    // Cet écran lisait "organizations/{id}/..." : il ne voyait donc jamais les
    // ventes ni les produits, d'où un résultat toujours à 0.00.
    Stream<QuerySnapshot>? produitsStream;
    Stream<QuerySnapshot>? ventesStream;
    if (entrepriseId.isNotEmpty) {
      final racine = FirebaseFirestore.instance.collection('entreprises').doc(entrepriseId);
      produitsStream = racine.collection('produits').snapshots();
      ventesStream = racine.collection('ventes').snapshots();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Compte de Résultat (P&L)',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            tooltip: 'Exporter l\'analyse',
            onSelected: (value) async {
              final periode = currentTab['label'] as String;
              final enTetes = ['Poste Financier', 'Montant'];
              final lignes = [
                ['Chiffre d\'Affaires (Ventes Brut)', '${_fmtExport(_lastCA)} $currency'],
                ['Coût d\'Achat des Marchandises', '-${_fmtExport(_lastCoutAchat)} $currency'],
                ['Marge Brute', '${_fmtExport(_lastMargeBrute)} $currency'],
                ['Total Charges & Dépenses', '-${_fmtExport(_lastTotalDepenses)} $currency'],
                ['Résultat Net (BÉNÉFICE NET)', '${_fmtExport(_lastBeneficeNet)} $currency'],
              ];

              if (value == 'excel') {
                await ReportExportService.exporterExcel(
                  titreRapport: 'Analyse_Financiere_PL',
                  enTetes: enTetes,
                  lignes: lignes,
                );
              } else if (value == 'pdf') {
                await ReportExportService.exporterPDF(
                  titreRapport: 'Compte de Résultat (P&L) - $periode',
                  nomBoutique: 'Stockly Pro',
                  enTetes: enTetes,
                  lignes: lignes,
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Exporter vers Excel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Imprimer / PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: entrepriseId.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 1. BARRE DE SÉLECTION PÉRIODE (Sur fond bleu nuit)
                Container(
                  color: const Color(0xFF1E293B),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: tabs.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final item = tabs[index];
                        final isSelected = _selectedPeriodeIndex == index;
                        final isCalendar = item['isCalendar'] as bool;
                        final label = item['label'] as String;

                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            if (isCalendar) {
                              _ouvrirDateRangePicker();
                            } else {
                              setState(() {
                                _selectedPeriodeIndex = index;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.orange.shade800
                                  : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isCalendar) ...[
                                  const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 16),
                                  if (label.isNotEmpty) const SizedBox(width: 6),
                                ],
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 2. CALCUL EN TEMPS RÉEL DEPUIS FIRESTORE
                Expanded(
                  child: depensesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(
                      child: Text('Erreur dépenses : $err', style: const TextStyle(color: Colors.grey)),
                    ),
                    data: (toutesLesDepenses) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: produitsStream,
                        builder: (context, snapshotProduits) {
                          return StreamBuilder<QuerySnapshot>(
                            stream: ventesStream,
                            builder: (context, snapshotVentes) {
                              // Erreurs visibles (avant : un accès refusé s'affichait comme "0.00")
                              if (snapshotVentes.hasError || snapshotProduits.hasError) {
                                final erreur = snapshotVentes.error ?? snapshotProduits.error;
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      'Impossible de charger les données : $erreur',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.red.shade700),
                                    ),
                                  ),
                                );
                              }

                              if (snapshotVentes.connectionState == ConnectionState.waiting ||
                                  snapshotProduits.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              final result = FinancialCalculationService.computePL(
                                toutesLesDepenses: toutesLesDepenses,
                                produitsDocs: snapshotProduits.data?.docs ?? [],
                                ventesDocs: snapshotVentes.data?.docs ?? [],
                                dateRange: dateRange,
                                entrepriseId: entrepriseId,
                              );

                              // Mémorisation des variables pour export
                              _lastCA = result.chiffreAffaires;
                              _lastCoutAchat = result.coutAchatStockVendu;
                              _lastMargeBrute = result.margeBrute;
                              _lastTotalDepenses = result.totalDepenses;
                              _lastBeneficeNet = result.beneficeNet;
                              _lastTaux = taux;
                              _lastDecimales = decimales;

                              final bool aucuneActivite =
                                  result.chiffreAffaires == 0 && result.totalDepenses == 0;

                              return SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // CARTE DE RÉSULTAT NET
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
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
                                            'RÉSULTAT NET (BÉNÉFICE NET)',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
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
                                                CircleAvatar(
                                                  backgroundColor: Colors.white24,
                                                  radius: 18,
                                                  child: Icon(
                                                    aucuneActivite
                                                        ? Icons.trending_flat_rounded
                                                        : (result.isProfit
                                                            ? Icons.trending_up_rounded
                                                            : Icons.trending_down_rounded),
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        '${fmt(result.beneficeNet)} $currency',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 22,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        aucuneActivite
                                                            ? 'Aucune activité sur cette période'
                                                            : (result.isProfit
                                                                ? 'Votre entreprise est bénéficiaire !'
                                                                : 'Votre entreprise est déficitaire'),
                                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Analyse Détaillée (P&L)',
                                          style: TextStyle(
                                            color: Color(0xFF1E293B),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Appuyez pour détailler',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // LISTE DÉTAILLÉE DU COMPTE DE RÉSULTAT
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.03),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          // 1. CHIFFRE D'AFFAIRES
                                          PLRowWidget(
                                            icon: Icons.store_rounded,
                                            color: Colors.teal,
                                            title: "Chiffre d'Affaires (Ventes Brut)",
                                            montant: result.chiffreAffaires * taux,
                                            currency: currency,
                                            onTap: () {
                                              DetailsBottomSheet.afficher(
                                                context: context,
                                                titre: "Détails du Chiffre d'Affaires",
                                                enfants: result.detailsVentesList.map((item) {
                                                  return ListTile(
                                                    dense: true,
                                                    leading: const Icon(Icons.shopping_bag, color: Colors.teal),
                                                    title: Text(
                                                      '${item['nom']} (x${item['qte']})',
                                                      style: const TextStyle(color: Color(0xFF1E293B)),
                                                    ),
                                                    subtitle: item['date'] != null
                                                        ? Text(
                                                            '${(item['date'] as DateTime).day}/${(item['date'] as DateTime).month}/${(item['date'] as DateTime).year}',
                                                            style: TextStyle(color: Colors.grey.shade600),
                                                          )
                                                        : null,
                                                    trailing: Text(
                                                      '${fmt(item['total'] as double)} $currency',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                                    ),
                                                  );
                                                }).toList(),
                                              );
                                            },
                                          ),
                                          const Divider(color: Colors.black12, height: 1),

                                          // 2. COÛT D'ACHAT
                                          PLRowWidget(
                                            icon: Icons.shopping_cart_rounded,
                                            color: Colors.orange.shade800,
                                            title: "Coût d'Achat des Marchandises",
                                            montant: -result.coutAchatStockVendu * taux,
                                            currency: currency,
                                            isNegative: true,
                                            onTap: () {
                                              DetailsBottomSheet.afficher(
                                                context: context,
                                                titre: "Détails du Coût d'Achat (Stock Vendu)",
                                                enfants: result.detailsCoutAchatList.map((item) {
                                                  final unitCost = (item['prixAchatUnit'] as double);
                                                  return ListTile(
                                                    dense: true,
                                                    leading: Icon(Icons.inventory, color: Colors.orange.shade800),
                                                    title: Text(
                                                      '${item['nom']} (x${item['qte']})',
                                                      style: const TextStyle(color: Color(0xFF1E293B)),
                                                    ),
                                                    subtitle: Text(
                                                      'Prix d\'achat unitaire : ${fmt(unitCost)} $currency',
                                                      style: TextStyle(color: Colors.grey.shade600),
                                                    ),
                                                    trailing: Text(
                                                      '-${fmt(item['total'] as double)} $currency',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                                                    ),
                                                  );
                                                }).toList(),
                                              );
                                            },
                                          ),
                                          const Divider(color: Colors.black12, height: 1),

                                          // 3. MARGE BRUTE
                                          PLRowWidget(
                                            icon: Icons.account_balance_wallet_rounded,
                                            color: Colors.blue.shade700,
                                            title: "Marge Brute",
                                            montant: result.margeBrute * taux,
                                            currency: currency,
                                            isBold: true,
                                            onTap: () {
                                              DetailsBottomSheet.afficher(
                                                context: context,
                                                titre: "Détails de la Marge Brute",
                                                enfants: result.detailsMargeList.map((item) {
                                                  final double m = item['marge'] as double;
                                                  return ListTile(
                                                    dense: true,
                                                    leading: Icon(
                                                      Icons.show_chart,
                                                      color: m >= 0 ? Colors.teal : Colors.redAccent,
                                                    ),
                                                    title: Text(
                                                      '${item['nom']} (x${item['qte']})',
                                                      style: const TextStyle(color: Color(0xFF1E293B)),
                                                    ),
                                                    subtitle: Text(
                                                      'Vente: ${fmt((item['totalVente'] as num).toDouble())} | Achat: ${fmt((item['totalAchat'] as num).toDouble())}',
                                                      style: TextStyle(color: Colors.grey.shade600),
                                                    ),
                                                    trailing: Text(
                                                      '${fmt(m)} $currency',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: m >= 0 ? Colors.teal : Colors.redAccent,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              );
                                            },
                                          ),
                                          const Divider(color: Colors.black12, height: 1),

                                          // 4. TOTAL CHARGES & DÉPENSES
                                          PLRowWidget(
                                            icon: Icons.receipt_long_rounded,
                                            color: Colors.red.shade600,
                                            title: "Total Charges & Dépenses",
                                            montant: -result.totalDepenses * taux,
                                            currency: currency,
                                            isNegative: true,
                                            onTap: () {
                                              DetailsBottomSheet.afficher(
                                                context: context,
                                                titre: "Détails des Dépenses par Catégorie",
                                                enfants: result.depensesParCategorie.entries.map((entry) {
                                                  return ListTile(
                                                    dense: true,
                                                    leading: const Icon(Icons.money_off, color: Colors.redAccent),
                                                    title: Text(
                                                      entry.key,
                                                      style: const TextStyle(color: Color(0xFF1E293B)),
                                                    ),
                                                    trailing: Text(
                                                      '-${fmt(entry.value)} $currency',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                                                    ),
                                                  );
                                                }).toList(),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
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