import 'dart:io';
import 'package:excel/excel.dart' as excel_lib;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ReportExportService {
  /// Exporte et partage un rapport au format Excel (.xlsx)
  static Future<File> exporterExcel({
    required String titreRapport,
    required List<String> enTetes,
    required List<List<dynamic>> lignes,
    bool partagerApresExport = true,
  }) async {
    final excel = excel_lib.Excel.createExcel();

    // Configuration de la feuille
    final String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'Rapport');
    final excel_lib.Sheet sheetObject = excel['Rapport'];

    // Style de l'en-tête
    final excel_lib.CellStyle headerStyle = excel_lib.CellStyle(
      bold: true,
      textWrapping: excel_lib.TextWrapping.WrapText,
    );

    // 1. Ajout des en-têtes
    sheetObject.appendRow(
      enTetes.map((e) => excel_lib.TextCellValue(e.toString())).toList(),
    );

    for (int col = 0; col < enTetes.length; col++) {
      final cell = sheetObject.cell(
        excel_lib.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
      cell.cellStyle = headerStyle;
    }

    // 2. Ajout des données avec détection dynamique du type de cellule
    for (final ligne in lignes) {
      final List<excel_lib.CellValue> rowData = ligne.map((valeur) {
        if (valeur == null) return excel_lib.TextCellValue('');
        if (valeur is int) return excel_lib.IntCellValue(valeur);
        if (valeur is double) return excel_lib.DoubleCellValue(valeur);
        if (valeur is bool) return excel_lib.BoolCellValue(valeur);
        return excel_lib.TextCellValue(valeur.toString());
      }).toList();

      sheetObject.appendRow(rowData);
    }

    // 3. Enregistrement et écriture
    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception("Erreur d'encodage du fichier Excel.");
    }

    final directory = await getTemporaryDirectory();
    final nomSanitise = titreRapport.replaceAll(RegExp(r'[^\w\s]+'), '_');
    final filePath = "${directory.path}/$nomSanitise.xlsx";

    final file = File(filePath);
    await file.writeAsBytes(bytes);

    // 4. Partage
    if (partagerApresExport) {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: titreRapport,
        text: 'Veuillez trouver ci-joint le rapport : $titreRapport',
      );
    }

    return file;
  }

  /// Exporte et imprime un rapport au format PDF (A4 Portrait ou Paysage)
  static Future<void> exporterPDF({
    required String titreRapport,
    required List<String> enTetes,
    required List<List<dynamic>> lignes,
    String nomBoutique = "Stockly Pro",
    bool modePaysage = false,
  }) async {
    final pdf = pw.Document();

    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final dateGenere = DateTime.now();
    final dateStr =
        "${dateGenere.day.toString().padLeft(2, '0')}/${dateGenere.month.toString().padLeft(2, '0')}/${dateGenere.year} à ${dateGenere.hour.toString().padLeft(2, '0')}h${dateGenere.minute.toString().padLeft(2, '0')}";

    final pageFormat = modePaysage ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        nomBoutique,
                        style:const pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        titreRapport,
                        style:const pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    "Généré le : $dateStr",
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(color: PdfColors.blue900, thickness: 1.5),
              pw.SizedBox(height: 8),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "Document généré par $nomBoutique",
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
              pw.Text(
                "Page ${context.pageNumber} / ${context.pagesCount}",
                style:const pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            pw.TableHelper.fromTextArray(
              headers: enTetes,
              data: lignes
                  .map((row) => row.map((e) => e?.toString() ?? '').toList())
                  .toList(),
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
              headerStyle:const pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${titreRapport.replaceAll(' ', '_')}.pdf',
    );
  }
}