import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../providers/currency_provider.dart';
import '../providers/user_role_provider.dart';
import '../providers/depense_provider.dart';
import '../services/report_export_service.dart';

enum PeriodeAnalyse { aujourdhui, cetteSemaine, ceMois, cetteAnnee, personnalise }

class FinancialAnalysisScreen extends ConsumerStatefulWidget {
  const FinancialAnalysisScreen({super.key});

  @override
  ConsumerState<FinancialAnalysisScreen> createState() => _FinancialAnalysisScreenState();
}

class _FinancialAnalysisScreenState extends ConsumerState<FinancialAnalysisScreen> {
  PeriodeAnalyse _periodeSelectionnee = PeriodeAnalyse.ceMois;
  DateTimeRange? _customRange;

  // Variables de sauvegarde pour l'exportation
  double _lastCA = 0.0;
  double _lastCoutAchat = 0.0;
  double _lastMargeBrute = 0.0;
  double _lastTotalDepenses = 0.0;
  double _lastBeneficeNet = 0.0;

  // --- FONCTION DE RÉINITIALISATION ---
  Future<void> _reinitialiserDonneesTest(String entrepriseId) async {
    final firestore = FirebaseFirestore.instance;

    final ventes = await firestore.collection('ventes').get();
    for (var doc in ventes.docs) {
      await doc.reference.delete();
    }

    final depenses = await firestore.collection('depenses').get();
    for (var doc in depenses.docs) {
      await doc.reference.delete();
    }

    final produits = await firestore.collection('produits').get();
    for (var doc in produits.docs) {
      await doc.reference.delete();
    }
  }

  // Filtrage par dates
  DateTimeRange _getRangeForPeriode() {
    final now = DateTime.now();
    switch (_periodeSelectionnee) {
      case PeriodeAnalyse.aujourdhui:
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case PeriodeAnalyse.cetteSemaine:
        final lundi = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(lundi.year, lundi.month, lundi.day);
        final dimanche = lundi.add(const Duration(days: 6));
        final end = DateTime(dimanche.year, dimanche.month, dimanche.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case PeriodeAnalyse.ceMois:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case PeriodeAnalyse.cetteAnnee:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case PeriodeAnalyse.personnalise:
        return _customRange ??
            DateTimeRange(
              start: DateTime(now.year, 1, 1),
              end: DateTime(now.year, 12, 31, 23, 59, 59),
            );
    }
  }

  // Affichage des détails sous forme de panneau coulissant (Bottom Sheet)
  void _afficherDetailsBottomSheet({
    required String titre,
    required List<Widget> enfants,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                titre,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Divider(),
              Expanded(
                child: enfants.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun détail disponible pour cette période.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView(children: enfants),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodChip(String label, PeriodeAnalyse periode) {
    final isSelected = _periodeSelectionnee == periode;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.indigo.shade900 : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: Colors.amber,
      backgroundColor: Colors.indigo.shade700,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _periodeSelectionnee = periode;
          });
        }
      },
    );
  }

  Widget _buildPLRow({
    required IconData icon,
    required Color color,
    required String title,
    required double montant,
    required String currency,
    bool isNegative = false,
    bool isBold = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${montant.toStringAsFixed(2)} $currency',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isNegative
                  ? Colors.red.shade700
                  : (montant >= 0 ? Colors.green.shade700 : Colors.red.shade700),
            ),
          ),
          if (onTap != null) const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider).activeCurrency;
    final userProfile = ref.watch(userProfileProvider).value;
    final entrepriseId = userProfile?.entrepriseId ?? '';

    final depensesAsync = ref.watch(depensesStreamProvider);
    final dateRange = _getRangeForPeriode();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Compte de Résultat (P&L)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo.shade800,
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
                ['Résultat Net (Bénéfice Net)', '${_lastBeneficeNet.toStringAsFixed(2)} $currency'],
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
                  title: const Text('Réinitialisation des données'),
                  content: const Text(
                    'Voulez-vous supprimer définitivement tous les produits, ventes et dépenses ?',
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ================= 1. BARRE DE SÉLECTION DE PÉRIODE =================
            Container(
              color: Colors.indigo.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPeriodChip('Aujourd\'hui', PeriodeAnalyse.aujourdhui),
                    const SizedBox(width: 6),
                    _buildPeriodChip('Cette Semaine', PeriodeAnalyse.cetteSemaine),
                    const SizedBox(width: 6),
                    _buildPeriodChip('Ce Mois', PeriodeAnalyse.ceMois),
                    const SizedBox(width: 6),
                    _buildPeriodChip('Cette Année', PeriodeAnalyse.cetteAnnee),
                    const SizedBox(width: 6),
                    ActionChip(
                      avatar: const Icon(Icons.date_range, size: 16, color: Colors.white),
                      label: Text(
                        _periodeSelectionnee == PeriodeAnalyse.personnalise && _customRange != null
                            ? '${_customRange!.start.day}/${_customRange!.start.month}/${_customRange!.start.year} - ${_customRange!.end.day}/${_customRange!.end.month}/${_customRange!.end.year}'
                            : 'Choisir une date...',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: _periodeSelectionnee == PeriodeAnalyse.personnalise
                          ? Colors.teal.shade600
                          : Colors.indigo.shade600,
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                          initialDateRange: _customRange,
                        );
                        if (picked != null) {
                          setState(() {
                            _customRange = DateTimeRange(
                              start: picked.start,
                              end: DateTime(
                                picked.end.year,
                                picked.end.month,
                                picked.end.day,
                                23,
                                59,
                                59,
                              ),
                            );
                            _periodeSelectionnee = PeriodeAnalyse.personnalise;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ================= 2. CALCUL EN TEMPS RÉEL =================
            depensesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Center(child: Text('Erreur dépenses : $err')),
              data: (toutesLesDepenses) {
                final depensesFiltrees = toutesLesDepenses.where((d) {
                  return d.date.isAfter(dateRange.start.subtract(const Duration(seconds: 1))) &&
                      d.date.isBefore(dateRange.end.add(const Duration(seconds: 1)));
                }).toList();

                double totalDepenses = 0.0;
                final Map<String, double> depensesParCategorie = {};

                for (var depense in depensesFiltrees) {
                  totalDepenses += depense.montant;
                  depensesParCategorie[depense.categorie] =
                      (depensesParCategorie[depense.categorie] ?? 0.0) + depense.montant;
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('produits').snapshots(),
                  builder: (context, snapshotProduits) {
                    final Map<String, double> prixAchatParId = {};
                    final Map<String, double> prixAchatParNom = {};

                    if (snapshotProduits.hasData) {
                      for (var prodDoc in snapshotProduits.data!.docs) {
                        final pData = prodDoc.data() as Map<String, dynamic>;
                        final pId = prodDoc.id;
                        final pCustomId = pData['id']?.toString();
                        final pNom = (pData['nom'] ?? pData['name'] ?? '').toString().trim().toLowerCase();

                        final pAchat = (pData['prixAchat'] ??
                                pData['prix_achat'] ??
                                pData['achat'] ??
                                pData['cost'] ??
                                0.0) as num;

                        prixAchatParId[pId] = pAchat.toDouble();
                        if (pCustomId != null) prixAchatParId[pCustomId] = pAchat.toDouble();
                        if (pNom.isNotEmpty) prixAchatParNom[pNom] = pAchat.toDouble();
                      }
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('ventes').snapshots(),
                      builder: (context, snapshotVentes) {
                        if (snapshotVentes.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        double chiffreAffaires = 0.0;
                        double coutAchatStockVendu = 0.0;

                        final List<Map<String, dynamic>> detailsVentesList = [];
                        final List<Map<String, dynamic>> detailsCoutAchatList = [];
                        final List<Map<String, dynamic>> detailsMargeList = [];

                        if (snapshotVentes.hasData) {
                          for (var doc in snapshotVentes.data!.docs) {
                            final data = doc.data() as Map<String, dynamic>;

                            final docEntrepriseId = data['entrepriseId']?.toString();
                            if (entrepriseId.isNotEmpty &&
                                docEntrepriseId != null &&
                                docEntrepriseId.isNotEmpty &&
                                docEntrepriseId != entrepriseId) {
                              continue;
                            }

                            double totalVente = 0.0;
                            final items = (data['produits'] ?? data['items'] ?? []) as List;

                            if (data['total'] != null) {
                              totalVente = (data['total'] as num).toDouble();
                            } else if (data['montantTotal'] != null) {
                              totalVente = (data['montantTotal'] as num).toDouble();
                            } else if (data['montantPaye'] != null) {
                              totalVente = (data['montantPaye'] as num).toDouble();
                            } else {
                              for (var item in items) {
                                totalVente += (item['total'] ??
                                    ((item['prix'] ?? 0.0) * (item['quantite'] ?? 1))).toDouble();
                              }
                            }

                            DateTime? dateVente;
                            final rawDate = data['date'] ?? data['createdAt'];
                            if (rawDate is Timestamp) {
                              dateVente = rawDate.toDate();
                            } else if (rawDate is String) {
                              dateVente = DateTime.tryParse(rawDate);
                            }

                            bool dansLaPeriode = true;
                            if (dateVente != null) {
                              dansLaPeriode = dateVente.isAfter(dateRange.start.subtract(const Duration(seconds: 1))) &&
                                  dateVente.isBefore(dateRange.end.add(const Duration(seconds: 1)));
                            }

                            if (dansLaPeriode) {
                              chiffreAffaires += totalVente;

                              for (var item in items) {
                                final qte = (item['quantite'] ?? item['quantity'] ?? 1) as num;
                                final nom = (item['nom'] ?? item['name'] ?? item['produit'] ?? 'Produit').toString();
                                final prixVenteTotal = (item['total'] ??
                                        ((item['prix'] ?? 0.0) * qte))
                                    .toDouble();

                                double prixAchatItem = ((item['prixAchat'] ??
                                        item['prix_achat'] ??
                                        item['achat'] ??
                                        0.0) as num).toDouble();

                                if (prixAchatItem == 0) {
                                  final pId = (item['produitId'] ?? item['productId'] ?? item['id'])?.toString();
                                  if (pId != null && prixAchatParId.containsKey(pId)) {
                                    prixAchatItem = prixAchatParId[pId]!;
                                  }
                                }

                                if (prixAchatItem == 0) {
                                  final pNom = nom.trim().toLowerCase();
                                  if (pNom.isNotEmpty && prixAchatParNom.containsKey(pNom)) {
                                    prixAchatItem = prixAchatParNom[pNom]!;
                                  }
                                }

                                final double totalCoutItem = (prixAchatItem * qte).toDouble();
                                coutAchatStockVendu += totalCoutItem;

                                detailsVentesList.add({
                                  'nom': nom,
                                  'qte': qte,
                                  'total': prixVenteTotal,
                                  'date': dateVente,
                                });

                                detailsCoutAchatList.add({
                                  'nom': nom,
                                  'qte': qte,
                                  'prixAchatUnit': prixAchatItem,
                                  'total': totalCoutItem,
                                  'date': dateVente,
                                });

                                detailsMargeList.add({
                                  'nom': nom,
                                  'qte': qte,
                                  'totalVente': prixVenteTotal,
                                  'totalAchat': totalCoutItem,
                                  'marge': prixVenteTotal - totalCoutItem,
                                });
                              }
                            }
                          }
                        }

                        final margeBrute = chiffreAffaires - coutAchatStockVendu;
                        final beneficeNet = margeBrute - totalDepenses;
                        final bool isProfit = beneficeNet >= 0;

                        // Sauvegarde des métriques pour l'exportation
                        _lastCA = chiffreAffaires;
                        _lastCoutAchat = coutAchatStockVendu;
                        _lastMargeBrute = margeBrute;
                        _lastTotalDepenses = totalDepenses;
                        _lastBeneficeNet = beneficeNet;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                color: isProfit ? Colors.teal.shade700 : Colors.red.shade700,
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isProfit ? Icons.trending_up : Icons.trending_down,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'RÉSULTAT NET (BÉNÉFICE NET)',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '${beneficeNet.toStringAsFixed(2)} $currency',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 34,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        isProfit
                                            ? 'Votre entreprise est bénéficiaire !'
                                            : 'Attention : Déficit sur cette période',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Analyse Détaillée (P&L)',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Appuyez pour détailler',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      // 1. CHIFFRE D'AFFAIRES
                                      _buildPLRow(
                                        icon: Icons.point_of_sale,
                                        color: Colors.green,
                                        title: "Chiffre d'Affaires (Ventes Brut)",
                                        montant: chiffreAffaires,
                                        currency: currency,
                                        onTap: () {
                                          _afficherDetailsBottomSheet(
                                            titre: "Détails du Chiffre d'Affaires",
                                            enfants: detailsVentesList.map((item) {
                                              return ListTile(
                                                dense: true,
                                                leading: const Icon(Icons.shopping_bag, color: Colors.green),
                                                title: Text('${item['nom']} (x${item['qte']})'),
                                                subtitle: item['date'] != null
                                                    ? Text('${(item['date'] as DateTime).day}/${(item['date'] as DateTime).month}/${(item['date'] as DateTime).year}')
                                                    : null,
                                                trailing: Text(
                                                  '${(item['total'] as double).toStringAsFixed(2)} $currency',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              );
                                            }).toList(),
                                          );
                                        },
                                      ),
                                      const Divider(height: 1),

                                      // 2. COÛT D'ACHAT
                                      _buildPLRow(
                                        icon: Icons.shopping_cart_checkout,
                                        color: Colors.orange,
                                        title: "Coût d'Achat des Marchandises",
                                        montant: -coutAchatStockVendu,
                                        currency: currency,
                                        isNegative: true,
                                        onTap: () {
                                          _afficherDetailsBottomSheet(
                                            titre: "Détails du Coût d'Achat (Stock Vendu)",
                                            enfants: detailsCoutAchatList.map((item) {
                                              final unitCost = (item['prixAchatUnit'] as double);
                                              return ListTile(
                                                dense: true,
                                                leading: const Icon(Icons.inventory, color: Colors.orange),
                                                title: Text('${item['nom']} (x${item['qte']})'),
                                                subtitle: Text('Prix d\'achat unitaire : ${unitCost.toStringAsFixed(2)} $currency'),
                                                trailing: Text(
                                                  '-${(item['total'] as double).toStringAsFixed(2)} $currency',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                                ),
                                              );
                                            }).toList(),
                                          );
                                        },
                                      ),
                                      const Divider(height: 1),

                                      // 3. MARGE BRUTE
                                      _buildPLRow(
                                        icon: Icons.account_balance_wallet,
                                        color: Colors.blue,
                                        title: "Marge Brute",
                                        montant: margeBrute,
                                        currency: currency,
                                        isBold: true,
                                        onTap: () {
                                          _afficherDetailsBottomSheet(
                                            titre: "Détails de la Marge Brute par Produit",
                                            enfants: detailsMargeList.map((item) {
                                              final marge = (item['marge'] as double);
                                              return ListTile(
                                                dense: true,
                                                leading: Icon(
                                                  marge >= 0 ? Icons.add_chart : Icons.show_chart,
                                                  color: marge >= 0 ? Colors.blue : Colors.red,
                                                ),
                                                title: Text('${item['nom']} (x${item['qte']})'),
                                                subtitle: Text(
                                                  'Vente: ${(item['totalVente'] as double).toStringAsFixed(2)} - Achat: ${(item['totalAchat'] as double).toStringAsFixed(2)}',
                                                ),
                                                trailing: Text(
                                                  '${marge.toStringAsFixed(2)} $currency',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: marge >= 0 ? Colors.blue : Colors.red,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          );
                                        },
                                      ),
                                      const Divider(height: 1),

                                      // 4. CHARGES & DÉPENSES
                                      _buildPLRow(
                                        icon: Icons.receipt_long,
                                        color: Colors.redAccent,
                                        title: "Total Charges & Dépenses",
                                        montant: -totalDepenses,
                                        currency: currency,
                                        isNegative: true,
                                        onTap: () {
                                          _afficherDetailsBottomSheet(
                                            titre: "Détails des Charges & Dépenses",
                                            enfants: depensesFiltrees.map((dep) {
                                              return ListTile(
                                                dense: true,
                                                leading: const Icon(Icons.money_off, color: Colors.redAccent),
                                                title: Text(dep.categorie),
                                                subtitle: Text('${dep.date.day}/${dep.date.month}/${dep.date.year} ${dep.note != null && dep.note!.isNotEmpty ? "- ${dep.note}" : ""}'),
                                                trailing: Text(
                                                  '-${dep.montant.toStringAsFixed(2)} $currency',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                                ),
                                              );
                                            }).toList(),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              if (depensesParCategorie.isNotEmpty) ...[
                                const Text(
                                  'Répartition des Charges',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Column(
                                    children: depensesParCategorie.entries.map((entry) {
                                      final pourcentage = totalDepenses > 0 ? (entry.value / totalDepenses) : 0.0;
                                      return Column(
                                        children: [
                                          ListTile(
                                            title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            subtitle: ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: pourcentage,
                                                minHeight: 6,
                                                backgroundColor: Colors.grey.shade200,
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                            trailing: Text(
                                              '${entry.value.toStringAsFixed(2)} $currency\n(${(pourcentage * 100).toStringAsFixed(1)}%)',
                                              textAlign: TextAlign.end,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ),
                                          const Divider(height: 1),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}