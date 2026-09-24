// lib/services/csv_export_service.dart

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stockly_saas/features/accounting/models/journal_entry.dart';
import '../utils/csv_export_helper.dart';

class CsvExportService {
  /// Génère le fichier CSV localement et ouvre le menu de partage Android/iOS/Desktop
  static Future<void> exportAndShareJournal(List<JournalEntry> entries) async {
    if (entries.isEmpty) return;

    // 1. Génération de la chaîne CSV
    final csvData = CsvExportHelper.exportJournalToCsv(entries);

    // 2. Obtention du répertoire temporaire
    final directory = await getTemporaryDirectory();
    final fileName = 'Journal_Comptable_${DateTime.now().millisecondsSinceEpoch}.csv';
    final path = '${directory.path}/$fileName';

    // 3. Écriture du fichier sur le disque (avec BOM UTF-8 pour la prise en charge des accents dans Excel)
    final file = File(path);
    await file.writeAsString('\uFEFF$csvData');

    // 4. Ouverture de la boîte de dialogue native de partage
    final xFile = XFile(path);
    await Share.shareXFiles(
      [xFile],
      text: 'Export du journal comptable SYSCOHADA',
      subject: 'Journal Comptable CSV',
    );
  }
}