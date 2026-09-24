import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stockly_saas/features/accounting/models/journal_entry.dart';
import 'package:stockly_saas/core/models/payment_method.dart';
import 'package:stockly_saas/core/providers/currency_provider.dart';
import 'package:stockly_saas/screens/ecriture_form_screen.dart';
import 'package:stockly_saas/core/services/accounting_journal_service.dart';

// ============================================================================
// 1. PROVIDERS & STREAMS (RIVERPOD - ISOLATION MULTI-TENANT)
// ============================================================================

/// Flux en temps réel des écritures comptables sous /entreprises/{entrepriseId}/ecritures_comptables
final ecrituresComptablesProvider =
    StreamProvider.family<List<JournalEntry>, String>((ref, entrepriseId) {
  if (entrepriseId.isEmpty) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('entreprises')
      .doc(entrepriseId)
      .collection('ecritures_comptables')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => JournalEntry.fromFirestore(doc)).toList());
});

/// Controller pour les opérations d'écriture et de synchronisation comptable
final comptabiliteControllerProvider =
    AsyncNotifierProvider.family<ComptabiliteController, void, String>(
  ComptabiliteController.new,
);

class ComptabiliteController extends FamilyAsyncNotifier<void, String> {
  final AccountingJournalService _journalService = AccountingJournalService();

  @override
  Future<void> build(String arg) async {}

  PaymentMethod _parsePaymentMethod(String? method) {
    if (method == null) return PaymentMethod.cash;
    switch (method.toLowerCase()) {
      case 'carte bancaire':
      case 'virement':
      case 'banque':
        return PaymentMethod.bank;
      case 'mobile money':
        return PaymentMethod.mobileMoney;
      case 'dette':
        return PaymentMethod.credit;
      case 'cash':
      default:
        return PaymentMethod.cash;
    }
  }

  /// Nettoyage des anciennes écritures plates/obsolètes
  Future<int> nettoyerEcrituresObsolescentes() async {
    final entrepriseId = arg;
    if (entrepriseId.isEmpty) return 0;

    state = const AsyncValue.loading();
    try {
      final count = await _journalService.cleanAndMigrateEcritures(entrepriseId);
      state = const AsyncValue.data(null);
      return count;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Synchronisation des ventes non comptabilisées
  Future<int> synchroniserHistoriqueComptable() async {
    final entrepriseId = arg;
    if (entrepriseId.isEmpty) return 0;

    state = const AsyncValue.loading();

    try {
      await _journalService.cleanAndMigrateEcritures(entrepriseId);

      final db = FirebaseFirestore.instance;
      final orgRef = db.collection('entreprises').doc(entrepriseId);
      final ventesSnap = await orgRef.collection('ventes').get();

      final uncomptabilizedDocs = ventesSnap.docs.where((doc) {
        final data = doc.data();
        return data['comptabilise'] != true;
      }).toList();

      if (uncomptabilizedDocs.isEmpty) {
        state = const AsyncValue.data(null);
        return 0;
      }

      WriteBatch batch = db.batch();
      int operationCount = 0;

      for (var doc in uncomptabilizedDocs) {
        final data = doc.data();
        final String client =
            data['clientNom'] ?? data['nomClient'] ?? 'Client Divers';
        final double verse = (data['montantPaye'] as num?)?.toDouble() ?? 0.0;
        final double reste = (data['resteAPayer'] as num?)?.toDouble() ?? 0.0;
        final double totalVente =
            (data['montantTotal'] as num?)?.toDouble() ?? (verse + reste);
        final dynamic date = data['date'] ?? FieldValue.serverTimestamp();
        final String? methodePaiement = data['methodePaiement'];

        if (totalVente <= 0) continue;

        final refEcriture = orgRef.collection('ecritures_comptables').doc();
        final List<Map<String, dynamic>> lines = [];

        if (verse > 0) {
          final pMethod = _parsePaymentMethod(methodePaiement);
          final codeTresorerie =
              AccountingJournalService.getAccountCodeForPayment(pMethod);
          final labelTresorerie =
              AccountingJournalService.getAccountLabel(codeTresorerie);

          lines.add({
            'accountCode': codeTresorerie,
            'accountLabel': labelTresorerie,
            'debit': verse,
            'credit': 0.0,
          });
        }

        if (reste > 0) {
          lines.add({
            'accountCode': '411000',
            'accountLabel': 'Clients - $client',
            'debit': reste,
            'credit': 0.0,
          });
        }

        lines.add({
          'accountCode': '701000',
          'accountLabel': AccountingJournalService.getAccountLabel('701000'),
          'debit': 0.0,
          'credit': totalVente,
        });

        batch.set(refEcriture, {
          'id': refEcriture.id,
          'entrepriseId': entrepriseId,
          'description': 'Vente - $client',
          'date': date,
          'reference': doc.id,
          'lines': lines,
          'montantEncaisse': verse,
        });
        operationCount++;

        batch.update(doc.reference, {'comptabilise': true});
        operationCount++;

        if (operationCount >= 400) {
          await batch.commit();
          batch = db.batch();
          operationCount = 0;
        }
      }

      if (operationCount > 0) {
        await batch.commit();
      }

      state = const AsyncValue.data(null);
      return uncomptabilizedDocs.length;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Extourne (Annulation) d'une écriture comptable
  Future<void> extournerEcriture(JournalEntry entry) async {
    final entrepriseId = arg;
    if (entrepriseId.isEmpty) return;

    state = const AsyncValue.loading();
    try {
      final db = FirebaseFirestore.instance;
      final refEcriture = db
          .collection('entreprises')
          .doc(entrepriseId)
          .collection('ecritures_comptables')
          .doc();

      final reversedLines = entry.lines.map((l) {
        return {
          'accountCode': l.accountCode,
          'accountLabel': l.accountLabel,
          'debit': l.credit,
          'credit': l.debit,
        };
      }).toList();

      await refEcriture.set({
        'id': refEcriture.id,
        'entrepriseId': entrepriseId,
        'description': 'Extourne / Annulation : ${entry.description}',
        'date': FieldValue.serverTimestamp(),
        'reference': 'EXT-${entry.id}',
        'lines': reversedLines,
      });

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Suppression d'une écriture comptable
  Future<void> supprimerEcriture(String ecritureId) async {
    final entrepriseId = arg;
    if (entrepriseId.isEmpty) return;

    state = const AsyncValue.loading();
    try {
      await FirebaseFirestore.instance
          .collection('entreprises')
          .doc(entrepriseId)
          .collection('ecritures_comptables')
          .doc(ecritureId)
          .delete();

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

// ============================================================================
// 2. ÉCRAN DE COMPTABILITÉ (PRESENTATION LAYER)
// ============================================================================

class ComptabiliteScreen extends ConsumerStatefulWidget {
  final String entrepriseId;

  const ComptabiliteScreen({super.key, required this.entrepriseId});

  @override
  ConsumerState<ComptabiliteScreen> createState() => _ComptabiliteScreenState();
}

class _ComptabiliteScreenState extends ConsumerState<ComptabiliteScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String? _selectedAccountFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleSync() async {
    try {
      final count = await ref
          .read(comptabiliteControllerProvider(widget.entrepriseId).notifier)
          .synchroniserHistoriqueComptable();

      if (!mounted) return;

      final message = count > 0
          ? '$count ventes rattrapées avec succès !'
          : 'Journal nettoyé et à jour.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.teal),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la synchronisation : $e')),
      );
    }
  }

  Future<void> _handleClean() async {
    try {
      final count = await ref
          .read(comptabiliteControllerProvider(widget.entrepriseId).notifier)
          .nettoyerEcrituresObsolescentes();

      if (!mounted) return;

      final message = count > 0
          ? 'Nettoyage terminé : $count écriture(s) obsolète(s) supprimée(s).'
          : 'Aucune écriture obsolète trouvée.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.teal),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du nettoyage : $e')),
      );
    }
  }

  void _exporterPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportation du Grand Livre PDF en cours...')),
    );
  }

  void _exporterCSV() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportation CSV / Excel en cours...')),
    );
  }

  Future<void> _extourner(JournalEntry entry) async {
    try {
      await ref
          .read(comptabiliteControllerProvider(widget.entrepriseId).notifier)
          .extournerEcriture(entry);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Écriture extournée avec succès.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'extourne : $e')),
      );
    }
  }

  Future<void> _supprimer(String entryId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
            'Voulez-vous vraiment supprimer cette écriture comptable ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref
          .read(comptabiliteControllerProvider(widget.entrepriseId).notifier)
          .supprimerEcriture(entryId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Écriture supprimée.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ecrituresAsync =
        ref.watch(ecrituresComptablesProvider(widget.entrepriseId));
    final controllerState =
        ref.watch(comptabiliteControllerProvider(widget.entrepriseId));
    final currencyState = ref.watch(currencyProvider);

    final isSyncing = controllerState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Comptabilité SYSCOHADA',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exporter Grand Livre PDF',
            onPressed: _exporterPDF,
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Synchroniser / Rattraper Ventes',
            onPressed: isSyncing ? null : _handleSync,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clean') {
                _handleClean();
              } else if (value == 'export_csv') {
                _exporterCSV();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clean',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services, color: Colors.teal, size: 20),
                    SizedBox(width: 8),
                    Text('Nettoyer les doublons'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.teal, size: 20),
                    SizedBox(width: 8),
                    Text('Exporter CSV / Excel'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Journal'),
            Tab(icon: Icon(Icons.account_balance), text: 'Bilan & Synthèse'),
          ],
        ),
      ),
      body: ecrituresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Erreur de chargement : $err',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
        data: (ecritures) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildJournalTab(ecritures, currencyState, isSyncing),
              _buildBilanSyntheseTab(ecritures, currencyState),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EcritureFormScreen(entrepriseId: widget.entrepriseId),
            ),
          );
        },
        backgroundColor: Colors.teal.shade800,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Saisie OD / Manuelle',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // --- ONGLET 1 : JOURNAL AVEC FILTRES, RECHERCHE ET ACTIONS ---
  Widget _buildJournalTab(
      List<JournalEntry> ecritures, CurrencyState currencyState, bool isSyncing) {
    final filtered = ecritures.where((entry) {
      final queryLower = _searchQuery.toLowerCase();

      final matchesSearch = entry.description.toLowerCase().contains(queryLower) ||
          entry.lines.any((l) =>
              l.accountLabel.toLowerCase().contains(queryLower) ||
              l.accountCode.toLowerCase().contains(queryLower));

      final matchesAccount = _selectedAccountFilter == null ||
          entry.lines.any((l) => l.accountCode.startsWith(_selectedAccountFilter!));

      return matchesSearch && matchesAccount;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher libellé, compte...',
                    prefixIcon: const Icon(Icons.search),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String?>(
                value: _selectedAccountFilter,
                hint: const Text('Compte'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tous')),
                  DropdownMenuItem(value: '701', child: Text('701 Ventes')),
                  DropdownMenuItem(value: '411', child: Text('411 Clients')),
                  DropdownMenuItem(value: '419', child: Text('419 Avances')),
                  DropdownMenuItem(value: '571', child: Text('571 Caisse')),
                  DropdownMenuItem(value: '521', child: Text('521 Banque')),
                  DropdownMenuItem(value: '6', child: Text('Classe 6 Charges')),
                ],
                onChanged: (val) => setState(() => _selectedAccountFilter = val),
              ),
            ],
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.menu_book, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucune écriture ne correspond aux critères.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      if (ecritures.isEmpty)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade800),
                          onPressed: isSyncing ? null : _handleSync,
                          icon: const Icon(Icons.sync, color: Colors.white),
                          label: const Text('Rattraper les ventes passées',
                              style: TextStyle(color: Colors.white)),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    return _buildEcritureCard(entry, currencyState);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEcritureCard(JournalEntry entry, CurrencyState currencyState) {
    final date = entry.date;
    final dateStr =
        "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

    final hasLines = entry.lines.isNotEmpty;
    final firstDebitCode = hasLines
        ? entry.lines
            .firstWhere((l) => l.debit > 0, orElse: () => entry.lines.first)
            .accountCode
        : 'N/A';
    final firstCreditCode = hasLines
        ? entry.lines
            .firstWhere((l) => l.credit > 0, orElse: () => entry.lines.last)
            .accountCode
        : 'N/A';

    final isExtourne = entry.description.startsWith('Extourne');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor:
              isExtourne ? Colors.orange.shade100 : Colors.teal.shade50,
          child: Icon(
            isExtourne ? Icons.hourglass_top : Icons.swap_horiz,
            color: isExtourne ? Colors.orange.shade800 : Colors.teal.shade800,
            size: 20,
          ),
        ),
        title: Text(
          entry.description,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          'D: $firstDebitCode | C: $firstCreditCode • $dateStr',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currencyState.formatPrice(entry.totalDebit),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade900,
                fontSize: 14,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'reverse') {
                  _extourner(entry);
                } else if (action == 'delete') {
                  _supprimer(entry.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'reverse',
                  child: Text('Extourner (Annuler)'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
        children: entry.lines.map((line) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${line.accountCode} - ${line.accountLabel}',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  line.debit > 0
                      ? 'D: ${currencyState.formatPrice(line.debit)}'
                      : 'C: ${currencyState.formatPrice(line.credit)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: line.debit > 0
                        ? Colors.green.shade800
                        : Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- ONGLET 2 : BILAN & SYNTHÈSE ENRICHI ---
  Widget _buildBilanSyntheseTab(List<JournalEntry> ecritures, CurrencyState currencyState) {
    double totalTresorerie = 0.0;
    double totalCreances = 0.0;
    double totalVentes = 0.0;
    double totalCharges = 0.0;
    double totalAvances = 0.0;

    for (var entry in ecritures) {
      for (var line in entry.lines) {
        final code = line.accountCode;

        if (code.startsWith('571') ||
            code.startsWith('531') ||
            code.startsWith('521') ||
            code.startsWith('572')) {
          totalTresorerie += (line.debit - line.credit);
        }

        if (code.startsWith('411')) {
          totalCreances += (line.debit - line.credit);
        }

        if (code.startsWith('419')) {
          totalAvances += (line.credit - line.debit);
        }

        if (code.startsWith('7')) {
          totalVentes += (line.credit - line.debit);
        }

        if (code.startsWith('6')) {
          totalCharges += (line.debit - line.credit);
        }
      }
    }

    final double resultat = totalVentes - totalCharges;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Synthèse Générale',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Divider(height: 20),
                  _buildSummaryRow(
                    'Trésorerie Globale (571/521)',
                    currencyState.formatPrice(totalTresorerie),
                    Colors.green.shade700,
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    'Chiffre d\'Affaires / Ventes (701)',
                    currencyState.formatPrice(totalVentes),
                    Colors.blue.shade700,
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    'Avances & Acomptes Reçus (419)',
                    currencyState.formatPrice(totalAvances),
                    Colors.orange.shade800,
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    'Créances Clients (411)',
                    currencyState.formatPrice(totalCreances),
                    Colors.red.shade700,
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    'Charges & Achats (Classe 6)',
                    currencyState.formatPrice(totalCharges),
                    Colors.purple.shade700,
                  ),
                  const Divider(thickness: 1.5),
                  _buildSummaryRow(
                    'Résultat Estimé (Ventes - Charges)',
                    currencyState.formatPrice(resultat),
                    resultat >= 0 ? Colors.teal.shade800 : Colors.red.shade900,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 15),
          ),
        ],
      ),
    );
  }
}