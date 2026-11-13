import 'dart:async';
import 'dart:io';
import 'package:excel/excel.dart' as excel_lib;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'boutique_info_service.dart';

// 📊 RAPPORTS EXCEL / PDF — version 3
//  - titres lisibles (les « _ » deviennent des espaces)
//  - les montants écrits en texte (« 1 800,00 », « 1800.00 USD ») deviennent
//    de VRAIS nombres dans Excel (on peut les additionner)
//  - dans le PDF, les colonnes de montants sont alignées à droite
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

  /// Titre affiché : « Analyse_Financiere_PL » -> « Analyse Financiere PL »
  static String _titreLisible(String titre) =>
      titre.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  // Montant écrit en texte : chiffres, espaces (milliers), une virgule ou un point
  // (décimales), un signe moins, et éventuellement une devise courte (USD, FC, $).
  static final RegExp _motifMontant = RegExp(
      r'^[-−]?\d[\d   ]*([.,]\d+)?( ?[A-Za-z$€]{1,4})?$');

  /// Convertit un texte de montant en nombre ; null si ce n'est pas un montant.
  /// Les codes avec zéro devant (« 0975… ») restent du texte (téléphones, codes).
  static double? _commeNombre(String texte) {
    final t = texte.trim();
    if (t.isEmpty || !_motifMontant.hasMatch(t)) return null;
    final sansSigne = t.replaceFirst(RegExp(r'^[-−]'), '');
    if (RegExp(r'^0\d').hasMatch(sansSigne)) return null;
    final chiffres = t
        .replaceAll(RegExp(r'[A-Za-z$€]'), '')
        .replaceAll(RegExp(r'[   ]'), '')
        .replaceAll('−', '-')
        .replaceAll(',', '.');
    return double.tryParse(chiffres);
  }

  static excel_lib.CellValue _cellule(dynamic valeur) {
    if (valeur == null) return excel_lib.TextCellValue('');
    if (valeur is int) return excel_lib.IntCellValue(valeur);
    if (valeur is double) return excel_lib.DoubleCellValue(valeur);
    if (valeur is num) return excel_lib.DoubleCellValue(valeur.toDouble());
    if (valeur is bool) return excel_lib.BoolCellValue(valeur);
    final texte = valeur.toString();
    final nombre = _commeNombre(texte);
    if (nombre != null) {
      return nombre == nombre.roundToDouble() && !texte.contains(RegExp(r'[.,]'))
          ? excel_lib.IntCellValue(nombre.toInt())
          : excel_lib.DoubleCellValue(nombre);
    }
    return excel_lib.TextCellValue(texte);
  }

  /// Exporte et partage un rapport au format Excel (.xlsx)
  static Future<File> exporterExcel({
    required String titreRapport,
    required List<String> enTetes,
    required List<List<dynamic>> lignes,
    bool partagerApresExport = true,
  }) async {
    final titre = _titreLisible(titreRapport);
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
    final nomBoutique = BoutiqueInfoService.choisir(infos?.nomBoutique, 'Nguli');
    final maintenant = DateTime.now();

    feuille.appendRow([excel_lib.TextCellValue(nomBoutique)]);
    feuille.appendRow([excel_lib.TextCellValue(titre)]);
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
      feuille.setColumnWidth(col, col == 0 ? 34 : 18);
    }

    // 2. Données (nombres reconnus, même écrits en texte)
    for (final ligne in lignes) {
      feuille.appendRow(ligne.map(_cellule).toList());
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
        subject: '$titre - $nomBoutique',
        text: 'Veuillez trouver ci-joint le rapport : $titre',
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
    String nomBoutique = "Nguli",
    bool modePaysage = false,
  }) async {
    final titre = _titreLisible(titreRapport);
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

    final donnees =
        lignes.map((row) => row.map((e) => e?.toString() ?? '').toList()).toList();

    // Colonnes de montants (toutes les valeurs remplies sont des nombres) : alignées à droite
    final Map<int, pw.Alignment> alignements = {};
    for (int col = 0; col < enTetes.length; col++) {
      var remplies = 0;
      var nombres = 0;
      for (final ligne in donnees) {
        if (col >= ligne.length || ligne[col].trim().isEmpty) continue;
        remplies++;
        if (_commeNombre(ligne[col]) != null) nombres++;
      }
      alignements[col] = (remplies > 0 && nombres == remplies)
          ? pw.Alignment.centerRight
          : pw.Alignment.centerLeft;
    }

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
                          titre,
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
                '$nomFinal - Généré avec Nguli',
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
              data: donnees,
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              headerAlignments: alignements,
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: alignements,
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
