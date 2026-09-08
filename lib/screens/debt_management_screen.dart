// lib/screens/debt_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockly_saas/models/dette.dart';

import '../controllers/debt_controller.dart';
import '../providers/currency_provider.dart';
import '../providers/user_role_provider.dart';
import '../services/report_export_service.dart';
import '../widgets/debt_dialogs.dart';
import '../widgets/debt_list_view.dart';

class DebtManagementScreen extends ConsumerWidget {
  const DebtManagementScreen({super.key});

  String _formaterDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  Future<void> _exporterRapport({
    required String format,
    required List<Dette> dettes,
    required bool isClientTab,
    required String currency,
  }) async {
    final currentTypeLabel =
        isClientTab ? 'Creances_Clients' : 'Dettes_Fournisseurs';
    final titreDoc = isClientTab
        ? 'Rapport des Créances Clients'
        : 'Rapport des Dettes Fournisseurs';

    final targetType = isClientTab ? TypeDette.client : TypeDette.fournisseur;
    final listeFiltree = dettes.where((d) => d.type == targetType).toList();

    final enTetes = [
      'Tiers / Nom',
      'N° Facture',
      'Total Initial',
      'Acompte',
      'Reste à Payer',
      'Statut',
      'Échéance'
    ];

    final lignes = listeFiltree.map((dette) {
      final String statutStr = dette.statut == 'paye'
          ? 'Soldé'
          : (dette.statut == 'partiel' ? 'Partiel' : 'Non Payé');

      final String echeanceStr = dette.dateEcheance != null
          ? _formaterDate(dette.dateEcheance!)
          : '-';

      return [
        dette.nomTiers,
        dette.numeroFacture,
        '${dette.montantInitial.toStringAsFixed(2)} $currency',
        '${dette.acomptePaye.toStringAsFixed(2)} $currency',
        '${dette.montantReste.toStringAsFixed(2)} $currency',
        statutStr,
        echeanceStr,
      ];
    }).toList();

    if (format == 'excel') {
      await ReportExportService.exporterExcel(
        titreRapport: 'Rapport_$currentTypeLabel',
        enTetes: enTetes,
        lignes: lignes,
      );
    } else if (format == 'pdf') {
      await ReportExportService.exporterPDF(
        titreRapport: titreDoc,
        nomBoutique: 'Stockly Pro',
        enTetes: enTetes,
        lignes: lignes,
      );
    }
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required String currency,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${amount.toStringAsFixed(2)} $currency',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider).activeCurrency;
    final userProfile = ref.watch(userProfileProvider).value;
    final entrepriseId = userProfile?.entrepriseId ?? '';

    final dettesAsync = ref.watch(dettesStreamProvider(entrepriseId));
    final controllerState = ref.watch(debtControllerProvider(entrepriseId));

    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.grey.shade100,
            appBar: AppBar(
              title: const Text(
                'Gestion des Dettes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.indigo.shade800,
              foregroundColor: Colors.white,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  tooltip: 'Exporter',
                  onSelected: (value) {
                    final dettes = dettesAsync.value ?? [];
                    final isClientTab =
                        DefaultTabController.of(context).index == 0;
                    _exporterRapport(
                      format: value,
                      dettes: dettes,
                      isClientTab: isClientTab,
                      currency: currency,
                    );
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
              bottom: const TabBar(
                indicatorColor: Colors.amber,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: [
                  Tab(
                    icon: Icon(Icons.call_received),
                    text: 'Clients (Créances)',
                  ),
                  Tab(
                    icon: Icon(Icons.call_made),
                    text: 'Fournisseurs (Dettes)',
                  ),
                ],
              ),
            ),
            body: Stack(
              children: [
                dettesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Erreur de chargement : $err',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  data: (dettes) {
                    final creancesClients = dettes
                        .where((d) => d.type == TypeDette.client)
                        .toList();

                    final dettesFournisseurs = dettes
                        .where((d) => d.type == TypeDette.fournisseur)
                        .toList();

                    final totalCreances = creancesClients.fold<double>(
                      0.0,
                      (sum, item) => sum + item.montantReste,
                    );
                    final totalDettes = dettesFournisseurs.fold<double>(
                      0.0,
                      (sum, item) => sum + item.montantReste,
                    );

                    return TabBarView(
                      children: [
                        Column(
                          children: [
                            _buildSummaryCard(
                              title: 'Total des Créances à Recouvrer',
                              amount: totalCreances,
                              currency: currency,
                              color: Colors.green.shade800,
                            ),
                            Expanded(
                              child: DebtListView(
                                entrepriseId: entrepriseId,
                                liste: creancesClients,
                                type: TypeDette.client,
                                currency: currency,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            _buildSummaryCard(
                              title: 'Total des Dettes à Payer',
                              amount: totalDettes,
                              currency: currency,
                              color: Colors.red.shade800,
                            ),
                            Expanded(
                              child: DebtListView(
                                entrepriseId: entrepriseId,
                                liste: dettesFournisseurs,
                                type: TypeDette.fournisseur,
                                currency: currency,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                if (controllerState.isLoading)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: Colors.indigo.shade800,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Ajouter une dette',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                final isClient = DefaultTabController.of(context).index == 0;
                DebtDialogs.afficherAjoutDette(
                  context,
                  ref,
                  entrepriseId,
                  isClient ? TypeDette.client : TypeDette.fournisseur,
                );
              },
            ),
          );
        },
      ),
    );
  }
}