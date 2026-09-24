import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/depense.dart';
import 'user_role_provider.dart';

/// Repository gérant les opérations CRUD Firestore pour les dépenses
class DepenseRepository {
  final FirebaseFirestore _firestore;

  DepenseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Ajoute une nouvelle dépense et lui assigne l'ID généré par Firestore
  Future<void> ajouterDepense(Depense depense) async {
    final docRef = _firestore.collection('depenses').doc();
    final nouvelleDepense = depense.copyWith(id: docRef.id);
    
    await docRef.set(nouvelleDepense.toJson());
  }

  /// Met à jour une dépense existante
  Future<void> modifierDepense(Depense depense) async {
    if (depense.id.isEmpty) return;
    await _firestore
        .collection('depenses')
        .doc(depense.id)
        .update(depense.toJson());
  }

  /// Supprime une dépense via son identifiant
  Future<void> supprimerDepense(String id) async {
    if (id.isEmpty) return;
    await _firestore.collection('depenses').doc(id).delete();
  }
}

/// Provider du repository des dépenses
final depenseRepositoryProvider = Provider<DepenseRepository>((ref) {
  return DepenseRepository();
});

/// StreamProvider écoutant en temps réel les dépenses de l'entreprise courante
final depensesStreamProvider = StreamProvider<List<Depense>>((ref) {
  // Optimisation Riverpod : On écoute uniquement la propriété 'entrepriseId'.
  // Le flux ne sera pas réinitialisé si d'autres champs non pertinents du profil changent.
  final entrepriseId = ref.watch(
    userProfileProvider.select(
      (asyncProfile) => asyncProfile.value?.entrepriseId ?? '',
    ),
  );

  if (entrepriseId.isEmpty) {
    return Stream.value(const []);
  }

  return FirebaseFirestore.instance
      .collection('depenses')
      .where('entrepriseId', isEqualTo: entrepriseId)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Depense.fromJson(doc.data(), doc.id))
          .toList());
});