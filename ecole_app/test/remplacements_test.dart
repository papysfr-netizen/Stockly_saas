import 'package:ecole_app/models/emploi_du_temps.dart';
import 'package:ecole_app/models/remplacement.dart';
import 'package:ecole_app/models/scolarite.dart';
import 'package:ecole_app/services/remplacements.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  Creneau c(String id, String classe, int jour, String plage, String prof, String matiere) =>
      Creneau(id: id, classeId: classe, jour: jour, plage: plage, matiereId: matiere, enseignantId: prof);
  Enseignant e(String id, String nom, {List<String> classes = const [], String specialite = ''}) =>
      Enseignant(id: id, nom: nom, prenom: '', classeIds: classes, specialite: specialite);

  // Semaine du lundi 30 novembre 2026.
  final creneaux = [
    c('k1', '5A', 1, '07:30-08:20', 'kas', 'fr5A'), // Kasongo : français en 5A le lundi
    c('k2', '5A', 1, '10:15-11:05', 'kas', 'fr5A'),
    c('k3', '6A', 2, '07:30-08:20', 'kas', 'fr6A'), // et en 6A le mardi
    c('i1', '6A', 1, '07:30-08:20', 'ilu', 'li6A'), // Ilunga occupé lundi 7:30
    c('m1', '6A', 1, '10:15-11:05', 'mbu', 'fr6A'), // Mbuyi enseigne le français, occupé lundi 10:15
    c('m2', '6B', 1, '08:20-09:10', 'mbu', 'fr6B'),
  ];
  final noms = {'fr5A': 'Français', 'fr6A': 'Français', 'fr6B': 'Français', 'li6A': 'Lingala'};
  final enseignants = [
    e('kas', 'KASONGO'),
    e('ilu', 'ILUNGA', classes: ['5A']),
    e('mbu', 'MBUYI'),
    e('tsh', 'TSHIBANDA'),
  ];
  const absence = AbsenceEnseignant(id: 'abs', enseignantId: 'kas', enseignantNom: 'KASONGO', debut: '2026-11-28', fin: '2026-12-01');

  test('jours de cours d\'une absence (week-end exclu)', () {
    final j = joursDeCours(DateTime(2026, 11, 28), DateTime(2026, 12, 1), [1, 2, 3, 4, 5]);
    expect(j, [DateTime(2026, 11, 30), DateTime(2026, 12, 1)]);
    expect(joursDeCours(DateTime(2026, 11, 28), DateTime(2026, 11, 28), [1, 2, 3, 4, 5, 6]), [DateTime(2026, 11, 28)]);
  });

  test('cours touchés par une absence', () {
    final t = coursTouches(absence: absence, creneaux: creneaux, jours: [1, 2, 3, 4, 5]);
    expect(t.map((r) => '${r.date} ${r.plage} ${r.classeId}'), [
      '2026-11-30 07:30-08:20 5A',
      '2026-11-30 10:15-11:05 5A',
      '2026-12-01 07:30-08:20 6A',
    ]);
    expect(t.first.id, '2026-11-30_k1');
    expect(t.every((r) => r.statut == StatutRemplacement.aPourvoir && r.absenceId == 'abs'), isTrue);
  });

  test('remplaçants disponibles et ordre de pertinence', () {
    final t = coursTouches(absence: absence, creneaux: creneaux, jours: [1, 2, 3, 4, 5]);
    // Lundi 7:30 : Ilunga est en cours → exclu ; Mbuyi (français) d'abord, puis Tshibanda.
    var cand = remplacantsDisponibles(
        cours: t[0], enseignants: enseignants, creneaux: creneaux, absences: const [absence], remplacementsDuJour: t, nomsMatieres: noms);
    expect(cand.map((x) => x.enseignant.id), ['mbu', 'tsh']);
    expect(cand.first.raisons, ['Enseigne cette branche']);
    expect(cand.first.minutesCeJour, 100);

    // Lundi 10:15 : Mbuyi est en cours → exclu ; Ilunga connaît la classe, avant Tshibanda.
    cand = remplacantsDisponibles(
        cours: t[1], enseignants: enseignants, creneaux: creneaux, absences: const [absence], remplacementsDuJour: t, nomsMatieres: noms);
    expect(cand.map((x) => x.enseignant.id), ['ilu', 'tsh']);
    expect(cand.first.raisons, ['Connaît la classe']);
  });

  test('un remplaçant déjà pris ou absent est exclu', () {
    final t = coursTouches(absence: absence, creneaux: creneaux, jours: [1, 2, 3, 4, 5]);
    final pris = [
      for (final r in t)
        r.id == t[0].id
            ? Remplacement(
                id: r.id, absenceId: r.absenceId, date: r.date, creneauId: r.creneauId, classeId: r.classeId, jour: r.jour,
                plage: r.plage, matiereId: r.matiereId, enseignantAbsentId: r.enseignantAbsentId,
                statut: StatutRemplacement.remplace, remplacantId: 'tsh', remplacantNom: 'TSHIBANDA')
            : r,
    ];
    const autreCours = Remplacement(
        id: 'x', absenceId: 'a2', date: '2026-11-30', creneauId: 'z', classeId: '7A', jour: 1, plage: '08:00-08:50',
        matiereId: 'fr5A', enseignantAbsentId: 'autre');
    final cand = remplacantsDisponibles(
        cours: autreCours, enseignants: enseignants, creneaux: creneaux,
        absences: const [absence, AbsenceEnseignant(id: 'b', enseignantId: 'mbu', enseignantNom: 'MBUYI', debut: '2026-11-30', fin: '2026-11-30')],
        remplacementsDuJour: [...pris, autreCours], nomsMatieres: noms);
    // Kasongo absent, Mbuyi absent, Ilunga en cours (7:30-8:20 chevauche 8:00), Tshibanda déjà en remplacement.
    expect(cand, isEmpty);
  });

  test('bilan des absences', () {
    final t = coursTouches(absence: absence, creneaux: creneaux, jours: [1, 2, 3, 4, 5]);
    final b = bilanAbsences('kas', const [absence], t, [1, 2, 3, 4, 5]);
    expect(b, (jours: 2, cours: 3, coursNonAssures: 3));
  });

  test('message au remplaçant (identique à la fonction serveur)', () {
    expect(
      messageRemplacement(annulation: false, remplacant: 'Paul MBUYI', absent: 'Marie KASONGO', date: '2026-11-30',
          plage: '07:30-08:20', classe: '5e A', branche: 'Français', ecole: 'CS Les Bâtisseurs'),
      'Bonjour Paul MBUYI, vous êtes désigné(e) pour remplacer Marie KASONGO le lundi 30/11 de 07:30 à 08:20 en 5e A (Français). Merci. — CS Les Bâtisseurs',
    );
    expect(
      messageRemplacement(annulation: true, remplacant: 'P', absent: 'M', date: '2026-12-05', plage: '07:30-08:20',
          classe: 'C', branche: 'B', ecole: 'E'),
      contains('le samedi 05/12 de 07:30 à 08:20 en C (B) est annulé'),
    );
  });

  test("statut d'envoi affiché", () {
    Remplacement r(String remplacant, String statut, {String erreur = ''}) => Remplacement(
        id: 'x', absenceId: 'a', date: '2026-11-30', creneauId: 'k', classeId: 'c', jour: 1, plage: '07:30-08:20',
        matiereId: 'm', enseignantAbsentId: 'kas', statut: StatutRemplacement.remplace, remplacantId: remplacant,
        notification: (statut: statut, canal: 'sms', enseignantId: 'mbu', erreur: erreur));
    expect(r('mbu', 'envoye').etatNotification, 'SMS envoyé au remplaçant');
    expect(r('mbu', 'echec', erreur: 'Numéro invalide').etatNotification, "Échec de l'envoi SMS : Numéro invalide");
    expect(r('mbu', 'sans_telephone').etatNotification, contains('pas de numéro'));
    expect(r('tsh', 'envoye').etatNotification, isNull); // concerne l'ancien remplaçant
  });
}
