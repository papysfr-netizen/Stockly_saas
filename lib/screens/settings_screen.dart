import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/currency_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/settings_provider.dart' hide currencyProvider;
import '../providers/user_role_provider.dart';
import '../services/excel_service.dart';
import 'gestion_equipe_screen.dart';

// ============================================================================
// 1. CONTROLLER & SERVICES DE MAINTENANCE (ISOLATION MULTI-TENANT)
// ============================================================================

final settingsMaintenanceControllerProvider =
    AsyncNotifierProvider.family<SettingsMaintenanceController, void, String>(
  SettingsMaintenanceController.new,
);

class SettingsMaintenanceController extends FamilyAsyncNotifier<void, String> {
  @override
  Future<void> build(String arg) async {}

  /// Exportation du stock depuis la sous-collection isolée de l'organisation
  Future<void> exportStockToExcel() async {
    final entrepriseId = arg;
    if (entrepriseId.isEmpty) return;

    state = const AsyncValue.loading();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(entrepriseId)
          .collection('produits')
          .get();

      final produitsList = snapshot.docs.map((doc) => doc.data()).toList();
      await ExcelService.exporterStockVersExcel(produitsList);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Nettoyage et fusion des doublons dans la sous-collection de l'organisation
  Future<void> nettoyerDoublonsFirestore() async {
    final entrepriseId = arg;
    if (entrepriseId.isEmpty) return;

    state = const AsyncValue.loading();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(entrepriseId)
          .collection('produits')
          .get();

      final Map<String, QueryDocumentSnapshot> produitsUniques = {};
      final Map<DocumentReference, int> qteAJoindre = {};
      final List<DocumentReference> docsADelete = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String nom = (data['nom'] ?? '').toString().trim().toLowerCase();

        if (produitsUniques.containsKey(nom)) {
          final premierDoc = produitsUniques[nom]!;
          final premierData = premierDoc.data() as Map<String, dynamic>;
          final int ancienneQte =
              qteAJoindre[premierDoc.reference] ?? (premierData['quantite'] ?? 0);
          final int nouvelleQte = data['quantite'] ?? 0;

          qteAJoindre[premierDoc.reference] = ancienneQte + nouvelleQte;
          docsADelete.add(doc.reference);
        } else {
          produitsUniques[nom] = doc;
        }
      }

      var batch = FirebaseFirestore.instance.batch();
      int opCount = 0;

      qteAJoindre.forEach((docRef, totalQte) {
        batch.update(docRef, {'quantite': totalQte});
        opCount++;
        if (opCount % 400 == 0) {
          batch.commit();
          batch = FirebaseFirestore.instance.batch();
        }
      });

      for (var docRef in docsADelete) {
        batch.delete(docRef);
        opCount++;
        if (opCount % 400 == 0) {
          batch.commit();
          batch = FirebaseFirestore.instance.batch();
        }
      }

      if (opCount % 400 != 0) {
        await batch.commit();
      }

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Suppression complète des produits de la sous-collection de l'organisation
  Future<void> viderStock() async {
    final entrepriseId = arg;
    if (entrepriseId.isEmpty) return;

    state = const AsyncValue.loading();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(entrepriseId)
          .collection('produits')
          .get();

      const int batchSize = 450;
      for (var i = 0; i < snapshot.docs.length; i += batchSize) {
        final batch = FirebaseFirestore.instance.batch();
        final end = (i + batchSize < snapshot.docs.length) ? i + batchSize : snapshot.docs.length;

        for (var j = i; j < end; j++) {
          batch.delete(snapshot.docs[j].reference);
        }
        await batch.commit();
      }

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

// ============================================================================
// 2. ÉCRAN DES PARAMÈTRES (PRESENTATION LAYER)
// ============================================================================

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final entrepriseId = userProfile?.entrepriseId ?? '';
    final controllerState = ref.watch(settingsMaintenanceControllerProvider(entrepriseId));

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('settings'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const _InfoCard(),
              const SizedBox(height: 16),
              if (userProfile?.role.isOwner == true) ...[
                const _TeamCard(),
                const SizedBox(height: 16),
              ],
              const _CurrencyCard(),
              const SizedBox(height: 16),
              const _LanguageCard(),
              const SizedBox(height: 16),
              _ExportCard(entrepriseId: entrepriseId),
              const SizedBox(height: 16),
              _MaintenanceCard(entrepriseId: entrepriseId),
              const SizedBox(height: 20),
            ],
          ),
          if (controllerState.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// INFORMATIONS GÉNÉRALES DU MAGASIN
// -----------------------------------------------------------------------------

class _InfoCard extends ConsumerStatefulWidget {
  const _InfoCard();

  @override
  ConsumerState<_InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends ConsumerState<_InfoCard> {
  late final TextEditingController nomController;
  late final TextEditingController adresseController;
  late final TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    nomController = TextEditingController(text: settings.nomBoutique);
    adresseController = TextEditingController(text: settings.adresse);
    phoneController = TextEditingController(text: settings.telephone);
  }

  @override
  void dispose() {
    nomController.dispose();
    adresseController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);

    ref.listen(settingsProvider, (_, next) {
      if (nomController.text != next.nomBoutique) nomController.text = next.nomBoutique;
      if (adresseController.text != next.adresse) adresseController.text = next.adresse;
      if (phoneController.text != next.telephone) phoneController.text = next.telephone;
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.store, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr('store_info'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nomController,
              decoration: InputDecoration(
                labelText: tr('store_name'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.storefront),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: adresseController,
              decoration: InputDecoration(
                labelText: tr('address'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: tr('phone'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: FittedBox(fit: BoxFit.scaleDown, child: Text(tr('save_info'))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ref.read(settingsProvider.notifier).updateSettings(
                        nom: nomController.text,
                        adresse: adresseController.text,
                        phone: phoneController.text,
                        currency: ref.read(currencyProvider).activeCurrency,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Paramètres enregistrés avec succès !'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// GESTION DE L'ÉQUIPE
// -----------------------------------------------------------------------------

class _TeamCard extends StatelessWidget {
  const _TeamCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.people, color: Colors.white),
        ),
        title: const Text(
          'Gestion de l\'Équipe & Permissions',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: const Text('Ajouter des collaborateurs et gérer leurs droits'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GestionEquipeScreen()),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAUX BCC & DEVISE
// -----------------------------------------------------------------------------

class _CurrencyCard extends ConsumerWidget {
  const _CurrencyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final currencyState = ref.watch(currencyProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr('bcc_section'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: currencyState.bccCdfRate.toStringAsFixed(0),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: tr('bcc_rate'),
                prefixIcon: const Icon(Icons.currency_exchange),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) {
                final double? newRate = double.tryParse(val);
                if (newRate != null && newRate > 0) {
                  ref.read(currencyProvider.notifier).updateBccRate(newRate);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: currencyState.activeCurrency,
              decoration: InputDecoration(
                labelText: tr('active_currency'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: currencyState.currencies.values.map((curr) {
                return DropdownMenuItem<String>(
                  value: curr.code,
                  child: Text(
                    '${curr.code} (${curr.symbol}) - ${curr.name}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(currencyProvider.notifier).setCurrency(val);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// LANGUE DE L'APPLICATION
// -----------------------------------------------------------------------------

class _LanguageCard extends ConsumerWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final currentLocale = ref.watch(localeProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.language, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr('app_language'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: currentLocale.languageCode,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: LocaleNotifier.supportedLanguages.map((lang) {
                return DropdownMenuItem<String>(
                  value: lang.code,
                  child: Row(
                    children: [
                      Text(lang.flag, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Flexible(child: Text(lang.name, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 6),
                      Text(
                        '(${lang.category})',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (code) {
                if (code != null) {
                  ref.read(localeProvider.notifier).setLanguage(code);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// EXPORTATION DES DONNÉES
// -----------------------------------------------------------------------------

class _ExportCard extends ConsumerWidget {
  final String entrepriseId;
  const _ExportCard({required this.entrepriseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.table_chart, color: Colors.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr('reports_export'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.file_download),
                label: FittedBox(fit: BoxFit.scaleDown, child: Text(tr('export_excel'))),
                onPressed: entrepriseId.isEmpty
                    ? null
                    : () async {
                        try {
                          await ref
                              .read(settingsMaintenanceControllerProvider(entrepriseId).notifier)
                              .exportStockToExcel();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Exportation Excel terminée avec succès !"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Erreur d'exportation : $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MAINTENANCE ET NETTOYAGE
// -----------------------------------------------------------------------------

class _MaintenanceCard extends ConsumerWidget {
  final String entrepriseId;
  const _MaintenanceCard({required this.entrepriseId});

  void _confirmerEtNettoyerDoublons(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Attention'),
        content: const Text(
          'Voulez-vous vraiment fusionner les produits en double ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(settingsMaintenanceControllerProvider(entrepriseId).notifier)
                    .nettoyerDoublonsFirestore();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nettoyage des doublons terminé avec succès !'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmerEtViderStock(BuildContext context, WidgetRef ref) async {
    final bool? confirmer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attention - Vider le stock'),
        content: const Text(
          'Voulez-vous vraiment supprimer TOUS les produits de votre entreprise ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tout supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmer == true) {
      try {
        await ref
            .read(settingsMaintenanceControllerProvider(entrepriseId).notifier)
            .viderStock();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Le stock a été entièrement vidé avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du nettoyage : $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cleaning_services, color: Colors.redAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr('db_maintenance'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.merge_type),
                label: FittedBox(fit: BoxFit.scaleDown, child: Text(tr('merge_duplicates'))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: entrepriseId.isEmpty
                    ? null
                    : () => _confirmerEtNettoyerDoublons(context, ref),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: FittedBox(fit: BoxFit.scaleDown, child: Text(tr('clear_stock'))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: entrepriseId.isEmpty ? null : () => _confirmerEtViderStock(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}