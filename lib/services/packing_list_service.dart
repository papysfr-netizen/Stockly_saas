import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

// ------------------------------------------------------------------
// Helpers : Extraction et nettoyage sécurisés des valeurs
// ------------------------------------------------------------------
dynamic _getRawValue(dynamic cell) {
  if (cell == null) return null;
  dynamic val = cell;
  if (val is Data) val = val.value;
  if (val == null) return null;

  // Extraction robuste pour les différentes versions du package excel
  try {
    if (val is CellValue) {
      var inner = (val as dynamic).value;
      return inner ?? val.toString();
    }
  } catch (_) {}

  return val;
}

String _cellToCode(dynamic cellValue) {
  var raw = _getRawValue(cellValue);
  if (raw == null) return '';
  if (raw is double) return raw.toInt().toString();
  if (raw is int) return raw.toString();
  String str = raw.toString().trim().replaceAll('\r', '');
  return str.endsWith('.0') ? str.substring(0, str.length - 2) : str;
}

String _cellToString(dynamic cellValue) {
  var raw = _getRawValue(cellValue);
  if (raw == null) return '';
  return raw.toString().trim().replaceAll('\r', '');
}

int _cellToInt(dynamic cellValue) {
  var raw = _getRawValue(cellValue);
  if (raw == null) return 0;
  if (raw is num) return raw.toInt();

  String str = raw.toString().trim().replaceAll('\r', '').replaceAll(',', '.');
  double? parsedDouble = double.tryParse(str);
  return parsedDouble?.toInt() ?? int.tryParse(str) ?? 0;
}

double _cellToDouble(dynamic cellValue) {
  var raw = _getRawValue(cellValue);
  if (raw == null) return 0.0;
  if (raw is num) return raw.toDouble();

  String str = raw.toString().trim().replaceAll('\r', '').replaceAll(',', '.');
  return double.tryParse(str) ?? 0.0;
}

// ------------------------------------------------------------------
// Parser Excel (.xlsx / .xls)
// ------------------------------------------------------------------
List<Map<String, dynamic>> _parserModeleProduits(Uint8List bytes) {
  try {
    var excel = Excel.decodeBytes(bytes);
    List<Map<String, dynamic>> produits = [];

    if (excel.tables.isEmpty) return produits;
    var sheet = excel.tables[excel.tables.keys.first];
    
    // Correction : vérification de sheet.rows.isEmpty
    if (sheet == null || sheet.maxRows == 0 || sheet.rows.isEmpty) return produits;

    int idxCode = 0, idxNom = 1, idxQte = 2, idxPA = 3, idxPV = 4;
    var headerRow = sheet.rows.first;
    bool hasHeaderRow = false;

    for (int col = 0; col < headerRow.length; col++) {
      String val = _cellToString(headerRow[col]).toLowerCase();
      if (val.contains('code') || val.contains('ref') || val.contains('barcode')) {
        idxCode = col;
        hasHeaderRow = true;
      } else if (val.contains('nom') || val.contains('desig') || val.contains('produit') || val.contains('article')) {
        idxNom = col;
        hasHeaderRow = true;
      } else if (val.contains('qte') || val.contains('quantit') || val.contains('stock')) {
        idxQte = col;
        hasHeaderRow = true;
      } else if (val == 'pa' || val.contains('achat') || val.contains('cout')) {
        idxPA = col;
        hasHeaderRow = true;
      } else if (val == 'pv' || val.contains('vente') || val.contains('prix')) {
        idxPV = col;
        hasHeaderRow = true;
      }
    }

    int startRow = hasHeaderRow ? 1 : 0;

    for (int i = startRow; i < sheet.maxRows; i++) {
      if (i >= sheet.rows.length) break;
      var row = sheet.rows[i];
      if (row.isEmpty) continue;

      String codeBarre = idxCode < row.length ? _cellToCode(row[idxCode]) : '';
      String nom = idxNom < row.length ? _cellToString(row[idxNom]) : '';
      int quantite = idxQte < row.length ? _cellToInt(row[idxQte]) : 0;
      double prixAchat = idxPA < row.length ? _cellToDouble(row[idxPA]) : 0.0;
      double prixVente = idxPV < row.length ? _cellToDouble(row[idxPV]) : 0.0;

      if (nom.isNotEmpty && nom.toLowerCase() != 'nom' && nom.toLowerCase() != 'designation') {
        produits.add({
          'codeBarre': codeBarre,
          'code_barre': codeBarre,
          'nom': nom,
          'quantite': quantite,
          'prixAchat': prixAchat,
          'prixVente': prixVente,
          'prix': prixVente,
          'categorie': 'Général',
          'seuilAlerte': 5,
          'totalPrixAchat': quantite * prixAchat,
          'totalPrixVente': quantite * prixVente,
          'benefice': prixVente - prixAchat,
          'beneficeTotal': quantite * (prixVente - prixAchat),
        });
      }
    }
    return produits;
  } catch (e) {
    debugPrint('Erreur lors du parsing Excel: $e');
    return [];
  }
}

// ------------------------------------------------------------------
// Parser CSV (.csv)
// ------------------------------------------------------------------
List<Map<String, dynamic>> _parserCsv(Uint8List bytes) {
  String content = utf8
      .decode(bytes, allowMalformed: true)
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');

  String delimiter = content.contains(';') ? ';' : ',';

  List<List<dynamic>> rows = CsvToListConverter(
    fieldDelimiter: delimiter,
    eol: '\n',
  ).convert(content);

  List<Map<String, dynamic>> produits = [];
  if (rows.isEmpty) return produits;

  int idxCode = 0, idxNom = 1, idxQte = 2, idxPA = 3, idxPV = 4;
  var headerRow = rows.first;
  bool hasHeaderRow = false;

  for (int col = 0; col < headerRow.length; col++) {
    String val = headerRow[col].toString().trim().toLowerCase();
    if (val.contains('code') || val.contains('ref') || val.contains('barcode')) {
      idxCode = col;
      hasHeaderRow = true;
    } else if (val.contains('nom') || val.contains('desig') || val.contains('produit') || val.contains('article')) {
      idxNom = col;
      hasHeaderRow = true;
    } else if (val.contains('qte') || val.contains('quantit') || val.contains('stock')) {
      idxQte = col;
      hasHeaderRow = true;
    } else if (val == 'pa' || val.contains('achat') || val.contains('cout')) {
      idxPA = col;
      hasHeaderRow = true;
    } else if (val == 'pv' || val.contains('vente') || val.contains('prix')) {
      idxPV = col;
      hasHeaderRow = true;
    }
  }

  int startRow = hasHeaderRow ? 1 : 0;

  for (int i = startRow; i < rows.length; i++) {
    var row = rows[i];
    if (row.isEmpty) continue;

    String codeBarre = idxCode < row.length ? _cellToCode(row[idxCode]) : '';
    String nom = idxNom < row.length ? _cellToString(row[idxNom]) : '';
    int quantite = idxQte < row.length ? _cellToInt(row[idxQte]) : 0;
    double prixAchat = idxPA < row.length ? _cellToDouble(row[idxPA]) : 0.0;
    double prixVente = idxPV < row.length ? _cellToDouble(row[idxPV]) : 0.0;

    if (nom.isNotEmpty && nom.toLowerCase() != 'nom' && nom.toLowerCase() != 'designation') {
      produits.add({
        'codeBarre': codeBarre,
        'code_barre': codeBarre,
        'nom': nom,
        'quantite': quantite,
        'prixAchat': prixAchat,
        'prixVente': prixVente,
        'prix': prixVente,
        'categorie': 'Général',
        'seuilAlerte': 5,
        'totalPrixAchat': quantite * prixAchat,
        'totalPrixVente': quantite * prixVente,
        'benefice': prixVente - prixAchat,
        'beneficeTotal': quantite * (prixVente - prixAchat),
      });
    }
  }
  return produits;
}

// ------------------------------------------------------------------
// Service Firestore
// ------------------------------------------------------------------
class PackingListService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> importerExcel({
    required String entrepriseId,
    Function(int traites, int total)? onProgress,
  }) async {
    // Correction : spécifier le type d'extension autorisé
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return 0;

    final pickedFile = result.files.first;
    final name = pickedFile.name.toLowerCase();

    final isExcel = name.endsWith('.xlsx') || name.endsWith('.xls');
    final isCsv = name.endsWith('.csv');

    if (!isExcel && !isCsv) {
      throw Exception("Format non supporté. Veuillez sélectionner un fichier .xlsx, .xls ou .csv.");
    }

    Uint8List? bytes = pickedFile.bytes;
    if (bytes == null && pickedFile.path != null && pickedFile.path!.isNotEmpty) {
      bytes = await File(pickedFile.path!).readAsBytes();
    }

    if (bytes == null || bytes.isEmpty) {
      throw Exception("Impossible de lire le contenu du fichier sélectionné.");
    }

    final List<Map<String, dynamic>> produitsAInserer = isCsv
        ? await compute(_parserCsv, bytes)
        : await compute(_parserModeleProduits, bytes);

    if (produitsAInserer.isEmpty) return 0;

    final collection = _firestore.collection('produits');
    final total = produitsAInserer.length;
    int traites = 0;

    const int batchSize = 400;
    for (int i = 0; i < total; i += batchSize) {
      final batch = _firestore.batch();
      final chunk = produitsAInserer.skip(i).take(batchSize);

      for (var item in chunk) {
        String rawKey = item['codeBarre'].toString().isNotEmpty
            ? item['codeBarre']
            : item['nom'];

        String sanitizedId = rawKey
            .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')
            .toLowerCase();

        final DocumentReference docRef = sanitizedId.replaceAll('_', '').isEmpty
            ? collection.doc()
            : collection.doc('${entrepriseId}_$sanitizedId');

        final data = Map<String, dynamic>.from(item);
        data['entrepriseId'] = entrepriseId;
        data['createdAt'] = FieldValue.serverTimestamp();
        data['updatedAt'] = FieldValue.serverTimestamp();

        batch.set(docRef, data, SetOptions(merge: true));
      }

      await batch.commit();
      traites += chunk.length;
      if (onProgress != null) {
        onProgress(traites, total);
      }
    }

    return traites;
  }
}