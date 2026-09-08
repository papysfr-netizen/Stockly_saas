import 'package:cloud_firestore/cloud_firestore.dart';

class EcommerceSyncService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> syncProduitToPublicStore({
    required String entrepriseId,
    required String slugStore,
    required String produitId,
    required Map<String, dynamic> produitData,
  }) async {
    final docRef = _db
        .collection('boutiques_publiques')
        .doc(slugStore)
        .collection('catalogue')
        .doc(produitId);

    if (produitData['isPublicEcommerce'] == true) {
      // Préparation des données avec traçabilité entreprise
      final dataToSync = Map<String, dynamic>.from(produitData)
        ..addAll({
          'entrepriseId': entrepriseId,
          'updatedAt': FieldValue.serverTimestamp(),
        });

      // Publier ou mettre à jour dans le catalogue web public
      await docRef.set(dataToSync, SetOptions(merge: true));
    } else {
      // Retirer du catalogue web si l'interrupteur est désactivé
      await docRef.delete();
    }
  }
}