import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/evaluation.dart';
import '../services/emploi_du_temps.dart' show plagesParDefaut;

class Ecole {
  final String id;
  final String nom;
  final String adresse;
  final String telephone;
  final String devise;
  final String anneeScolaire;
  final SystemeEvaluation systeme;

  /// Indicatif téléphonique du pays (ex. +225), pour les numéros saisis en local.
  final String indicatif;

  /// Modèle du message de rappel d'impayé ({parent}, {eleve}, {classe}, {montant}, {ecole}).
  final String modeleRappel;

  /// Heures de cours de la journée ("07:30-08:20"…), dans l'ordre.
  final List<String> plagesHoraires;

  /// Cours le samedi.
  final bool samedi;

  /// Prévenir automatiquement les remplaçants : 'aucune', 'sms' ou 'whatsapp'.
  final String notificationRemplacement;

  /// Alerter le parent dès qu'un élève est noté absent : 'aucune', 'sms' ou 'whatsapp'.
  final String alerteAbsence;

  /// Nombre d'absences non justifiées sur 30 jours à partir duquel un élève est « à suivre ».
  final int seuilAbsences;

  const Ecole({
    required this.id,
    required this.nom,
    this.adresse = '',
    this.telephone = '',
    this.devise = 'USD',
    this.anneeScolaire = '',
    this.systeme = SystemeEvaluation.rdc,
    this.indicatif = '+243',
    this.modeleRappel = '',
    this.plagesHoraires = plagesParDefaut,
    this.samedi = false,
    this.notificationRemplacement = 'aucune',
    this.alerteAbsence = 'aucune',
    this.seuilAbsences = 3,
  });

  /// Jours de cours : 1 = lundi … 5 ou 6.
  List<int> get jours => [1, 2, 3, 4, 5, if (samedi) 6];

  factory Ecole.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Ecole(
      id: doc.id,
      nom: m['nom'] ?? '',
      adresse: m['adresse'] ?? '',
      telephone: m['telephone'] ?? '',
      devise: m['devise'] ?? 'USD',
      anneeScolaire: m['anneeScolaire'] ?? '',
      systeme: SystemeEvaluationX.parse(m['systeme']),
      indicatif: m['indicatif'] ?? '+243',
      modeleRappel: m['modeleRappel'] ?? '',
      plagesHoraires: m['plagesHoraires'] == null ? plagesParDefaut : List<String>.from(m['plagesHoraires']),
      samedi: m['samedi'] ?? false,
      notificationRemplacement: m['notificationRemplacement'] ?? 'aucune',
      alerteAbsence: m['alerteAbsence'] ?? 'aucune',
      seuilAbsences: (m['seuilAbsences'] as num?)?.toInt() ?? 3,
    );
  }

  Map<String, dynamic> toMap() => {
        'nom': nom,
        'adresse': adresse,
        'telephone': telephone,
        'devise': devise,
        'anneeScolaire': anneeScolaire,
        'systeme': systeme.name,
        'indicatif': indicatif,
        'modeleRappel': modeleRappel,
        'plagesHoraires': plagesHoraires,
        'samedi': samedi,
        'notificationRemplacement': notificationRemplacement,
        'alerteAbsence': alerteAbsence,
        'seuilAbsences': seuilAbsences,
      };

  Ecole copyWith({String? nom, String? adresse, String? telephone, String? devise, String? anneeScolaire, SystemeEvaluation? systeme, String? indicatif, String? modeleRappel, List<String>? plagesHoraires, bool? samedi, String? notificationRemplacement, String? alerteAbsence, int? seuilAbsences}) =>
      Ecole(
        id: id,
        nom: nom ?? this.nom,
        adresse: adresse ?? this.adresse,
        telephone: telephone ?? this.telephone,
        devise: devise ?? this.devise,
        anneeScolaire: anneeScolaire ?? this.anneeScolaire,
        systeme: systeme ?? this.systeme,
        indicatif: indicatif ?? this.indicatif,
        modeleRappel: modeleRappel ?? this.modeleRappel,
        plagesHoraires: plagesHoraires ?? this.plagesHoraires,
        samedi: samedi ?? this.samedi,
        notificationRemplacement: notificationRemplacement ?? this.notificationRemplacement,
        alerteAbsence: alerteAbsence ?? this.alerteAbsence,
        seuilAbsences: seuilAbsences ?? this.seuilAbsences,
      );
}
