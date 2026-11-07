import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockly_saas/core/services/journal_service.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'xlsx_lecteur_simple.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockly_saas/features/boutiques/boutique_provider.dart';

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
  'noms', 'designations', 'articles', 'produits', 'descriptions', 'libelles',
  'codes', 'refs', 'references', 'noms des produits',
  'item', 'items',
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
  int ligneEntete = -1;

  // 🔎 La ligne de titres n'est pas toujours la 1re (titre du document,
  // ligne vide…) : on la cherche dans les 10 premières lignes.
  for (int r = 0; r < rows.length && r < 10 && ligneEntete == -1; r++) {
    final entete = rows[r];
    // Une ligne qui contient des nombres est une ligne de produit, pas de titres
    if (entete.any((c) => _getRawValue(c) is num)) continue;

    int c0 = -1, n0 = -1, q0 = -1, a0 = -1, v0 = -1;
    final cols = <String, String>{};
    for (int col = 0; col < entete.length; col++) {
      final brut = _cellToString(entete[col]);
      final val = normaliserTexte(brut);
      if (val.isEmpty) continue;
      final court = val.replaceAll(RegExp(r'[.\s]'), ''); // « P.A » -> « pa »

      if (c0 == -1 &&
          (val.contains('code') || val.contains('ref') || val.contains('barcode') || val.contains('ean'))) {
        c0 = col;
        cols['code'] = brut;
      } else if (n0 == -1 &&
          (val.contains('nom') || val.contains('desig') || val.contains('produit') ||
              val.contains('article') || val.contains('libelle') || val.contains('description'))) {
        n0 = col;
        cols['nom'] = brut;
      } else if (q0 == -1 &&
          (val.contains('qte') || val.contains('qty') || val.contains('quantit') || val.contains('stock'))) {
        q0 = col;
        cols['quantite'] = brut;
      } else if (a0 == -1 &&
          (court == 'pa' || court == 'pau' || val.contains('achat') || val.contains('cout') ||
              val.contains('revient'))) {
        a0 = col;
        cols['prixAchat'] = brut;
      } else if (v0 == -1 &&
          (court == 'pv' || court == 'pu' || court == 'pvu' || val.contains('vente') || val.contains('prix'))) {
        v0 = col;
        cols['prixVente'] = brut;
      }
    }

    // Au moins 2 titres reconnus = c'est la ligne de titres
    if ([c0, n0, q0, a0, v0].where((i) => i >= 0).length >= 2) {
      ligneEntete = r;
      idxCode = c0;
      idxNom = n0;
      idxQte = q0;
      idxPA = a0;
      idxPV = v0;
      colonnes.addAll(cols);
    }
  }

  final avecEntete = ligneEntete >= 0;

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

  final debut = avecEntete ? ligneEntete + 1 : 0;
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
    // 🛑 Ligne « TOTAL » : fin du tableau des produits (la suite = autres tableaux)
    if (produits.isNotEmpty &&
        (nomNorm.startsWith('total') || normaliserTexte(codeBarre).startsWith('total'))) {
      break;
    }
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

  // 🟠 Cas douteux : produit qui ressemble à un produit existant
  bool douteux = false;
  String doute = '';
  String? idCandidat;
  String nomCandidat = '';
  String codeCandidat = '';
  bool codeCandidatVide = true;
  int stockCandidat = 0;
  /// null = pas encore choisi ; true = même produit ; false = nouveau produit
  bool? memeProduit;

  LigneImport({
    required this.numeroLigne,
    required this.nom,
    required this.codeBarre,
    required this.quantite,
    required this.prixAchat,
    required this.prixVente,
  });

  /// 🟠 Choix de l'utilisateur pour un cas douteux
  void choisir(bool meme) {
    memeProduit = meme;
    if (meme) {
      statut = StatutLigne.existant;
      idExistant = idCandidat;
      nomExistant = nomCandidat;
      stockActuel = stockCandidat;
      codeExistantVide = codeCandidatVide;
    } else {
      statut = StatutLigne.nouveau;
      idExistant = null;
      nomExistant = '';
      stockActuel = 0;
    }
  }

  int nouveauStock(ModeImport mode) {
    if (statut == StatutLigne.nouveau) return quantite;
    return mode == ModeImport.arrivage ? stockActuel + quantite : quantite;
  }
}

// Code-barres d'un produit enregistré
String _codeDe(Map<String, dynamic> data) =>
    (data['codeBarre'] ?? data['code_barre'] ?? '').toString().trim();

// Même nom ? (sans tenir compte des majuscules, accents, espaces et ponctuation)
bool _memeNom(String a, String b) {
  String cle(String s) => normaliserTexte(s).replaceAll(RegExp(r'[^a-z0-9]'), '');
  return cle(a) == cle(b);
}

// 🏬 Stock d'un produit dans une boutique
//  (principale = stock total − stocks des autres boutiques)
int _stockDans(Map<String, dynamic> data, String boutiqueId) {
  final total = (data['quantite'] as num?)?.toInt() ?? 0;
  final stocks = data['stocks'] is Map ? data['stocks'] as Map : const {};
  if (boutiqueId != 'principale') return (stocks[boutiqueId] as num?)?.toInt() ?? 0;
  var autres = 0;
  stocks.forEach((k, v) {
    if (k != 'principale' && v is num) autres += v.toInt();
  });
  final reste = total - autres;
  return reste < 0 ? 0 : reste;
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
    this.boutiqueId = 'principale',
    this.nomBoutique = '',
  });

  /// 🏬 Boutique qui reçoit la marchandise
  final String boutiqueId;
  final String nomBoutique;

  int get nbNouveaux => lignes.where((l) => l.statut == StatutLigne.nouveau).length;
  int get nbExistants => lignes.where((l) => l.statut == StatutLigne.existant).length;
  int get nbIgnores => lignes.where((l) => l.statut == StatutLigne.ignore).length;

  /// 🟠 Cas douteux sur lesquels l'utilisateur n'a pas encore choisi
  int get nbAChoisir => lignes
      .where((l) => l.douteux && l.memeProduit == null && l.statut != StatutLigne.ignore)
      .length;
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
    // 📷 Lecture par l'IA d'une photo (au lieu d'un fichier Excel)
    Future<List<Map<String, dynamic>>?> Function()? lirePhoto,
  }) async {
    if (!context.mounted) return 0;
    // 🏬 Boutique qui reçoit la marchandise (boutique affichée ; « Toutes » = principale)
    var boutiqueId = 'principale';
    var nomBoutique = 'Boutique principale';
    try {
      final conteneur = ProviderScope.containerOf(context, listen: false);
      boutiqueId = conteneur.read(boutiqueActiveProvider) ?? 'principale';
      for (final b in conteneur.read(boutiquesActivesProvider(entrepriseId))) {
        if (b.id == boutiqueId) nomBoutique = b.nom;
      }
    } catch (_) {}
    if (boutiqueId != 'principale' && nomBoutique == 'Boutique principale') nomBoutique = boutiqueId;

    final continuer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lirePhoto != null ? 'Importer une photo' : 'Importer un fichier'),
        content: Text('La marchandise sera ajoutée à la boutique :\n\n🏬 $nomBoutique\n\n'
            "Pour une autre boutique, changez d'abord de boutique dans l'application."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continuer')),
        ],
      ),
    );
    if (continuer != true || !context.mounted) return 0;

    // 📷 Photo : l'IA lit d'abord les produits
    List<Map<String, dynamic>>? lus;
    if (lirePhoto != null) {
      lus = await lirePhoto();
      if (lus == null || !context.mounted) return 0;
    }
    final analyse = await choisirEtAnalyser(
        entrepriseId: entrepriseId, boutiqueId: boutiqueId, nomBoutique: nomBoutique,
        produitsFournis: lus);
    if (analyse == null || !context.mounted) return 0;

    // Au premier plan : le geste « retour » du téléphone ferme bien l'aperçu
    final resultat = await Navigator.of(context, rootNavigator: true).push<ResultatImport>(
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
  Future<AnalyseImport?> choisirEtAnalyser({
    required String entrepriseId,
    String boutiqueId = 'principale',
    String nomBoutique = '',
    // 📷 Produits déjà lus (photo + IA) : pas de fichier à choisir
    List<Map<String, dynamic>>? produitsFournis,
    String? nomSource,
  }) async {
    if (entrepriseId.isEmpty) throw Exception("Identifiant d'entreprise manquant.");

    // 📷 Produits déjà lus (photo + IA) : on saute le choix du fichier
    Map<String, dynamic> brut;
    String nomFichierLu;
    if (produitsFournis != null) {
      const ia = "Lu par l'IA";
      brut = {
        'produits': produitsFournis,
        'colonnes': <String, String>{
          'codeBarre': ia, 'code': ia, 'code_barre': ia,
          'nom': ia, 'quantite': ia, 'prixAchat': ia, 'prixVente': ia,
        },
        'avecEntete': true,
      };
      nomFichierLu = nomSource ?? 'Photo (IA)';
    } else {
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

      brut = isCsv ? await compute(_parserCsv, bytes) : await compute(_parserExcel, bytes);
      if (brut['erreur'] != null) throw Exception(brut['erreur']);
      nomFichierLu = pickedFile.name;
    }

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

      // Recherche du produit existant : code-barres, puis nom.
      // 🟠 Cas douteux (même code + autre nom, ou même nom + autre code) :
      //    c'est l'utilisateur qui choisit dans l'aperçu.
      final parLeCode = ligne.codeBarre.isNotEmpty ? parCode[ligne.codeBarre] : null;
      final parLeNom = parNom[normaliserTexte(ligne.nom)];
      QueryDocumentSnapshot<Map<String, dynamic>>? existant;
      QueryDocumentSnapshot<Map<String, dynamic>>? douteux;
      if (parLeCode != null) {
        if (_memeNom((parLeCode.data()['nom'] ?? '').toString(), ligne.nom)) {
          existant = parLeCode;
        } else {
          douteux = parLeCode;
          ligne.doute = 'même code, nom différent';
        }
      } else if (parLeNom != null) {
        final codeCandidat = _codeDe(parLeNom.data());
        if (ligne.codeBarre.isEmpty || codeCandidat.isEmpty || codeCandidat == ligne.codeBarre) {
          existant = parLeNom;
        } else {
          douteux = parLeNom;
          ligne.doute = 'même nom, code différent';
        }
      }

      if (existant != null) {
        final data = existant.data();
        ligne.statut = StatutLigne.existant;
        ligne.idExistant = existant.id;
        ligne.nomExistant = (data['nom'] ?? '').toString();
        ligne.stockActuel = _stockDans(data, boutiqueId); // 🏬 stock de la boutique
        ligne.codeExistantVide =
            (data['codeBarre'] ?? data['code_barre'] ?? '').toString().trim().isEmpty;
      } else {
        ligne.statut = StatutLigne.nouveau;
        if (douteux != null) {
          final data = douteux.data();
          ligne.douteux = true;
          ligne.idCandidat = douteux.id;
          ligne.nomCandidat = (data['nom'] ?? '').toString();
          ligne.codeCandidat = _codeDe(data);
          ligne.stockCandidat = _stockDans(data, boutiqueId);
          ligne.codeCandidatVide = ligne.codeCandidat.isEmpty;
        }
      }

      dejaVu[cle] = ligne;
      lignes.add(ligne);
    }

    // Nouveau produit sans quantité : rien à créer
    for (final l in lignes) {
      if (l.statut == StatutLigne.nouveau && l.quantite <= 0) {
        l.statut = StatutLigne.ignore;
        l.raison = 'Nouveau produit avec quantité 0';
      }
    }

    return AnalyseImport(
      entrepriseId: entrepriseId,
      nomFichier: nomFichierLu,
      colonnes: colonnes,
      avecEntete: brut['avecEntete'] == true,
      lignes: lignes,
      boutiqueId: boutiqueId,
      nomBoutique: nomBoutique,
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
          // 🏬 Le stock total change de l'écart ; celui de la boutique aussi
          final b = analyse.boutiqueId;
          final ecart = mode == ModeImport.arrivage ? l.quantite : l.quantite - l.stockActuel;
          final maj = <String, dynamic>{
            'quantite': FieldValue.increment(ecart),
            if (b != 'principale')
              'stocks.$b': mode == ModeImport.arrivage ? FieldValue.increment(l.quantite) : l.quantite,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          // Un prix vide ou à 0 dans le fichier ne remplace pas le prix actuel
          if (l.prixAchat > 0) maj['prixAchat'] = l.prixAchat;
          if (l.prixVente > 0) {
            if (b == 'principale') {
              maj['prixVente'] = l.prixVente;
              maj['prix'] = l.prixVente;
            } else {
              maj['prixParBoutique.$b'] = l.prixVente; // 🏬 prix propre à la boutique
            }
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
            // 🏬 Nouveau produit : tout son stock est dans la boutique choisie
            if (analyse.boutiqueId != 'principale') 'stocks': {analyse.boutiqueId: l.quantite},
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

    // 📒 Journal « qui a fait quoi » (n'empêche jamais l'import)
    if (aEcrire.isNotEmpty) {
      final arrivage = mode == ModeImport.arrivage;
      final pieces = aEcrire.fold<num>(0, (s, l) => s + l.quantite);
      final nomB =
          analyse.nomBoutique.isEmpty ? analyse.boutiqueId : analyse.nomBoutique;
      var detailsImport = '${arrivage ? 'Arrivage' : 'Inventaire'} · $nomB · '
          '${resultat.nouveaux} nouveau(x), ${resultat.misAJour} mis à jour · '
          '$pieces pièce(s)';
      if (!arrivage) {
        var ecarts = aEcrire
            .where((l) =>
                l.statut == StatutLigne.existant && l.quantite != l.stockActuel)
            .map((l) => '${l.codeBarre.isEmpty ? l.nom : l.codeBarre} '
                '${l.stockActuel} → ${l.quantite}')
            .join(', ');
        if (ecarts.length > 300) ecarts = '${ecarts.substring(0, 300)}…';
        if (ecarts.isNotEmpty) detailsImport += ' · écarts : $ecarts';
      }
      unawaited(noterJournal(
        entrepriseId: analyse.entrepriseId,
        action: ActionsJournal.import,
        details: detailsImport,
        boutiqueId: analyse.boutiqueId,
      ));
    }

    return resultat;
  }
}