import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Énumération intégrée pour le type de dette / créance
enum TypeDette { client, fournisseur }

@immutable
class Dette {
  final String id;
  final String nomTiers;
  final String numeroFacture;
  final double montantInitial;
  final double acomptePaye;
  final double montantReste;
  final TypeDette type;
  final String statut; // 'non_paye', 'partiel', 'paye'
  final String note;
  final DateTime dateCreation;
  final DateTime? dateEcheance;
  final DateTime? dernierPaiement;
  final String entrepriseId;
  final bool comptabilise;

  const Dette({
    required this.id,
    required this.nomTiers,
    required this.numeroFacture,
    required this.montantInitial,
    required this.acomptePaye,
    required this.montantReste,
    required this.type,
    required this.statut,
    required this.note,
    required this.dateCreation,
    this.dateEcheance,
    this.dernierPaiement,
    required this.entrepriseId,
    this.comptabilise = true,
  });

  /// Indique si la créance/dette est en retard de paiement
  bool get estEnRetard {
    if (montantReste <= 0 || dateEcheance == null) return false;
    return dateEcheance!.isBefore(DateTime.now());
  }

  /// Indique si la dette/créance est entièrement soldée
  bool get estSolde => montantReste <= 0;

  /// Pourcentage réglé (entre 0.0 et 1.0)
  double get pourcentagePaye {
    if (montantInitial <= 0) return 0.0;
    return (acomptePaye / montantInitial).clamp(0.0, 1.0);
  }

  /// Parseur de date sécurisé (gère Timestamp Firestore, String ISO et DateTime)
  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue is Timestamp) {
      return dateValue.toDate();
    } else if (dateValue is String) {
      return DateTime.tryParse(dateValue);
    } else if (dateValue is DateTime) {
      return dateValue;
    }
    return null;
  }

  /// Helper de conversion numérique sécurisé
  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Helper de conversion booléenne sécurisé (évite les TypeErrors)
  static bool _parseBool(dynamic value, {bool defaultValue = true}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return defaultValue;
  }

  /// Factory pour construire une instance depuis une Map / JSON
  factory Dette.fromJson(Map<String, dynamic> json, [String? docId]) {
    // 1. Détection intelligente du type (fallback si le champ 'type' n'existe pas)
    final typeStr = json['type']?.toString().toLowerCase() ?? '';
    TypeDette typeEnum;
    if (typeStr.contains('fournisseur')) {
      typeEnum = TypeDette.fournisseur;
    } else if (typeStr.contains('client') || typeStr.contains('creance')) {
      typeEnum = TypeDette.client;
    } else {
      typeEnum = json.containsKey('nomFournisseur')
          ? TypeDette.fournisseur
          : TypeDette.client;
    }

    // 2. Mapping avec fallback pour les alias Firestore
    final String nomTiersResolved = json['nomTiers']?.toString() ??
        json['nomClient']?.toString() ??
        json['nomFournisseur']?.toString() ??
        json['nom']?.toString() ??
        'Inconnu';

    final String numeroFactureResolved = json['numeroFacture']?.toString() ??
        json['venteId']?.toString() ??
        '';

    // Parsing sécurisé des montants
    final double montantInitialResolved = _parseDouble(
        json['montantInitial'] ?? json['montantTotal'] ?? json['montant']);

    // Résolution sécurisée de l'acompte
    final bool hasAcompteKey =
        json.containsKey('acomptePaye') || json.containsKey('acompte');
    final double acompteResolved = hasAcompteKey
        ? _parseDouble(json['acomptePaye'] ?? json['acompte'])
        : 0.0;

    // Résolution sécurisée du reste (Calculé si absent de Firestore)
    final bool hasResteKey =
        json.containsKey('montantReste') || json.containsKey('montantRestant');
    final double montantResteResolved = hasResteKey
        ? _parseDouble(json['montantReste'] ?? json['montantRestant'])
        : (montantInitialResolved - acompteResolved).clamp(0.0, double.infinity);

    // Ajustement réciproque de l'acompte si non renseigné explicitement
    final double finalAcompte = hasAcompteKey
        ? acompteResolved
        : (montantInitialResolved - montantResteResolved)
            .clamp(0.0, double.infinity);

    // Parsing des dates avec support des alias
    final DateTime dateCreationResolved = _parseDateTime(
            json['dateCreation'] ?? json['createdAt']) ??
        DateTime.now();

    // Calcul automatique du statut si non fourni ou incohérent
    String statutResolved = json['statut']?.toString() ?? '';
    if (statutResolved.isEmpty) {
      if (montantResteResolved <= 0) {
        statutResolved = 'paye';
      } else if (finalAcompte > 0) {
        statutResolved = 'partiel';
      } else {
        statutResolved = 'non_paye';
      }
    }

    return Dette(
      id: docId ?? json['id']?.toString() ?? '',
      nomTiers: nomTiersResolved,
      numeroFacture: numeroFactureResolved,
      montantInitial: montantInitialResolved,
      acomptePaye: finalAcompte,
      montantReste: montantResteResolved,
      type: typeEnum,
      statut: statutResolved,
      note: json['note']?.toString() ?? '',
      dateCreation: dateCreationResolved,
      dateEcheance: _parseDateTime(
          json['dateEcheance'] ?? json['dueDate'] ?? json['echeance']),
      dernierPaiement: _parseDateTime(
          json['dernierPaiement'] ?? json['lastPaymentDate']),
      entrepriseId: json['entrepriseId']?.toString() ?? '',
      comptabilise: _parseBool(json['comptabilise'], defaultValue: true),
    );
  }

  /// Factory alias pour compatibilité directe avec (id, map)
  factory Dette.fromMap(String id, Map<String, dynamic> map) {
    return Dette.fromJson(map, id);
  }

  /// Factory pour construire une instance depuis un DocumentSnapshot Firestore
  factory Dette.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Dette.fromJson(data, doc.id);
  }

  /// Conversion en Map standard / JSON (Dates en ISO 8601 String)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nomTiers': nomTiers,
      'numeroFacture': numeroFacture,
      'montantInitial': montantInitial,
      'acomptePaye': acomptePaye,
      'montantReste': montantReste,
      'type': type.name,
      'statut': statut,
      'note': note,
      'dateCreation': dateCreation.toIso8601String(),
      'dateEcheance': dateEcheance?.toIso8601String(),
      'dernierPaiement': dernierPaiement?.toIso8601String(),
      'entrepriseId': entrepriseId,
      'comptabilise': comptabilise,
    };
  }

  /// Enregistrement spécifique pour Firestore (utilise les objets Timestamp)
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'nomTiers': nomTiers,
      'numeroFacture': numeroFacture,
      'montantInitial': montantInitial,
      'acomptePaye': acomptePaye,
      'montantReste': montantReste,
      'type': type.name,
      'statut': statut,
      'note': note,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'dateEcheance':
          dateEcheance != null ? Timestamp.fromDate(dateEcheance!) : null,
      'dernierPaiement': dernierPaiement != null
          ? Timestamp.fromDate(dernierPaiement!)
          : null,
      'entrepriseId': entrepriseId,
      'comptabilise': comptabilise,
    };
  }

  /// Duplication immuable d'une instance (Riverpod / State Management)
  Dette copyWith({
    String? id,
    String? nomTiers,
    String? numeroFacture,
    double? montantInitial,
    double? acomptePaye,
    double? montantReste,
    TypeDette? type,
    String? statut,
    String? note,
    DateTime? dateCreation,
    DateTime? dateEcheance,
    DateTime? dernierPaiement,
    String? entrepriseId,
    bool? comptabilise,
  }) {
    return Dette(
      id: id ?? this.id,
      nomTiers: nomTiers ?? this.nomTiers,
      numeroFacture: numeroFacture ?? this.numeroFacture,
      montantInitial: montantInitial ?? this.montantInitial,
      acomptePaye: acomptePaye ?? this.acomptePaye,
      montantReste: montantReste ?? this.montantReste,
      type: type ?? this.type,
      statut: statut ?? this.statut,
      note: note ?? this.note,
      dateCreation: dateCreation ?? this.dateCreation,
      dateEcheance: dateEcheance ?? this.dateEcheance,
      dernierPaiement: dernierPaiement ?? this.dernierPaiement,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      comptabilise: comptabilise ?? this.comptabilise,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Dette &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nomTiers == other.nomTiers &&
          numeroFacture == other.numeroFacture &&
          montantInitial == other.montantInitial &&
          acomptePaye == other.acomptePaye &&
          montantReste == other.montantReste &&
          type == other.type &&
          statut == other.statut &&
          note == other.note &&
          dateCreation == other.dateCreation &&
          dateEcheance == other.dateEcheance &&
          dernierPaiement == other.dernierPaiement &&
          entrepriseId == other.entrepriseId &&
          comptabilise == other.comptabilise;

  @override
  int get hashCode => Object.hash(
        id,
        nomTiers,
        numeroFacture,
        montantInitial,
        acomptePaye,
        montantReste,
        type,
        statut,
        note,
        dateCreation,
        dateEcheance,
        dernierPaiement,
        entrepriseId,
        comptabilise,
      );

  @override
  String toString() {
    return 'Dette(id: $id, nomTiers: $nomTiers, montantInitial: $montantInitial, montantReste: $montantReste, type: ${type.name})';
  }
}