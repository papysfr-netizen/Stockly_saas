import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/produit.dart';
import '../repositories/produit_repository.dart';

// 1. Instance du Repository
final produitRepositoryProvider = Provider<ProduitRepository>((ref) {
  return ProduitRepository();
});

// 2. Écoute du statut d'authentification Firebase
final authStateStreamProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 3. Écoute temps réel de l'entrepriseId
final entrepriseIdProvider = StreamProvider<String?>((ref) {
  final authAsync = ref.watch(authStateStreamProvider);

  return authAsync.when(
    data: (user) {
      if (user == null) {
        debugPrint('⚠️ [entrepriseIdProvider] Aucun utilisateur connecté !');
        return Stream.value(null);
      }
      debugPrint('👤 [entrepriseIdProvider] User UID : ${user.uid}');
      
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) {
        final id = doc.data()?['entrepriseId'] as String?;
        debugPrint('🏢 [entrepriseIdProvider] entrepriseId : "$id"');
        return id;
      });
    },
    loading: () => Stream.value(null),
    error: (err, stack) => Stream.error(err, stack),
  );
});

// 4. Flux multi-tenant réactif des produits
final produitsStreamProvider = StreamProvider<List<Produit>>((ref) {
  final entrepriseId = ref.watch(entrepriseIdProvider).value;

  if (entrepriseId == null || entrepriseId.isEmpty) {
    debugPrint('⚠️ [produitsStreamProvider] En attente de l\'entrepriseId...');
    return Stream.value([]);
  }

  debugPrint('🚀 [produitsStreamProvider] Chargement pour : "$entrepriseId"');
  final repository = ref.watch(produitRepositoryProvider);
  return repository.getProduits(entrepriseId);
});