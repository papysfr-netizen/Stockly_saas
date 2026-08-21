import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/depense.dart';
import 'user_role_provider.dart';

final depensesStreamProvider = StreamProvider<List<Depense>>((ref) {
  final userProfile = ref.watch(userProfileProvider).value;
  final entrepriseId = userProfile?.entrepriseId ?? '';

  if (entrepriseId.isEmpty) {
    return Stream.value([]);
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

class DepenseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> ajouterDepense(Depense depense) async {
    final docRef = _firestore.collection('depenses').doc();
    final nouvelleDepense = depense.copyWith(id: docRef.id);
    await docRef.set(nouvelleDepense.toJson());
  }

  Future<void> supprimerDepense(String id) async {
    await _firestore.collection('depenses').doc(id).delete();
  }
}

final depenseRepositoryProvider = Provider((ref) => DepenseRepository());