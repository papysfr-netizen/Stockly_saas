import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../settings_screen.dart'; // Pour accéder au controller de maintenance
import '../../l10n/app_localizations.dart';

class ExportCard extends ConsumerWidget {
  final String entrepriseId;
  const ExportCard({super.key, required this.entrepriseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
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
                    t.reportsExport,
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
                label: Text(t.exportExcel),
                onPressed: entrepriseId.isEmpty
                    ? null
                    : () async {
                        try {
                          await ref
                              .read(settingsMaintenanceControllerProvider(entrepriseId).notifier)
                              .exportStockToExcel();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(t.exportDone),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(t.exportError('$e')),
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