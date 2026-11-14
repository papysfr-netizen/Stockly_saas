import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Énumération intégrée pour le type de dette / créance
enum TypeDette { client, fournisseur }

/// 🧭 Origine d'une dette : d'où vient l'argent dû
///  - quelqu'un me doit : vente hors caisse, argent prêté, ancienne dette (cahier)
///  - je dois : achat de marchandises à crédit, argent emprunté, ancienne dette (cahier)
class OrigineDette {
  OrigineDette._();
  static const vente = 'vente';
  static const pret = 'pret';
  static const achat = 'achat';
  static const emprunt = 'emprunt';
  static const cahier = 'cahier';

  static const pourClient = [vente, pret, cahier];
  static const pourFournisseur = [achat, emprunt, cahier];

  /// Origine des anciennes dettes (avant ce choix) : vente ou achat
  static String parDefaut(TypeDette type) => type == TypeDette.client ? vente : achat;

  /// Compte comptable du tiers (SYSCOHADA)
  static String compteTiers(TypeDette type, String origine) {
    if (origine == pret) return '471000'; // débiteurs divers
    if (origine == emprunt) return '168000'; // autres emprunts
    return type == TypeDette.client ? '411000' : '401000';
  }
}

@immutable
class Dette {
  final String id;
  final String nomTiers;
  final String telephone;
  final String numeroFacture;
  /// Identifiant complet de la vente liée ('' si dette ajoutée à la main)
  final String venteId;
  /// 🏬 Boutique de la dette ('' = ancienne dette pas encore rattachée)
  final String boutiqueId;
  /// Historique des paiements : {date, montant, methode, parNom, parUid}
  final List<Map<String, dynamic>> paiements;
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

  /// 🧭 Origine (voir [OrigineDette])
  final String origine;
  String get compteTiers => OrigineDette.compteTiers(type, origine);

  const Dette({
    required this.id,
    required this.nomTiers,
    this.telephone = '',
    required this.numeroFacture,
    this.venteId = '',
    this.boutiqueId = '',
    this.paiements = const [],
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
    String? origine,
  }) : origine = origine ?? (type == TypeDette.client ? OrigineDette.vente : OrigineDette.achat);

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

  /// Liste des paiements (ignore ce qui n'est pas une fiche valide)
  static List<Map<String, dynamic>> _parsePaiements(dynamic v) {
    if (v is! List) return const [];
    return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
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
      telephone: (json['telephone'] ?? json['telephoneClient'] ?? json['tel'] ?? '').toString(),
      numeroFacture: numeroFactureResolved,
      venteId: (json['venteId'] ?? '').toString(),
      boutiqueId: (json['boutiqueId'] ?? '').toString(),
      paiements: _parsePaiements(json['paiements']),
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
      origine: (json['origine'] ?? '').toString().isEmpty ? null : json['origine'].toString(),
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
      'telephone': telephone,
      'numeroFacture': numeroFacture,
      if (venteId.isNotEmpty) 'venteId': venteId,
      if (boutiqueId.isNotEmpty) 'boutiqueId': boutiqueId,
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
      'origine': origine,
    };
  }

  /// Enregistrement spécifique pour Firestore (utilise les objets Timestamp)
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'nomTiers': nomTiers,
      'telephone': telephone,
      'numeroFacture': numeroFacture,
      if (venteId.isNotEmpty) 'venteId': venteId,
      if (boutiqueId.isNotEmpty) 'boutiqueId': boutiqueId,
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
      'origine': origine,
    };
  }

  /// Duplication immuable d'une instance (Riverpod / State Management)
  Dette copyWith({
    String? id,
    String? nomTiers,
    String? telephone,
    String? numeroFacture,
    String? venteId,
    String? boutiqueId,
    List<Map<String, dynamic>>? paiements,
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
      telephone: telephone ?? this.telephone,
      numeroFacture: numeroFacture ?? this.numeroFacture,
      venteId: venteId ?? this.venteId,
      boutiqueId: boutiqueId ?? this.boutiqueId,
      paiements: paiements ?? this.paiements,
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
      origine: origine,
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