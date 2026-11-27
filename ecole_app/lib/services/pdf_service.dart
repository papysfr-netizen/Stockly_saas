import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/format.dart';
import '../models/classe.dart';
import '../models/ecole.dart';
import '../models/eleve.dart';
import '../models/scolarite.dart';
import 'calculs.dart';

class PdfService {
  static pw.Widget _entete(Ecole ecole, String titre) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(ecole.nom, style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          if (ecole.adresse.isNotEmpty) pw.Text(ecole.adresse),
          if (ecole.telephone.isNotEmpty) pw.Text('Tél. : ${ecole.telephone}'),
          pw.SizedBox(height: 12),
          pw.Center(
            child: pw.Text(titre,
                style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
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
    final doc = pw.Document();
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

  static Future<Uint8List> bulletin({
    required Ecole ecole,
    required Eleve eleve,
    required Classe classe,
    required int trimestre,
    required ResultatEleve resultat,
    required int effectif,
    required double? moyenneClasse,
    required int absences,
  }) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _entete(ecole, 'BULLETIN DE NOTES — TRIMESTRE $trimestre'),
          _ligne('Élève', eleve.nomComplet),
          _ligne('Matricule', eleve.matricule),
          _ligne('Classe', '${classe.nom}  (effectif : $effectif)'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['Matière', 'Coef.', 'Note /20', 'Points', 'Appréciation'],
            data: [
              for (final l in resultat.lignes)
                [
                  l.matiere.nom,
                  l.matiere.coefficient.toStringAsFixed(0),
                  formatNote(l.note),
                  formatNote(l.points),
                  appreciation(l.note),
                ],
            ],
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignments: {
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
            },
          ),
          pw.SizedBox(height: 16),
          _ligne('Moyenne générale', '${formatNote(resultat.moyenne)} / 20', gras: true),
          _ligne('Rang', resultat.rang == null ? '-' : '${resultat.rang}e / $effectif'),
          _ligne('Moyenne de la classe', formatNote(moyenneClasse)),
          _ligne('Absences / retards', '$absences'),
          _ligne('Appréciation', appreciation(resultat.moyenne)),
          pw.Spacer(),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Le titulaire'),
            pw.Text('La direction'),
            pw.Text('Le parent'),
          ]),
        ],
      ),
    ));
    return doc.save();
  }

  static pw.Widget _ligne(String label, String valeur, {bool gras = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(children: [
          pw.SizedBox(width: 150, child: pw.Text('$label :')),
          pw.Expanded(
            child: pw.Text(valeur,
                style: gras ? const pw.TextStyle(fontWeight: pw.FontWeight.bold) : null),
          ),
        ]),
      );

  static Future<void> afficher(Uint8List bytes, String nom) =>
      Printing.layoutPdf(onLayout: (_) async => bytes, name: nom);
}
