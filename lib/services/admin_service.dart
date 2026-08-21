import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Helper pour pointer sur l'organisation
  static DocumentReference _orgRef(String orgId) {
    return _firestore.collection('organizations').doc(orgId);
  }

  /// Supprime le contenu d'une sous-collection de manière ultra-rapide par lots (Batches de 500)
  static Future<void> _supprimerSousCollectionParLots(
    String entrepriseId,
    String collectionName,
  ) async {
    final collectionRef = _orgRef(entrepriseId).collection(collectionName);

    // Lecture des documents de la sous-collection
    final snapshot = await collectionRef.get();
    if (snapshot.docs.isEmpty) return;

    WriteBatch batch = _firestore.batch();
    int count = 0;

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
      count++;

      // Firestore limite les WriteBatch à 500 opérations
      if (count == 500) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }

    // Soumission du reste s'il en reste
    if (count > 0) {
      await batch.commit();
    }
  }

  /// Réinitialise toutes les données de test d'une entreprise (Ventes, Dépenses, Produits, Compta)
  static Future<void> reinitialiserDonneesTest(String entrepriseId) async {
    // 1. Garde-fou de sécurité
    if (entrepriseId.trim().isEmpty) {

      throw ArgumentError("L'ID de l'organisation ne peut pas être vide.");
    }

    // 2. Nettoyage par lots sur toutes les sous-collections de l'entreprise
    final collectionsANettoyer = [
      'ventes',
      'depenses',
      'produits',
      'ecritures_comptables',
      'audit_logs',
    ];

    for (final collection in collectionsANettoyer) {
      await _supprimerSousCollectionParLots(entrepriseId, collection);
    }
  }
}