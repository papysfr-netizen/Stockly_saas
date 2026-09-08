// lib/utils/csv_export_helper.dart

import 'package:intl/intl.dart';
import '../models/journal_entry.dart';

class CsvExportHelper {
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  /// Convertit une liste d'écritures comptables en format CSV compatible SYSCOHADA / Excel
  static String exportJournalToCsv(List<JournalEntry> entries) {
    final buffer = StringBuffer();

    // En-têtes du fichier CSV (séparateur point-virgule pour Excel FR)
    buffer.writeln(
      'Date;Code Journal;N° Pièce / Réf;Compte;Intitulé Compte;Libellé Opération;Débit (FCFA);Crédit (FCFA)',
    );

    for (final entry in entries) {
      final formattedDate = _dateFormat.format(entry.date);
      final journal = _cleanCsvField(entry.journalCode);
      final reference = _cleanCsvField(entry.reference);
      final description = _cleanCsvField(entry.description);

      for (final line in entry.lines) {
        final accountCode = _cleanCsvField(line.accountCode);
        final accountLabel = _cleanCsvField(line.accountLabel);
        final debit = line.debit > 0 ? line.debit.toStringAsFixed(2).replaceAll('.', ',') : '0,00';
        final credit = line.credit > 0 ? line.credit.toStringAsFixed(2).replaceAll('.', ',') : '0,00';

        buffer.writeln(
          '$formattedDate;$journal;$reference;$accountCode;$accountLabel;$description;$debit;$credit',
        );
      }
    }

    return buffer.toString();
  }

  /// Échappe les guillemets et prévient les injections/erreurs de découpage CSV
  static String _cleanCsvField(String field) {
    if (field.contains(';') || field.contains('"') || field.contains('\n')) {
      final escaped = field.replaceAll('"', '""');
      return '"$escaped"';
    }
    return field;
  }
}