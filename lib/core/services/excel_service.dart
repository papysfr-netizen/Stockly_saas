import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/produit.dart';

// 📤 EXPORT DU STOCK — version 2 (titres clairs, totaux, date dans le nom)
class ExcelService {
  static String _extractString(dynamic cellValue) {
    if (cellValue == null) return '';
    dynamic val = cellValue;
    if (val is Data) val = val.value;
    if (val is CellValue) {
      return val.toString().trim();
    }
    return val.toString().trim();
  }

  static int _extractInt(dynamic cellValue) {
    if (cellValue == null) return 0;
    dynamic raw = cellValue;
    if (raw is Data) raw = raw.value;
    if (raw is num) return raw.toInt();
    String str = _extractString(raw);
    double? parsedDouble = double.tryParse(str.replaceAll(',', '.'));
    return parsedDouble?.toInt() ?? int.tryParse(str) ?? 0;
  }

  static double _extractDouble(dynamic cellValue) {
    if (cellValue == null) return 0.0;
    dynamic raw = cellValue;
    if (raw is Data) raw = raw.value;
    if (raw is num) return raw.toDouble();
    String str = _extractString(raw).replaceAll(',', '.');
    return double.tryParse(str) ?? 0.0;
  }

  // ------------------------------------------------------------------
  // 1. Ancien import (NON UTILISÉ — remplacé par PackingListService).
  //    Gardé temporairement, à supprimer après vérification.
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
          'codeBarre': codeBarre,
          'nom': nom,
          'quantite': quantite,
          'prixAchat': prixAchat,
          'prixVente': prixVente,
          'entrepriseId': entrepriseId,
        }, ''));
      }
    }
    return produits;
  }

  static List<Produit> _importerDepuisCsv(List<int> bytes, String entrepriseId) {
    String content = utf8.decode(bytes, allowMalformed: true);
    String delimiter = content.contains(';') ? ';' : ',';
    List<List<dynamic>> rows = CsvToListConverter(fieldDelimiter: delimiter).convert(content);

    List<Produit> produits = [];
    if (rows.isEmpty) return produits;

    int idxCode = 0, idxNom = 1, idxQte = 2, idxPA = 3, idxPV = 4;
    var headerRow = rows.first;
    bool hasHeader = false;

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
          'codeBarre': codeBarre,
          'nom': nom,
          'quantite': quantite,
          'prixAchat': prixAchat,
          'prixVente': prixVente,
          'entrepriseId': entrepriseId,
        }, ''));
      }
    }
    return produits;
  }

  // ------------------------------------------------------------------
  // 2. 📤 Exporter le stock vers Excel et le partager
  // ------------------------------------------------------------------
  static double _nombre(dynamic v) => v is num ? v.toDouble() : (double.tryParse('$v') ?? 0.0);

  static String _deux(int n) => n.toString().padLeft(2, '0');

  static Future<File> exporterStockVersExcel(
    List<Map<String, dynamic>> produits, {
    bool triggerShare = true,
  }) async {
    final excel = Excel.createExcel();
    final String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'Stock Actuel');
    final Sheet feuille = excel['Stock Actuel'];

    // Titres clairs (et toujours reconnus par l'import de Stockly)
    const titres = [
      'Code-barres',
      'Nom',
      'Quantité',
      "Prix d'achat (USD)",
      'Prix de vente (USD)',
      'Valeur achat (USD)',
      'Valeur vente (USD)',
      'Marge unitaire (USD)',
    ];
    feuille.appendRow(titres.map((t) => TextCellValue(t)).toList());

    // Lecture sûre (anciens champs acceptés), puis tri alphabétique
    final lignes = produits.map((p) {
      return (
        code: (p['codeBarre'] ?? p['code_barre'] ?? '').toString(),
        nom: (p['nom'] ?? 'Inconnu').toString(),
        quantite: _nombre(p['quantite'] ?? p['stock']).toInt(),
        prixAchat: _nombre(p['prixAchat']),
        prixVente: _nombre(p['prixVente'] ?? p['prix']),
      );
    }).toList()
      ..sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));

    int totalQuantite = 0;
    double totalAchat = 0, totalVente = 0;

    for (final l in lignes) {
      final valeurAchat = l.quantite * l.prixAchat;
      final valeurVente = l.quantite * l.prixVente;
      totalQuantite += l.quantite;
      totalAchat += valeurAchat;
      totalVente += valeurVente;

      feuille.appendRow([
        TextCellValue(l.code),
        TextCellValue(l.nom),
        IntCellValue(l.quantite),
        DoubleCellValue(l.prixAchat),
        DoubleCellValue(l.prixVente),
        DoubleCellValue(valeurAchat),
        DoubleCellValue(valeurVente),
        DoubleCellValue(l.prixVente - l.prixAchat),
      ]);
    }

    // Ligne TOTAL
    feuille.appendRow([
      TextCellValue(''),
      TextCellValue('TOTAL (${lignes.length} produits)'),
      IntCellValue(totalQuantite),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(totalAchat),
      DoubleCellValue(totalVente),
      DoubleCellValue(totalVente - totalAchat),
    ]);

    // Titres et TOTAL en gras + largeur des colonnes
    final gras = CellStyle(bold: true);
    final ligneTotal = lignes.length + 1;
    for (int c = 0; c < titres.length; c++) {
      feuille.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0)).cellStyle = gras;
      feuille.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: ligneTotal)).cellStyle = gras;
    }
    feuille.setColumnWidth(0, 18);
    feuille.setColumnWidth(1, 32);
    for (int c = 2; c < titres.length; c++) {
      feuille.setColumnWidth(c, 16);
    }

    final fileBytes = excel.encode();
    if (fileBytes == null) {
      throw Exception('Erreur lors de la génération du fichier Excel.');
    }

    // Nom du fichier avec la date et l'heure
    final m = DateTime.now();
    final horodatage =
        '${m.year}-${_deux(m.month)}-${_deux(m.day)}_${_deux(m.hour)}h${_deux(m.minute)}';
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/Stock_Stockly_$horodatage.xlsx';

    final file = File(filePath);
    await file.writeAsBytes(fileBytes);

    if (triggerShare) {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'État du stock du ${_deux(m.day)}/${_deux(m.month)}/${m.year}',
        text: 'Veuillez trouver ci-joint l\'état du stock.',
      );
    }

    return file;
  }
}