import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/currency_provider.dart';
import '../providers/user_role_provider.dart';
import '../services/compta_service.dart';
import '../services/report_export_service.dart';

enum TypeDette { client, fournisseur }

// ============================================================================
// 1. PROVIDERS & CONTROLLER (ISOLATION MULTI-TENANT & LOGIQUE MÉTIER)
// ============================================================================

/// Flux temps réel des dettes/créances isolées par organisation
final dettesStreamProvider =
    StreamProvider.family<List<QueryDocumentSnapshot>, String>((ref, entrepriseId) {
  if (entrepriseId.isEmpty) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('organizations')
      .doc(entrepriseId)
      .collection('dettes')
      .orderBy('dateCreation', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs);
});

/// Controller gérant les mutations de dettes et l'écriture comptable
final debtControllerProvider =
    AsyncNotifierProvider.family<DebtController, void, String>(
  DebtController.new,
);

class DebtController extends FamilyAsyncNotifier<void, String> {
  @override
  Future<void> build(String arg) async {}

  /// Ajoute une nouvelle dette/créance et génère l'écriture d'acompte si applicable
  Future<void> ajouterDette({
    required String nomTiers,
    required String numeroFacture,
    required double montantTotal,
    required double acompte,
    required TypeDette type,
    required String note,
    required DateTime? dateEcheance,
  }) async {
    final entrepriseId = arg;
    if (entrepriseId.isEmpty) return;

    state = const AsyncValue.loading();
    try {
      final db = FirebaseFirestore.instance;
      final orgRef = db.collection('organizations').doc(entrepriseId);
      final detteRef = orgRef.collection('dettes').doc();
      final now = DateTime.now();

      final double montantReste = (montantTotal - acompte) < 0 ? 0.0 : (montantTotal - acompte);
      String statutInitial = 'non_paye';
      if (montantReste == 0) {
        statutInitial = 'paye';
      } else if (acompte > 0) {
        statutInitial = 'partiel';
      }

      final batch = db.batch();

      batch.set(detteRef, {
        'id': detteRef.id,
        'nomTiers': nomTiers,
        'numeroFacture': numeroFacture,
        'montantInitial': montantTotal,
        'acomptePaye': acompte,
        'montantReste': montantReste,
        'type': type.name,
        'statut': statutInitial,
        'note': note,
        'dateCreation': FieldValue.serverTimestamp(),
        'dateEcheance': dateEcheance != null ? Timestamp.fromDate(dateEcheance) : null,
        'entrepriseId': entrepriseId,
      });

      if (acompte > 0) {
        if (type == TypeDette.client) {
          ComptaService.ajouterEcritureDansBatch(
            batch: batch,
            entrepriseId: entrepriseId,
            libelle: 'Acompte créance - Client : $nomTiers',
            compteDebit: '531000',
            compteCredit: '411000',
            montant: acompte,
            date: now,
          );
        } else {
          ComptaService.ajouterEcritureDansBatch(
            batch: batch,
            entrepriseId: entrepriseId,
            libelle: 'Acompte dette - Fournisseur : $nomTiers',
            compteDebit: '401000',
            compteCredit: '531000',
            montant: acompte,
            date: now,
          );
        }
      }

      await batch.commit();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Enregistre un règlement partiel ou total et synchronise la comptabilité
  Future<void> enregistrerPaiement({
    required DocumentSnapshot doc,
    required double montantPaye,
  }) async {
    final entrepriseId = arg;
    if (entrepriseId.isEmpty) return;

    state = const AsyncValue.loading();
    try {
      final data = doc.data() as Map<String, dynamic>;
      final double resteActuel = ((data['montantReste'] ?? 0.0) as num).toDouble();
      final String nomTiers = data['nomTiers'] ?? data['nom'] ?? 'Inconnu';
      final String typeStr = (data['type'] ?? 'client').toString().toLowerCase();

      final double nouveauReste = (resteActuel - montantPaye) < 0 ? 0.0 : (resteActuel - montantPaye);
      final String nouveauStatut = nouveauReste == 0 ? 'paye' : 'partiel';
      final double acompteCumule = ((data['acomptePaye'] ?? 0.0) as num).toDouble() + montantPaye;
      final datePaiement = DateTime.now();

      final batch = FirebaseFirestore.instance.batch();

      batch.update(doc.reference, {
        'montantReste': nouveauReste,
        'acomptePaye': acompteCumule,
        'statut': nouveauStatut,
        'dernierPaiement': FieldValue.serverTimestamp(),
      });

      if (typeStr == 'client') {
        ComptaService.ajouterEcritureDansBatch(
          batch: batch,
          entrepriseId: entrepriseId,
          libelle: 'Règlement créance - Client : $nomTiers',
          compteDebit: '531000',
          compteCredit: '411000',
          montant: montantPaye,
          date: datePaiement,
        );
      } else {
        ComptaService.ajouterEcritureDansBatch(
          batch: batch,
          entrepriseId: entrepriseId,
          libelle: 'Règlement dette - Fournisseur : $nomTiers',
          compteDebit: '401000',
          compteCredit: '531000',
          montant: montantPaye,
          date: datePaiement,
        );
      }

      await batch.commit();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

// ============================================================================
// 2. ÉCRAN PRINCIPAL (PRESENTATION LAYER)
// ============================================================================

class DebtManagementScreen extends ConsumerWidget {
  const DebtManagementScreen({super.key});

  String _formaterDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  void _afficherDialogueAjoutDette(BuildContext context, WidgetRef ref, String entrepriseId, TypeDette type) {
    final nomController = TextEditingController();
    final factureController = TextEditingController();
    final montantTotalController = TextEditingController();
    final acompteController = TextEditingController();
    final noteController = TextEditingController();
    DateTime? dateEcheanceSelectionnee;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(
              type == TypeDette.client ? 'Nouvelle Créance Client' : 'Nouvelle Dette Fournisseur',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomController,
                    decoration: InputDecoration(
                      labelText: type == TypeDette.client ? 'Nom du Client *' : 'Nom du Fournisseur *',
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: factureController,
                    decoration: const InputDecoration(
                      labelText: 'N° Facture / Référence',
                      prefixIcon: Icon(Icons.receipt_long),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: montantTotalController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Montant Total *',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: acompteController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Acompte Versé (Si crédit partiel)',
                      prefixIcon: Icon(Icons.payments),
                      hintText: '0.0',
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: dialogContext,
                        initialDate: DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (pickedDate != null) {
                        setDialogState(() {
                          dateEcheanceSelectionnee = pickedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.indigo),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              dateEcheanceSelectionnee == null
                                  ? "Sélectionner une date d'échéance"
                                  : "Échéance : ${_formaterDate(dateEcheanceSelectionnee!)}",
                              style: TextStyle(
                                color: dateEcheanceSelectionnee == null ? Colors.grey.shade600 : Colors.black,
                                fontWeight: dateEcheanceSelectionnee != null ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note / Description (Optionnel)',
                      prefixIcon: Icon(Icons.note),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: type == TypeDette.client ? Colors.orange.shade800 : Colors.red.shade800,
                ),
                onPressed: () async {
                  final nom = nomController.text.trim();
                  final montantTotal = double.tryParse(montantTotalController.text.trim()) ?? 0.0;
                  final acompte = double.tryParse(acompteController.text.trim()) ?? 0.0;

                  if (nom.isNotEmpty && montantTotal > 0) {
                    final navigator = Navigator.of(dialogContext);
                    await ref
                        .read(debtControllerProvider(entrepriseId).notifier)
                        .ajouterDette(
                          nomTiers: nom,
                          numeroFacture: factureController.text.trim(),
                          montantTotal: montantTotal,
                          acompte: acompte,
                          type: type,
                          note: noteController.text.trim(),
                          dateEcheance: dateEcheanceSelectionnee,
                        );
                    navigator.pop();
                  }
                },
                child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _afficherDialoguePaiement(
      BuildContext context, WidgetRef ref, String entrepriseId, DocumentSnapshot doc, String currency) {
    final data = doc.data() as Map<String, dynamic>;
    final double resteActuel = ((data['montantReste'] ?? 0.0) as num).toDouble();
    final String nomTiers = data['nomTiers'] ?? data['nom'] ?? 'Inconnu';
    final montantPaiementController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Règlement : $nomTiers'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['numeroFacture'] != null && (data['numeroFacture'] as String).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Facture N° : ${data['numeroFacture']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
              ),
            Text('Reste à payer actuel : ${resteActuel.toStringAsFixed(2)} $currency'),
            const SizedBox(height: 12),
            TextField(
              controller: montantPaiementController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Montant du Règlement',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
            onPressed: () async {
              final paye = double.tryParse(montantPaiementController.text.trim()) ?? 0.0;
              if (paye > 0) {
                final navigator = Navigator.of(dialogContext);
                await ref
                    .read(debtControllerProvider(entrepriseId).notifier)
                    .enregistrerPaiement(doc: doc, montantPaye: paye);
                navigator.pop();
              }
            },
            child: const Text('Valider le Règlement', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _exporterRapport({
    required String format,
    required List<QueryDocumentSnapshot> docs,
    required bool isClientTab,
    required String currency,
  }) async {
    final currentTypeLabel = isClientTab ? 'Creances_Clients' : 'Dettes_Fournisseurs';
    final titreDoc = isClientTab ? 'Rapport des Créances Clients' : 'Rapport des Dettes Fournisseurs';

    final listeFiltree = docs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      final typeStr = (data['type'] ?? '').toString().toLowerCase();
      return typeStr == (isClientTab ? 'client' : 'fournisseur');
    }).toList();

    final enTetes = ['Tiers / Nom', 'N° Facture', 'Total Initial', 'Acompte', 'Reste à Payer', 'Statut', 'Échéance'];
    final lignes = listeFiltree.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final double initial = ((data['montantInitial'] ?? 0.0) as num).toDouble();
      final double acompte = ((data['acomptePaye'] ?? 0.0) as num).toDouble();
      final double reste = ((data['montantReste'] ?? 0.0) as num).toDouble();
      final String statutStr = data['statut'] == 'paye'
          ? 'Soldé'
          : (data['statut'] == 'partiel' ? 'Partiel' : 'Non Payé');

      String echeanceStr = '-';
      if (data['dateEcheance'] != null && data['dateEcheance'] is Timestamp) {
        echeanceStr = _formaterDate((data['dateEcheance'] as Timestamp).toDate());
      }

      return [
        data['nomTiers'] ?? data['nom'] ?? 'Inconnu',
        data['numeroFacture'] ?? '',
        '${initial.toStringAsFixed(2)} $currency',
        '${acompte.toStringAsFixed(2)} $currency',
        '${reste.toStringAsFixed(2)} $currency',
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
              title: const Text('Gestion des Dettes', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.indigo.shade800,
              foregroundColor: Colors.white,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  tooltip: 'Exporter',
                  onSelected: (value) {
                    final docs = dettesAsync.value ?? [];
                    final isClientTab = DefaultTabController.of(context).index == 0;
                    _exporterRapport(
                      format: value,
                      docs: docs,
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
                  Tab(icon: Icon(Icons.call_received), text: 'Clients (Créances)'),
                  Tab(icon: Icon(Icons.call_made), text: 'Fournisseurs (Dettes)'),
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
                      child: Text('Erreur de chargement : $err', style: const TextStyle(color: Colors.red)),
                    ),
                  ),
                  data: (docs) {
                    final creancesClients = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return (data['type'] ?? '').toString().toLowerCase() == 'client';
                    }).toList();

                    final dettesFournisseurs = docs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return (data['type'] ?? '').toString().toLowerCase() == 'fournisseur';
                    }).toList();

                    return TabBarView(
                      children: [
                        _buildVueDetteList(
                          context: context,
                          ref: ref,
                          entrepriseId: entrepriseId,
                          liste: creancesClients,
                          type: TypeDette.client,
                          currency: currency,
                        ),
                        _buildVueDetteList(
                          context: context,
                          ref: ref,
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
              backgroundColor: Colors.indigo.shade800,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Ajouter une dette', style: TextStyle(color: Colors.white)),
              onPressed: () {
                final isClient = DefaultTabController.of(context).index == 0;
                _afficherDialogueAjoutDette(
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

  Widget _buildVueDetteList({
    required BuildContext context,
    required WidgetRef ref,
    required String entrepriseId,
    required List<QueryDocumentSnapshot> liste,
    required TypeDette type,
    required String currency,
  }) {
    double totalDetteReste = 0.0;
    for (var doc in liste) {
      final data = doc.data() as Map<String, dynamic>;
      totalDetteReste += ((data['montantReste'] ?? 0.0) as num).toDouble();
    }

    final bool isClient = type == TypeDette.client;
    final Color couleurPrincipale = isClient ? Colors.orange.shade800 : Colors.red.shade800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: couleurPrincipale,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white24,
                    radius: 24,
                    child: Icon(
                      isClient ? Icons.arrow_downward : Icons.arrow_upward,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isClient ? 'Total À Recouvrer (Clients)' : 'Total À Payer (Fournisseurs)',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${totalDetteReste.toStringAsFixed(2)} $currency',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (liste.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                isClient ? 'Aucune créance client enregistrée.' : 'Aucune dette fournisseur enregistrée.',
                style: const TextStyle(color: Colors.grey),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: liste.length,
              itemBuilder: (context, index) {
                final doc = liste[index];
                final data = doc.data() as Map<String, dynamic>;

                final double montantReste = ((data['montantReste'] ?? 0.0) as num).toDouble();
                final double montantInitial = ((data['montantInitial'] ?? 0.0) as num).toDouble();
                final double acomptePaye = ((data['acomptePaye'] ?? 0.0) as num).toDouble();
                final String statut = data['statut'] ?? 'non_paye';
                final String? numFacture = data['numeroFacture'];

                DateTime? dateEcheance;
                bool estEnRetard = false;
                if (data['dateEcheance'] != null && data['dateEcheance'] is Timestamp) {
                  dateEcheance = (data['dateEcheance'] as Timestamp).toDate();
                  if (montantReste > 0 && dateEcheance.isBefore(DateTime.now())) {
                    estEnRetard = true;
                  }
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          data['nomTiers'] ?? data['nom'] ?? 'Inconnu',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (numFacture != null && numFacture.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Facture: $numFacture',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.indigo.shade900, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Total initial : ${montantInitial.toStringAsFixed(2)} $currency'),
                        if (acomptePaye > 0)
                          Text('Acompte versé : ${acomptePaye.toStringAsFixed(2)} $currency',
                              style: const TextStyle(color: Colors.blueGrey)),
                        if (dateEcheance != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Icon(Icons.event, size: 14, color: estEnRetard ? Colors.red : Colors.grey.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Échéance : ${_formaterDate(dateEcheance)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: estEnRetard ? FontWeight.bold : FontWeight.normal,
                                    color: estEnRetard ? Colors.red.shade700 : Colors.grey.shade800,
                                  ),
                                ),
                                if (estEnRetard) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                        color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                                    child: const Text('EN RETARD',
                                        style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        if (data['note'] != null && (data['note'] as String).isNotEmpty)
                          Text('Note : ${data['note']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${montantReste.toStringAsFixed(2)} $currency',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: montantReste > 0 ? Colors.red.shade700 : Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statut == 'paye'
                                ? Colors.green.shade100
                                : (statut == 'partiel' ? Colors.orange.shade100 : Colors.red.shade100),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statut == 'paye' ? 'Soldé' : (statut == 'partiel' ? 'Partiel' : 'Non Payé'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statut == 'paye'
                                  ? Colors.green.shade800
                                  : (statut == 'partiel' ? Colors.orange.shade800 : Colors.red.shade800),
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: montantReste > 0
                        ? () => _afficherDialoguePaiement(context, ref, entrepriseId, doc, currency)
                        : null,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}