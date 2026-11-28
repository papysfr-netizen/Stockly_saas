// Systèmes d'évaluation pris en charge.
//
// RD Congo (par défaut) : l'année compte deux semestres ; chacun a deux
// périodes et un examen. Chaque branche a un « maxima » de points par
// période ; l'examen vaut le double. Les résultats sont des pourcentages.
//
// Trimestres sur 20 (Congo-Brazzaville, Côte d'Ivoire…) : trois trimestres,
// notes sur 20 pondérées par des coefficients.

enum SystemeEvaluation { rdc, trimestres }

extension SystemeEvaluationX on SystemeEvaluation {
  String get label => switch (this) {
        SystemeEvaluation.rdc => 'RD Congo (périodes et examens)',
        SystemeEvaluation.trimestres => 'Trimestres, notes sur 20',
      };
  static SystemeEvaluation parse(String? v) =>
      SystemeEvaluation.values.firstWhere((s) => s.name == v, orElse: () => SystemeEvaluation.rdc);
}

enum Cycle { maternelle, primaire, secondaire }

extension CycleX on Cycle {
  String get label => switch (this) {
        Cycle.maternelle => 'Maternelle',
        Cycle.primaire => 'Primaire',
        Cycle.secondaire => 'Secondaire',
      };
  static Cycle parse(String? v) => Cycle.values.firstWhere((c) => c.name == v, orElse: () => Cycle.primaire);

  /// Niveaux proposés à la création d'une classe (RD Congo).
  List<String> get niveauxRdc => switch (this) {
        Cycle.maternelle => ['1re maternelle', '2e maternelle', '3e maternelle'],
        Cycle.primaire => ['1re année', '2e année', '3e année', '4e année', '5e année', '6e année'],
        Cycle.secondaire => [
            '7e année (EB)',
            '8e année (EB)',
            '1re humanité',
            '2e humanité',
            '3e humanité',
            '4e humanité',
          ],
      };
}

class Periode {
  const Periode(this.code, this.label, {this.examen = false, this.semestre = 0});
  final String code;
  final String label;
  final bool examen;
  final int semestre; // 1 ou 2 en RD Congo, 0 sinon
}

const _p1 = Periode('P1', '1re période', semestre: 1);
const _p2 = Periode('P2', '2e période', semestre: 1);
const _ex1 = Periode('EX1', 'Examen 1er semestre', examen: true, semestre: 1);
const _p3 = Periode('P3', '3e période', semestre: 2);
const _p4 = Periode('P4', '4e période', semestre: 2);
const _ex2 = Periode('EX2', 'Examen 2e semestre', examen: true, semestre: 2);

/// Périodes évaluées selon le système et le cycle.
/// La maternelle n'a pas d'examens : elle est évaluée par période, en cotes.
List<Periode> periodesPour(SystemeEvaluation s, Cycle c) {
  if (s == SystemeEvaluation.trimestres) {
    return const [Periode('T1', '1er trimestre'), Periode('T2', '2e trimestre'), Periode('T3', '3e trimestre')];
  }
  return c == Cycle.maternelle ? const [_p1, _p2, _p3, _p4] : const [_p1, _p2, _ex1, _p3, _p4, _ex2];
}

/// Regroupement de périodes pour un résultat : une période, un semestre, l'année.
class Vue {
  const Vue(this.label, this.codes);
  final String label;
  final List<String> codes;
}

List<Vue> vuesPour(SystemeEvaluation s, Cycle c) {
  final periodes = periodesPour(s, c);
  return [
    for (final p in periodes) Vue(p.label, [p.code]),
    if (s == SystemeEvaluation.rdc && c != Cycle.maternelle) ...[
      const Vue('1er semestre', ['P1', 'P2', 'EX1']),
      const Vue('2e semestre', ['P3', 'P4', 'EX2']),
    ],
    Vue('Année (total général)', [for (final p in periodes) p.code]),
  ];
}

/// Cotes de la maternelle.
const cotesMaternelle = <(String, String)>[
  ('A', 'Acquis'),
  ('ECA', "En cours d'acquisition"),
  ('NA', 'Non acquis'),
];

/// Échelle pour l'application et la conduite.
const echelleComportement = ['Élite', 'Très bon', 'Bon', 'Assez bon', 'Médiocre', 'Mauvais'];
