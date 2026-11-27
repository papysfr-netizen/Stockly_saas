import 'package:ecole_app/models/emploi_du_temps.dart';
import 'package:ecole_app/services/emploi_du_temps.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Creneau c(String classe, int jour, String plage, {String? prof, String salle = '', String matiere = 'fr'}) =>
      Creneau(id: '$classe$jour$plage', classeId: classe, jour: jour, plage: plage, matiereId: matiere, enseignantId: prof, salle: salle);

  test('lecture et normalisation des plages', () {
    expect(lirePlage('07:30-08:20'), (450, 500));
    expect(normaliserPlage('7:30 - 8:20'), '07:30-08:20');
    expect(lirePlage('08:20-07:30'), isNull);
    expect(lirePlage('25:00-26:00'), isNull);
    expect(lirePlage('n\'importe quoi'), isNull);
  });

  test('validation de la grille', () {
    final ok = validerGrille(['10:15-11:05', '07:30-08:20', '', '08:20-09:10']);
    expect(ok.erreur, isNull);
    expect(ok.plages, ['07:30-08:20', '08:20-09:10', '10:15-11:05']);
    expect(validerGrille(['07:30-08:20', '08:00-08:50']).erreur, contains('chevauchent'));
    expect(validerGrille(['7h30']).erreur, contains('invalide'));
    expect(validerGrille([]).erreur, isNotNull);
  });

  test("conflit : même enseignant au même moment dans une autre classe", () {
    final existants = [c('5A', 1, '07:30-08:20', prof: 'p1'), c('5B', 1, '08:20-09:10', prof: 'p1')];
    expect(conflits(existants, c('6A', 1, '07:30-08:20', prof: 'p1')), hasLength(1));
    expect(conflits(existants, c('6A', 1, '08:00-08:50', prof: 'p1')), hasLength(2)); // chevauche les deux
    expect(conflits(existants, c('6A', 2, '07:30-08:20', prof: 'p1')), isEmpty); // autre jour
    expect(conflits(existants, c('6A', 1, '07:30-08:20', prof: 'p2')), isEmpty); // autre enseignant
    expect(conflits(existants, c('5A', 1, '07:30-08:20', prof: 'p1')), isEmpty); // même classe : remplacement
  });

  test('conflit : même salle', () {
    final existants = [c('5A', 3, '07:30-08:20', salle: 'Labo')];
    expect(conflits(existants, c('6A', 3, '07:30-08:20', salle: 'labo ')), hasLength(1));
    expect(conflits(existants, c('6A', 3, '07:30-08:20')), isEmpty); // pas de salle indiquée
  });

  test('volume horaire', () {
    final cr = [
      c('5A', 1, '07:30-08:20', prof: 'p1', matiere: 'fr'),
      c('5A', 2, '07:30-08:20', prof: 'p1', matiere: 'fr'),
      c('5A', 3, '10:15-11:05', prof: 'p2', matiere: 'ma'),
    ];
    expect(volumeHoraire(cr, (x) => x.matiereId), {'fr': 100, 'ma': 50});
    expect(volumeHoraire(cr, (x) => x.enseignantId), {'p1': 100, 'p2': 50});
    expect(formatDuree(100), '1 h 40');
    expect(formatDuree(120), '2 h');
  });

  test('identifiant de créneau', () {
    expect(Creneau.docId('5A', 1, '07:30-08:20'), '5A_1_0730-0820');
  });
}
