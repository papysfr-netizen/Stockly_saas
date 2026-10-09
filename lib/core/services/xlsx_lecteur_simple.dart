// lib/core/services/xlsx_lecteur_simple.dart
//
// 🛟 Lecteur .xlsx DE SECOURS.
// La bibliothèque « excel » plante sur certains fichiers enregistrés par WPS,
// LibreOffice ou Google Sheets (styles, formats de nombres…).
// Un .xlsx est un dossier ZIP de fichiers XML : ici on lit SEULEMENT les
// valeurs des cellules de la première feuille, sans les styles.

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class XlsxLecteurSimple {
  /// Lignes de la première feuille : chaque cellule est un String, un num,
  /// un bool ou null (case vide).
  static List<List<dynamic>> lirePremiereFeuille(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    String? lire(String chemin) {
      final f = archive.findFile(chemin);
      if (f == null) return null;
      final contenu = f.content as List<int>;
      return utf8.decode(contenu, allowMalformed: true);
    }

    // 1. Textes partagés (la plupart des textes y sont stockés)
    final partages = <String>[];
    final xmlPartages = lire('xl/sharedStrings.xml');
    if (xmlPartages != null) {
      final doc = XmlDocument.parse(xmlPartages);
      for (final si in _elements(doc, 'si')) {
        partages.add(_texteSansPhonetique(si));
      }
    }

    // 2. Chemin de la première feuille
    final xmlFeuille = lire(_cheminPremiereFeuille(archive, lire));
    if (xmlFeuille == null) return [];
    final doc = XmlDocument.parse(xmlFeuille);

    // 3. Lignes et cellules
    final lignes = <List<dynamic>>[];
    var numeroLigneAttendu = 1;
    for (final row in _elements(doc, 'row')) {
      final rAttr = int.tryParse(row.getAttribute('r') ?? '');
      final numero = rAttr ?? numeroLigneAttendu;
      // Lignes vides sautées par le fichier : on les remet pour garder la numérotation
      while (lignes.length < numero - 1) {
        lignes.add(<dynamic>[]);
      }
      numeroLigneAttendu = numero + 1;

      final cellules = <dynamic>[];
      var colonneAttendue = 0;
      for (final c in row.children.whereType<XmlElement>().where((e) => e.name.local == 'c')) {
        final col = _indexColonne(c.getAttribute('r')) ?? colonneAttendue;
        while (cellules.length < col) {
          cellules.add(null);
        }
        cellules.add(_valeurCellule(c, partages));
        colonneAttendue = col + 1;
      }
      lignes.add(cellules);
    }
    return lignes;
  }

  // ------------------------------------------------------------------

  static Iterable<XmlElement> _elements(XmlNode noeud, String nomLocal) =>
      noeud.descendants.whereType<XmlElement>().where((e) => e.name.local == nomLocal);

  /// Texte d'un <si> ou <is> sans les annotations phonétiques (<rPh>).
  static String _texteSansPhonetique(XmlElement e) {
    final buffer = StringBuffer();
    for (final t in _elements(e, 't')) {
      final dansPhonetique = t.ancestors
          .whereType<XmlElement>()
          .any((a) => a.name.local == 'rPh');
      if (!dansPhonetique) buffer.write(t.innerText);
    }
    return buffer.toString();
  }

  static String _cheminPremiereFeuille(Archive archive, String? Function(String) lire) {
    try {
      final workbook = lire('xl/workbook.xml');
      final rels = lire('xl/_rels/workbook.xml.rels');
      if (workbook != null && rels != null) {
        final sheet = _elements(XmlDocument.parse(workbook), 'sheet').first;
        final rid = sheet.attributes
            .firstWhere((a) => a.name.local == 'id')
            .value;
        final rel = _elements(XmlDocument.parse(rels), 'Relationship')
            .firstWhere((r) => r.getAttribute('Id') == rid);
        var cible = rel.getAttribute('Target') ?? '';
        if (cible.startsWith('/')) {
          cible = cible.substring(1);
        } else {
          cible = 'xl/$cible';
        }
        if (archive.findFile(cible) != null) return cible;
      }
    } catch (_) {
      // on tente le chemin habituel ci-dessous
    }
    if (archive.findFile('xl/worksheets/sheet1.xml') != null) {
      return 'xl/worksheets/sheet1.xml';
    }
    final feuilles = archive.files
        .map((f) => f.name)
        .where((n) => n.startsWith('xl/worksheets/') && n.endsWith('.xml'))
        .toList()
      ..sort();
    return feuilles.isEmpty ? '' : feuilles.first;
  }

  /// « B12 » -> 1 (colonne B = index 1)
  static int? _indexColonne(String? reference) {
    if (reference == null) return null;
    final lettres = RegExp(r'^[A-Za-z]+').stringMatch(reference);
    if (lettres == null) return null;
    var index = 0;
    for (final code in lettres.toUpperCase().codeUnits) {
      index = index * 26 + (code - 64);
    }
    return index - 1;
  }

  static dynamic _valeurCellule(XmlElement c, List<String> partages) {
    final type = c.getAttribute('t');
    final v = _elements(c, 'v').map((e) => e.innerText).firstOrNull;

    switch (type) {
      case 's':
        final i = int.tryParse(v ?? '');
        return (i != null && i >= 0 && i < partages.length) ? partages[i] : '';
      case 'inlineStr':
        final isElement = _elements(c, 'is').firstOrNull;
        return isElement == null ? '' : _texteSansPhonetique(isElement);
      case 'str':
        return v ?? '';
      case 'b':
        return v == '1';
      case 'e':
        return null;
      default:
        if (v == null || v.trim().isEmpty) return null;
        final entier = int.tryParse(v.trim());
        if (entier != null) return entier;
        final decimal = double.tryParse(v.trim());
        if (decimal == null) return v;
        // 12.000000001 -> 12 ; 10.5 reste 10.5
        if ((decimal - decimal.roundToDouble()).abs() < 1e-9) return decimal.round();
        return decimal;
    }
  }
}
