import '../models/emploi_du_temps.dart';

const nomsJours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];

/// Grille par défaut : 6 heures de 50 minutes, récréation de 10 h à 10 h 15.
const plagesParDefaut = [
  '07:30-08:20',
  '08:20-09:10',
  '09:10-10:00',
  '10:15-11:05',
  '11:05-11:55',
  '11:55-12:45',
];

/// "07:30-08:20" → (450, 500) en minutes depuis minuit ; null si invalide.
(int, int)? lirePlage(String plage) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})$').firstMatch(plage.trim());
  if (m == null) return null;
  final debut = int.parse(m[1]!) * 60 + int.parse(m[2]!);
  final fin = int.parse(m[3]!) * 60 + int.parse(m[4]!);
  if (int.parse(m[1]!) > 23 || int.parse(m[3]!) > 23 || int.parse(m[2]!) > 59 || int.parse(m[4]!) > 59) return null;
  return fin > debut ? (debut, fin) : null;
}

/// Remet une plage au format "HH:MM-HH:MM" (ou null si invalide).
String? normaliserPlage(String saisie) {
  final p = lirePlage(saisie);
  if (p == null) return null;
  String h(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  return '${h(p.$1)}-${h(p.$2)}';
}

/// Trie les plages par heure de début et signale les chevauchements.
({List<String> plages, String? erreur}) validerGrille(List<String> saisies) {
  final plages = <String>[];
  for (final s in saisies.where((s) => s.trim().isNotEmpty)) {
    final n = normaliserPlage(s);
    if (n == null) return (plages: const [], erreur: 'Plage invalide : « $s » (format 07:30-08:20).');
    plages.add(n);
  }
  plages.sort((a, b) => lirePlage(a)!.$1.compareTo(lirePlage(b)!.$1));
  for (var i = 1; i < plages.length; i++) {
    if (lirePlage(plages[i])!.$1 < lirePlage(plages[i - 1])!.$2) {
      return (plages: const [], erreur: 'Les plages ${plages[i - 1]} et ${plages[i]} se chevauchent.');
    }
  }
  if (plages.isEmpty) return (plages: const [], erreur: 'Indiquez au moins une plage horaire.');
  return (plages: plages, erreur: null);
}

bool _seChevauchent(String a, String b) {
  final x = lirePlage(a), y = lirePlage(b);
  if (x == null || y == null) return a == b;
  return x.$1 < y.$2 && y.$1 < x.$2;
}

/// Conflits que créerait [nouveau] : même enseignant ou même salle, au même
/// moment, dans une autre classe. (Dans sa propre classe, le créneau remplace l'ancien.)
List<Creneau> conflits(Iterable<Creneau> existants, Creneau nouveau) => [
      for (final c in existants)
        if (c.classeId != nouveau.classeId &&
            c.jour == nouveau.jour &&
            _seChevauchent(c.plage, nouveau.plage) &&
            ((nouveau.enseignantId != null && c.enseignantId == nouveau.enseignantId) ||
                (nouveau.salle.trim().isNotEmpty &&
                    c.salle.trim().toLowerCase() == nouveau.salle.trim().toLowerCase())))
          c,
    ];

/// Durée totale en minutes, regroupée par une clé (branche, enseignant…).
Map<String, int> volumeHoraire(Iterable<Creneau> creneaux, String? Function(Creneau) cle) {
  final r = <String, int>{};
  for (final c in creneaux) {
    final k = cle(c);
    final p = lirePlage(c.plage);
    if (k == null || p == null) continue;
    r[k] = (r[k] ?? 0) + p.$2 - p.$1;
  }
  return r;
}

String formatDuree(int minutes) {
  final h = minutes ~/ 60, m = minutes % 60;
  return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')}';
}
