import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../settings_screen.dart'; // Pour accéder au controller de maintenance

class ExportCard extends ConsumerWidget {
  final String entrepriseId;
  const ExportCard({super.key, required this.entrepriseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.table_chart, color: Colors.teal),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Exportation des données',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                label: const Text('Exporter le stock vers Excel'),
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