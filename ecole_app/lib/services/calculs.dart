import 'package:intl/intl.dart';

import '../core/evaluation.dart';
import '../models/classe.dart';
import '../models/scolarite.dart';

/// Index des évaluations par élève / branche / période.
class Evaluations {
  Evaluations(Iterable<Note> notes)
      : _idx = {for (final n in notes) '${n.eleveId}|${n.matiereId}|${n.periode}': n};
  final Map<String, Note> _idx;

  Note? de(String eleveId, String matiereId, String periode) => _idx['$eleveId|$matiereId|$periode'];

  /// Points et maxima cumulés des notes saisies d'une branche sur des périodes.
  ({double points, double maxima})? total(String eleveId, String matiereId, List<String> codes) {
    double pts = 0, max = 0;
    var trouve = false;
    for (final c in codes) {
      final n = de(eleveId, matiereId, c);
      if (n?.valeur == null) continue;
      trouve = true;
      pts += n!.valeur!;
      max += n.sur;
    }
    return trouve ? (points: pts, maxima: max) : null;
  }
}

/// Résultat d'un élève sur un ensemble de périodes :
/// - RD Congo : pourcentage des points obtenus sur les maxima des notes saisies ;
/// - trimestres : moyenne sur 20 pondérée par les coefficients.
double? scoreEleve({
  required SystemeEvaluation systeme,
  required String eleveId,
  required List<Matiere> matieres,
  required List<String> codes,
  required Evaluations ev,
}) {
  double num = 0, den = 0;
  for (final m in matieres) {
    for (final c in codes) {
      final n = ev.de(eleveId, m.id, c);
      if (n?.valeur == null || n!.sur == 0) continue;
      if (systeme == SystemeEvaluation.rdc) {
        num += n.valeur!;
        den += n.sur;
      } else {
        num += n.sur20! * m.coefficient;
        den += m.coefficient;
      }
    }
  }
  if (den == 0) return null;
  return systeme == SystemeEvaluation.rdc ? num * 100 / den : num / den;
}

/// Places dans la classe ; les ex æquo partagent la même place (1, 2, 2, 4…).
Map<String, int?> classer(Map<String, double?> scores) {
  final tries = scores.values.whereType<double>().toList()..sort((a, b) => b.compareTo(a));
  return {for (final e in scores.entries) e.key: e.value == null ? null : tries.indexOf(e.value!) + 1};
}

class ResultatsClasse {
  ResultatsClasse(this.scores) : rangs = classer(scores);
  final Map<String, double?> scores;
  final Map<String, int?> rangs;

  int get effectif => scores.length;
  double? get moyenne {
    final v = scores.values.whereType<double>().toList();
    return v.isEmpty ? null : v.reduce((a, b) => a + b) / v.length;
  }
}

ResultatsClasse resultatsClasse({
  required SystemeEvaluation systeme,
  required List<String> eleveIds,
  required List<Matiere> matieres,
  required List<String> codes,
  required Evaluations ev,
}) =>
    ResultatsClasse({
      for (final id in eleveIds)
        id: scoreEleve(systeme: systeme, eleveId: id, matieres: matieres, codes: codes, ev: ev),
    });

/// Seuil de réussite : 50 % en RD Congo, 10/20 sinon.
double seuilReussite(SystemeEvaluation s) => s == SystemeEvaluation.rdc ? 50 : 10;

String formatScore(SystemeEvaluation s, double? v) {
  if (v == null) return '-';
  return s == SystemeEvaluation.rdc
      ? '${NumberFormat('0.0', 'fr_FR').format(v)} %'
      : '${NumberFormat('0.00', 'fr_FR').format(v)} / 20';
}

/// Branches sous le seuil de réussite sur les périodes données.
List<Matiere> branchesEchouees({
  required SystemeEvaluation systeme,
  required String eleveId,
  required List<Matiere> matieres,
  required List<String> codes,
  required Evaluations ev,
}) =>
    [
      for (final m in matieres)
        if (scoreEleve(systeme: systeme, eleveId: eleveId, matieres: [m], codes: codes, ev: ev)
            case final s? when s < seuilReussite(systeme))
          m,
    ];

/// Décision de fin d'année proposée (à valider par le conseil de classe).
String decisionProposee(SystemeEvaluation s, double? scoreAnnuel, int nbEchecs) {
  if (scoreAnnuel == null) return '-';
  if (scoreAnnuel < seuilReussite(s)) return 'Ajourné(e)';
  if (nbEchecs > 0) return 'Seconde session ($nbEchecs branche${nbEchecs > 1 ? 's' : ''})';
  return 'Admis(e) en classe supérieure';
}

/// Appréciation d'une moyenne sur 20 (système trimestres).
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

String formatPoints(double? v) {
  if (v == null) return '';
  return v % 1 == 0 ? v.toStringAsFixed(0) : NumberFormat('0.#', 'fr_FR').format(v);
}
