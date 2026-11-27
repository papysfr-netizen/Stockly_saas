import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class AuthRepository {
  AuthRepository(this._auth, this._db);
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> authChanges() => _auth.authStateChanges();

  Stream<AppUser?> profil(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? AppUser.fromDoc(d) : null);

  Future<void> connexion(String email, String motDePasse) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: motDePasse);

  Future<void> deconnexion() => _auth.signOut();

  Future<void> motDePasseOublie(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// Crée un compte. Si une invitation existe pour cet e-mail, l'utilisateur
  /// rejoint l'école correspondante ; sinon, [nomEcole] est obligatoire et une
  /// nouvelle école est créée dont il devient la direction.
  Future<void> inscription({
    required String nom,
    required String email,
    required String motDePasse,
    String? nomEcole,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cred = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail, password: motDePasse);
    final uid = cred.user!.uid;

    final invRef = _db.collection('invitations').doc(cleanEmail);
    final inv = await invRef.get();

    if (inv.exists) {
      final invitation = Invitation.fromMap(inv.data()!);
      final user = AppUser(
        uid: uid,
        email: cleanEmail,
        nom: nom.isNotEmpty ? nom : invitation.nom,
        role: invitation.role,
        ecoleId: invitation.ecoleId,
        classeIds: invitation.classeIds,
        eleveIds: invitation.eleveIds,
      );
      final batch = _db.batch()
        ..set(_db.collection('users').doc(uid), {
          ...user.toMap(),
          'invitation': cleanEmail,
          'creeLe': FieldValue.serverTimestamp(),
        })
        ..delete(invRef);
      await batch.commit();
      return;
    }

    if (nomEcole == null || nomEcole.trim().isEmpty) {
      await cred.user!.delete();
      throw FirebaseAuthException(
        code: 'aucune-invitation',
        message: "Aucune invitation pour cet e-mail. Renseignez le nom de l'école pour en créer une.",
      );
    }

    final ecoleRef = _db.collection('ecoles').doc();
    final user = AppUser(
      uid: uid,
      email: cleanEmail,
      nom: nom,
      role: Role.admin,
      ecoleId: ecoleRef.id,
    );
    final batch = _db.batch()
      ..set(ecoleRef, {
        'nom': nomEcole.trim(),
        'devise': 'FCFA',
        'anneeScolaire': _anneeScolaireCourante(),
        'proprietaire': uid,
        'creeLe': FieldValue.serverTimestamp(),
      })
      ..set(_db.collection('users').doc(uid), {
        ...user.toMap(),
        'creeLe': FieldValue.serverTimestamp(),
      });
    await batch.commit();
  }

  static String _anneeScolaireCourante() {
    final now = DateTime.now();
    final debut = now.month >= 9 ? now.year : now.year - 1;
    return '$debut-${debut + 1}';
  }
}
