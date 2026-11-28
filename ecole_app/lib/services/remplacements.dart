import '../core/format.dart';
import '../models/emploi_du_temps.dart';
import '../models/remplacement.dart';
import '../models/scolarite.dart';
import 'emploi_du_temps.dart';

/// Jours de cours entre deux dates incluses (jours = 1 lundi … 6 samedi).
List<DateTime> joursDeCours(DateTime debut, DateTime fin, List<int> jours) {
  final r = <DateTime>[];
  for (var d = DateTime(debut.year, debut.month, debut.day);
      !d.isAfter(DateTime(fin.year, fin.month, fin.day));
      d = DateTime(d.year, d.month, d.day + 1)) {
    if (jours.contains(d.weekday)) r.add(d);
  }
  return r;
}

/// Cours de l'enseignant absent, pour chaque jour de cours de l'absence.
List<Remplacement> coursTouches({
  required AbsenceEnseignant absence,
  required List<Creneau> creneaux,
  required List<int> jours,
}) {
  final siens = creneaux.where((c) => c.enseignantId == absence.enseignantId).toList();
  return [
    for (final d in joursDeCours(DateTime.parse(absence.debut), DateTime.parse(absence.fin), jours))
      for (final c in siens.where((c) => c.jour == d.weekday).toList()
        ..sort((a, b) => (lirePlage(a.plage)?.$1 ?? 0).compareTo(lirePlage(b.plage)?.$1 ?? 0)))
        Remplacement(
          id: Remplacement.docId(isoDay(d), c.id),
          absenceId: absence.id,
          date: isoDay(d),
          creneauId: c.id,
          classeId: c.classeId,
          jour: c.jour,
          plage: c.plage,
          matiereId: c.matiereId,
          enseignantAbsentId: absence.enseignantId,
          enseignantAbsentNom: absence.enseignantNom,
        ),
  ];
}

bool _chevauche(String a, String b) {
  final x = lirePlage(a), y = lirePlage(b);
  if (x == null || y == null) return a == b;
  return x.$1 < y.$2 && y.$1 < x.$2;
}

class Candidat {
  const Candidat(this.enseignant, this.raisons, this.score, this.minutesCeJour);
  final Enseignant enseignant;
  final List<String> raisons;
  final int score;
  final int minutesCeJour;
}

/// Enseignants libres pour assurer [cours] : ni en cours à cette heure, ni
/// absents ce jour-là, ni déjà en remplacement au même moment. Les plus
/// pertinents d'abord : même branche, même classe, puis les moins chargés ce jour.
List<Candidat> remplacantsDisponibles({
  required Remplacement cours,
  required List<Enseignant> enseignants,
  required List<Creneau> creneaux,
  required List<AbsenceEnseignant> absences,
  required List<Remplacement> remplacementsDuJour,
  required Map<String, String> nomsMatieres,
}) {
  final nomBranche = (nomsMatieres[cours.matiereId] ?? '').trim().toLowerCase();
  final r = <Candidat>[];
  for (final e in enseignants) {
    if (e.id == cours.enseignantAbsentId) continue;
    if (absences.any((a) => a.enseignantId == e.id && a.couvre(cours.date))) continue;
    final sesCours = creneaux.where((c) => c.enseignantId == e.id && c.jour == cours.jour).toList();
    if (sesCours.any((c) => _chevauche(c.plage, cours.plage))) continue;
    final sesRemplacements = remplacementsDuJour
        .where((x) => x.id != cours.id && x.remplacantId == e.id && x.statut == StatutRemplacement.remplace)
        .toList();
    if (sesRemplacements.any((x) => _chevauche(x.plage, cours.plage))) continue;

    final raisons = <String>[];
    var score = 0;
    final branches = creneaux
        .where((c) => c.enseignantId == e.id)
        .map((c) => (nomsMatieres[c.matiereId] ?? '').trim().toLowerCase())
        .toSet();
    if (nomBranche.isNotEmpty && (branches.contains(nomBranche) || e.specialite.trim().toLowerCase() == nomBranche)) {
      raisons.add('Enseigne cette branche');
      score += 2;
    }
    if (e.classeIds.contains(cours.classeId) || creneaux.any((c) => c.enseignantId == e.id && c.classeId == cours.classeId)) {
      raisons.add('Connaît la classe');
      score += 1;
    }
    final minutes = volumeHoraire(sesCours, (_) => 'x')['x'] ?? 0;
    final minutesRemp = volumeHoraire(
        [for (final x in sesRemplacements) Creneau(id: '', classeId: '', jour: 0, plage: x.plage, matiereId: '')],
        (_) => 'x')['x'] ?? 0;
    r.add(Candidat(e, raisons, score, minutes + minutesRemp));
  }
  r.sort((a, b) => a.score != b.score
      ? b.score.compareTo(a.score)
      : a.minutesCeJour != b.minutesCeJour
          ? a.minutesCeJour.compareTo(b.minutesCeJour)
          : a.enseignant.nomComplet.compareTo(b.enseignant.nomComplet));
  return r;
}

/// Bilan des absences d'un enseignant : jours d'absence et cours manqués.
({int jours, int cours, int coursNonAssures}) bilanAbsences(
  String enseignantId,
  List<AbsenceEnseignant> absences,
  List<Remplacement> remplacements,
  List<int> joursOuvres,
) {
  final jours = <String>{};
  for (final a in absences.where((a) => a.enseignantId == enseignantId)) {
    for (final d in joursDeCours(DateTime.parse(a.debut), DateTime.parse(a.fin), joursOuvres)) {
      jours.add(isoDay(d));
    }
  }
  final siens = remplacements.where((r) => r.enseignantAbsentId == enseignantId).toList();
  return (
    jours: jours.length,
    cours: siens.length,
    coursNonAssures: siens.where((r) => r.statut == StatutRemplacement.annule || r.statut == StatutRemplacement.aPourvoir).length,
  );
}

const _jours = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];

/// Message envoyé au remplaçant. Même texte que `functions/remplacements.js`.
String messageRemplacement({
  required bool annulation,
  required String remplacant,
  required String absent,
  required String date,
  required String plage,
  required String classe,
  required String branche,
  required String ecole,
}) {
  final d = DateTime.parse(date);
  final quand = 'le ${_jours[d.weekday - 1]} ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
      'de ${plage.replaceAll('-', ' à ')}';
  return annulation
      ? 'Bonjour $remplacant, le remplacement prévu $quand en $classe ($branche) est annulé. Merci. — $ecole'
      : 'Bonjour $remplacant, vous êtes désigné(e) pour remplacer $absent $quand en $classe ($branche). Merci. — $ecole';
}
