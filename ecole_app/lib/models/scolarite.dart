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

/// Évaluation d'un élève dans une branche pour une période :
/// des points ([valeur] sur [sur]) ou, en maternelle, une [cote] (A, ECA, NA).
class Note {
  final String id;
  final String eleveId;
  final String classeId;
  final String matiereId;
  final String periode; // P1, P2, EX1… ou T1, T2, T3
  final double? valeur;
  final double sur;
  final String? cote;

  const Note({
    required this.id,
    required this.eleveId,
    required this.classeId,
    required this.matiereId,
    required this.periode,
    this.valeur,
    this.sur = 20,
    this.cote,
  });

  /// Note ramenée sur 20 (système trimestres).
  double? get sur20 => valeur == null || sur == 0 ? null : valeur! * 20 / sur;

  /// Identifiant déterministe : une évaluation par élève / branche / période.
  static String docId(String eleveId, String matiereId, String periode) => '${eleveId}_${matiereId}_$periode';

  factory Note.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Note(
      id: doc.id,
      eleveId: m['eleveId'] ?? '',
      classeId: m['classeId'] ?? '',
      matiereId: m['matiereId'] ?? '',
      periode: m['periode'] ?? 'T${m['trimestre'] ?? 1}',
      valeur: m['valeur'] == null ? null : readDouble(m['valeur']),
      sur: readDouble(m['sur'], 20),
      cote: m['cote'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'eleveId': eleveId,
        'classeId': classeId,
        'matiereId': matiereId,
        'periode': periode,
        if (valeur != null) 'valeur': valeur,
        'sur': sur,
        if (cote != null) 'cote': cote,
        'modifieLe': FieldValue.serverTimestamp(),
      };
}

/// Application et conduite d'un élève pour une période.
class Comportement {
  final String eleveId;
  final String periode;
  final String application;
  final String conduite;
  const Comportement(this.eleveId, this.periode, this.application, this.conduite);

  static String docId(String eleveId, String periode) => '${eleveId}_$periode';

  factory Comportement.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Comportement(m['eleveId'] ?? '', m['periode'] ?? '', m['application'] ?? '', m['conduite'] ?? '');
  }
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
