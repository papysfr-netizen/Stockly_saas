import 'package:cloud_firestore/cloud_firestore.dart';

const motifsAbsence = ['Maladie', 'Formation', 'Congé', 'Raison familiale', 'Mission', 'Non motivée', 'Autre'];

/// Absence déclarée d'un enseignant, sur une ou plusieurs journées.
class AbsenceEnseignant {
  final String id;
  final String enseignantId;
  final String enseignantNom;
  final String debut; // yyyy-MM-dd
  final String fin; // yyyy-MM-dd (inclus)
  final String motif;
  final bool justifiee;
  final String note;

  const AbsenceEnseignant({
    required this.id,
    required this.enseignantId,
    required this.enseignantNom,
    required this.debut,
    required this.fin,
    this.motif = 'Maladie',
    this.justifiee = false,
    this.note = '',
  });

  factory AbsenceEnseignant.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return AbsenceEnseignant(
      id: doc.id,
      enseignantId: m['enseignantId'] ?? '',
      enseignantNom: m['enseignantNom'] ?? '',
      debut: m['debut'] ?? '',
      fin: m['fin'] ?? '',
      motif: m['motif'] ?? '',
      justifiee: m['justifiee'] ?? false,
      note: m['note'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'enseignantId': enseignantId,
        'enseignantNom': enseignantNom,
        'debut': debut,
        'fin': fin,
        'motif': motif,
        'justifiee': justifiee,
        'note': note,
      };

  bool couvre(String jourIso) => debut.compareTo(jourIso) <= 0 && fin.compareTo(jourIso) >= 0;
}

enum StatutRemplacement { aPourvoir, remplace, etude, annule }

extension StatutRemplacementX on StatutRemplacement {
  String get label => switch (this) {
        StatutRemplacement.aPourvoir => 'À pourvoir',
        StatutRemplacement.remplace => 'Remplacé',
        StatutRemplacement.etude => 'Étude surveillée',
        StatutRemplacement.annule => 'Cours annulé',
      };
  static StatutRemplacement parse(String? v) =>
      StatutRemplacement.values.firstWhere((s) => s.name == v, orElse: () => StatutRemplacement.aPourvoir);
}

/// Un cours touché par une absence, à une date donnée, et ce qui a été décidé.
class Remplacement {
  final String id;
  final String absenceId;
  final String date; // yyyy-MM-dd
  final String creneauId;
  final String classeId;
  final int jour;
  final String plage;
  final String matiereId;
  final String enseignantAbsentId;
  final String enseignantAbsentNom;
  final StatutRemplacement statut;
  final String? remplacantId;
  final String remplacantNom;

  /// Résultat de l'envoi automatique au remplaçant (écrit par la fonction serveur).
  final ({String statut, String canal, String enseignantId, String erreur})? notification;

  const Remplacement({
    required this.id,
    required this.absenceId,
    required this.date,
    required this.creneauId,
    required this.classeId,
    required this.jour,
    required this.plage,
    required this.matiereId,
    required this.enseignantAbsentId,
    this.enseignantAbsentNom = '',
    this.statut = StatutRemplacement.aPourvoir,
    this.remplacantId,
    this.remplacantNom = '',
    this.notification,
  });

  /// Texte du statut d'envoi pour le remplaçant actuel (null s'il n'y a rien à dire).
  String? get etatNotification {
    final n = notification;
    if (n == null || n.enseignantId != remplacantId || statut != StatutRemplacement.remplace) return null;
    final canal = n.canal == 'whatsapp' ? 'WhatsApp' : 'SMS';
    return switch (n.statut) {
      'envoye' => '$canal envoyé au remplaçant',
      'sans_telephone' => 'Remplaçant prévenu : non (pas de numéro sur sa fiche)',
      'echec' => 'Échec de l\'envoi $canal${n.erreur.isEmpty ? '' : ' : ${n.erreur}'}',
      _ => null,
    };
  }

  static String docId(String date, String creneauId) => '${date}_$creneauId';

  /// Texte court pour les parents et le tableau.
  String get resume => switch (statut) {
        StatutRemplacement.remplace => 'Remplacé par $remplacantNom',
        StatutRemplacement.aPourvoir => 'Enseignant absent',
        _ => statut.label,
      };

  factory Remplacement.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Remplacement(
      id: doc.id,
      absenceId: m['absenceId'] ?? '',
      date: m['date'] ?? '',
      creneauId: m['creneauId'] ?? '',
      classeId: m['classeId'] ?? '',
      jour: (m['jour'] as num?)?.toInt() ?? 1,
      plage: m['plage'] ?? '',
      matiereId: m['matiereId'] ?? '',
      enseignantAbsentId: m['enseignantAbsentId'] ?? '',
      enseignantAbsentNom: m['enseignantAbsentNom'] ?? '',
      statut: StatutRemplacementX.parse(m['statut']),
      remplacantId: m['remplacantId'],
      remplacantNom: m['remplacantNom'] ?? '',
      notification: m['notification'] is Map
          ? (
              statut: '${m['notification']['statut'] ?? ''}',
              canal: '${m['notification']['canal'] ?? ''}',
              enseignantId: '${m['notification']['enseignantId'] ?? ''}',
              erreur: '${m['notification']['erreur'] ?? ''}',
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'absenceId': absenceId,
        'date': date,
        'creneauId': creneauId,
        'classeId': classeId,
        'jour': jour,
        'plage': plage,
        'matiereId': matiereId,
        'enseignantAbsentId': enseignantAbsentId,
        'enseignantAbsentNom': enseignantAbsentNom,
        'statut': statut.name,
        'remplacantId': remplacantId,
        'remplacantNom': remplacantNom,
      };
}
