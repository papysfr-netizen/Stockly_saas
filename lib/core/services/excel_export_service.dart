// lib/services/excel_export_service.dart
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stockly_saas/features/accounting/models/journal_entry.dart';
import 'accounting_report_service.dart';

class ExcelExportService {
  /// Génère un classeur Excel complet (Journal + Balance) et ouvre le menu de partage
  static Future<void> exportAndShareExcel({
    required List<JournalEntry> entries,
    required List<AccountBalance> balances,
  }) async {
    final excel = Excel.createExcel();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    // 1. Onglet Journal
    final Sheet journalSheet = excel['Journal Comptable'];
    excel.setDefaultSheet('Journal Comptable');

    journalSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Référence'),
      TextCellValue('Libellé'),
      TextCellValue('Code Compte'),
      TextCellValue('Intitulé Compte'),
      TextCellValue('Débit'),
      TextCellValue('Crédit'),
    ]);

    for (var entry in entries) {
      for (var line in entry.lines) {
        journalSheet.appendRow([
          TextCellValue(dateFormat.format(entry.date)),
          TextCellValue(entry.reference),
          TextCellValue(entry.description),
          TextCellValue(line.accountCode),
          TextCellValue(line.accountLabel),
          DoubleCellValue(line.debit),
          DoubleCellValue(line.credit),
        ]);
      }
    }

    // 2. Onglet Balance
    final Sheet balanceSheet = excel['Balance des Comptes'];
    balanceSheet.appendRow([
      TextCellValue('Compte'),
      TextCellValue('Intitulé'),
      TextCellValue('Total Débit'),
      TextCellValue('Total Crédit'),
      TextCellValue('Solde Débiteur'),
      TextCellValue('Solde Créditeur'),
    ]);

    for (var b in balances) {
      final net = b.netBalance;
      balanceSheet.appendRow([
        TextCellValue(b.accountCode),
        TextCellValue(b.accountLabel),
        DoubleCellValue(b.totalDebit),
        DoubleCellValue(b.totalCredit),
        DoubleCellValue(net > 0 ? net : 0.0),
        DoubleCellValue(net < 0 ? net.abs() : 0.0),
      ]);
    }

    // Supprimer l'onglet par défaut créé par le package s'il est différent
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // 3. Sauvegarde et partage
    final fileBytes = excel.encode();
    if (fileBytes == null) return;

    final directory = await getTemporaryDirectory();
    final fileName = 'Rapport_Comptable_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(fileBytes);

    final xFile = XFile(filePath);
    await Share.shareXFiles(
      [xFile],
      text: 'Rapport Comptable Excel (Journal & Balance)',
      subject: 'Export Comptabilité Excel',
    );
  }
}