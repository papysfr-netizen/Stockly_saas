import 'dart:io';

import 'package:ecole_app/core/evaluation.dart';
import 'package:ecole_app/models/classe.dart';
import 'package:ecole_app/models/ecole.dart';
import 'package:ecole_app/models/eleve.dart';
import 'package:ecole_app/models/scolarite.dart';
import 'package:ecole_app/services/calculs.dart';
import 'package:ecole_app/services/excel_export.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

/// Avec EXPORT_DIR=<dossier>, les classeurs générés y sont écrits.
void main() {
  const ecole = Ecole(id: 'e', nom: 'CS Les Bâtisseurs', anneeScolaire: '2026-2027', devise: 'USD');
  const classe = Classe(id: 'c', nom: '5e A', cycle: Cycle.primaire, fraisScolarite: 300);
  const fr = Matiere(id: 'fr', classeId: 'c', nom: 'Français', maxima: 20);
  const ca = Matiere(id: 'ca', classeId: 'c', nom: 'Calcul', maxima: 10);
  const eleves = [
    Eleve(id: 'a', matricule: 'EL-1', nom: 'MBUYI', prenom: 'Grâce', classeId: 'c', parentNom: 'M. Mbuyi', parentTelephone: '0812345678'),
    Eleve(id: 'b', matricule: 'EL-2', nom: 'KABEYA', prenom: 'Jean', classeId: 'c'),
  ];

  Note n(String e, Matiere m, String p, double v) =>
      Note(id: '', eleveId: e, classeId: 'c', matiereId: m.id, periode: p, valeur: v, sur: p.startsWith('EX') ? m.maxima * 2 : m.maxima);

  void ecrire(String nom, List<int> octets) {
    final dir = Platform.environment['EXPORT_DIR'];
    if (dir != null) File('$dir/$nom.xlsx').writeAsBytesSync(octets);
  }

  List<String> ligne(Sheet s, int i) => [for (final c in s.rows[i]) c?.value?.toString() ?? ''];

  test('export des notes (palmarès + détail)', () {
    final octets = exporterNotes(
      ecole: ecole,
      classe: classe,
      matieres: const [fr, ca],
      eleves: eleves,
      ev: Evaluations([
        n('a', fr, 'P1', 15), n('a', ca, 'P1', 8), n('a', fr, 'P2', 16), n('a', ca, 'P2', 9), n('a', fr, 'EX1', 30), n('a', ca, 'EX1', 18),
        n('b', fr, 'P1', 10), n('b', ca, 'P1', 4), n('b', fr, 'P2', 8), n('b', ca, 'P2', 5), n('b', fr, 'EX1', 18), n('b', ca, 'EX1', 9),
      ]),
      comportements: const [Comportement('a', 'P1', 'Très bon', 'Élite')],
    );
    ecrire('notes_5eA', octets);
    final x = Excel.decodeBytes(octets);
    expect(x.tables.keys, containsAll(['Palmarès', 'P1', 'P2', 'EX1', 'Total S1', 'Total général']));
    expect(x.tables.keys, isNot(contains('P3'))); // période sans notes : pas de feuille
    expect(x.tables.keys, isNot(contains('Sheet1')));

    final palmares = x.tables['Palmarès']!;
    expect(ligne(palmares, 2), ['Place (T.G.)', 'Matricule', 'Nom et prénom', '% P1', '% P2', '% EX1', '% TOT. S1', '% T.G.']);
    expect(ligne(palmares, 3).take(3), ['1', 'EL-1', 'MBUYI Grâce']);
    expect(double.parse(ligne(palmares, 3)[6]), 80); // 96 / 120
    expect(ligne(palmares, 4).take(3), ['2', 'EL-2', 'KABEYA Jean']);

    final p1 = x.tables['P1']!;
    expect(ligne(p1, 2), ['N°', 'Matricule', 'Nom et prénom', 'Français (/20)', 'Calcul (/10)', 'Total', 'Maxima', 'Pourcentage', 'Place', 'Application', 'Conduite']);
    // Ordre alphabétique : KABEYA puis MBUYI.
    expect(ligne(p1, 3).take(5), ['1', 'EL-2', 'KABEYA Jean', '10', '4']);
    expect(ligne(p1, 4), ['2', 'EL-1', 'MBUYI Grâce', '15', '8', '23', '30', '76.67', '1', 'Très bon', 'Élite']);

    final s1 = x.tables['Total S1']!;
    expect(ligne(s1, 2)[3], 'Français (/80)'); // 20 + 20 + 40
    expect(ligne(x.tables['EX1']!, 2).contains('Conduite'), isFalse);
  });

  test('export des notes en maternelle (cotes)', () {
    const mat = Classe(id: 'c', nom: '3e maternelle', cycle: Cycle.maternelle);
    final octets = exporterNotes(
      ecole: ecole,
      classe: mat,
      matieres: const [Matiere(id: 'la', classeId: 'c', nom: 'Langage')],
      eleves: eleves,
      ev: Evaluations([const Note(id: '', eleveId: 'a', classeId: 'c', matiereId: 'la', periode: 'P1', cote: 'ECA', sur: 0)]),
      comportements: const [],
    );
    final x = Excel.decodeBytes(octets);
    expect(x.tables.keys.toList(), ['P1']);
    expect(ligne(x.tables['P1']!, 5).take(4), ['2', 'EL-1', 'MBUYI Grâce', 'ECA']);
  });

  test('export des impayés', () {
    final octets = exporterFinances(
      ecole: ecole,
      classes: const [classe],
      eleves: eleves,
      paiements: [
        Paiement(id: '1', eleveId: 'a', classeId: 'c', montant: 100, date: DateTime(2026, 10, 5), recuNumero: 'R2026-00001', motif: 'Minerval — 1re tranche'),
        Paiement(id: '2', eleveId: 'b', classeId: 'c', montant: 300, date: DateTime(2026, 9, 15), recuNumero: 'R2026-00002'),
      ],
      derniersRappels: {'a': DateTime(2026, 11, 20)},
      maintenant: DateTime(2026, 11, 27),
    );
    ecrire('finances', octets);
    final x = Excel.decodeBytes(octets);
    expect(x.tables.keys, containsAll(['Impayés', 'Par classe', 'Encaissements']));

    final imp = x.tables['Impayés']!;
    expect(ligne(imp, 0).first, contains('27/11/2026'));
    expect(ligne(imp, 3).take(8), ['5e A', 'EL-1', 'MBUYI Grâce', 'M. Mbuyi', '0812345678', '300', '100', '200']);
    expect(ligne(imp, 3)[8], startsWith('2026-11-20'));
    expect(ligne(imp, 5)[7], '200'); // total ; l'élève soldé n'apparaît pas

    final pc = x.tables['Par classe']!;
    expect(ligne(pc, 3), ['5e A', '2', '600', '400', '200', '66.67', '1']);

    final enc = x.tables['Encaissements']!;
    expect(ligne(enc, 3)[1], 'R2026-00001'); // le plus récent d'abord
    expect(ligne(enc, 6)[7], '400');
  });
}
