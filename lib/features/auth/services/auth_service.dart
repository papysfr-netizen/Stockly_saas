import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> registerEnterprise({
    required String nomEntreprise,
    required String nomGerant,
    required String email,
    required String telephone,
    required String password,
  }) async {
    // 1. Création du compte utilisateur Firebase Auth
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final String uid = userCredential.user!.uid;

    try {
      // 2. PRÉ-GÉNÉRATION DES RÉFÉRENCES (Sans encore écrire dans Firestore)
      // Reference Entreprise
      DocumentReference entrepriseRef = _firestore.collection('entreprises').doc();
      final String entrepriseId = entrepriseRef.id;

      // Référence Boutique Principale (sous-collection)
      DocumentReference boutiqueRef = entrepriseRef.collection('boutiques').doc();

      // Référence Utilisateur
      DocumentReference userRef = _firestore.collection('users').doc(uid);

      // 3. CRÉATION DU BATCH ATOMIQUE
      WriteBatch batch = _firestore.batch();

      // A. Document /entreprises/{entrepriseId}
      batch.set(entrepriseRef, {
        'id': entrepriseId,
        'nom': nomEntreprise.trim(),
        'ownerId': uid,
        'telephone': telephone.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'actif': true,
      });

      // B. Document /entreprises/{entrepriseId}/boutiques/{boutiqueId}
      batch.set(boutiqueRef, {
        'id': boutiqueRef.id,
        'nom': 'Boutique Principale',
        'createdAt': FieldValue.serverTimestamp(),
        'estPrincipale': true,
      });

      // C. Document /users/{uid}
      batch.set(userRef, {
        'uid': uid,
        'nom': nomGerant.trim(),
        'email': email.trim(),
        'telephone': telephone.trim(),
        'entrepriseId': entrepriseId, // 🛡️ Clé d'isolation SaaS Multi-Tenant
        'role': 'owner', // Le créateur de l'entreprise est le propriétaire
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. EXÉCUTION SIMULTANÉE DE TOUTES LES ÉCRITURES
      await batch.commit();

      // 5. Mettre à jour le nom affiché sur Firebase Auth
      await userCredential.user?.updateDisplayName(nomGerant.trim());

      return userCredential;
    } catch (e) {
      // ⚠️ Sécurité : Si l'écriture Firestore échoue, on supprime le compte Auth créé
      await userCredential.user?.delete();
      rethrow;
    }
  }

  // ------------------------------------------------------------------
  // 🔑 Déconnexion
  // ------------------------------------------------------------------
  Future<void> signOut() async {
    await _auth.signOut();
  }
}