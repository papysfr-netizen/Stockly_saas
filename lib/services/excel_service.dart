import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/produit.dart';

class ExcelService {
  // ------------------------------------------------------------------
  // Helper : Extraction sécurisée des valeurs Excel (compatibilité v4+)
  // ------------------------------------------------------------------
  static String _extractString(dynamic cellValue) {
    if (cellValue == null) return '';
    dynamic val = cellValue;
    if (val is Data) val = val.value;
    if (val is CellValue) {
      val = (val as dynamic).value;
    }
    return val?.toString().trim() ?? '';
  }

  static int _extractInt(dynamic cellValue) {
    if (cellValue == null) return 0;
    dynamic raw = cellValue;
    if (raw is Data) raw = raw.value;
    if (raw is CellValue) raw = (raw as dynamic).value;

    if (raw is num) return raw.toInt();
    String str = raw.toString().trim();
    double? parsedDouble = double.tryParse(str.replaceAll(',', '.'));
    return parsedDouble?.toInt() ?? int.tryParse(str) ?? 0;
  }

  static double _extractDouble(dynamic cellValue) {
    if (cellValue == null) return 0.0;
    dynamic raw = cellValue;
    if (raw is Data) raw = raw.value;
    if (raw is CellValue) raw = (raw as dynamic).value;

    if (raw is num) return raw.toDouble();
    String str = raw.toString().trim().replaceAll(',', '.');
    return double.tryParse(str) ?? 0.0;
  }

  // ------------------------------------------------------------------
  // 1. Importer le catalogue (Excel .xlsx / .xls ou CSV .csv)
  // ------------------------------------------------------------------
  static List<Produit> importerStockDepuisExcel(
    List<int> bytes,
    String entrepriseId, {
    bool isCsv = false,
  }) {
    if (isCsv) {
      return _importerDepuisCsv(bytes, entrepriseId);
    }

    var excel = Excel.decodeBytes(bytes);
    List<Produit> produits = [];

    if (excel.tables.isEmpty) return produits;

    var sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null || sheet.maxRows == 0) return produits;

    int idxCode = 0, idxNom = 1, idxQte = 2, idxPA = 3, idxPV = 4;
    var headerRow = sheet.rows.first;
    bool hasHeader = false;

    // Détection dynamique des colonnes par leurs intitulés
    for (int col = 0; col < headerRow.length; col++) {
      String val = _extractString(headerRow[col]).toLowerCase();
      if (val.contains('code') || val.contains('ref') || val.contains('barcode')) {
        idxCode = col;
        hasHeader = true;
      } else if (val.contains('nom') || val.contains('desig') || val.contains('produit') || val.contains('article')) {
        idxNom = col;
        hasHeader = true;
      } else if (val.contains('qte') || val.contains('quantit') || val.contains('stock')) {
        idxQte = col;
        hasHeader = true;
      } else if (val == 'pa' || val.contains('achat') || val.contains('cout')) {
        idxPA = col;
        hasHeader = true;
      } else if (val == 'pv' || val.contains('vente') || val.contains('prix')) {
        idxPV = col;
        hasHeader = true;
      }
    }

    int startRow = hasHeader ? 1 : 0;

    for (int i = startRow; i < sheet.maxRows; i++) {
      var row = sheet.rows[i];
      if (row.isEmpty) continue;

      String codeBarre = idxCode < row.length ? _extractString(row[idxCode]) : '';
      String nom = idxNom < row.length ? _extractString(row[idxNom]) : '';
      int quantite = idxQte < row.length ? _extractInt(row[idxQte]) : 0;
      double prixAchat = idxPA < row.length ? _extractDouble(row[idxPA]) : 0.0;
      double prixVente = idxPV < row.length ? _extractDouble(row[idxPV]) : 0.0;

      if (nom.isNotEmpty && nom.toLowerCase() != 'nom' && nom.toLowerCase() != 'designation') {
        produits.add(Produit.fromJson({
          'id': '',
          'codeBarre': codeBarre,
          'code_barre': codeBarre,
          'nom': nom,
          'quantite': quantite,
          'prixAchat': prixAchat,
          'prixVente': prixVente,
          'prix': prixVente,
          'entrepriseId': entrepriseId,
        }));
      }
    }
    return produits;
  }

  // ------------------------------------------------------------------
  // Parsing CSV sécurisé avec détection dynamique de colonnes
  // ------------------------------------------------------------------
  static List<Produit> _importerDepuisCsv(List<int> bytes, String entrepriseId) {
    // Décodage avec tolérance aux caractères non-UTF8
    String content = utf8.decode(bytes, allowMalformed: true);
    String delimiter = content.contains(';') ? ';' : ',';

    List<List<dynamic>> rows = CsvToListConverter(
      fieldDelimiter: delimiter,
      eol: '\n',
    ).convert(content);

    List<Produit> produits = [];
    if (rows.isEmpty) return produits;

    int idxCode = 0, idxNom = 1, idxQte = 2, idxPA = 3, idxPV = 4;
    var headerRow = rows.first;
    bool hasHeader = false;

    // Détection dynamique des colonnes CSV
    for (int col = 0; col < headerRow.length; col++) {
      String val = headerRow[col].toString().trim().toLowerCase();
      if (val.contains('code') || val.contains('ref') || val.contains('barcode')) {
        idxCode = col;
        hasHeader = true;
      } else if (val.contains('nom') || val.contains('desig') || val.contains('produit') || val.contains('article')) {
        idxNom = col;
        hasHeader = true;
      } else if (val.contains('qte') || val.contains('quantit') || val.contains('stock')) {
        idxQte = col;
        hasHeader = true;
      } else if (val == 'pa' || val.contains('achat') || val.contains('cout')) {
        idxPA = col;
        hasHeader = true;
      } else if (val == 'pv' || val.contains('vente') || val.contains('prix')) {
        idxPV = col;
        hasHeader = true;
      }
    }

    int startRow = hasHeader ? 1 : 0;

    for (int i = startRow; i < rows.length; i++) {
      var row = rows[i];
      if (row.isEmpty) continue;

      String codeBarre = idxCode < row.length ? row[idxCode].toString().trim() : '';
      String nom = idxNom < row.length ? row[idxNom].toString().trim() : '';
      int quantite = idxQte < row.length ? _extractInt(row[idxQte]) : 0;
      double prixAchat = idxPA < row.length ? _extractDouble(row[idxPA]) : 0.0;
      double prixVente = idxPV < row.length ? _extractDouble(row[idxPV]) : 0.0;

      if (nom.isNotEmpty && nom.toLowerCase() != 'nom' && nom.toLowerCase() != 'designation') {
        produits.add(Produit.fromJson({
          'id': '',
          'codeBarre': codeBarre,
          'code_barre': codeBarre,
          'nom': nom,
          'quantite': quantite,
          'prixAchat': prixAchat,
          'prixVente': prixVente,
          'prix': prixVente,
          'entrepriseId': entrepriseId,
        }));
      }
    }
    return produits;
  }

  // ------------------------------------------------------------------
  // 2. Exporter le catalogue vers un fichier Excel et le partager
  // ------------------------------------------------------------------
  static Future<File> exporterStockVersExcel(
    List<Map<String, dynamic>> produits, {
    bool triggerShare = true,
  }) async {
    var excel = Excel.createExcel();

    String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'Stock Actuel');
    Sheet sheetObject = excel['Stock Actuel'];

    // En-têtes de colonnes
    sheetObject.appendRow([
      TextCellValue('codeBarre'),
      TextCellValue('nom'),
      TextCellValue('quantite'),
      TextCellValue('PA'),
      TextCellValue('PV'),
    ]);

    for (var produit in produits) {
      sheetObject.appendRow([
        TextCellValue(produit['codeBarre']?.toString() ?? ''),
        TextCellValue(produit['nom']?.toString() ?? 'Inconnu'),
        IntCellValue((produit['quantite'] as num?)?.toInt() ?? 0),
        DoubleCellValue((produit['prixAchat'] as num?)?.toDouble() ?? 0.0),
        DoubleCellValue((produit['prixVente'] as num?)?.toDouble() ?? 0.0),
      ]);
    }

    final fileBytes = excel.encode();
    if (fileBytes == null) {
      throw Exception("Erreur lors de la génération du fichier Excel.");
    }

    final directory = await getTemporaryDirectory();
    final filePath = "${directory.path}/Rapport_Stock_Stockly.xlsx";

    final file = File(filePath);
    await file.writeAsBytes(fileBytes);

    if (triggerShare) {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Rapport de Stock',
        text: 'Veuillez trouver ci-joint le rapport de stock.',
      );
    }

    return file;
  }
}