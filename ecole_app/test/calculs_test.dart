import 'package:ecole_app/models/classe.dart';
import 'package:ecole_app/models/scolarite.dart';
import 'package:ecole_app/services/calculs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const maths = Matiere(id: 'm', classeId: 'c', nom: 'Maths', coefficient: 3);
  const francais = Matiere(id: 'f', classeId: 'c', nom: 'Français', coefficient: 2);
  const sport = Matiere(id: 's', classeId: 'c', nom: 'Sport', coefficient: 1);

  Note note(String eleve, String matiere, double v, {double sur = 20}) => Note(
      id: '', eleveId: eleve, classeId: 'c', matiereId: matiere, trimestre: 1, valeur: v, sur: sur);

  test('moyenne pondérée par les coefficients', () {
    final moy = moyennePonderee(const [
      LigneBulletin(maths, 12),
      LigneBulletin(francais, 15),
      LigneBulletin(sport, 18),
    ]);
    expect(moy, closeTo((12 * 3 + 15 * 2 + 18) / 6, 1e-9));
  });

  test('les matières sans note sont ignorées', () {
    expect(moyennePonderee(const [LigneBulletin(maths, 10), LigneBulletin(francais, null)]), 10);
    expect(moyennePonderee(const [LigneBulletin(maths, null)]), isNull);
  });

  test('une note sur 10 est ramenée sur 20', () {
    expect(note('a', 'm', 7, sur: 10).sur20, 14);
  });

  test('rangs avec ex æquo', () {
    final r = resultatsClasse(
      eleveIds: ['a', 'b', 'c', 'd'],
      matieres: [maths],
      notes: [note('a', 'm', 15), note('b', 'm', 12), note('c', 'm', 15)],
    );
    expect(r['a']!.rang, 1);
    expect(r['c']!.rang, 1);
    expect(r['b']!.rang, 3);
    expect(r['d']!.rang, isNull);
    expect(r['d']!.moyenne, isNull);
  });

  test('reste à payer', () {
    Paiement p(double m) => Paiement(id: '', eleveId: 'a', classeId: 'c', montant: m, date: DateTime(2026));
    expect(resteAPayer(100000, [p(30000), p(20000)]), 50000);
    expect(resteAPayer(100000, [p(120000)]), 0);
    expect(resteAPayer(100000, const []), 100000);
  });

  test('appréciations', () {
    expect(appreciation(17), 'Excellent');
    expect(appreciation(10), 'Passable');
    expect(appreciation(5), 'Faible');
    expect(appreciation(null), '-');
  });
}
