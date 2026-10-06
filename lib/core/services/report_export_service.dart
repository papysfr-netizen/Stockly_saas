import 'dart:async';
import 'dart:io';
import 'package:excel/excel.dart' as excel_lib;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'boutique_info_service.dart';

// 📊 RAPPORTS EXCEL / PDF — version 2 (PDF sans internet, en-tête boutique, date)
class ReportExportService {
  static String _deux(int n) => n.toString().padLeft(2, '0');

  static String _dateTexte(DateTime d) =>
      '${_deux(d.day)}/${_deux(d.month)}/${d.year} à ${_deux(d.hour)}h${_deux(d.minute)}';

  static String _horodatage(DateTime d) =>
      '${d.year}-${_deux(d.month)}-${_deux(d.day)}_${_deux(d.hour)}h${_deux(d.minute)}';

  /// Nom de fichier propre : garde les accents, retire seulement les caractères interdits.
  static String _nomFichier(String titre) => titre
      .trim()
      .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
      .replaceAll(RegExp(r'\s+'), '_');

  /// Exporte et partage un rapport au format Excel (.xlsx)
  static Future<File> exporterExcel({
    required String titreRapport,
    required List<String> enTetes,
    required List<List<dynamic>> lignes,
    bool partagerApresExport = true,
  }) async {
    final excel = excel_lib.Excel.createExcel();
    final String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'Rapport');
    final excel_lib.Sheet feuille = excel['Rapport'];

    final gras = excel_lib.CellStyle(bold: true);
    final grasRetour = excel_lib.CellStyle(
      bold: true,
      textWrapping: excel_lib.TextWrapping.WrapText,
    );

    // 0. En-tête du document : boutique, titre, date
    final infos = await BoutiqueInfoService.charger();
    final nomBoutique = BoutiqueInfoService.choisir(infos?.nomBoutique, 'Stockly Pro');
    final maintenant = DateTime.now();

    feuille.appendRow([excel_lib.TextCellValue(nomBoutique)]);
    feuille.appendRow([excel_lib.TextCellValue(titreRapport)]);
    feuille.appendRow([excel_lib.TextCellValue('Généré le ${_dateTexte(maintenant)}')]);
    feuille.appendRow([excel_lib.TextCellValue('')]);
    feuille.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = gras;
    feuille.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).cellStyle = gras;

    // 1. Titres des colonnes (ligne 5)
    const ligneTitres = 4;
    feuille.appendRow(enTetes.map((e) => excel_lib.TextCellValue(e.toString())).toList());
    for (int col = 0; col < enTetes.length; col++) {
      feuille
          .cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: ligneTitres))
          .cellStyle = grasRetour;
      feuille.setColumnWidth(col, col == 0 ? 28 : 18);
    }

    // 2. Données (le type de chaque cellule est détecté)
    for (final ligne in lignes) {
      final List<excel_lib.CellValue> rowData = ligne.map((valeur) {
        if (valeur == null) return excel_lib.TextCellValue('');
        if (valeur is int) return excel_lib.IntCellValue(valeur);
        if (valeur is double) return excel_lib.DoubleCellValue(valeur);
        if (valeur is bool) return excel_lib.BoolCellValue(valeur);
        return excel_lib.TextCellValue(valeur.toString());
      }).toList();
      feuille.appendRow(rowData);
    }

    // 3. Enregistrement (date et heure dans le nom du fichier)
    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception("Erreur d'encodage du fichier Excel.");
    }

    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/${_nomFichier(titreRapport)}_${_horodatage(maintenant)}.xlsx';

    final file = File(filePath);
    await file.writeAsBytes(bytes);

    // 4. Partage
    if (partagerApresExport) {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: '$titreRapport - $nomBoutique',
        text: 'Veuillez trouver ci-joint le rapport : $titreRapport',
      );
    }

    return file;
  }

  /// Police du PDF : Roboto si internet répond vite, sinon la police intégrée.
  static Future<pw.ThemeData?> _themePdf() async {
    try {
      final regular = await PdfGoogleFonts.robotoRegular().timeout(const Duration(seconds: 6));
      final bold = await PdfGoogleFonts.robotoBold().timeout(const Duration(seconds: 6));
      return pw.ThemeData.withFont(base: regular, bold: bold);
    } catch (_) {
      return null; // police intégrée
    }
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
    final theme = await _themePdf();

    final infos = await BoutiqueInfoService.charger();
    final String nomFinal = BoutiqueInfoService.choisir(infos?.nomBoutique, nomBoutique);
    final List<String> coordonnees = [
      if ((infos?.adresse.trim() ?? '').isNotEmpty) infos!.adresse.trim(),
      if ((infos?.telephone.trim() ?? '').isNotEmpty) 'Tél : ${infos!.telephone.trim()}',
    ];

    final dateStr = _dateTexte(DateTime.now());
    final pageFormat = modePaysage ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(24),
        theme: theme,
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          nomFinal,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        if (coordonnees.isNotEmpty)
                          pw.Text(
                            coordonnees.join('  |  '),
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                          ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          titreRapport,
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Text(
                    'Généré le : $dateStr',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
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
                '$nomFinal - Généré avec Stockly Pro',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
              pw.Text(
                'Page ${context.pageNumber} / ${context.pagesCount}',
                style: pw.TextStyle(
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
              data: lignes.map((row) => row.map((e) => e?.toString() ?? '').toList()).toList(),
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
              headerStyle: pw.TextStyle(
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
      name: '${_nomFichier(titreRapport)}.pdf',
    );
  }
}