import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/rattrapage_cout_service.dart';
import '../settings_screen.dart';
import '../../l10n/app_localizations.dart';

class MaintenanceCard extends ConsumerWidget {
  final String entrepriseId;
  const MaintenanceCard({super.key, required this.entrepriseId});

  void _confirmerEtNettoyerDoublons(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.attention),
        content: Text(t.mergeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
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
                    SnackBar(
                      content: Text(t.mergeDone),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t.errorPrefix('$e')), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(t.confirmBtn),
          ),
        ],
      ),
    );
  }

  // ================= RATTRAPAGE DU COÛT DES ANCIENNES VENTES =================

  Future<void> _rattraperCouts(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.backfillTitle),
        content: Text(t.backfillExplain),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.launch),
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
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(t.backfillRunning)),
          ],
        ),
      ),
    );

    String titre;
    String message;
    try {
      final r = await RattrapageCoutService.executer(entrepriseId);
      titre = r.ventesRattrapees == 0 ? t.backfillNothing : t.backfillDone;
      message = r.ventesRattrapees == 0
          ? t.backfillAllDone('${r.ventesAnalysees}')
          : t.backfillResult('${r.ventesRattrapees}', '${r.ventesAnalysees}', r.coutTotal.toStringAsFixed(2));
      if (r.articlesSansPrix > 0) {
        message += '\n\n${t.backfillNoPrice('${r.articlesSansPrix}')}';
      }
      if (r.enAttenteReseau) {
        message += '\n\n${t.backfillOffline}';
      }
    } catch (e) {
      titre = t.error;
      message = t.backfillFailed('$e');
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
    final t = AppLocalizations.of(context);
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
                    t.maintTitle,
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
            // ---- NOUVEAU : rattrapage du coût des anciennes ventes ----
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.history_rounded),
                label: Text(t.backfillTitle),
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
                label: Text(t.mergeDuplicates),
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