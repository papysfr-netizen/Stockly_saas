import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/rattrapage_cout_service.dart';
import '../settings_screen.dart';

class MaintenanceCard extends ConsumerWidget {
  final String entrepriseId;
  const MaintenanceCard({super.key, required this.entrepriseId});

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

  // ================= RATTRAPAGE DU COÛT DES ANCIENNES VENTES =================

  Future<void> _rattraperCouts(BuildContext context) async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rattraper le coût des anciennes ventes'),
        content: const Text(
          'Les anciennes ventes qui n\'ont pas encore d\'écriture « Sortie de stock » '
          'vont en recevoir une, à leur date d\'origine.\n\n'
          'Le coût est calculé avec le prix d\'achat ACTUEL de chaque produit.\n\n'
          'Vous pouvez relancer cette opération sans risque : '
          'une vente n\'est jamais comptée deux fois.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lancer'),
          ),
        ],
      ),
    );
    if (confirmer != true || !context.mounted) return;

    final navigator = Navigator.of(context);

    // Fenêtre d'attente
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Rattrapage en cours…')),
          ],
        ),
      ),
    );

    String titre;
    String message;
    try {
      final r = await RattrapageCoutService.executer(entrepriseId);
      titre = r.ventesRattrapees == 0 ? 'Rien à rattraper' : 'Rattrapage terminé';
      message = r.ventesRattrapees == 0
          ? 'Toutes les ventes (${r.ventesAnalysees}) ont déjà leur écriture « Sortie de stock ».'
          : '${r.ventesRattrapees} vente(s) rattrapée(s) sur ${r.ventesAnalysees}.\n\n'
              'Coût des marchandises ajouté : ${r.coutTotal.toStringAsFixed(2)} \$';
      if (r.articlesSansPrix > 0) {
        message += '\n\n⚠️ ${r.articlesSansPrix} article(s) sans prix d\'achat : '
            'leur coût est compté à 0. Complétez leur prix d\'achat puis relancez.';
      }
      if (r.enAttenteReseau) {
        message += '\n\nEnregistré sur le téléphone : l\'envoi se fera au retour d\'internet.';
      }
    } catch (e) {
      titre = 'Erreur';
      message = 'Le rattrapage n\'a pas pu se faire : $e';
    }

    navigator.pop(); // ferme la fenêtre d'attente
    await Future.delayed(const Duration(milliseconds: 300));
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titre),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            const Row(
              children: [
                Icon(Icons.cleaning_services, color: Colors.redAccent),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Maintenance & Base de données',
                    style: TextStyle(
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
            // ---- NOUVEAU : rattrapage du coût des anciennes ventes ----
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.history_rounded),
                label: const Text('Rattraper le coût des anciennes ventes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: entrepriseId.isEmpty ? null : () => _rattraperCouts(context),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.merge_type),
                label: const Text('Fusionner les doublons'),
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
          ],
        ),
      ),
    );
  }
}