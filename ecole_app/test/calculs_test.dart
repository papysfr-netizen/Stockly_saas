import 'package:ecole_app/core/evaluation.dart';
import 'package:ecole_app/models/classe.dart';
import 'package:ecole_app/models/scolarite.dart';
import 'package:ecole_app/services/calculs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  const rdc = SystemeEvaluation.rdc;
  const francais = Matiere(id: 'fr', classeId: 'c', nom: 'Français', maxima: 20);
  const calcul = Matiere(id: 'ca', classeId: 'c', nom: 'Calcul', maxima: 10);
  const matieres = [francais, calcul];

  Note n(String eleve, Matiere m, String periode, double v) {
    final p = periodesPour(rdc, Cycle.primaire).firstWhere((p) => p.code == periode);
    return Note(id: '', eleveId: eleve, classeId: 'c', matiereId: m.id, periode: periode, valeur: v, sur: m.maximaPour(p));
  }

  // Élève a : 96 / 120 au 1er semestre ; élève b : 54 / 120.
  final ev = Evaluations([
    n('a', francais, 'P1', 15), n('a', francais, 'P2', 16), n('a', francais, 'EX1', 30),
    n('a', calcul, 'P1', 8), n('a', calcul, 'P2', 9), n('a', calcul, 'EX1', 18),
    n('b', francais, 'P1', 10), n('b', francais, 'P2', 8), n('b', francais, 'EX1', 18),
    n('b', calcul, 'P1', 4), n('b', calcul, 'P2', 5), n('b', calcul, 'EX1', 9),
  ]);
  const s1 = ['P1', 'P2', 'EX1'];

  group('RD Congo', () {
    test("l'examen est noté sur le double du maxima", () {
      final ex = periodesPour(rdc, Cycle.primaire).firstWhere((p) => p.examen);
      expect(calcul.maximaPour(ex), 20);
      expect(ev.de('a', francais.id, 'EX1')?.sur, 40);
    });

    test('périodes et regroupements', () {
      expect(periodesPour(rdc, Cycle.primaire).map((p) => p.code), ['P1', 'P2', 'EX1', 'P3', 'P4', 'EX2']);
      expect(periodesPour(rdc, Cycle.maternelle).map((p) => p.code), ['P1', 'P2', 'P3', 'P4']);
      expect(vuesPour(rdc, Cycle.secondaire).map((v) => v.label),
          containsAllInOrder(['1re période', '1er semestre', '2e semestre', 'Année (total général)']));
    });

    test('totaux et pourcentage du semestre', () {
      expect(ev.total('a', francais.id, s1), (points: 61.0, maxima: 80.0));
      expect(scoreEleve(systeme: rdc, eleveId: 'a', matieres: matieres, codes: s1, ev: ev), 80);
      expect(scoreEleve(systeme: rdc, eleveId: 'b', matieres: matieres, codes: s1, ev: ev), 45);
      expect(scoreEleve(systeme: rdc, eleveId: 'a', matieres: matieres, codes: ['P1'], ev: ev),
          closeTo(23 * 100 / 30, 1e-9));
      expect(scoreEleve(systeme: rdc, eleveId: 'a', matieres: matieres, codes: ['P3'], ev: ev), isNull);
      expect(formatScore(rdc, 80), '80,0 %');
    });

    test('places dans la classe', () {
      final r = resultatsClasse(systeme: rdc, eleveIds: ['a', 'b', 'c'], matieres: matieres, codes: s1, ev: ev);
      expect(r.rangs, {'a': 1, 'b': 2, 'c': null});
      expect(r.moyenne, 62.5);
    });

    test('branches en échec et décision proposée', () {
      expect(branchesEchouees(systeme: rdc, eleveId: 'a', matieres: matieres, codes: s1, ev: ev), isEmpty);
      expect(branchesEchouees(systeme: rdc, eleveId: 'b', matieres: matieres, codes: s1, ev: ev).map((m) => m.nom),
          ['Français', 'Calcul']);
      expect(decisionProposee(rdc, 80, 0), 'Admis(e) en classe supérieure');
      expect(decisionProposee(rdc, 55, 1), 'Seconde session (1 branche)');
      expect(decisionProposee(rdc, 45, 2), 'Ajourné(e)');
      expect(decisionProposee(rdc, null, 0), '-');
    });
  });

  test('ex æquo', () {
    expect(classer({'a': 70, 'b': 80, 'c': 70, 'd': 60, 'e': null}), {'a': 2, 'b': 1, 'c': 2, 'd': 4, 'e': null});
  });

  test('trimestres : moyenne sur 20 pondérée', () {
    const t = SystemeEvaluation.trimestres;
    const maths = Matiere(id: 'm', classeId: 'c', nom: 'Maths', coefficient: 3);
    const fr = Matiere(id: 'f', classeId: 'c', nom: 'Français', coefficient: 2);
    const sport = Matiere(id: 's', classeId: 'c', nom: 'Sport', coefficient: 1);
    Note nt(String m, double v, {double sur = 20}) =>
        Note(id: '', eleveId: 'a', classeId: 'c', matiereId: m, periode: 'T1', valeur: v, sur: sur);
    final evt = Evaluations([nt('m', 12), nt('f', 15), nt('s', 9, sur: 10)]);
    expect(scoreEleve(systeme: t, eleveId: 'a', matieres: [maths, fr, sport], codes: ['T1'], ev: evt),
        closeTo((12 * 3 + 15 * 2 + 18) / 6, 1e-9));
    expect(appreciation(14), 'Très bien');
  });

  test('reste à payer', () {
    Paiement p(double m) => Paiement(id: '', eleveId: 'a', classeId: 'c', montant: m, date: DateTime(2026));
    expect(resteAPayer(300, [p(100), p(50.5)]), 149.5);
    expect(resteAPayer(100, [p(120)]), 0);
  });
}
