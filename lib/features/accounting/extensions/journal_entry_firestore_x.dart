import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/comptabilite_models.dart';

extension EcritureComptableFirestoreX on EcritureComptable {
  /// Conversion adaptée pour Cloud Firestore
  /// [isUpdate] : Si `true`, applique `updatedAt`, sinon `createdAt`.
  Map<String, dynamic> toFirestore({bool isUpdate = false}) {
    final map = <String, dynamic>{
      'entrepriseId': entrepriseId,
      'date': Timestamp.fromDate(date),
      'libelle': libelle,
      'pieceRef': pieceRef,
      'lignes': lignes.map((l) => l.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!isUpdate) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }

    return map;
  }

  /// Création d'une instance depuis un document Firestore
  static EcritureComptable fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    // Parsing sécurisé de la date d'écriture
    final dateRaw = data['date'];
    DateTime dateParsed;
    if (dateRaw is Timestamp) {
      dateParsed = dateRaw.toDate();
    } else if (dateRaw is String) {
      dateParsed = DateTime.tryParse(dateRaw) ?? DateTime.now();
    } else if (dateRaw is int) {
      dateParsed = DateTime.fromMillisecondsSinceEpoch(dateRaw);
    } else {
      dateParsed = DateTime.now();
    }

    // Parsing sécurisé des lignes d'écriture
    final lignesRaw = data['lignes'];
    List<LigneEcriture> lignesParsed = [];

    if (lignesRaw is List) {
      lignesParsed = lignesRaw
          .whereType<Map>()
          .map((l) => LigneEcriture.fromMap(Map<String, dynamic>.from(l)))
          .toList();
    }

    return EcritureComptable(
      id: doc.id,
      entrepriseId: data['entrepriseId']?.toString() ?? '',
      date: dateParsed,
      libelle: data['libelle']?.toString() ?? '',
      pieceRef: data['pieceRef']?.toString() ?? '',
      lignes: lignesParsed,
    );
  }
}