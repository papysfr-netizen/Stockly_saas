import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'xlsx_lecteur_simple.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../features/import/import_apercu_screen.dart';

// ------------------------------------------------------------------
// Helpers : nettoyage des textes et des cellules
// ------------------------------------------------------------------

String normaliserTexte(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[àâä]'), 'a')
      .replaceAll(RegExp(r'[îï]'), 'i')
      .replaceAll(RegExp(r'[ôö]'), 'o')
      .replaceAll(RegExp(r'[ùûü]'), 'u')
      .replaceAll(RegExp(r'[ç]'), 'c')
      .replaceAll(RegExp(r'\s+'), ' ')
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

// Mots qui ne sont jamais de vrais noms de produits (en-têtes, lignes de total)
const _motsEntete = {
  'nom', 'designation', 'article', 'produit', 'description', 'libelle', 'total',
  'code', 'ref', 'reference', 'nom du produit', 'nom produit',
};

// ------------------------------------------------------------------
// Analyse commune (Excel et CSV) — tourne en arrière-plan
// ------------------------------------------------------------------
Map<String, dynamic> _analyserLignes(List<List<dynamic>> rows) {
  final produits = <Map<String, dynamic>>[];
  final colonnes = <String, String>{};

  if (rows.isEmpty) {
    return {'produits': produits, 'colonnes': colonnes, 'avecEntete': false};
  }

  int idxCode = -1, idxNom = -1, idxQte = -1, idxPA = -1, idxPV = -1;
  final entete = rows.first;

  for (int col = 0; col < entete.length; col++) {
    final brut = _cellToString(entete[col]);
    final val = normaliserTexte(brut);
    if (val.isEmpty) continue;

    if (idxCode == -1 &&
        (val.contains('code') || val.contains('ref') || val.contains('barcode') || val.contains('ean'))) {
      idxCode = col;
      colonnes['code'] = brut;
    } else if (idxNom == -1 &&
        (val.contains('nom') || val.contains('desig') || val.contains('produit') ||
            val.contains('article') || val.contains('libelle') || val.contains('description'))) {
      idxNom = col;
      colonnes['nom'] = brut;
    } else if (idxQte == -1 &&
        (val.contains('qte') || val.contains('qty') || val.contains('quantit') || val.contains('stock'))) {
      idxQte = col;
      colonnes['quantite'] = brut;
    } else if (idxPA == -1 &&
        (val == 'pa' || val.contains('achat') || val.contains('cout') || val.contains('revient'))) {
      idxPA = col;
      colonnes['prixAchat'] = brut;
    } else if (idxPV == -1 && (val == 'pv' || val.contains('vente') || val.contains('prix'))) {
      idxPV = col;
      colonnes['prixVente'] = brut;
    }
  }

  // Au moins 2 titres reconnus = la 1re ligne est une ligne d'en-tête
  final trouves = [idxCode, idxNom, idxQte, idxPA, idxPV].where((i) => i >= 0).length;
  final avecEntete = trouves >= 2;

  if (!avecEntete) {
    // Pas d'en-tête : ordre standard A=Code, B=Nom, C=Qté, D=Prix achat, E=Prix vente
    idxCode = 0;
    idxNom = 1;
    idxQte = 2;
    idxPA = 3;
    idxPV = 4;
    colonnes
      ..clear()
      ..['code'] = 'colonne A'
      ..['nom'] = 'colonne B'
      ..['quantite'] = 'colonne C'
      ..['prixAchat'] = 'colonne D'
      ..['prixVente'] = 'colonne E';
  } else if (idxNom == -1) {
    return {
      'produits': produits,
      'colonnes': colonnes,
      'avecEntete': true,
      'erreur': 'Colonne du nom des produits introuvable. Ajoutez un titre « Nom » ou « Désignation ».',
    };
  }

  final debut = avecEntete ? 1 : 0;
  for (int i = debut; i < rows.length; i++) {
    final row = rows[i];
    if (row.isEmpty) continue;

    String lireTexte(int idx) => (idx >= 0 && idx < row.length) ? _cellToString(row[idx]) : '';
    final codeBarre = (idxCode >= 0 && idxCode < row.length) ? _cellToCode(row[idxCode]) : '';
    final nom = lireTexte(idxNom);
    final quantite = (idxQte >= 0 && idxQte < row.length) ? _cellToInt(row[idxQte]) : 0;
    final prixAchat = (idxPA >= 0 && idxPA < row.length) ? _cellToDouble(row[idxPA]) : 0.0;
    final prixVente = (idxPV >= 0 && idxPV < row.length) ? _cellToDouble(row[idxPV]) : 0.0;

    final nomNorm = normaliserTexte(nom);
    if (nom.isEmpty || _motsEntete.contains(nomNorm) || nomNorm.startsWith('total')) continue;

    produits.add({
      'ligne': i + 1,
      'codeBarre': codeBarre,
      'nom': nom,
      'quantite': quantite,
      'prixAchat': prixAchat,
      'prixVente': prixVente,
    });
  }

  return {'produits': produits, 'colonnes': colonnes, 'avecEntete': avecEntete};
}

Map<String, dynamic> _parserExcel(Uint8List bytes) {
  try {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return _analyserLignes([]);
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null || sheet.rows.isEmpty) return _analyserLignes([]);
    final rows = sheet.rows.map((r) => List<dynamic>.from(r)).toList();
    return _analyserLignes(rows);
  } catch (e) {
    // 🛟 Lecteur de secours (fichiers WPS, LibreOffice, Google Sheets…)
    try {
      final rows = XlsxLecteurSimple.lirePremiereFeuille(bytes);
      if (rows.isNotEmpty) return _analyserLignes(rows);
    } catch (_) {
      // fichier vraiment illisible
    }
    return {
      'produits': <Map<String, dynamic>>[],
      'colonnes': <String, String>{},
      'avecEntete': false,
      'erreur': "Fichier Excel illisible. S'il s'agit d'un ancien fichier .xls, "
          'enregistrez-le au format .xlsx ou .csv puis réessayez.',
    };
  }
}

Map<String, dynamic> _parserCsv(Uint8List bytes) {
  final content = utf8
      .decode(bytes, allowMalformed: true)
      .replaceFirst('\uFEFF', '')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');

  final delimiter = content.contains(';') ? ';' : ',';
  final rows = CsvToListConverter(fieldDelimiter: delimiter, eol: '\n').convert(content);
  return _analyserLignes(rows);
}

// ------------------------------------------------------------------
// Modèles
// ------------------------------------------------------------------
enum StatutLigne { nouveau, existant, ignore }

enum ModeImport { arrivage, inventaire }

class LigneImport {
  final int numeroLigne;
  final String nom;
  final String codeBarre;
  int quantite;
  double prixAchat;
  double prixVente;

  StatutLigne statut = StatutLigne.nouveau;
  String? idExistant;
  String nomExistant = '';
  bool codeExistantVide = true;
  int stockActuel = 0;
  String raison = '';

  LigneImport({
    required this.numeroLigne,
    required this.nom,
    required this.codeBarre,
    required this.quantite,
    required this.prixAchat,
    required this.prixVente,
  });

  int nouveauStock(ModeImport mode) {
    if (statut == StatutLigne.nouveau) return quantite;
    return mode == ModeImport.arrivage ? stockActuel + quantite : quantite;
  }
}

class AnalyseImport {
  final String entrepriseId;
  final String nomFichier;
  final Map<String, String> colonnes;
  final bool avecEntete;
  final List<LigneImport> lignes;

  AnalyseImport({
    required this.entrepriseId,
    required this.nomFichier,
    required this.colonnes,
    required this.avecEntete,
    required this.lignes,
  });

  int get nbNouveaux => lignes.where((l) => l.statut == StatutLigne.nouveau).length;
  int get nbExistants => lignes.where((l) => l.statut == StatutLigne.existant).length;
  int get nbIgnores => lignes.where((l) => l.statut == StatutLigne.ignore).length;
}

class ResultatImport {
  int nouveaux = 0;
  int misAJour = 0;
  int ignores = 0;
  bool horsLigne = false;
  int get total => nouveaux + misAJour;
}

// ------------------------------------------------------------------
// Service
// ------------------------------------------------------------------
class PackingListService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _produits(String entrepriseId) =>
      _firestore.collection('entreprises').doc(entrepriseId).collection('produits');

  /// Point d'entrée : choix du fichier → aperçu → import. Renvoie le nombre de produits écrits.
  Future<int> importerAvecApercu(
    BuildContext context, {
    required String entrepriseId,
    void Function(int traites, int total)? onProgress,
  }) async {
    final analyse = await choisirEtAnalyser(entrepriseId: entrepriseId);
    if (analyse == null || !context.mounted) return 0;

    final resultat = await Navigator.of(context).push<ResultatImport>(
      MaterialPageRoute(
        builder: (_) => ImportApercuScreen(analyse: analyse, service: this),
      ),
    );
    return resultat?.total ?? 0;
  }

  /// Ancien point d'entrée (gardé pour compatibilité).
  static Future<void> importerEtTraiter(
    BuildContext context, {
    required String entrepriseId,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final nb = await PackingListService().importerAvecApercu(context, entrepriseId: entrepriseId);
      if (nb > 0) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('$nb produit(s) importé(s) ou mis à jour.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur d\'importation : $e'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  /// 1) Choisit le fichier, le lit, et compare avec les produits existants.
  Future<AnalyseImport?> choisirEtAnalyser({required String entrepriseId}) async {
    if (entrepriseId.isEmpty) throw Exception("Identifiant d'entreprise manquant.");

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final pickedFile = result.files.first;
    final name = pickedFile.name.toLowerCase();
    final isExcel = name.endsWith('.xlsx') || name.endsWith('.xls');
    final isCsv = name.endsWith('.csv');
    if (!isExcel && !isCsv) {
      throw Exception('Format non supporté. Choisissez un fichier .xlsx ou .csv.');
    }

    Uint8List? bytes = pickedFile.bytes;
    if (bytes == null && pickedFile.path != null && pickedFile.path!.isNotEmpty) {
      bytes = await File(pickedFile.path!).readAsBytes();
    }
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Impossible de lire le contenu du fichier.');
    }

    final brut = isCsv ? await compute(_parserCsv, bytes) : await compute(_parserExcel, bytes);
    if (brut['erreur'] != null) throw Exception(brut['erreur']);

    final produitsFichier = (brut['produits'] as List).cast<Map<String, dynamic>>();
    final colonnes = Map<String, String>.from(brut['colonnes'] as Map);

    // Produits existants (serveur, sinon copie du téléphone)
    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _produits(entrepriseId).get().timeout(const Duration(seconds: 8));
    } catch (_) {
      snap = await _produits(entrepriseId).get(const GetOptions(source: Source.cache));
    }

    final parCode = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    final parNom = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final d in snap.docs) {
      final data = d.data();
      final code = (data['codeBarre'] ?? data['code_barre'] ?? '').toString().trim();
      if (code.isNotEmpty) parCode[code] = d;
      final nom = normaliserTexte((data['nom'] ?? '').toString());
      if (nom.isNotEmpty) parNom.putIfAbsent(nom, () => d);
    }

    final lignes = <LigneImport>[];
    final dejaVu = <String, LigneImport>{};

    for (final p in produitsFichier) {
      final ligne = LigneImport(
        numeroLigne: (p['ligne'] as num?)?.toInt() ?? 0,
        nom: (p['nom'] ?? '').toString().trim(),
        codeBarre: (p['codeBarre'] ?? '').toString().trim(),
        quantite: (p['quantite'] as num?)?.toInt() ?? 0,
        prixAchat: (p['prixAchat'] as num?)?.toDouble() ?? 0.0,
        prixVente: (p['prixVente'] as num?)?.toDouble() ?? 0.0,
      );

      if (ligne.quantite < 0) {
        ligne.statut = StatutLigne.ignore;
        ligne.raison = 'Quantité négative';
        lignes.add(ligne);
        continue;
      }

      // Même produit deux fois dans le fichier → on fusionne
      final cle = ligne.codeBarre.isNotEmpty ? 'c:${ligne.codeBarre}' : 'n:${normaliserTexte(ligne.nom)}';
      final precedent = dejaVu[cle];
      if (precedent != null) {
        precedent.quantite += ligne.quantite;
        if (ligne.prixAchat > 0) precedent.prixAchat = ligne.prixAchat;
        if (ligne.prixVente > 0) precedent.prixVente = ligne.prixVente;
        ligne.statut = StatutLigne.ignore;
        ligne.raison = 'Fusionné avec la ligne ${precedent.numeroLigne}';
        lignes.add(ligne);
        continue;
      }

      // Recherche du produit existant : code-barres d'abord, puis nom
      QueryDocumentSnapshot<Map<String, dynamic>>? existant;
      if (ligne.codeBarre.isNotEmpty) existant = parCode[ligne.codeBarre];
      if (existant == null) {
        final candidat = parNom[normaliserTexte(ligne.nom)];
        if (candidat != null) {
          final codeCandidat =
              (candidat.data()['codeBarre'] ?? candidat.data()['code_barre'] ?? '').toString().trim();
          // Même nom mais code-barres différent = autre article : on ne mélange pas
          if (ligne.codeBarre.isEmpty || codeCandidat.isEmpty || codeCandidat == ligne.codeBarre) {
            existant = candidat;
          }
        }
      }

      if (existant != null) {
        final data = existant.data();
        ligne.statut = StatutLigne.existant;
        ligne.idExistant = existant.id;
        ligne.nomExistant = (data['nom'] ?? '').toString();
        ligne.stockActuel = (data['quantite'] as num?)?.toInt() ?? 0;
        ligne.codeExistantVide =
            (data['codeBarre'] ?? data['code_barre'] ?? '').toString().trim().isEmpty;
      } else {
        ligne.statut = StatutLigne.nouveau;
      }

      dejaVu[cle] = ligne;
      lignes.add(ligne);
    }

    return AnalyseImport(
      entrepriseId: entrepriseId,
      nomFichier: pickedFile.name,
      colonnes: colonnes,
      avecEntete: brut['avecEntete'] == true,
      lignes: lignes,
    );
  }

  /// 2) Enregistre l'import (après confirmation sur l'écran d'aperçu).
  Future<ResultatImport> appliquer(
    AnalyseImport analyse,
    ModeImport mode, {
    void Function(int traites, int total)? onProgress,
  }) async {
    final resultat = ResultatImport();
    final aEcrire = analyse.lignes.where((l) => l.statut != StatutLigne.ignore).toList();
    resultat.ignores = analyse.lignes.length - aEcrire.length;

    final collection = _produits(analyse.entrepriseId);
    const taille = 400;
    int faits = 0;

    for (int i = 0; i < aEcrire.length; i += taille) {
      final batch = _firestore.batch();
      final paquet = aEcrire.skip(i).take(taille).toList();

      for (final l in paquet) {
        if (l.statut == StatutLigne.existant && l.idExistant != null) {
          final maj = <String, dynamic>{
            'quantite': mode == ModeImport.arrivage ? FieldValue.increment(l.quantite) : l.quantite,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          // Un prix vide ou à 0 dans le fichier ne remplace pas le prix actuel
          if (l.prixAchat > 0) maj['prixAchat'] = l.prixAchat;
          if (l.prixVente > 0) {
            maj['prixVente'] = l.prixVente;
            maj['prix'] = l.prixVente;
          }
          if (l.codeBarre.isNotEmpty && l.codeExistantVide) {
            maj['codeBarre'] = l.codeBarre;
            maj['code_barre'] = l.codeBarre;
          }
          batch.update(collection.doc(l.idExistant), maj);
          resultat.misAJour++;
        } else {
          batch.set(collection.doc(), {
            'nom': l.nom,
            'codeBarre': l.codeBarre,
            'code_barre': l.codeBarre,
            'quantite': l.quantite,
            'prixAchat': l.prixAchat,
            'prixVente': l.prixVente,
            'prix': l.prixVente,
            'categorie': 'Général',
            'seuilAlerte': 5,
            'entrepriseId': analyse.entrepriseId,
            'isPublicEcommerce': false,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          resultat.nouveaux++;
        }
      }

      try {
        await batch.commit().timeout(const Duration(seconds: 15));
      } on TimeoutException {
        // Hors ligne : gardé sur le téléphone, envoyé au retour d'internet
        resultat.horsLigne = true;
      }

      faits += paquet.length;
      onProgress?.call(faits, aEcrire.length);
    }

    return resultat;
  }
}