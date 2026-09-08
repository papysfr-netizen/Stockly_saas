import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../providers/currency_provider.dart';
import '../../providers/user_role_provider.dart';
import '../../providers/depense_provider.dart';
import '../../services/report_export_service.dart';

import 'services/financial_calculation_service.dart';
import 'widgets/net_result_card.dart';
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

  double _lastCA = 0.0;
  double _lastCoutAchat = 0.0;
  double _lastMargeBrute = 0.0;
  double _lastTotalDepenses = 0.0;
  double _lastBeneficeNet = 0.0;

  List<Map<String, dynamic>> _getTabs() {
    final now = DateTime.now();
    final formatter = DateFormat('EEE. d MMM', 'fr_FR');

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
            colorScheme: const ColorScheme.dark(
              primary: Colors.indigoAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF1E2640),
              onSurface: Colors.white,
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

  Future<void> _reinitialiserDonneesTest(String entrepriseId) async {
    final firestore = FirebaseFirestore.instance;

    final ventesRef = entrepriseId.isNotEmpty
        ? firestore.collection('organizations').doc(entrepriseId).collection('ventes')
        : firestore.collection('ventes');

    final depensesRef = entrepriseId.isNotEmpty
        ? firestore.collection('organizations').doc(entrepriseId).collection('depenses')
        : firestore.collection('depenses');

    final produitsRef = entrepriseId.isNotEmpty
        ? firestore.collection('organizations').doc(entrepriseId).collection('produits')
        : firestore.collection('produits');

    final ventes = await ventesRef.get();
    for (var doc in ventes.docs) {
      await doc.reference.delete();
    }

    final depenses = await depensesRef.get();
    for (var doc in depenses.docs) {
      await doc.reference.delete();
    }

    final produits = await produitsRef.get();
    for (var doc in produits.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider).activeCurrency;
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

    final produitsStream = entrepriseId.isNotEmpty
        ? FirebaseFirestore.instance
            .collection('organizations')
            .doc(entrepriseId)
            .collection('produits')
            .snapshots()
        : FirebaseFirestore.instance.collection('produits').snapshots();

    final ventesStream = entrepriseId.isNotEmpty
        ? FirebaseFirestore.instance
            .collection('organizations')
            .doc(entrepriseId)
            .collection('ventes')
            .snapshots()
        : FirebaseFirestore.instance.collection('ventes').snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFF121829),
      appBar: AppBar(
        title: const Text(
          'Compte de Résultat (P&L)',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E2640),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            tooltip: 'Exporter l\'analyse',
            onSelected: (value) async {
              final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());
              final enTetes = ['Poste Financier', 'Montant'];
              final lignes = [
                ['Chiffre d\'Affaires (Ventes Brut)', '${_lastCA.toStringAsFixed(2)} $currency'],
                ['Coût d\'Achat des Marchandises', '-${_lastCoutAchat.toStringAsFixed(2)} $currency'],
                ['Marge Brute', '${_lastMargeBrute.toStringAsFixed(2)} $currency'],
                ['Total Charges & Dépenses', '-${_lastTotalDepenses.toStringAsFixed(2)} $currency'],
                ['Résultat Net (BÉNÉFICE NET)', '${_lastBeneficeNet.toStringAsFixed(2)} $currency'],
              ];

              if (value == 'excel') {
                await ReportExportService.exporterExcel(
                  titreRapport: 'Analyse_Financiere_PL',
                  enTetes: enTetes,
                  lignes: lignes,
                );
              } else if (value == 'pdf') {
                await ReportExportService.exporterPDF(
                  titreRapport: 'Compte de Résultat (P&L) - $dateStr',
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
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            tooltip: 'Réinitialiser les données de test',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E2640),
                  title: const Text('Réinitialisation des données', style: TextStyle(color: Colors.white)),
                  content: const Text(
                    'Voulez-vous supprimer définitivement tous les produits, ventes et dépenses ?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _reinitialiserDonneesTest(entrepriseId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Toutes les données de test ont été supprimées.'),
                            ),
                          );
                        }
                      },
                      child: const Text('Supprimer Tout', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. BARRE DE SÉLECTION PÉRIODE
          Container(
            color: const Color(0xFF1E2640),
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
                            ? Colors.indigoAccent.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: isSelected ? Colors.indigoAccent : Colors.transparent,
                        ),
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
                              color: isSelected ? Colors.indigoAccent : Colors.white70,
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
                child: Text('Erreur dépenses : $err', style: const TextStyle(color: Colors.white70)),
              ),
              data: (toutesLesDepenses) {
                return StreamBuilder<QuerySnapshot>(
                  stream: produitsStream,
                  builder: (context, snapshotProduits) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: ventesStream,
                      builder: (context, snapshotVentes) {
                        if (snapshotVentes.connectionState == ConnectionState.waiting) {
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

                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // CARTE DE RÉSULTAT NET
                              NetResultCard(
                                beneficeNet: result.beneficeNet,
                                currency: currency,
                                isProfit: result.isProfit,
                              ),

                              const SizedBox(height: 20),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Analyse Détaillée (P&L)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Appuyez pour détailler',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // LISTE DÉTAILLÉE DU COMPTE DE RÉSULTAT
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E2640),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    // 1. CHIFFRE D'AFFAIRES
                                    PLRowWidget(
                                      icon: Icons.store_rounded,
                                      color: Colors.greenAccent,
                                      title: "Chiffre d'Affaires (Ventes Brut)",
                                      montant: result.chiffreAffaires,
                                      currency: currency,
                                      onTap: () {
                                        DetailsBottomSheet.afficher(
                                          context: context,
                                          titre: "Détails du Chiffre d'Affaires",
                                          enfants: result.detailsVentesList.map((item) {
                                            return ListTile(
                                              dense: true,
                                              leading: const Icon(Icons.shopping_bag, color: Colors.greenAccent),
                                              title: Text(
                                                '${item['nom']} (x${item['qte']})',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                              subtitle: item['date'] != null
                                                  ? Text(
                                                      '${(item['date'] as DateTime).day}/${(item['date'] as DateTime).month}/${(item['date'] as DateTime).year}',
                                                      style: const TextStyle(color: Colors.white54),
                                                    )
                                                  : null,
                                              trailing: Text(
                                                '${(item['total'] as double).toStringAsFixed(2)} $currency',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      },
                                    ),
                                    const Divider(color: Colors.white10, height: 1),

                                    // 2. COÛT D'ACHAT
                                    PLRowWidget(
                                      icon: Icons.shopping_cart_rounded,
                                      color: Colors.orangeAccent,
                                      title: "Coût d'Achat des Marchandises",
                                      montant: -result.coutAchatStockVendu,
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
                                              leading: const Icon(Icons.inventory, color: Colors.orangeAccent),
                                              title: Text(
                                                '${item['nom']} (x${item['qte']})',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                              subtitle: Text(
                                                'Prix d\'achat unitaire : ${unitCost.toStringAsFixed(2)} $currency',
                                                style: const TextStyle(color: Colors.white54),
                                              ),
                                              trailing: Text(
                                                '-${(item['total'] as double).toStringAsFixed(2)} $currency',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      },
                                    ),
                                    const Divider(color: Colors.white10, height: 1),

                                    // 3. MARGE BRUTE
                                    PLRowWidget(
                                      icon: Icons.account_balance_wallet_rounded,
                                      color: Colors.blueAccent,
                                      title: "Marge Brute",
                                      montant: result.margeBrute,
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
                                                color: m >= 0 ? Colors.greenAccent : Colors.redAccent,
                                              ),
                                              title: Text(
                                                '${item['nom']} (x${item['qte']})',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                              subtitle: Text(
                                                'Vente: ${item['totalVente'].toStringAsFixed(2)} | Achat: ${item['totalAchat'].toStringAsFixed(2)}',
                                                style: const TextStyle(color: Colors.white54),
                                              ),
                                              trailing: Text(
                                                '${m.toStringAsFixed(2)} $currency',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: m >= 0 ? Colors.greenAccent : Colors.redAccent,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      },
                                    ),
                                    const Divider(color: Colors.white10, height: 1),

                                    // 4. TOTAL CHARGES & DÉPENSES
                                    PLRowWidget(
                                      icon: Icons.receipt_long_rounded,
                                      color: Colors.redAccent,
                                      title: "Total Charges & Dépenses",
                                      montant: -result.totalDepenses,
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
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                              trailing: Text(
                                                '-${entry.value.toStringAsFixed(2)} $currency',
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