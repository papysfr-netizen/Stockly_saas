import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/evaluation.dart';
import '../core/format.dart';

class Classe {
  final String id;
  final String nom;
  final Cycle cycle;
  final String niveau;
  final String section; // option / section au secondaire (ex. Scientifique, Commerciale)
  final double fraisScolarite;
  final String? enseignantPrincipalId;

  const Classe({
    required this.id,
    required this.nom,
    this.cycle = Cycle.primaire,
    this.niveau = '',
    this.section = '',
    this.fraisScolarite = 0,
    this.enseignantPrincipalId,
  });

  factory Classe.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Classe(
      id: doc.id,
      nom: m['nom'] ?? '',
      cycle: CycleX.parse(m['cycle']),
      niveau: m['niveau'] ?? '',
      section: m['section'] ?? '',
      fraisScolarite: readDouble(m['fraisScolarite']),
      enseignantPrincipalId: m['enseignantPrincipalId'],
    );
  }

  Map<String, dynamic> toMap() => {
        'nom': nom,
        'cycle': cycle.name,
        'niveau': niveau,
        'section': section,
        'fraisScolarite': fraisScolarite,
        'enseignantPrincipalId': enseignantPrincipalId,
      };

  String get description => [
        if (niveau.isNotEmpty) niveau,
        if (section.isNotEmpty) section,
      ].join(' · ');
}

class Matiere {
  final String id;
  final String classeId;
  final String nom;

  /// RD Congo : points d'une période (l'examen vaut le double).
  final double maxima;

  /// Système « trimestres sur 20 » uniquement.
  final double coefficient;
  final String? enseignantId;

  const Matiere({
    required this.id,
    required this.classeId,
    required this.nom,
    this.maxima = 10,
    this.coefficient = 1,
    this.enseignantId,
  });

  factory Matiere.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Matiere(
      id: doc.id,
      classeId: m['classeId'] ?? '',
      nom: m['nom'] ?? '',
      maxima: readDouble(m['maxima'], 10),
      coefficient: readDouble(m['coefficient'], 1),
      enseignantId: m['enseignantId'],
    );
  }

  /// Points maximum de la branche pour une période donnée.
  double maximaPour(Periode p) => p.examen ? maxima * 2 : maxima;

  Map<String, dynamic> toMap() => {
        'classeId': classeId,
        'nom': nom,
        'maxima': maxima,
        'coefficient': coefficient,
        'enseignantId': enseignantId,
      };
}
