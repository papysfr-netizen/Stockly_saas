import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Nom de l'utilisateur connecté, lu dans son profil users/{uid}.
/// Téléphone d'abord (instantané), puis serveur (3 secondes maximum).
Future<String> nomUtilisateurConnecte() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return '';
  final ref = FirebaseFirestore.instance.collection('users').doc(uid);
  try {
    final d = await ref.get(const GetOptions(source: Source.cache));
    final n = d.data()?['nom'];
    if (n is String && n.trim().isNotEmpty) return n.trim();
  } catch (_) {}
  try {
    final d = await ref.get().timeout(const Duration(seconds: 3));
    final n = d.data()?['nom'];
    if (n is String) return n.trim();
  } catch (_) {}
  return '';
}