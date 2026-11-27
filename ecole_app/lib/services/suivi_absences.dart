import '../models/absence_eleve.dart';

/// Élèves ayant au moins [seuil] absences non justifiées sur les [jours]
/// derniers jours, du plus absent au moins absent.
List<({String eleveId, int absences, DateTime derniere})> elevesASuivre(
  Iterable<AbsenceEleve> absences, {
  required int seuil,
  required DateTime maintenant,
  int jours = 30,
}) {
  final debut = DateTime(maintenant.year, maintenant.month, maintenant.day).subtract(Duration(days: jours - 1));
  final parEleve = <String, List<AbsenceEleve>>{};
  for (final a in absences) {
    if (!a.estAbsence || a.justifiee || a.date.isBefore(debut)) continue;
    parEleve.putIfAbsent(a.eleveId, () => []).add(a);
  }
  final r = [
    for (final e in parEleve.entries)
      if (e.value.length >= seuil)
        (
          eleveId: e.key,
          absences: e.value.length,
          derniere: e.value.map((a) => a.date).reduce((x, y) => x.isAfter(y) ? x : y),
        ),
  ];
  r.sort((a, b) => a.absences != b.absences ? b.absences.compareTo(a.absences) : b.derniere.compareTo(a.derniere));
  return r;
}

typedef BilanAbsences = ({int absences, int nonJustifiees, int retards});

/// Compte absences, absences non justifiées et retards d'un ensemble.
BilanAbsences bilan(Iterable<AbsenceEleve> absences) {
  var abs = 0, nj = 0, ret = 0;
  for (final a in absences) {
    if (a.estAbsence) {
      abs++;
      if (!a.justifiee) nj++;
    } else {
      ret++;
    }
  }
  return (absences: abs, nonJustifiees: nj, retards: ret);
}

/// Absences d'un mois donné (ou de toute la liste si [mois] est null).
Iterable<AbsenceEleve> duMois(Iterable<AbsenceEleve> absences, DateTime? mois) =>
    mois == null ? absences : absences.where((a) => a.date.year == mois.year && a.date.month == mois.month);

const _jours = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];

/// Message d'absence envoyé au parent. Même texte que `functions/absences.js`.
String messageAbsenceParent({
  required String parent,
  required String eleve,
  required String classe,
  required DateTime date,
  required String ecole,
}) {
  final p = parent.trim().isEmpty ? 'cher parent' : parent.trim();
  final d = '${_jours[date.weekday - 1]} ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  return "Bonjour $p, $eleve ($classe) est noté(e) absent(e) le $d. "
      "Merci de contacter l'école ou de justifier l'absence. — $ecole";
}
