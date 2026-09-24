import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/models/produit.dart';

class ProduitRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper pour cibler la sous-collection spécifique à l'organisation
  CollectionReference<Map<String, dynamic>> _getCollection(String entrepriseId) {
    return _firestore
        .collection('entreprises') // 👈 Correction : 'entreprises' au lieu de 'organizations'
        .doc(entrepriseId)
        .collection('produits');
  }

  // ------------------------------------------------------------------
  // 1. Récupération en temps réel des produits avec logs de diagnostic
  // ------------------------------------------------------------------
  Stream<List<Produit>> getProduits(String entrepriseId) {
    debugPrint('🔍 [ProduitRepository] Recherche des produits pour entrepriseId : "$entrepriseId"');

    if (entrepriseId.isEmpty) {
      debugPrint('⚠️ [ProduitRepository] entrepriseId est vide !');
      return Stream<List<Produit>>.value([]);
    }

    return _getCollection(entrepriseId)
        .snapshots()
        .map((snapshot) {
      debugPrint('📦 [ProduitRepository] Documents Firestore trouvés dans la sous-collection : ${snapshot.docs.length}');

      final List<Produit> produits = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          produits.add(Produit.fromJson(data, doc.id));
        } catch (e, stack) {
          debugPrint('❌ Erreur de parsing sur le document ${doc.id} : $e\n$stack');
        }
      }

      debugPrint('✅ [ProduitRepository] Produits convertis avec succès : ${produits.length}');
      return produits;
    }).handleError((error) {
      debugPrint('🚨 Erreur Firestore (ex: Règles de sécurité) : $error');
    });
  }

  // ------------------------------------------------------------------
  // 2. Importer une liste de produits en masse (WriteBatch)
  // ------------------------------------------------------------------
  Future<void> importerProduitsEnMasse(
    List<Produit> produits,
    String entrepriseId,
  ) async {
    if (produits.isEmpty || entrepriseId.isEmpty) return;

    final batch = _firestore.batch();
    final collection = _getCollection(entrepriseId);

    for (var produit in produits) {
      final docRef = collection.doc();
      final Map<String, dynamic> data = produit.toJson();

      data['entrepriseId'] = entrepriseId;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      batch.set(docRef, data);
    }

    await batch.commit();
  }

  // ------------------------------------------------------------------
  // 3. Ajouter ou mettre à jour un produit individuel
  // ------------------------------------------------------------------
  Future<void> ajouterOuMettreAJourProduit(
    Produit produit,
    String entrepriseId,
  ) async {
    if (entrepriseId.isEmpty) return;

    final collection = _getCollection(entrepriseId);

    final query = await collection
        .where('nom', isEqualTo: produit.nom)
        .get();

    if (query.docs.isNotEmpty) {
      final docId = query.docs.first.id;
      await collection.doc(docId).update({
        'quantite': FieldValue.increment(produit.quantite),
        'prixAchat': produit.prixAchat,
        'prixVente': produit.prixVente,
        'codeBarre': produit.codeBarre.isNotEmpty
            ? produit.codeBarre
            : query.docs.first.data()['codeBarre'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final Map<String, dynamic> data = produit.toJson();
      data['entrepriseId'] = entrepriseId;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await collection.add(data);
    }
  }

  // ------------------------------------------------------------------
  // 4. Diminuer la quantité en stock lors d'une vente
  // ------------------------------------------------------------------
  Future<void> diminuerStock(String entrepriseId, String produitId, int quantiteVendue) async {
    if (entrepriseId.isEmpty || produitId.isEmpty) return;

    await _getCollection(entrepriseId).doc(produitId).update({
      'quantite': FieldValue.increment(-quantiteVendue),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------------
  // 5. Supprimer un produit
  // ------------------------------------------------------------------
  Future<void> supprimerProduit(String entrepriseId, String produitId) async {
    if (entrepriseId.isEmpty || produitId.isEmpty) return;
    await _getCollection(entrepriseId).doc(produitId).delete();
  }
}