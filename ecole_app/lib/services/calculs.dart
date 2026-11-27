import '../models/classe.dart';
import '../models/scolarite.dart';

/// Ligne de bulletin pour une matière.
class LigneBulletin {
  final Matiere matiere;
  final double? note; // sur 20
  const LigneBulletin(this.matiere, this.note);
  double? get points => note == null ? null : note! * matiere.coefficient;
}

class ResultatEleve {
  final String eleveId;
  final List<LigneBulletin> lignes;
  final double? moyenne;
  final int? rang;
  const ResultatEleve(this.eleveId, this.lignes, this.moyenne, this.rang);
}

/// Moyenne pondérée par les coefficients, en ignorant les matières sans note.
double? moyennePonderee(List<LigneBulletin> lignes) {
  double points = 0, coefs = 0;
  for (final l in lignes) {
    if (l.note == null) continue;
    points += l.note! * l.matiere.coefficient;
    coefs += l.matiere.coefficient;
  }
  return coefs == 0 ? null : points / coefs;
}

/// Calcule moyennes et rangs d'une classe pour un trimestre.
/// Les ex æquo partagent le même rang (1, 2, 2, 4…).
Map<String, ResultatEleve> resultatsClasse({
  required List<String> eleveIds,
  required List<Matiere> matieres,
  required List<Note> notes,
}) {
  final index = <String, Note>{for (final n in notes) '${n.eleveId}|${n.matiereId}': n};
  final lignesParEleve = {
    for (final id in eleveIds)
      id: [for (final m in matieres) LigneBulletin(m, index['$id|${m.id}']?.sur20)],
  };
  final moyennes = {for (final e in lignesParEleve.entries) e.key: moyennePonderee(e.value)};
  final classees = moyennes.values.whereType<double>().toList()..sort((a, b) => b.compareTo(a));

  return {
    for (final id in eleveIds)
      id: ResultatEleve(
        id,
        lignesParEleve[id]!,
        moyennes[id],
        moyennes[id] == null ? null : classees.indexOf(moyennes[id]!) + 1,
      ),
  };
}

String appreciation(double? moyenne) {
  if (moyenne == null) return '-';
  if (moyenne >= 16) return 'Excellent';
  if (moyenne >= 14) return 'Très bien';
  if (moyenne >= 12) return 'Bien';
  if (moyenne >= 10) return 'Passable';
  if (moyenne >= 8) return 'Insuffisant';
  return 'Faible';
}

/// Reste à payer pour un élève (jamais négatif).
double resteAPayer(double fraisScolarite, Iterable<Paiement> paiements) {
  final paye = paiements.fold<double>(0, (s, p) => s + p.montant);
  final reste = fraisScolarite - paye;
  return reste < 0 ? 0 : reste;
}
