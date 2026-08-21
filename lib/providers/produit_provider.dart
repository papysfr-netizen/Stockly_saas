import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/produit.dart';
import '../repositories/produit_repository.dart';

// 1. Instance du Repository
final produitRepositoryProvider = Provider<ProduitRepository>((ref) {
  return ProduitRepository();
});

// 2. Écoute dynamique du statut d'authentification Firebase
final authStateStreamProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 3. Récupération réactive de l'entrepriseId liée à l'utilisateur connecté
final entrepriseIdProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authStateStreamProvider).value;
  if (user == null) return null;

  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  return userDoc.data()?['entrepriseId'] as String?;
});

// 4. Flux multi-tenant synchronisé en temps réel avec la base de données
final produitsStreamProvider = StreamProvider<List<Produit>>((ref) {
  final entrepriseIdAsync = ref.watch(entrepriseIdProvider);

  return entrepriseIdAsync.when(
    data: (entrepriseId) {
      if (entrepriseId == null || entrepriseId.isEmpty) {
        return Stream<List<Produit>>.value([]);
      }
      final repository = ref.watch(produitRepositoryProvider);
      return repository.getProduits(entrepriseId);
    },
    loading: () =>const Stream<List<Produit>>.empty(),
    error: (_, __) => Stream<List<Produit>>.value([]),
  );
});