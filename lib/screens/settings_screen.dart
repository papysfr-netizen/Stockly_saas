import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockly_saas/features/boutiques/boutiques_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/user_role_provider.dart';
import '../core/services/excel_service.dart';
import '../l10n/app_localizations.dart';
import 'gestion_equipe_screen.dart';

// Importation des widgets modulaires
import 'settings_widgets/info_card.dart';
import 'settings_widgets/currency_card.dart';
import 'settings_widgets/language_card.dart';
import 'settings_widgets/export_card.dart';
import 'settings_widgets/maintenance_card.dart';

// ============================================================================
// CONTROLLER DE MAINTENANCE (ISOLATION MULTI-TENANT)
// ============================================================================

final settingsMaintenanceControllerProvider =
    AsyncNotifierProvider.family<SettingsMaintenanceController, void, String>(
  SettingsMaintenanceController.new,
);

class SettingsMaintenanceController extends FamilyAsyncNotifier<void, String> {
  @override
  Future<void> build(String arg) async {}

  Future<void> exportStockToExcel() async {
    final entrepriseId = arg;
    if (entrepriseId.isEmpty) return;

    state = const AsyncValue.loading();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('entreprises')
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

  // ⚠️ À REVOIR (tâche I) : fusionne les produits PAR NOM.
  // Deux articles différents portant le même nom seraient fusionnés
  // et l'un d'eux supprimé. À baser sur le code-barres avant usage.
  Future<void> nettoyerDoublonsFirestore() async {
    final entrepriseId = arg;
    if (entrepriseId.isEmpty) return;

    state = const AsyncValue.loading();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('entreprises')
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
          final int ancienneQte = qteAJoindre[premierDoc.reference] ??
              ((premierData['quantite'] ?? 0) as num).toInt();
          final int nouvelleQte = ((data['quantite'] ?? 0) as num).toInt();

          qteAJoindre[premierDoc.reference] = ancienneQte + nouvelleQte;
          docsADelete.add(doc.reference);
        } else {
          produitsUniques[nom] = doc;
        }
      }

      var batch = FirebaseFirestore.instance.batch();
      int opCount = 0;

      for (final entry in qteAJoindre.entries) {
        batch.update(entry.key, {'quantite': entry.value});
        opCount++;
        if (opCount >= 400) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          opCount = 0;
        }
      }

      for (var docRef in docsADelete) {
        batch.delete(docRef);
        opCount++;
        if (opCount >= 400) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          opCount = 0;
        }
      }

      if (opCount > 0) {
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
// ÉCRAN DES PARAMÈTRES PRINCIPAL
// ============================================================================

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final userProfile = ref.watch(userProfileProvider).value;
    final entrepriseId = userProfile?.entrepriseId ?? '';
    final controllerState =
        ref.watch(settingsMaintenanceControllerProvider(entrepriseId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.settings,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const InfoCard(),
              const SizedBox(height: 16),
              if (userProfile?.role.isOwner == true) ...[
                const _TeamCard(),
                const SizedBox(height: 16),
                MesBoutiquesCard(entrepriseId: entrepriseId),
                const SizedBox(height: 16),
              ],
              const CurrencyCard(),
              const SizedBox(height: 16),
              const LanguageCard(),
              const SizedBox(height: 16),
              ExportCard(entrepriseId: entrepriseId),
              const SizedBox(height: 16),
              if (userProfile?.peutMaintenance == true) ...[
                MaintenanceCard(entrepriseId: entrepriseId),
                const SizedBox(height: 20),
              ],
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

// Petit widget interne pour la gestion d'équipe
class _TeamCard extends StatelessWidget {
  const _TeamCard();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.people, color: Colors.white),
        ),
        title: Text(
          t.teamManagement,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(t.teamManagementSubtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const GestionEquipeScreen()),
          );
        },
      ),
    );
  }
}