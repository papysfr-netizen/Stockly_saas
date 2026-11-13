// 🌙 mode sombre automatique
// lib/features/debts/screens/debt_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stockly_saas/core/models/dette.dart';
import 'package:stockly_saas/features/debts/controllers/debt_controller.dart';
import 'package:stockly_saas/core/providers/currency_provider.dart';
import 'package:stockly_saas/core/providers/user_role_provider.dart';
import 'package:stockly_saas/core/services/report_export_service.dart';
import 'package:stockly_saas/features/debts/widgets/debt_dialogs.dart';
import 'package:stockly_saas/features/debts/widgets/debt_list_view.dart';
import 'package:stockly_saas/l10n/app_localizations.dart';

class DebtManagementScreen extends ConsumerWidget {
  const DebtManagementScreen({super.key});

  static const Color _bleuNuit = Color(0xFF1E293B);

  String _formaterDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  Future<void> _exporterRapport({
    required String format,
    required List<Dette> dettes,
    required bool isClientTab,
    required String currency,
  }) async {
    final titreDoc = isClientTab ? 'Créances clients' : 'Dettes fournisseurs';

    final targetType = isClientTab ? TypeDette.client : TypeDette.fournisseur;
    final listeFiltree = dettes.where((d) => d.type == targetType && !d.estSolde).toList()
      ..sort((a, b) => a.dateCreation.compareTo(b.dateCreation));

    final enTetes = [
      isClientTab ? 'Client' : 'Fournisseur',
      'Téléphone',
      'N° Facture',
      'Date',
      'Âge (jours)',
      'Total ($currency)',
      'Déjà payé ($currency)',
      'Reste ($currency)',
      'Statut',
    ];

    double total = 0;
    final lignes = <List<dynamic>>[];
    for (final d in listeFiltree) {
      total += d.montantReste;
      final age = DateTime.now().difference(d.dateCreation).inDays;
      final statut = (d.estEnRetard || age > 30)
          ? 'En retard'
          : (d.acomptePaye > 0 ? 'Partiel' : 'Non payée');
      lignes.add(<dynamic>[
        d.nomTiers,
        d.telephone,
        d.numeroFacture,
        _formaterDate(d.dateCreation),
        age,
        d.montantInitial,
        d.acomptePaye,
        d.montantReste,
        statut,
      ]);
    }
    lignes.add(<dynamic>['TOTAL', '', '', '', '', '', '', total, '']);

    if (format == 'excel') {
      await ReportExportService.exporterExcel(
        titreRapport: titreDoc,
        enTetes: enTetes,
        lignes: lignes,
      );
    } else if (format == 'pdf') {
      await ReportExportService.exporterPDF(
        titreRapport: titreDoc,
        nomBoutique: 'Nguli',
        enTetes: enTetes,
        lignes: lignes
            .map((l) => l.map((v) => v is double ? v.toStringAsFixed(2) : v).toList())
            .toList(),
        modePaysage: true,
      );
    }
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
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF121418) : const Color(0xFFF3F4F6),
            appBar: AppBar(
              title: Text(
                AppLocalizations.of(context).debtScreenTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: _bleuNuit,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
                  tooltip: AppLocalizations.of(context).debtExport,
                  onSelected: (value) {
                    final dettes = dettesAsync.value ?? [];
                    final isClientTab = DefaultTabController.of(context).index == 0;
                    _exporterRapport(
                      format: value,
                      dettes: dettes,
                      isClientTab: isClientTab,
                      currency: currency,
                    );
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'excel',
                      child: Row(children: [
                        const Icon(Icons.table_chart, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context).debtExportExcel),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'pdf',
                      child: Row(children: [
                        const Icon(Icons.picture_as_pdf, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context).debtPrintPdf),
                      ]),
                    ),
                  ],
                ),
              ],
              bottom: TabBar(
                indicatorColor: Colors.amber,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(icon: const Icon(Icons.call_received_rounded), text: AppLocalizations.of(context).debtTabClients),
                  Tab(icon: const Icon(Icons.call_made_rounded), text: AppLocalizations.of(context).debtTabSuppliers),
                ],
              ),
            ),
            body: Stack(
              children: [
                dettesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        AppLocalizations.of(context).debtLoadError('$err'),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  data: (dettes) {
                    final creancesClients =
                        dettes.where((d) => d.type == TypeDette.client).toList();
                    final dettesFournisseurs =
                        dettes.where((d) => d.type == TypeDette.fournisseur).toList();

                    return TabBarView(
                      children: [
                        DebtListView(
                          entrepriseId: entrepriseId,
                          liste: creancesClients,
                          type: TypeDette.client,
                          currency: currency,
                        ),
                        DebtListView(
                          entrepriseId: entrepriseId,
                          liste: dettesFournisseurs,
                          type: TypeDette.fournisseur,
                          currency: currency,
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
              backgroundColor: _bleuNuit,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                AppLocalizations.of(context).debtAdd,
                style: const TextStyle(color: Colors.white),
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
