import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/comptabilite_models.dart';

extension EcritureComptableFirestoreX on EcritureComptable {
  /// Conversion adaptée pour Cloud Firestore (conversion DateTime -> Timestamp)
  Map<String, dynamic> toFirestore() {
    return {
      'entrepriseId': entrepriseId,
      'date': Timestamp.fromDate(date),
      'libelle': libelle,
      'pieceRef': pieceRef,
      'lignes': lignes.map((l) => l.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Création d'une instance depuis un document Firestore
  static EcritureComptable fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final dateRaw = data['date'];
    DateTime dateParsed;
    if (dateRaw is Timestamp) {
      dateParsed = dateRaw.toDate();
    } else if (dateRaw is String) {
      dateParsed = DateTime.tryParse(dateRaw) ?? DateTime.now();
    } else {
      dateParsed = DateTime.now();
    }

    return EcritureComptable(
      id: doc.id,
      entrepriseId: data['entrepriseId']?.toString() ?? '',
      date: dateParsed,
      libelle: data['libelle']?.toString() ?? '',
      pieceRef: data['pieceRef']?.toString() ?? '',
      lignes: (data['lignes'] as List<dynamic>?)
              ?.map((l) => LigneEcriture.fromMap(Map<String, dynamic>.from(l as Map)))
              .toList() ??
          [],
    );
  }
}