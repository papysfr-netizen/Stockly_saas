import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/format.dart';
import 'scolarite.dart';

const motifsJustification = [
  'Maladie',
  'Rendez-vous médical',
  'Deuil',
  'Raison familiale',
  'Intempéries / transport',
  'Autre',
];

/// Une absence ou un retard d'élève, issu de l'appel (`absences/`).
class AbsenceEleve {
  final String id;
  final String eleveId;
  final String classeId;
  final DateTime date;
  final StatutPresence statut;
  final bool justifiee;
  final String motif;
  final String note;

  /// Justification envoyée par le parent, en attente de validation par l'école.
  final ({String motif, String message})? justificationParent;

  /// Résultat de l'alerte automatique au parent (écrit par la fonction serveur).
  final ({String statut, String canal, String erreur})? alerte;

  const AbsenceEleve({
    required this.id,
    required this.eleveId,
    required this.classeId,
    required this.date,
    required this.statut,
    this.justifiee = false,
    this.motif = '',
    this.note = '',
    this.justificationParent,
    this.alerte,
  });

  bool get estAbsence => statut == StatutPresence.absent;
  bool get enAttente => !justifiee && justificationParent != null;

  String? get etatAlerte {
    final a = alerte;
    if (a == null) return null;
    final canal = a.canal == 'whatsapp' ? 'WhatsApp' : 'SMS';
    return switch (a.statut) {
      'envoye' => 'Parent prévenu par $canal',
      'sans_telephone' => 'Parent non prévenu : pas de numéro',
      'echec' => 'Échec de l\'alerte $canal${a.erreur.isEmpty ? '' : ' : ${a.erreur}'}',
      _ => null,
    };
  }

  factory AbsenceEleve.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    final jp = m['justificationParent'];
    final al = m['alerte'];
    return AbsenceEleve(
      id: doc.id,
      eleveId: m['eleveId'] ?? '',
      classeId: m['classeId'] ?? '',
      date: readDate(m['date']) ?? DateTime(2000),
      statut: StatutPresenceX.parse(m['statut'] as String?),
      justifiee: m['justifiee'] ?? false,
      motif: m['motif'] ?? '',
      note: m['note'] ?? '',
      justificationParent: jp is Map ? (motif: '${jp['motif'] ?? ''}', message: '${jp['message'] ?? ''}') : null,
      alerte: al is Map
          ? (statut: '${al['statut'] ?? ''}', canal: '${al['canal'] ?? ''}', erreur: '${al['erreur'] ?? ''}')
          : null,
    );
  }
}
