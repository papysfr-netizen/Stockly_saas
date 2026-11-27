import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/evaluation.dart';
import '../core/format.dart';
import '../models/classe.dart';
import '../models/ecole.dart';
import '../models/eleve.dart';
import '../models/emploi_du_temps.dart';
import '../models/scolarite.dart';
import 'calculs.dart';
import 'emploi_du_temps.dart' show nomsJours;
import 'suivi_absences.dart' show BilanAbsences;

class PdfService {
  /// Police Roboto embarquée : accents, tirets et symboles s'affichent quel que
  /// soit le texte (les polices PDF standard ne couvrent que le Latin-1).
  static Future<pw.ThemeData>? _theme;
  static Future<pw.ThemeData> _chargerTheme() => _theme ??= () async {
        final regular = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
        final bold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
        return pw.ThemeData.withFont(base: pw.Font.ttf(regular), bold: pw.Font.ttf(bold));
      }();

  static pw.Widget _entete(Ecole ecole, String titre) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(ecole.nom, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          if (ecole.adresse.isNotEmpty) pw.Text(ecole.adresse),
          if (ecole.telephone.isNotEmpty) pw.Text('Tél. : ${ecole.telephone}'),
          pw.SizedBox(height: 12),
          pw.Center(
            child: pw.Text(titre,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
          if (ecole.anneeScolaire.isNotEmpty)
            pw.Center(child: pw.Text('Année scolaire ${ecole.anneeScolaire}')),
          pw.Divider(),
        ],
      );

  static Future<Uint8List> recu({
    required Ecole ecole,
    required Paiement paiement,
    required Eleve eleve,
    required Classe? classe,
    required double resteAPayer,
  }) async {
    final doc = pw.Document(theme: await _chargerTheme());
    String m(num v) => formatMontant(v, devise: ecole.devise);
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a5,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _entete(ecole, 'REÇU DE PAIEMENT N° ${paiement.recuNumero}'),
          _ligne('Date', formatDate(paiement.date)),
          _ligne('Élève', '${eleve.nomComplet} (${eleve.matricule})'),
          _ligne('Classe', classe?.nom ?? '-'),
          _ligne('Motif', paiement.motif),
          _ligne('Mode de paiement', paiement.mode),
          pw.SizedBox(height: 8),
          _ligne('Montant versé', m(paiement.montant), gras: true),
          _ligne('Reste à payer', m(resteAPayer)),
          pw.Spacer(),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Encaissé par : ${paiement.encaissePar}'),
            pw.Text('Signature & cachet'),
          ]),
        ],
      ),
    ));
    return doc.save();
  }

  /// Bulletin annuel de l'élève, rempli avec les périodes déjà évaluées.
  static Future<Uint8List> bulletin({
    required Ecole ecole,
    required Eleve eleve,
    required Classe classe,
    required List<Matiere> matieres,
    required List<String> eleveIds,
    required Evaluations ev,
    required List<Comportement> comportements,
    required BilanAbsences absences,
  }) async {
    final systeme = ecole.systeme;
    final periodes = periodesPour(systeme, classe.cycle);
    final comp = {for (final c in comportements) c.periode: c};
    final maternelle = classe.cycle == Cycle.maternelle;

    final colonnes = colonnesResultats(systeme, classe.cycle);

    final resultats = {
      for (final c in colonnes)
        c.titre: resultatsClasse(systeme: systeme, eleveIds: eleveIds, matieres: matieres, codes: c.codes, ev: ev),
    };

    String cellule(Matiere m, List<String> codes) {
      if (maternelle) return ev.de(eleve.id, m.id, codes.single)?.cote ?? '';
      if (systeme == SystemeEvaluation.trimestres) {
        return formatNote(scoreEleve(systeme: systeme, eleveId: eleve.id, matieres: [m], codes: codes, ev: ev));
      }
      return formatPoints(ev.total(eleve.id, m.id, codes)?.points);
    }

    final enTete = [
      maternelle ? 'Domaines / branches' : 'Branches',
      if (systeme == SystemeEvaluation.rdc && !maternelle) 'Max. P',
      if (systeme == SystemeEvaluation.trimestres) 'Coef.',
      for (final c in colonnes) c.titre,
    ];
    final lignes = [
      for (final m in [...matieres]..sort((a, b) => a.maxima.compareTo(b.maxima)))
        [
          m.nom,
          if (systeme == SystemeEvaluation.rdc && !maternelle) formatPoints(m.maxima),
          if (systeme == SystemeEvaluation.trimestres) formatPoints(m.coefficient),
          for (final c in colonnes) cellule(m, c.codes),
        ],
    ];
    final vide = systeme == SystemeEvaluation.trimestres || (systeme == SystemeEvaluation.rdc && !maternelle);
    List<String> pied(String label, String Function(Colonne c) f) =>
        [label, if (vide) '', for (final c in colonnes) f(c)];

    double? sommeDe(List<String> codes, bool maxima) {
      double s = 0;
      var trouve = false;
      for (final m in matieres) {
        final t = ev.total(eleve.id, m.id, codes);
        if (t == null) continue;
        trouve = true;
        s += maxima ? t.maxima : t.points;
      }
      return trouve ? s : null;
    }

    String comportement(List<String> codes, bool application) {
      if (codes.length != 1) return '';
      final c = comp[codes.single];
      return (application ? c?.application : c?.conduite) ?? '';
    }

    final pieds = <List<String>>[
      if (systeme == SystemeEvaluation.rdc && !maternelle) ...[
        pied('MAXIMA GÉNÉRAUX', (c) => formatPoints(sommeDe(c.codes, true))),
        pied('TOTAUX', (c) => formatPoints(sommeDe(c.codes, false))),
        pied('POURCENTAGE', (c) {
          final v = resultats[c.titre]!.scores[eleve.id];
          return v == null ? '' : formatScore(systeme, v);
        }),
      ],
      if (systeme == SystemeEvaluation.trimestres)
        pied('MOYENNE GÉNÉRALE', (c) {
          final v = resultats[c.titre]!.scores[eleve.id];
          return v == null ? '' : formatNote(v);
        }),
      if (!maternelle)
        pied('PLACE', (c) {
          final r = resultats[c.titre]!.rangs[eleve.id];
          return r == null ? '' : '$r / ${eleveIds.length}';
        }),
      pied('APPLICATION', (c) => comportement(c.codes, true)),
      pied('CONDUITE', (c) => comportement(c.codes, false)),
    ];

    final annuel = colonnes.where((c) => c.total).lastOrNull;
    final derniere = periodes.last.code;
    final anneeComplete = matieres.any((m) => ev.de(eleve.id, m.id, derniere) != null);
    final echecs = annuel == null
        ? const <Matiere>[]
        : branchesEchouees(systeme: systeme, eleveId: eleve.id, matieres: matieres, codes: annuel.codes, ev: ev);

    final doc = pw.Document(theme: await _chargerTheme());
    const petit = pw.TextStyle(fontSize: 8);
    final gras = pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold);
    doc.addPage(pw.Page(
      pageFormat: maternelle ? PdfPageFormat.a4 : PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                if (systeme == SystemeEvaluation.rdc) pw.Text('RÉPUBLIQUE DÉMOCRATIQUE DU CONGO', style: gras),
                pw.Text(ecole.nom, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                if (ecole.adresse.isNotEmpty) pw.Text(ecole.adresse, style: petit),
                if (ecole.telephone.isNotEmpty) pw.Text('Tél. : ${ecole.telephone}', style: petit),
              ]),
            ),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Élève : ${eleve.nomComplet}', style: gras),
              pw.Text('Sexe : ${eleve.sexe}   Né(e) le : ${formatDate(eleve.dateNaissance)}', style: petit),
              pw.Text('Matricule : ${eleve.matricule}', style: petit),
              pw.Text('Classe : ${classe.nom}${classe.description.isEmpty ? '' : ' (${classe.description})'}', style: petit),
            ]),
          ]),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'BULLETIN ${maternelle ? 'D\'ÉVALUATION' : 'DE L\'ÉLÈVE'} — ANNÉE SCOLAIRE ${ecole.anneeScolaire}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: enTete,
            data: [...lignes, ...pieds],
            headerStyle: gras,
            cellStyle: petit,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.center,
            cellAlignments: {0: pw.Alignment.centerLeft},
            columnWidths: {0: const pw.FlexColumnWidth(4)},
            defaultColumnWidth: const pw.FlexColumnWidth(1),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            rowDecoration: const pw.BoxDecoration(),
          ),
          pw.SizedBox(height: 8),
          if (maternelle)
            pw.Text('Légende : ${cotesMaternelle.map((c) => '${c.$1} = ${c.$2}').join(' · ')}', style: petit),
          pw.Text(
            'Absences : ${absences.absences} (dont ${absences.nonJustifiees} non justifiée${absences.nonJustifiees > 1 ? 's' : ''})'
            ' · Retards : ${absences.retards}',
            style: petit,
          ),
          if (!maternelle && anneeComplete && annuel != null) ...[
            pw.Text(
              'Décision proposée : ${decisionProposee(systeme, resultats[annuel.titre]!.scores[eleve.id], echecs.length)}',
              style: gras,
            ),
            if (echecs.isNotEmpty)
              pw.Text('Branches en échec : ${echecs.map((m) => m.nom).join(', ')}', style: petit),
          ],
          pw.Spacer(),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Signature du parent', style: petit),
            pw.Text('Le titulaire', style: petit),
            pw.Text("Le chef d'établissement (sceau)", style: petit),
          ]),
        ],
      ),
    ));
    return doc.save();
  }

  /// Emploi du temps imprimable (A4 paysage) : jours en colonnes, heures en lignes.
  static Future<Uint8List> emploiDuTemps({
    required Ecole ecole,
    required String titre,
    required List<Creneau> creneaux,
    required ({String titre, String detail}) Function(Creneau c) contenu,
  }) async {
    final doc = pw.Document(theme: await _chargerTheme());
    const petit = pw.TextStyle(fontSize: 8);
    final gras = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);
    pw.Widget cellule(int jour, String plage) {
      final c = creneaux.where((x) => x.jour == jour && x.plage == plage).firstOrNull;
      if (c == null) return pw.SizedBox(height: 46);
      final t = contenu(c);
      return pw.Container(
        height: 46,
        padding: const pw.EdgeInsets.all(4),
        color: PdfColors.blue50,
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(t.titre, style: gras, maxLines: 1),
          if (t.detail.isNotEmpty) pw.Text(t.detail, style: petit, maxLines: 2),
        ]),
      );
    }

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(ecole.nom, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        if (ecole.anneeScolaire.isNotEmpty) pw.Text('Année scolaire ${ecole.anneeScolaire}', style: petit),
        pw.SizedBox(height: 8),
        pw.Center(child: pw.Text(titre, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(60),
            for (var i = 1; i <= ecole.jours.length; i++) i: const pw.FlexColumnWidth(1),
          },
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey300), children: [
              pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Heure', style: gras)),
              for (final j in ecole.jours)
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(nomsJours[j - 1], style: gras)),
            ]),
            for (final p in ecole.plagesHoraires)
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(p.replaceAll('-', ' - '), style: petit)),
                for (final j in ecole.jours) pw.Padding(padding: const pw.EdgeInsets.all(1), child: cellule(j, p)),
              ]),
          ],
        ),
      ]),
    ));
    return doc.save();
  }

  static pw.Widget _ligne(String label, String valeur, {bool gras = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(children: [
          pw.SizedBox(width: 150, child: pw.Text('$label :')),
          pw.Expanded(
            child: pw.Text(valeur,
                style: gras ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null),
          ),
        ]),
      );

  static Future<void> afficher(Uint8List bytes, String nom) =>
      Printing.layoutPdf(onLayout: (_) async => bytes, name: nom);
}
