import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ------------------------------------------------------------------
// Helpers : Nettoyage et normalisation des textes et accents
// ------------------------------------------------------------------

String _normalize(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[àâä]'), 'a')
      .replaceAll(RegExp(r'[îï]'), 'i')
      .replaceAll(RegExp(r'[ôö]'), 'o')
      .replaceAll(RegExp(r'[ùûü]'), 'u')
      .replaceAll(RegExp(r'[ç]'), 'c')
      .trim();
}

dynamic _getRawValue(dynamic cell) {
  if (cell == null) return null;
  dynamic val = cell;
  if (val is Data) val = val.value;
  if (val == null) return null;

  if (val is CellValue) {
    try {
      return (val as dynamic).value;
    } catch (_) {
      return val.toString();
    }
  }
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

    if (sheet == null || sheet.maxRows == 0 || sheet.rows.isEmpty) return produits;

    int idxCode = -1, idxNom = -1, idxQte = -1, idxPA = -1, idxPV = -1;
    var headerRow = sheet.rows.first;

    for (int col = 0; col < headerRow.length; col++) {
      String val = _normalize(_cellToString(headerRow[col]));
      if (val.contains('code') || val.contains('ref') || val.contains('barcode')) {
        idxCode = col;
      } else if (val.contains('nom') || val.contains('desig') || val.contains('produit') || val.contains('article')) {
        idxNom = col;
      } else if (val.contains('qte') || val.contains('quantit') || val.contains('stock')) {
        idxQte = col;
      } else if (val == 'pa' || val.contains('achat') || val.contains('cout')) {
        idxPA = col;
      } else if (val == 'pv' || val.contains('vente') || val.contains('prix')) {
        idxPV = col;
      }
    }

    if (idxNom == -1) idxNom = 1;
    if (idxCode == -1) idxCode = 0;
    if (idxQte == -1) idxQte = 2;
    if (idxPA == -1) idxPA = 3;
    if (idxPV == -1) idxPV = 4;

    bool hasHeaderRow = idxNom >= 0 && _normalize(_cellToString(headerRow[idxNom])).contains('nom');
    int startRow = hasHeaderRow ? 1 : 0;

    for (int i = startRow; i < sheet.maxRows; i++) {
      if (i >= sheet.rows.length) break;
      var row = sheet.rows[i];
      if (row.isEmpty) continue;

      String codeBarre = (idxCode < row.length && idxCode >= 0) ? _cellToCode(row[idxCode]) : '';
      String nom = (idxNom < row.length && idxNom >= 0) ? _cellToString(row[idxNom]) : '';
      int quantite = (idxQte < row.length && idxQte >= 0) ? _cellToInt(row[idxQte]) : 0;
      double prixAchat = (idxPA < row.length && idxPA >= 0) ? _cellToDouble(row[idxPA]) : 0.0;
      double prixVente = (idxPV < row.length && idxPV >= 0) ? _cellToDouble(row[idxPV]) : 0.0;

      String nomNorm = _normalize(nom);
      if (nom.isNotEmpty && nomNorm != 'nom' && nomNorm != 'designation') {
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

  int idxCode = -1, idxNom = -1, idxQte = -1, idxPA = -1, idxPV = -1;
  var headerRow = rows.first;

  for (int col = 0; col < headerRow.length; col++) {
    String val = _normalize(headerRow[col].toString());
    if (val.contains('code') || val.contains('ref') || val.contains('barcode')) {
      idxCode = col;
    } else if (val.contains('nom') || val.contains('desig') || val.contains('produit') || val.contains('article')) {
      idxNom = col;
    } else if (val.contains('qte') || val.contains('quantit') || val.contains('stock')) {
      idxQte = col;
    } else if (val == 'pa' || val.contains('achat') || val.contains('cout')) {
      idxPA = col;
    } else if (val == 'pv' || val.contains('vente') || val.contains('prix')) {
      idxPV = col;
    }
  }

  if (idxNom == -1) idxNom = 1;
  if (idxCode == -1) idxCode = 0;
  if (idxQte == -1) idxQte = 2;
  if (idxPA == -1) idxPA = 3;
  if (idxPV == -1) idxPV = 4;

  bool hasHeaderRow = idxNom >= 0 && _normalize(headerRow[idxNom].toString()).contains('nom');
  int startRow = hasHeaderRow ? 1 : 0;

  for (int i = startRow; i < rows.length; i++) {
    var row = rows[i];
    if (row.isEmpty) continue;

    String codeBarre = (idxCode < row.length && idxCode >= 0) ? _cellToCode(row[idxCode]) : '';
    String nom = (idxNom < row.length && idxNom >= 0) ? _cellToString(row[idxNom]) : '';
    int quantite = (idxQte < row.length && idxQte >= 0) ? _cellToInt(row[idxQte]) : 0;
    double prixAchat = (idxPA < row.length && idxPA >= 0) ? _cellToDouble(row[idxPA]) : 0.0;
    double prixVente = (idxPV < row.length && idxPV >= 0) ? _cellToDouble(row[idxPV]) : 0.0;

    String nomNorm = _normalize(nom);
    if (nom.isNotEmpty && nomNorm != 'nom' && nomNorm != 'designation') {
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

  static Future<void> importerEtTraiter(
    BuildContext context, {
    required String entrepriseId,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final ValueNotifier<String> statusNotifier =
        ValueNotifier("Sélection du fichier...");

    bool dialogDisplayed = false;

    if (entrepriseId.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Erreur: Identifiant d\'entreprise non valide.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final service = PackingListService();

      int nbTraites = await service.importerExcel(
        entrepriseId: entrepriseId,
        onProgress: (traites, total) {
          if (!dialogDisplayed && context.mounted) {
            dialogDisplayed = true;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) {
                return ValueListenableBuilder<String>(
                  valueListenable: statusNotifier,
                  builder: (_, message, __) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text("Importation en cours"),
                      content: Row(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(width: 20),
                          Expanded(child: Text(message)),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          }
          statusNotifier.value =
              "Enregistrement : $traites / $total produits...";
        },
      );

      if (dialogDisplayed && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (nbTraites > 0) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('$nbTraites produit(s) importé(s) avec succès !'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (dialogDisplayed && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erreur d\'importation : $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<int> importerExcel({
    required String entrepriseId,
    Function(int traites, int total)? onProgress,
  }) async {
    if (entrepriseId.isEmpty) {
      throw Exception("Identifiant d'entreprise manquant.");
    }

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
      throw Exception(
          "Format non supporté. Veuillez sélectionner un fichier .xlsx, .xls ou .csv.");
    }

    Uint8List? bytes = pickedFile.bytes;
    if (bytes == null &&
        pickedFile.path != null &&
        pickedFile.path!.isNotEmpty) {
      bytes = await File(pickedFile.path!).readAsBytes();
    }

    if (bytes == null || bytes.isEmpty) {
      throw Exception("Impossible de lire le contenu du fichier sélectionné.");
    }

    final List<Map<String, dynamic>> produitsAInserer = isCsv
        ? await compute(_parserCsv, bytes)
        : await compute(_parserModeleProduits, bytes);

    if (produitsAInserer.isEmpty) return 0;

    // NOUVEAU CHEMIN : Ciblage direct sous /entreprises/{entrepriseId}/produits
    final collection = _firestore
        .collection('entreprises')
        .doc(entrepriseId)
        .collection('produits');

    final total = produitsAInserer.length;
    int traites = 0;

    const int batchSize = 400;
    for (int i = 0; i < total; i += batchSize) {
      final batch = _firestore.batch();
      final chunk = produitsAInserer.skip(i).take(batchSize);

      for (var item in chunk) {
        String barcode = item['codeBarre']?.toString().trim() ?? '';
        
        DocumentReference docRef;
        if (barcode.isNotEmpty) {
          String sanitizedCode = barcode.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
          docRef = collection.doc('${entrepriseId}_$sanitizedCode');
        } else {
          docRef = collection.doc();
        }

        final data = Map<String, dynamic>.from(item);
        data['entrepriseId'] = entrepriseId;
        data['isPublicEcommerce'] = false; // Flag pour préparation e-commerce
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