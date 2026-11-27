import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/format.dart';

class Classe {
  final String id;
  final String nom;
  final String niveau;
  final double fraisScolarite;
  final String? enseignantPrincipalId;

  const Classe({
    required this.id,
    required this.nom,
    this.niveau = '',
    this.fraisScolarite = 0,
    this.enseignantPrincipalId,
  });

  factory Classe.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Classe(
      id: doc.id,
      nom: m['nom'] ?? '',
      niveau: m['niveau'] ?? '',
      fraisScolarite: readDouble(m['fraisScolarite']),
      enseignantPrincipalId: m['enseignantPrincipalId'],
    );
  }

  Map<String, dynamic> toMap() => {
        'nom': nom,
        'niveau': niveau,
        'fraisScolarite': fraisScolarite,
        'enseignantPrincipalId': enseignantPrincipalId,
      };
}

class Matiere {
  final String id;
  final String classeId;
  final String nom;
  final double coefficient;
  final String? enseignantId;

  const Matiere({
    required this.id,
    required this.classeId,
    required this.nom,
    this.coefficient = 1,
    this.enseignantId,
  });

  factory Matiere.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Matiere(
      id: doc.id,
      classeId: m['classeId'] ?? '',
      nom: m['nom'] ?? '',
      coefficient: readDouble(m['coefficient'], 1),
      enseignantId: m['enseignantId'],
    );
  }

  Map<String, dynamic> toMap() => {
        'classeId': classeId,
        'nom': nom,
        'coefficient': coefficient,
        'enseignantId': enseignantId,
      };
}
