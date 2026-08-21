import 'package:cloud_firestore/cloud_firestore.dart';

class Depense {
  final String id;
  final String entrepriseId;
  final String titre;
  final double montant;
  final String categorie;
  final DateTime date;
  final String? note;
  final String? enregistrePar;

  const Depense({
    required this.id,
    required this.entrepriseId,
    required this.titre,
    required this.montant,
    required this.categorie,
    required this.date,
    this.note,
    this.enregistrePar,
  });

  Depense copyWith({
    String? id,
    String? entrepriseId,
    String? titre,
    double? montant,
    String? categorie,
    DateTime? date,
    String? note,
    String? enregistrePar,
  }) {
    return Depense(
      id: id ?? this.id,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      titre: titre ?? this.titre,
      montant: montant ?? this.montant,
      categorie: categorie ?? this.categorie,
      date: date ?? this.date,
      note: note ?? this.note,
      enregistrePar: enregistrePar ?? this.enregistrePar,
    );
  }

  factory Depense.fromJson(Map<String, dynamic> json, [String? docId]) {
    return Depense(
      id: docId ?? json['id'] as String? ?? '',
      entrepriseId: json['entrepriseId'] as String? ?? '',
      titre: json['titre'] as String? ?? '',
      montant: (json['montant'] as num?)?.toDouble() ?? 0.0,
      categorie: json['categorie'] as String? ?? 'Autre',
      date: json['date'] is Timestamp
          ? (json['date'] as Timestamp).toDate()
          : DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      note: json['note'] as String?,
      enregistrePar: json['enregistrePar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entrepriseId': entrepriseId,
      'titre': titre,
      'montant': montant,
      'categorie': categorie,
      'date': Timestamp.fromDate(date),
      'note': note,
      'enregistrePar': enregistrePar,
    };
  }
}