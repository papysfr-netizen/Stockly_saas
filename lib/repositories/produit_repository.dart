import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/produit.dart';

class ProduitRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'produits';

  // ------------------------------------------------------------------
  // 1. Récupération en temps réel des produits (filtrée par Entreprise)
  // ------------------------------------------------------------------
  Stream<List<Produit>> getProduits(String entrepriseId) {
    if (entrepriseId.isEmpty) {
      return Stream<List<Produit>>.value([]);
    }

    return _firestore
        .collection(_collection)
        .where('entrepriseId', isEqualTo: entrepriseId)
        .snapshots()
        .map((snapshot) {
      final List<Produit> produits = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          produits.add(Produit.fromJson(data, doc.id));
        } catch (e, stack) {
          // Affiche l'erreur exacte si un champ Firestore ne correspond pas au modèle
          debugPrint('Erreur de parsing sur le document ${doc.id} : $e\n$stack');
        }
      }

      return produits;
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

    for (var produit in produits) {
      final docRef = _firestore.collection(_collection).doc();
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

    final query = await _firestore
        .collection(_collection)
        .where('entrepriseId', isEqualTo: entrepriseId)
        .where('nom', isEqualTo: produit.nom)
        .get();

    if (query.docs.isNotEmpty) {
      final docId = query.docs.first.id;
      await _firestore.collection(_collection).doc(docId).update({
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

      await _firestore.collection(_collection).add(data);
    }
  }

  // ------------------------------------------------------------------
  // 4. Diminuer la quantité en stock lors d'une vente
  // ------------------------------------------------------------------
  Future<void> diminuerStock(String produitId, int quantiteVendue) async {
    if (produitId.isEmpty) return;

    await _firestore.collection(_collection).doc(produitId).update({
      'quantite': FieldValue.increment(-quantiteVendue),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------------
  // 5. Supprimer un produit
  // ------------------------------------------------------------------
  Future<void> supprimerProduit(String produitId) async {
    if (produitId.isEmpty) return;
    await _firestore.collection(_collection).doc(produitId).delete();
  }
}