class Vente {
  final String id;
  final List<Map<String, dynamic>> produits;
  final double total;
  final DateTime date;
  final String? clientNom;
  final String methodePaiement;
  final String statutPaiement;
  final double montantPaye;
  final double resteAPayer;
  final String statutLivraison;

  Vente({
    required this.id,
    required this.produits,
    required this.total,
    required this.date,
    this.clientNom,
    this.methodePaiement = 'Cash',
    this.statutPaiement = 'Payé',
    this.montantPaye = 0.0,
    this.resteAPayer = 0.0,
    this.statutLivraison = 'Livré',
  });

  // Conversion depuis JSON / Firestore (gère aussi bien les dates ISO que les Timestamps Firestore)
  factory Vente.fromJson(Map<String, dynamic> json, [String? docId]) {
    DateTime parsedDate;
    if (json['date'] == null) {
      parsedDate = DateTime.now();
    } else if (json['date'] is String) {
      parsedDate = DateTime.parse(json['date'] as String);
    } else {
      // Pour la compatibilité avec Firestore Timestamp
      try {
        parsedDate = (json['date'] as dynamic).toDate();
      } catch (_) {
        parsedDate = DateTime.now();
      }
    }

    return Vente(
      id: docId ?? json['id'] ?? '',
      produits: (json['produits'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      date: parsedDate,
      clientNom: json['clientNom'] as String?,
      methodePaiement: json['methodePaiement'] as String? ?? 'Cash',
      statutPaiement: json['statutPaiement'] as String? ?? 'Payé',
      montantPaye: (json['montantPaye'] as num?)?.toDouble() ?? 0.0,
      resteAPayer: (json['resteAPayer'] as num?)?.toDouble() ?? 0.0,
      statutLivraison: json['statutLivraison'] as String? ?? 'Livré',
    );
  }

  // Conversion vers JSON / Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produits': produits,
      'total': total,
      'date': date.toIso8601String(),
      'clientNom': clientNom,
      'methodePaiement': methodePaiement,
      'statutPaiement': statutPaiement,
      'montantPaye': montantPaye,
      'resteAPayer': resteAPayer,
      'statutLivraison': statutLivraison,
    };
  }

  // Permet de dupliquer/modifier facilement un objet Vente
  Vente copyWith({
    String? id,
    List<Map<String, dynamic>>? produits,
    double? total,
    DateTime? date,
    String? clientNom,
    String? methodePaiement,
    String? statutPaiement,
    double? montantPaye,
    double? resteAPayer,
    String? statutLivraison,
  }) {
    return Vente(
      id: id ?? this.id,
      produits: produits ?? this.produits,
      total: total ?? this.total,
      date: date ?? this.date,
      clientNom: clientNom ?? this.clientNom,
      methodePaiement: methodePaiement ?? this.methodePaiement,
      statutPaiement: statutPaiement ?? this.statutPaiement,
      montantPaye: montantPaye ?? this.montantPaye,
      resteAPayer: resteAPayer ?? this.resteAPayer,
      statutLivraison: statutLivraison ?? this.statutLivraison,
    );
  }
}