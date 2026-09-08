import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Modèle représentatif d'une dépense d'exploitation dans Stockly
@immutable
class Depense {
  final String id;
  final String entrepriseId;
  final String titre;
  final double montant;
  final String categorie;
  final DateTime date;
  final String methodePaiement;
  final String? note;
  final String? enregistrePar;
  final bool comptabilise;

  const Depense({
    required this.id,
    this.entrepriseId = '',
    required this.titre,
    required this.montant,
    required this.categorie,
    required this.date,
    this.methodePaiement = 'Cash',
    this.note,
    this.enregistrePar,
    this.comptabilise = false,
  });

  /// Parseur de date sécurisé (Timestamp Firestore, String ISO 8601, Epoch Int)
  static DateTime _parseDate(dynamic dateRaw) {
    if (dateRaw is Timestamp) {
      return dateRaw.toDate();
    } else if (dateRaw is String) {
      return DateTime.tryParse(dateRaw) ?? DateTime.now();
    } else if (dateRaw is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateRaw);
    }
    return DateTime.now();
  }

  /// Factory optimisée pour la désérialisation (Map / JSON)
  factory Depense.fromJson(Map<String, dynamic> json, [String? docId]) {
    return Depense(
      id: docId ?? json['id']?.toString() ?? '',
      entrepriseId: json['entrepriseId']?.toString() ?? '',
      titre: json['titre']?.toString() ?? '',
      montant: (json['montant'] as num?)?.toDouble() ?? 0.0,
      categorie: json['categorie']?.toString() ?? 'Autre',
      date: _parseDate(json['date']),
      methodePaiement: json['methodePaiement']?.toString() ?? 'Cash',
      note: json['note']?.toString(),
      enregistrePar: json['enregistrePar']?.toString() ?? json['createdBy']?.toString(),
      comptabilise: json['comptabilise'] as bool? ?? false,
    );
  }

  /// Factory pratique pour Firestore DocumentSnapshot
  factory Depense.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Depense.fromJson(data, doc.id);
  }

  /// Sérialisation standard vers Map / JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entrepriseId': entrepriseId,
      'titre': titre,
      'montant': montant,
      'categorie': categorie,
      'date': date.toIso8601String(),
      'methodePaiement': methodePaiement,
      'note': note,
      'enregistrePar': enregistrePar,
      'comptabilise': comptabilise,
    };
  }

  /// Sérialisation spécifique Cloud Firestore avec `Timestamp`
  Map<String, dynamic> toFirestore() {
    final map = toJson();
    map['date'] = Timestamp.fromDate(date);
    return map;
  }

  /// Immutabilité : Duplication avec modifications partielles
  Depense copyWith({
    String? id,
    String? entrepriseId,
    String? titre,
    double? montant,
    String? categorie,
    DateTime? date,
    String? methodePaiement,
    String? note,
    String? enregistrePar,
    bool? comptabilise,
  }) {
    return Depense(
      id: id ?? this.id,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      titre: titre ?? this.titre,
      montant: montant ?? this.montant,
      categorie: categorie ?? this.categorie,
      date: date ?? this.date,
      methodePaiement: methodePaiement ?? this.methodePaiement,
      note: note ?? this.note,
      enregistrePar: enregistrePar ?? this.enregistrePar,
      comptabilise: comptabilise ?? this.comptabilise,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Depense &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          entrepriseId == other.entrepriseId &&
          titre == other.titre &&
          montant == other.montant &&
          categorie == other.categorie &&
          date == other.date &&
          methodePaiement == other.methodePaiement &&
          note == other.note &&
          enregistrePar == other.enregistrePar &&
          comptabilise == other.comptabilise;

  @override
  int get hashCode => Object.hash(
        id,
        entrepriseId,
        titre,
        montant,
        categorie,
        date,
        methodePaiement,
        note,
        enregistrePar,
        comptabilise,
      );

  @override
  String toString() {
    return 'Depense(id: $id, titre: $titre, montant: $montant, categorie: $categorie, comptabilise: $comptabilise)';
  }
}