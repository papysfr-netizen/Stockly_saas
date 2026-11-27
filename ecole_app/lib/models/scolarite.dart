import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/format.dart';

class Paiement {
  final String id;
  final String eleveId;
  final String classeId;
  final double montant;
  final String motif;
  final String mode; // Espèces, Mobile Money, Virement, Chèque
  final DateTime date;
  final String recuNumero;
  final String encaissePar;

  const Paiement({
    required this.id,
    required this.eleveId,
    required this.classeId,
    required this.montant,
    required this.date,
    this.motif = 'Frais de scolarité',
    this.mode = 'Espèces',
    this.recuNumero = '',
    this.encaissePar = '',
  });

  factory Paiement.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Paiement(
      id: doc.id,
      eleveId: m['eleveId'] ?? '',
      classeId: m['classeId'] ?? '',
      montant: readDouble(m['montant']),
      motif: m['motif'] ?? '',
      mode: m['mode'] ?? '',
      date: readDate(m['date']) ?? DateTime.now(),
      recuNumero: m['recuNumero'] ?? '',
      encaissePar: m['encaissePar'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'eleveId': eleveId,
        'classeId': classeId,
        'montant': montant,
        'motif': motif,
        'mode': mode,
        'date': Timestamp.fromDate(date),
        'recuNumero': recuNumero,
        'encaissePar': encaissePar,
      };
}

class Note {
  final String id;
  final String eleveId;
  final String classeId;
  final String matiereId;
  final int trimestre;
  final double valeur;
  final double sur;

  const Note({
    required this.id,
    required this.eleveId,
    required this.classeId,
    required this.matiereId,
    required this.trimestre,
    required this.valeur,
    this.sur = 20,
  });

  /// Note ramenée sur 20.
  double get sur20 => sur == 0 ? 0 : valeur * 20 / sur;

  /// Identifiant déterministe : une note par élève / matière / trimestre.
  static String docId(String eleveId, String matiereId, int trimestre) =>
      '${eleveId}_${matiereId}_T$trimestre';

  factory Note.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Note(
      id: doc.id,
      eleveId: m['eleveId'] ?? '',
      classeId: m['classeId'] ?? '',
      matiereId: m['matiereId'] ?? '',
      trimestre: (m['trimestre'] as num?)?.toInt() ?? 1,
      valeur: readDouble(m['valeur']),
      sur: readDouble(m['sur'], 20),
    );
  }

  Map<String, dynamic> toMap() => {
        'eleveId': eleveId,
        'classeId': classeId,
        'matiereId': matiereId,
        'trimestre': trimestre,
        'valeur': valeur,
        'sur': sur,
        'modifieLe': FieldValue.serverTimestamp(),
      };
}

enum StatutPresence { present, absent, retard }

extension StatutPresenceX on StatutPresence {
  String get label => switch (this) {
        StatutPresence.present => 'Présent',
        StatutPresence.absent => 'Absent',
        StatutPresence.retard => 'Retard',
      };
  static StatutPresence parse(String? v) => StatutPresence.values
      .firstWhere((s) => s.name == v, orElse: () => StatutPresence.present);
}

/// Feuille d'appel d'une classe pour une journée.
class FeuillePresence {
  final String classeId;
  final DateTime date;
  final Map<String, StatutPresence> statuts;

  const FeuillePresence({
    required this.classeId,
    required this.date,
    required this.statuts,
  });

  static String docId(String classeId, DateTime date) => '${classeId}_${isoDay(date)}';

  factory FeuillePresence.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    final raw = Map<String, dynamic>.from(m['statuts'] ?? const {});
    return FeuillePresence(
      classeId: m['classeId'] ?? '',
      date: readDate(m['date']) ?? DateTime.now(),
      statuts: raw.map((k, v) => MapEntry(k, StatutPresenceX.parse(v as String?))),
    );
  }

  Map<String, dynamic> toMap() => {
        'classeId': classeId,
        'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
        'jour': isoDay(date),
        'statuts': statuts.map((k, v) => MapEntry(k, v.name)),
        'eleveIds': statuts.keys.toList(),
        'modifieLe': FieldValue.serverTimestamp(),
      };
}

class Enseignant {
  final String id;
  final String nom;
  final String prenom;
  final String telephone;
  final String email;
  final String specialite;
  final List<String> classeIds;

  const Enseignant({
    required this.id,
    required this.nom,
    required this.prenom,
    this.telephone = '',
    this.email = '',
    this.specialite = '',
    this.classeIds = const [],
  });

  String get nomComplet => '$prenom $nom';

  factory Enseignant.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Enseignant(
      id: doc.id,
      nom: m['nom'] ?? '',
      prenom: m['prenom'] ?? '',
      telephone: m['telephone'] ?? '',
      email: m['email'] ?? '',
      specialite: m['specialite'] ?? '',
      classeIds: List<String>.from(m['classeIds'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'email': email.trim().toLowerCase(),
        'specialite': specialite,
        'classeIds': classeIds,
      };
}
