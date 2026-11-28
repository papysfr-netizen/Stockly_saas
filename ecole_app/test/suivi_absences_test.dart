import 'package:ecole_app/models/absence_eleve.dart';
import 'package:ecole_app/models/scolarite.dart';
import 'package:ecole_app/services/suivi_absences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AbsenceEleve a(String eleve, DateTime d, {bool justifiee = false, StatutPresence s = StatutPresence.absent}) =>
      AbsenceEleve(id: '$eleve$d', eleveId: eleve, classeId: 'c', date: d, statut: s, justifiee: justifiee);
  final now = DateTime(2026, 11, 30);

  test('élèves à suivre : seuil, justifiées et retards exclus, fenêtre de 30 jours', () {
    final liste = [
      a('jean', DateTime(2026, 11, 3)), a('jean', DateTime(2026, 11, 12)), a('jean', DateTime(2026, 11, 27)),
      a('ruth', DateTime(2026, 11, 10)), a('ruth', DateTime(2026, 11, 11)),
      a('ruth', DateTime(2026, 11, 12), justifiee: true), // justifiée : ne compte pas
      a('ruth', DateTime(2026, 11, 13), s: StatutPresence.retard), // retard : ne compte pas
      a('david', DateTime(2026, 10, 2)), a('david', DateTime(2026, 10, 3)), a('david', DateTime(2026, 11, 20)), // 2 hors fenêtre
      a('sarah', DateTime(2026, 11, 2)), a('sarah', DateTime(2026, 11, 5)), a('sarah', DateTime(2026, 11, 6)), a('sarah', DateTime(2026, 11, 9)),
    ];
    final r = elevesASuivre(liste, seuil: 3, maintenant: now);
    expect(r.map((x) => (x.eleveId, x.absences)), [('sarah', 4), ('jean', 3)]);
    expect(r[1].derniere, DateTime(2026, 11, 27));
    expect(elevesASuivre(liste, seuil: 2, maintenant: now).map((x) => x.eleveId), ['sarah', 'jean', 'ruth']);
  });

  test('bilan et filtre par mois', () {
    final liste = [
      a('x', DateTime(2026, 10, 5)),
      a('x', DateTime(2026, 11, 5), justifiee: true),
      a('x', DateTime(2026, 11, 6)),
      a('x', DateTime(2026, 11, 7), s: StatutPresence.retard),
    ];
    expect(bilan(liste), (absences: 3, nonJustifiees: 2, retards: 1));
    expect(bilan(duMois(liste, DateTime(2026, 11))), (absences: 2, nonJustifiees: 1, retards: 1));
    expect(duMois(liste, null).length, 4);
  });

  test("état de l'alerte et justification en attente", () {
    final x = AbsenceEleve(id: '1', eleveId: 'e', classeId: 'c', date: now, statut: StatutPresence.absent,
        alerte: (statut: 'envoye', canal: 'sms', erreur: ''), justificationParent: (motif: 'Maladie', message: 'Fièvre'));
    expect(x.etatAlerte, 'Parent prévenu par SMS');
    expect(x.enAttente, isTrue);
  });

  test('message au parent (identique à la fonction serveur)', () {
    expect(
      messageAbsenceParent(parent: 'M. Kabeya', eleve: 'KABEYA Jean', classe: '5e année A', date: DateTime(2026, 11, 30), ecole: 'CS La Référence'),
      "Bonjour M. Kabeya, KABEYA Jean (5e année A) est noté(e) absent(e) le lundi 30/11. Merci de contacter l'école ou de justifier l'absence. — CS La Référence",
    );
  });
}
