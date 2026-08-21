import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/currency_provider.dart';

// ============================================================================
// HELPER : CONVERSION DE DATE SÉCURISÉE
// ============================================================================

/// Convertit n'importe quelle valeur de date (Timestamp, String ISO, DateTime) en DateTime
DateTime parseDate(dynamic dateValue) {
  if (dateValue is Timestamp) {
    return dateValue.toDate();
  } else if (dateValue is String) {
    return DateTime.tryParse(dateValue) ?? DateTime.now();
  } else if (dateValue is DateTime) {
    return dateValue;
  }
  return DateTime.now();
}

// ============================================================================
// 1. PROVIDERS & STREAMS (ISOLATION MULTI-TENANT)
// ============================================================================

/// Flux en temps réel des écritures comptables sous /organizations/{orgId}/ecritures_comptables
final ecrituresComptablesProvider =
    StreamProvider.family<List<QueryDocumentSnapshot>, String>((ref, entrepriseId) {
  if (entrepriseId.isEmpty) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('organizations')
      .doc(entrepriseId)
      .collection('ecritures_comptables')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs);
});

/// Controller pour les opérations d'écriture et de synchronisation comptable
final comptabiliteControllerProvider =
    AsyncNotifierProvider.family<ComptabiliteController, void, String>(
  ComptabiliteController.new,
);

class ComptabiliteController extends FamilyAsyncNotifier<void, String> {
  @override
  Future<void> build(String arg) async {
    // Initialisation
  }

  /// Synchronisation des ventes non comptabilisées dans le journal (SYSCOHADA)
  Future<int> synchroniserHistoriqueComptable() async {
    final entrepriseId = arg;
    if (entrepriseId.isEmpty) return 0;

    state = const AsyncValue.loading();

    try {
      final db = FirebaseFirestore.instance;
      final orgRef = db.collection('organizations').doc(entrepriseId);

      // Récupération des ventes non comptabilisées de l'organisation
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
        final String client = data['clientNom'] ?? data['nomClient'] ?? 'Client Divers';
        final double verse = (data['montantPaye'] as num?)?.toDouble() ?? 0.0;
        final double reste = (data['resteAPayer'] as num?)?.toDouble() ?? 0.0;
        final dynamic date = data['date'] ?? FieldValue.serverTimestamp();

        // Écriture Caisse (531000 Debit / 701000 Credit)
        if (verse > 0) {
          final refEcriture = orgRef.collection('ecritures_comptables').doc();
          batch.set(refEcriture, {
            'entrepriseId': entrepriseId,
            'libelle': 'Vente en caisse - $client',
            'compteDebit': '531000',
            'compteCredit': '701000',
            'montant': verse,
            'date': date,
            'pieceRef': doc.id,
          });
          operationCount++;
        }

        // Écriture Crédit Client (411000 Debit / 701000 Credit)
        if (reste > 0) {
          final refEcriture = orgRef.collection('ecritures_comptables').doc();
          batch.set(refEcriture, {
            'entrepriseId': entrepriseId,
            'libelle': 'Créance vente - Client : $client',
            'compteDebit': '411000',
            'compteCredit': '701000',
            'montant': reste,
            'date': date,
            'pieceRef': doc.id,
          });
          operationCount++;
        }

        // Marquer la vente comme comptabilisée dans la sous-collection
        batch.update(doc.reference, {'comptabilise': true});
        operationCount++;

        // Subdivisions de batch (limite Firestore de 500 opérations)
        if (operationCount >= 450) {
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
}

// ============================================================================
// 2. ÉCRAN DE COMPTABILITÉ (PRESENTATION LAYER)
// ============================================================================

class ComptabiliteScreen extends ConsumerWidget {
  final String entrepriseId;

  const ComptabiliteScreen({super.key, required this.entrepriseId});

  Future<void> _handleSync(BuildContext context, WidgetRef ref) async {
    try {
      final count = await ref
          .read(comptabiliteControllerProvider(entrepriseId).notifier)
          .synchroniserHistoriqueComptable();

      if (!context.mounted) return;

      final message = count > 0
          ? '$count ventes rattrapées avec succès !'
          : 'Toutes les ventes sont déjà comptabilisées.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la synchronisation : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ecrituresAsync = ref.watch(ecrituresComptablesProvider(entrepriseId));
    final controllerState = ref.watch(comptabiliteControllerProvider(entrepriseId));
    final currency = ref.watch(currencyProvider).activeCurrency;

    final isSyncing = controllerState.isLoading;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Comptabilité', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.teal.shade800,
          foregroundColor: Colors.white,
          actions: [
            isSyncing
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.sync),
                    tooltip: 'Synchroniser l\'historique',
                    onPressed: () => _handleSync(context, ref),
                  ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
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
          data: (docs) {
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu_book, size: 64, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'Aucune écriture comptable trouvée.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800),
                      onPressed: isSyncing ? null : () => _handleSync(context, ref),
                      icon: const Icon(Icons.sync, color: Colors.white),
                      label: const Text('Rattraper les ventes passées',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            }

            // Agrégation SYSCOHADA
            double totalCaisse = 0.0;     // Compte 531000
            double totalCreances = 0.0;   // Compte 411000
            double totalVentes = 0.0;     // Compte 701000
            double totalAchats = 0.0;     // Compte 601000

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final montant = ((data['montant'] ?? 0.0) as num).toDouble();
              final cDebit = data['compteDebit']?.toString() ?? '';
              final cCredit = data['compteCredit']?.toString() ?? '';

              if (cDebit.startsWith('531')) totalCaisse += montant;
              if (cCredit.startsWith('531')) totalCaisse -= montant;

              if (cDebit.startsWith('411')) totalCreances += montant;
              if (cCredit.startsWith('411')) totalCreances -= montant;

              if (cCredit.startsWith('701')) totalVentes += montant;
              if (cDebit.startsWith('601')) totalAchats += montant;
            }

            return TabBarView(
              children: [
                _buildJournalTab(docs, currency),
                _buildBilanTab(
                  caisse: totalCaisse,
                  creances: totalCreances,
                  ventes: totalVentes,
                  achats: totalAchats,
                  currency: currency,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildJournalTab(List<QueryDocumentSnapshot> docs, String currency) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final libelle = data['libelle'] ?? 'Écriture sans nom';
        final compteDebit = data['compteDebit'] ?? '531000';
        final compteCredit = data['compteCredit'] ?? '701000';
        final montant = ((data['montant'] ?? 0.0) as num).toDouble();

        // Utilisation sécurisée de parseDate() pour éviter les erreurs de type String/Timestamp
        final rawDate = data['date'];
        final DateTime date = parseDate(rawDate);
        final dateStr = rawDate != null
            ? "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}"
            : "";

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal.shade50,
              child: Icon(Icons.swap_horiz, color: Colors.teal.shade800, size: 20),
            ),
            title: Text(libelle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              'D: $compteDebit | C: $compteCredit${dateStr.isNotEmpty ? " • $dateStr" : ""}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            trailing: Text(
              "${montant.toStringAsFixed(2)} $currency",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900, fontSize: 14),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBilanTab({
    required double caisse,
    required double creances,
    required double ventes,
    required double achats,
    required String currency,
  }) {
    final double resultatNivel = ventes - achats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('Trésorerie (Caisse)', '${caisse.toStringAsFixed(2)} $currency', Colors.green.shade700),
                    Container(width: 1, height: 40, color: Colors.grey.shade300),
                    _buildStatColumn('Créances Clients', '${creances.toStringAsFixed(2)} $currency', Colors.orange.shade800),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('Chiffre d\'Affaires (Ventes)', '${ventes.toStringAsFixed(2)} $currency', Colors.blue.shade700),
                    Container(width: 1, height: 40, color: Colors.grey.shade300),
                    _buildStatColumn('Résultat Estimé', '${resultatNivel.toStringAsFixed(2)} $currency', resultatNivel >= 0 ? Colors.teal.shade800 : Colors.red.shade700),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
      ],
    );
  }
}