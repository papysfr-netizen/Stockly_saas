import 'package:cloud_firestore/cloud_firestore.dart';

/// Une heure de cours dans l'emploi du temps d'une classe.
class Creneau {
  final String id;
  final String classeId;
  final int jour; // 1 = lundi … 6 = samedi
  final String plage; // "07:30-08:20"
  final String matiereId;
  final String? enseignantId;
  final String enseignantNom; // copié pour l'affichage (les parents ne lisent pas les fiches enseignants)
  final String salle;

  const Creneau({
    required this.id,
    required this.classeId,
    required this.jour,
    required this.plage,
    required this.matiereId,
    this.enseignantId,
    this.enseignantNom = '',
    this.salle = '',
  });

  /// Une seule heure de cours par classe, jour et plage.
  static String docId(String classeId, int jour, String plage) => '${classeId}_${jour}_${plage.replaceAll(':', '')}';

  factory Creneau.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Creneau(
      id: doc.id,
      classeId: m['classeId'] ?? '',
      jour: (m['jour'] as num?)?.toInt() ?? 1,
      plage: m['plage'] ?? '',
      matiereId: m['matiereId'] ?? '',
      enseignantId: m['enseignantId'],
      enseignantNom: m['enseignantNom'] ?? '',
      salle: m['salle'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'classeId': classeId,
        'jour': jour,
        'plage': plage,
        'matiereId': matiereId,
        'enseignantId': enseignantId,
        'enseignantNom': enseignantNom,
        'salle': salle,
      };
}
