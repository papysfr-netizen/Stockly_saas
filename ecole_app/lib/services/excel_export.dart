import 'package:excel/excel.dart';

import '../core/evaluation.dart';
import '../models/classe.dart';
import '../models/ecole.dart';
import '../models/eleve.dart';
import '../models/scolarite.dart';
import 'calculs.dart';

/// Construction des classeurs Excel (.xlsx). Les nombres sont de vraies
/// valeurs numériques : on peut trier, filtrer et calculer dans Excel.

final _entete = CellStyle(bold: true, backgroundColorHex: ExcelColor.fromHexString('#D9E2F3'));
final _gras = CellStyle(bold: true);

CellValue? _n(double? v) => v == null ? null : DoubleCellValue(double.parse(v.toStringAsFixed(2)));
CellValue _t(String s) => TextCellValue(s);

class _Feuille {
  _Feuille(this.sheet);
  final Sheet sheet;
  int _ligne = 0;

  void titre(String texte) {
    sheet.appendRow([_t(texte)]);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: _ligne++)).cellStyle = _gras;
  }

  void vide() {
    sheet.appendRow([null]);
    _ligne++;
  }

  void entete(List<String> colonnes, {List<double>? largeurs}) {
    sheet.appendRow([for (final c in colonnes) _t(c)]);
    for (var i = 0; i < colonnes.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: _ligne)).cellStyle = _entete;
      sheet.setColumnWidth(i, largeurs != null && i < largeurs.length ? largeurs[i] : 14);
    }
    _ligne++;
  }

  void ligne(List<CellValue?> valeurs, {bool gras = false}) {
    sheet.appendRow(valeurs);
    if (gras) {
      for (var i = 0; i < valeurs.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: _ligne)).cellStyle = _gras;
      }
    }
    _ligne++;
  }
}

/// Nom de feuille Excel valide (31 caractères, sans : \ / ? * [ ]).
String _nomFeuille(String titre) => switch (titre) {
      'TOT. S1' => 'Total S1',
      'TOT. S2' => 'Total S2',
      'T.G.' => 'Total général',
      _ => titre,
    }
        .replaceAll(RegExp(r'[:\\/?*\[\]]'), '-');

Excel _classeur() => Excel.createExcel();

List<int> _encoder(Excel x, String premiere) {
  x.setDefaultSheet(premiere);
  if (x.sheets.containsKey('Sheet1') && premiere != 'Sheet1') x.delete('Sheet1');
  return x.encode()!;
}

// ===================================================================
// Notes d'une classe : palmarès + une feuille par colonne de résultats
// ===================================================================
List<int> exporterNotes({
  required Ecole ecole,
  required Classe classe,
  required List<Matiere> matieres,
  required List<Eleve> eleves,
  required Evaluations ev,
  required List<Comportement> comportements,
}) {
  final s = ecole.systeme;
  final maternelle = classe.cycle == Cycle.maternelle;
  final colonnes = colonnesResultats(s, classe.cycle);
  final ids = [for (final e in eleves) e.id];
  final alpha = [...eleves]..sort((a, b) => a.nomComplet.compareTo(b.nomComplet));
  final comp = {for (final c in comportements) '${c.eleveId}|${c.periode}': c};
  final x = _classeur();
  final intitule = '${ecole.nom} — ${classe.nom}${classe.section.isEmpty ? '' : ' (${classe.section})'} — ${ecole.anneeScolaire}';

  bool aDesNotes(List<String> codes) => eleves.any((e) => matieres.any((m) => codes.any((c) => ev.de(e.id, m.id, c) != null)));
  final utiles = colonnes.where((c) => aDesNotes(c.codes)).toList();

  // ---- Palmarès (synthèse)
  String? premiere;
  if (!maternelle && utiles.isNotEmpty) {
    premiere = 'Palmarès';
    final f = _Feuille(x[premiere]);
    final res = {
      for (final c in utiles) c.titre: resultatsClasse(systeme: s, eleveIds: ids, matieres: matieres, codes: c.codes, ev: ev),
    };
    final derniere = utiles.last;
    final annee = colonnes.last;
    final anneeComplete = eleves.any((e) => matieres.any((m) => ev.de(e.id, m.id, periodesPour(s, classe.cycle).last.code) != null));
    f.titre('Palmarès — $intitule');
    f.vide();
    f.entete([
      'Place (${derniere.titre})',
      'Matricule',
      'Nom et prénom',
      for (final c in utiles) s == SystemeEvaluation.rdc ? '% ${c.titre}' : 'Moy. ${c.titre}',
      if (anneeComplete) 'Décision proposée',
    ], largeurs: [12, 16, 30]);
    final tries = [...eleves]
      ..sort((a, b) => (res[derniere.titre]!.rangs[a.id] ?? 9999).compareTo(res[derniere.titre]!.rangs[b.id] ?? 9999));
    for (final e in tries) {
      final echecs = branchesEchouees(systeme: s, eleveId: e.id, matieres: matieres, codes: annee.codes, ev: ev);
      f.ligne([
        if (res[derniere.titre]!.rangs[e.id] case final r?) IntCellValue(r) else null,
        _t(e.matricule),
        _t(e.nomComplet),
        for (final c in utiles) _n(res[c.titre]!.scores[e.id]),
        if (anneeComplete)
          _t(decisionProposee(s, scoreEleve(systeme: s, eleveId: e.id, matieres: matieres, codes: annee.codes, ev: ev), echecs.length)),
      ]);
    }
    f.vide();
    f.ligne([null, null, _t('Moyenne de la classe'), for (final c in utiles) _n(res[c.titre]!.moyenne)], gras: true);
    f.ligne([
      null,
      null,
      _t('Élèves en réussite'),
      for (final c in utiles)
        IntCellValue(res[c.titre]!.scores.values.whereType<double>().where((v) => v >= seuilReussite(s)).length),
    ], gras: true);
  }

  // ---- Détail par colonne (points par branche)
  for (final c in utiles) {
    final nom = _nomFeuille(c.titre);
    premiere ??= nom;
    final f = _Feuille(x[nom]);
    final periode = c.codes.length == 1 ? c.codes.single : null;
    final avecComportement = periode != null && !(periodesPour(s, classe.cycle).firstWhere((p) => p.code == periode).examen);
    final res = maternelle ? null : resultatsClasse(systeme: s, eleveIds: ids, matieres: matieres, codes: c.codes, ev: ev);

    String enTeteBranche(Matiere m) {
      if (maternelle) return m.nom;
      if (s == SystemeEvaluation.trimestres) return '${m.nom} (coef. ${formatPoints(m.coefficient)})';
      final max = c.codes.fold<double>(
          0, (t, code) => t + m.maximaPour(periodesPour(s, classe.cycle).firstWhere((p) => p.code == code)));
      return '${m.nom} (/${formatPoints(max)})';
    }

    f.titre('${c.total ? c.titre : periodesPour(s, classe.cycle).firstWhere((p) => p.code == periode).label} — $intitule');
    if (maternelle) f.titre('Cotes : ${cotesMaternelle.map((x) => '${x.$1} = ${x.$2}').join(' · ')}');
    f.vide();
    f.entete([
      'N°',
      'Matricule',
      'Nom et prénom',
      for (final m in matieres) enTeteBranche(m),
      if (!maternelle && s == SystemeEvaluation.rdc) ...['Total', 'Maxima', 'Pourcentage'],
      if (!maternelle && s == SystemeEvaluation.trimestres) 'Moyenne /20',
      if (!maternelle) 'Place',
      if (avecComportement) ...['Application', 'Conduite'],
    ], largeurs: [6, 16, 30]);

    for (final (i, e) in alpha.indexed) {
      double? total, maxima;
      final cellules = <CellValue?>[];
      for (final m in matieres) {
        if (maternelle) {
          final cote = ev.de(e.id, m.id, periode!)?.cote;
          cellules.add(cote == null ? null : _t(cote));
        } else if (s == SystemeEvaluation.trimestres) {
          cellules.add(_n(scoreEleve(systeme: s, eleveId: e.id, matieres: [m], codes: c.codes, ev: ev)));
        } else {
          final t = ev.total(e.id, m.id, c.codes);
          cellules.add(_n(t?.points));
          if (t != null) {
            total = (total ?? 0) + t.points;
            maxima = (maxima ?? 0) + t.maxima;
          }
        }
      }
      final co = periode == null ? null : comp['${e.id}|$periode'];
      f.ligne([
        IntCellValue(i + 1),
        _t(e.matricule),
        _t(e.nomComplet),
        ...cellules,
        if (!maternelle && s == SystemeEvaluation.rdc) ...[_n(total), _n(maxima), _n(res!.scores[e.id])],
        if (!maternelle && s == SystemeEvaluation.trimestres) _n(res!.scores[e.id]),
        if (!maternelle) res!.rangs[e.id] == null ? null : IntCellValue(res.rangs[e.id]!),
        if (avecComportement) ...[_t(co?.application ?? ''), _t(co?.conduite ?? '')],
      ]);
    }
  }

  if (premiere == null) {
    premiere = 'Notes';
    _Feuille(x[premiere]).titre('Aucune note saisie — $intitule');
  }
  return _encoder(x, premiere);
}

// ===================================================================
// Finances : impayés, situation par classe, encaissements
// ===================================================================
List<int> exporterFinances({
  required Ecole ecole,
  required List<Classe> classes,
  required List<Eleve> eleves,
  required List<Paiement> paiements,
  required Map<String, DateTime> derniersRappels,
  DateTime? maintenant,
}) {
  final x = _classeur();
  final classeParId = {for (final c in classes) c.id: c};
  final eleveParId = {for (final e in eleves) e.id: e};
  final parEleve = <String, List<Paiement>>{};
  for (final p in paiements) {
    parEleve.putIfAbsent(p.eleveId, () => []).add(p);
  }
  double paye(String id) => (parEleve[id] ?? const []).fold(0, (s, p) => s + p.montant);
  final devise = ecole.devise;
  final date = maintenant ?? DateTime.now();
  final dateTexte = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  // ---- Impayés
  final f = _Feuille(x['Impayés']);
  f.titre('Impayés au $dateTexte — ${ecole.nom} — ${ecole.anneeScolaire} (montants en $devise)');
  f.vide();
  f.entete(
    ['Classe', 'Matricule', 'Élève', 'Parent', 'Téléphone', 'Frais annuels', 'Payé', 'Reste à payer', 'Dernier rappel'],
    largeurs: [14, 16, 28, 24, 18, 14, 14, 14, 14],
  );
  final impayes = [
    for (final e in eleves)
      if (resteAPayer(classeParId[e.classeId]?.fraisScolarite ?? 0, parEleve[e.id] ?? const []) > 0) e,
  ]..sort((a, b) {
      final c = (classeParId[a.classeId]?.nom ?? '').compareTo(classeParId[b.classeId]?.nom ?? '');
      return c != 0 ? c : a.nomComplet.compareTo(b.nomComplet);
    });
  double totalReste = 0;
  for (final e in impayes) {
    final frais = classeParId[e.classeId]?.fraisScolarite ?? 0;
    final reste = resteAPayer(frais, parEleve[e.id] ?? const []);
    totalReste += reste;
    f.ligne([
      _t(classeParId[e.classeId]?.nom ?? ''),
      _t(e.matricule),
      _t(e.nomComplet),
      _t(e.parentNom),
      _t(e.parentTelephone),
      _n(frais),
      _n(paye(e.id)),
      _n(reste),
      if (derniersRappels[e.id] case final d?) DateCellValue.fromDateTime(d) else null,
    ]);
  }
  f.vide();
  f.ligne([_t('TOTAL'), null, _t('${impayes.length} élève(s)'), null, null, null, null, _n(totalReste)], gras: true);

  // ---- Situation par classe
  final g = _Feuille(x['Par classe']);
  g.titre('Recouvrement par classe au $dateTexte (montants en $devise)');
  g.vide();
  g.entete(['Classe', 'Effectif', 'Montant attendu', 'Encaissé', 'Reste à recouvrer', 'Taux de recouvrement (%)', 'Élèves en retard'],
      largeurs: [18, 10, 16, 14, 18, 22, 16]);
  double tAtt = 0, tEnc = 0, tRes = 0;
  var tEff = 0, tRet = 0;
  for (final c in [...classes]..sort((a, b) => a.nom.compareTo(b.nom))) {
    final dans = eleves.where((e) => e.classeId == c.id).toList();
    final attendu = c.fraisScolarite * dans.length;
    final encaisse = dans.fold<double>(0, (s, e) => s + paye(e.id));
    final reste = dans.fold<double>(0, (s, e) => s + resteAPayer(c.fraisScolarite, parEleve[e.id] ?? const []));
    final retard = dans.where((e) => resteAPayer(c.fraisScolarite, parEleve[e.id] ?? const []) > 0).length;
    tAtt += attendu;
    tEnc += encaisse;
    tRes += reste;
    tEff += dans.length;
    tRet += retard;
    g.ligne([
      _t(c.nom),
      IntCellValue(dans.length),
      _n(attendu),
      _n(encaisse),
      _n(reste),
      _n(attendu == 0 ? null : (attendu - reste) * 100 / attendu),
      IntCellValue(retard),
    ]);
  }
  g.vide();
  g.ligne([
    _t('TOTAL'),
    IntCellValue(tEff),
    _n(tAtt),
    _n(tEnc),
    _n(tRes),
    _n(tAtt == 0 ? null : (tAtt - tRes) * 100 / tAtt),
    IntCellValue(tRet),
  ], gras: true);

  // ---- Encaissements
  final h = _Feuille(x['Encaissements']);
  h.titre('Journal des encaissements — ${ecole.nom} (montants en $devise)');
  h.vide();
  h.entete(['Date', 'N° reçu', 'Matricule', 'Élève', 'Classe', 'Motif', 'Mode', 'Montant', 'Encaissé par'],
      largeurs: [12, 16, 16, 28, 14, 28, 16, 12, 20]);
  final tries = [...paiements]..sort((a, b) => b.date.compareTo(a.date));
  for (final p in tries) {
    final e = eleveParId[p.eleveId];
    h.ligne([
      DateCellValue.fromDateTime(p.date),
      _t(p.recuNumero),
      _t(e?.matricule ?? ''),
      _t(e?.nomComplet ?? 'Élève retiré'),
      _t(classeParId[p.classeId]?.nom ?? ''),
      _t(p.motif),
      _t(p.mode),
      _n(p.montant),
      _t(p.encaissePar),
    ]);
  }
  h.vide();
  h.ligne([_t('TOTAL'), null, null, _t('${paiements.length} paiement(s)'), null, null, null,
      _n(paiements.fold<double>(0, (s, p) => s + p.montant))], gras: true);

  return _encoder(x, 'Impayés');
}
