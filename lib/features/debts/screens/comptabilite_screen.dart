import 'package:stockly_saas/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockly_saas/features/boutiques/compta_boutique.dart';
import 'package:stockly_saas/features/boutiques/boutique_provider.dart';
import 'package:stockly_saas/core/providers/user_role_provider.dart';

import 'package:stockly_saas/features/accounting/models/journal_entry.dart';
import 'package:stockly_saas/core/models/payment_method.dart';
import 'package:stockly_saas/core/providers/currency_provider.dart';
import 'package:stockly_saas/features/accounting/services/accounting_journal_service.dart';
import 'package:stockly_saas/features/accounting/services/soldes_mensuels_service.dart';
import 'package:stockly_saas/features/accounting/screens/ecriture_form_screen.dart';
import 'package:stockly_saas/core/widgets/recherche_differee.dart';
import 'package:stockly_saas/core/widgets/chargement_squelette.dart';
// ============================================================================
// 1. PROVIDERS & STREAMS (RIVERPOD - ISOLATION MULTI-TENANT)
// ============================================================================

/// 📅 Écritures d'UN mois, en direct (avant : toutes les écritures depuis le début,
///    relues à chaque ouverture). [mois] = 'AAAA-MM'.
final ecrituresDuMoisProvider =
    StreamProvider.family<List<JournalEntry>, ({String entrepriseId, String mois})>((ref, cle) {
  if (cle.entrepriseId.isEmpty) return Stream.value([]);
  final morceaux = cle.mois.split('-');
  final mois = DateTime(int.parse(morceaux[0]), int.parse(morceaux[1]));

  return SoldesMensuelsService.requeteDuMois(cle.entrepriseId, mois)
      .snapshots()
      .map((snapshot) {
        // 🏬 On note la boutique de chaque écriture (pour le filtre)
        for (final doc in snapshot.docs) {
          noterInfosEcriture(doc.id, doc.data());
        }
        return snapshot.docs.map((doc) => JournalEntry.fromFirestore(doc)).toList();
      });
});

/// 📊 Soldes cumulés des mois passés (résumés mensuels). [version] change
///    quand on demande « Recalculer » (tout est relu une fois).
final soldesAvantProvider = FutureProvider.family<SoldesParBoutique,
    ({String entrepriseId, String mois, int version})>((ref, cle) {
  if (cle.entrepriseId.isEmpty) return Future.value(<String, Map<String, double>>{});
  final morceaux = cle.mois.split('-');
  return SoldesMensuelsService.cumulAvant(
    cle.entrepriseId,
    DateTime(int.parse(morceaux[0]), int.parse(morceaux[1])),
    toutRecalculer: cle.version > 0,
  );
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
      // 💸 Le grand balayage (toutes les écritures et toutes les ventes) n'est
      //    fait qu'UNE fois par téléphone. Ensuite : seulement les ventes
      //    marquées « non comptabilisées ».
      final prefs = await SharedPreferences.getInstance();
      final cleBalayage = 'balayage_compta_fait_$entrepriseId';
      final premierBalayage = prefs.getBool(cleBalayage) != true;
      if (premierBalayage) {
        await _journalService.cleanAndMigrateEcritures(entrepriseId);
      }

      final db = FirebaseFirestore.instance;
      final orgRef = db.collection('entreprises').doc(entrepriseId);
      final ventesSnap = premierBalayage
          ? await orgRef.collection('ventes').get()
          : await orgRef.collection('ventes').where('comptabilise', isEqualTo: false).get();

      final uncomptabilizedDocs = ventesSnap.docs.where((doc) {
        final data = doc.data();
        return data['comptabilise'] != true;
      }).toList();

      if (uncomptabilizedDocs.isEmpty) {
        if (premierBalayage) await prefs.setBool(cleBalayage, true);
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
          'boutiqueId': (data['boutiqueId'] ?? 'principale').toString(), // 🏬
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

      // Balayage réussi jusqu'au bout : la prochaine fois, seulement le nouveau
      if (premierBalayage) await prefs.setBool(cleBalayage, true);
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
        'boutiqueId': boutiqueEcriture(entry.id), // 🏬 même boutique
        'lines': reversedLines,
      });

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Suppression d'une écriture comptable
  Future<void> supprimerEcriture(String ecritureId, {DateTime? date}) async {
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
      // 📊 Le résumé du mois (s'il est passé) sera refait
      if (date != null) await SoldesMensuelsService.invalider(entrepriseId, date);

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
    with SingleTickerProviderStateMixin, RechercheDifferee<ComptabiliteScreen> {
  late TabController _tabController;
  String _searchQuery = '';
  String? _selectedAccountFilter;
  // 📅 Mois affiché dans le Journal
  DateTime _mois = SoldesMensuelsService.debutMois(DateTime.now());
  // 📊 > 0 : « Recalculer » le bilan (relit tout une fois)
  int _versionBilan = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 🏬 Patron / gérant : les anciennes écritures reçoivent leur boutique
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final futur = ref.read(userProfileProvider.future);
      try {
        final profil = await futur.timeout(const Duration(seconds: 10));
        if (!profil.role.isAdminOrOwner) return;
        // Une seule fois par téléphone : les nouvelles écritures ont déjà leur boutique
        final prefs = await SharedPreferences.getInstance();
        final cle = 'boutiques_ecritures_ok_${profil.entrepriseId}';
        if (prefs.getBool(cle) == true) return;
        if (await rattraperBoutiquesEcritures(profil.entrepriseId)) {
          await prefs.setBool(cle, true);
        }
      } catch (_) {}
    });
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
          ? AppLocalizations.of(context).cptSynced('$count')
          : AppLocalizations.of(context).cptUpToDate;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.teal),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).cptSyncError('$e'))),
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
          ? AppLocalizations.of(context).cptCleaned('$count')
          : AppLocalizations.of(context).cptNothingToClean;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.teal),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).cptCleanError('$e'))),
      );
    }
  }

  void _exporterPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).cptExportingPdf)),
    );
  }

  void _exporterCSV() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).cptExportingCsv)),
    );
  }

  Future<void> _extourner(JournalEntry entry) async {
    try {
      await ref
          .read(comptabiliteControllerProvider(widget.entrepriseId).notifier)
          .extournerEcriture(entry);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).cptReversed),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).cptReverseError('$e'))),
      );
    }
  }

  Future<void> _supprimer(String entryId, DateTime date) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).cptConfirmDelete),
        content: Text(
            AppLocalizations.of(context).cptDeleteQ),
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
          .supprimerEcriture(entryId, date: date);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).cptDeleted)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).cptDeleteError('$e'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ecrituresAsync = ref.watch(ecrituresDuMoisProvider(
        (entrepriseId: widget.entrepriseId, mois: SoldesMensuelsService.cleMois(_mois))));
    final controllerState =
        ref.watch(comptabiliteControllerProvider(widget.entrepriseId));
    final currencyState = ref.watch(currencyProvider);

    final isSyncing = controllerState.isLoading;
    final boutique = ref.watch(boutiqueActiveProvider); // 🏬

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).cptTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: AppLocalizations.of(context).cptExportPdf,
            onPressed: _exporterPDF,
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: AppLocalizations.of(context).cptSyncTip,
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
              PopupMenuItem(
                value: 'clean',
                child: Row(
                  children: [
                    const Icon(Icons.cleaning_services, color: Colors.teal, size: 20),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context).cptCleanDup),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export_csv',
                child: Row(
                  children: [
                    const Icon(Icons.table_chart, color: Colors.teal, size: 20),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context).cptExportCsv),
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
          tabs: [
            Tab(icon: const Icon(Icons.receipt_long), text: AppLocalizations.of(context).cptTabJournal),
            Tab(icon: const Icon(Icons.account_balance), text: AppLocalizations.of(context).cptTabBalance),
          ],
        ),
      ),
      body: ecrituresAsync.when(
        loading: () => const ChargementSquelette(),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              AppLocalizations.of(context).cptLoadError('$err'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
        data: (toutes) {
          // 🏬 Seulement les écritures de la boutique affichée
          final ecritures = boutique == null
              ? toutes
              : toutes.where((e) => boutiqueEcriture(e.id) == boutique).toList();
          return TabBarView(
            controller: _tabController,
            children: [
              _buildJournalTab(ecritures, currencyState, isSyncing),
              _buildBilanSyntheseTab(boutique, currencyState),
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
        label: Text(AppLocalizations.of(context).cptManual,
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

    final ceMois = SoldesMensuelsService.debutMois(DateTime.now());
    return Column(
      children: [
        // 📅 Un mois à la fois (lecture rapide et économique)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _mois = DateTime(_mois.year, _mois.month - 1)),
            ),
            Text('${AppLocalizations.of(context).cptMonths.split(',')[_mois.month - 1]} ${_mois.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _mois.isBefore(ceMois)
                  ? () => setState(() => _mois = DateTime(_mois.year, _mois.month + 1))
                  : null,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).cptSearch,
                    prefixIcon: const Icon(Icons.search),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) => differer(() => setState(() => _searchQuery = val)),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String?>(
                value: _selectedAccountFilter,
                hint: Text(AppLocalizations.of(context).cptAccount),
                items: [
                  DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context).cptAll)),
                  DropdownMenuItem(value: '701', child: Text(AppLocalizations.of(context).cptAcc701)),
                  DropdownMenuItem(value: '411', child: Text(AppLocalizations.of(context).cptAcc411)),
                  DropdownMenuItem(value: '419', child: Text(AppLocalizations.of(context).cptAcc419)),
                  DropdownMenuItem(value: '571', child: Text(AppLocalizations.of(context).cptAcc571)),
                  DropdownMenuItem(value: '521', child: Text(AppLocalizations.of(context).cptAcc521)),
                  DropdownMenuItem(value: '6', child: Text(AppLocalizations.of(context).cptAcc6)),
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
                      Text(
                        AppLocalizations.of(context).cptNoMatch,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      if (ecritures.isEmpty)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade800),
                          onPressed: isSyncing ? null : _handleSync,
                          icon: const Icon(Icons.sync, color: Colors.white),
                          label: Text(AppLocalizations.of(context).cptCatchUp,
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
                  _supprimer(entry.id, entry.date);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'reverse',
                  child: Text(AppLocalizations.of(context).cptReverse),
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
                        ? (Theme.of(context).brightness == Brightness.dark ? Colors.green.shade300 : Colors.green.shade800)
                        : (Theme.of(context).brightness == Brightness.dark ? Colors.blue.shade200 : Colors.blue.shade800),
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
  Widget _buildBilanSyntheseTab(String? boutique, CurrencyState currencyState) {
    // 📊 Bilan = résumés des mois passés + écritures du mois en cours (en direct)
    final ceMois = SoldesMensuelsService.debutMois(DateTime.now());
    final cleMois = SoldesMensuelsService.cleMois(ceMois);
    final avant = ref.watch(soldesAvantProvider(
        (entrepriseId: widget.entrepriseId, mois: cleMois, version: _versionBilan)));
    final courant = ref.watch(ecrituresDuMoisProvider((entrepriseId: widget.entrepriseId, mois: cleMois)));

    if (avant.isLoading || courant.isLoading) {
      return const ChargementSquelette();
    }
    if (avant.hasError || courant.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(AppLocalizations.of(context).cptLoadError('${avant.error ?? courant.error}'),
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    final soldes = SoldesMensuelsService.pourBoutique(avant.value ?? const {}, boutique);
    for (final entry in courant.value ?? const <JournalEntry>[]) {
      if (boutique != null && boutiqueEcriture(entry.id) != boutique) continue;
      for (final line in entry.lines) {
        soldes[line.accountCode] = (soldes[line.accountCode] ?? 0) + line.debit - line.credit;
      }
    }

    double totalTresorerie = 0.0;
    double totalCreances = 0.0;
    double totalVentes = 0.0;
    double totalCharges = 0.0;
    double totalAvances = 0.0;

    soldes.forEach((code, net) {
      if (code.startsWith('571') ||
          code.startsWith('531') ||
          code.startsWith('521') ||
          code.startsWith('572')) {
        totalTresorerie += net;
      }
      if (code.startsWith('411')) totalCreances += net;
      if (code.startsWith('419')) totalAvances -= net;
      if (code.startsWith('7')) totalVentes -= net;
      if (code.startsWith('6')) totalCharges += net;
    });

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
                  Text(
                    AppLocalizations.of(context).cptSummary,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Divider(height: 20),
                  _buildSummaryRow(
                    AppLocalizations.of(context).cptCash,
                    currencyState.formatPrice(totalTresorerie),
                    Colors.green.shade700,
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    AppLocalizations.of(context).cptRevenue,
                    currencyState.formatPrice(totalVentes),
                    Colors.blue.shade700,
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    AppLocalizations.of(context).cptAdvances,
                    currencyState.formatPrice(totalAvances),
                    Colors.orange.shade800,
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    AppLocalizations.of(context).cptReceivables,
                    currencyState.formatPrice(totalCreances),
                    Colors.red.shade700,
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    AppLocalizations.of(context).cptCharges,
                    currencyState.formatPrice(totalCharges),
                    Colors.purple.shade700,
                  ),
                  const Divider(thickness: 1.5),
                  _buildSummaryRow(
                    AppLocalizations.of(context).cptResult,
                    currencyState.formatPrice(resultat),
                    resultat >= 0 ? Colors.teal.shade800 : Colors.red.shade900,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).cptBalanceNote,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          TextButton.icon(
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(AppLocalizations.of(context).cptRecompute),
            onPressed: () => setState(() => _versionBilan++),
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