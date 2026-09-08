import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Modèle représentatif d'une transaction de vente dans Stockly
@immutable
class Vente {
  final String id;
  final String entrepriseId;
  final List<Map<String, dynamic>> produits;
  final double total;
  final DateTime date;
  final String? clientNom;
  final String methodePaiement;
  final String statutPaiement;
  final double montantPaye;
  final double resteAPayer;
  final String statutLivraison;
  final bool comptabilise;

  const Vente({
    required this.id,
    this.entrepriseId = '',
    required this.produits,
    required this.total,
    required this.date,
    this.clientNom,
    this.methodePaiement = 'Cash',
    this.statutPaiement = 'Payé',
    this.montantPaye = 0.0,
    this.resteAPayer = 0.0,
    this.statutLivraison = 'Livré',
    this.comptabilise = false,
  });

  /// Getters utilitaires métier et UI
  bool get estSolde => resteAPayer <= 0 || statutPaiement.toLowerCase() == 'payé';
  bool get estLivre => statutLivraison.toLowerCase() == 'livré';
  bool get estAcompte => montantPaye > 0 && resteAPayer > 0;
  
  String get nomClientAffiche =>
      (clientNom != null && clientNom!.trim().isNotEmpty)
          ? clientNom!
          : 'Client Divers';

  int get nombreTotalArticles {
    return produits.fold(0, (acc, item) {
      final qte = (item['quantite'] as num?)?.toInt() ?? 1;
      return acc + qte;
    });
  }

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
  factory Vente.fromJson(Map<String, dynamic> json, [String? docId]) {
    final double totalVal = (json['total'] as num?)?.toDouble() ?? 0.0;
    final double payeVal = (json['montantPaye'] as num?)?.toDouble() ?? 0.0;

    final double resteVal = (json['resteAPayer'] as num?)?.toDouble() ??
        ((totalVal - payeVal) < 0 ? 0.0 : totalVal - payeVal);

    return Vente(
      id: docId ?? json['id']?.toString() ?? '',
      entrepriseId: json['entrepriseId']?.toString() ?? '',
      produits: (json['produits'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          const [],
      total: totalVal,
      date: _parseDate(json['date']),
      clientNom: json['clientNom']?.toString() ?? json['nomClient']?.toString(),
      methodePaiement: json['methodePaiement']?.toString() ?? 'Cash',
      statutPaiement: json['statutPaiement']?.toString() ?? 'Payé',
      montantPaye: payeVal,
      resteAPayer: resteVal,
      statutLivraison: json['statutLivraison']?.toString() ?? 'Livré',
      comptabilise: json['comptabilise'] as bool? ?? false,
    );
  }

  /// Factory pratique pour Firestore DocumentSnapshot
  factory Vente.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Vente.fromJson(data, doc.id);
  }

  /// Sérialisation standard vers Map / JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entrepriseId': entrepriseId,
      'produits': produits,
      'total': total,
      'date': date.toIso8601String(),
      'clientNom': clientNom,
      'methodePaiement': methodePaiement,
      'statutPaiement': statutPaiement,
      'montantPaye': montantPaye,
      'resteAPayer': resteAPayer,
      'statutLivraison': statutLivraison,
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
  Vente copyWith({
    String? id,
    String? entrepriseId,
    List<Map<String, dynamic>>? produits,
    double? total,
    DateTime? date,
    String? clientNom,
    String? methodePaiement,
    String? statutPaiement,
    double? montantPaye,
    double? resteAPayer,
    String? statutLivraison,
    bool? comptabilise,
  }) {
    return Vente(
      id: id ?? this.id,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      produits: produits ?? this.produits,
      total: total ?? this.total,
      date: date ?? this.date,
      clientNom: clientNom ?? this.clientNom,
      methodePaiement: methodePaiement ?? this.methodePaiement,
      statutPaiement: statutPaiement ?? this.statutPaiement,
      montantPaye: montantPaye ?? this.montantPaye,
      resteAPayer: resteAPayer ?? this.resteAPayer,
      statutLivraison: statutLivraison ?? this.statutLivraison,
      comptabilise: comptabilise ?? this.comptabilise,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vente &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          entrepriseId == other.entrepriseId &&
          total == other.total &&
          date == other.date &&
          clientNom == other.clientNom &&
          methodePaiement == other.methodePaiement &&
          statutPaiement == other.statutPaiement &&
          montantPaye == other.montantPaye &&
          resteAPayer == other.resteAPayer &&
          statutLivraison == other.statutLivraison &&
          comptabilise == other.comptabilise &&
          listEquals(produits, other.produits);

  @override
  int get hashCode => Object.hash(
        id,
        entrepriseId,
        total,
        date,
        clientNom,
        methodePaiement,
        statutPaiement,
        montantPaye,
        resteAPayer,
        statutLivraison,
        comptabilise,
        Object.hashAll(produits),
      );

  @override
  String toString() {
    return 'Vente(id: $id, total: $total, clientNom: $clientNom, statutPaiement: $statutPaiement, resteAPayer: $resteAPayer, comptabilise: $comptabilise)';
  }
}