import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/app_user.dart';

/// Vérification d'un numéro en cours : il reste à saisir le code reçu par SMS.
class VerificationTelephone {
  VerificationTelephone._(this._confirmer, {this.dejaConnecte = false});
  final Future<void> Function(String code) _confirmer;

  /// Android a validé le numéro tout seul : pas de code à saisir.
  final bool dejaConnecte;
  Future<void> confirmer(String code) => _confirmer(code.trim());
}

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

  // ---------------- E-mail ----------------
  Future<void> connexion(String email, String motDePasse) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: motDePasse);

  Future<void> motDePasseOublie(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// Crée le compte puis le profil. Si le profil ne peut pas encore être créé
  /// (aucune invitation et pas de nom d'école), l'utilisateur reste connecté
  /// et l'écran de finalisation prend le relais.
  Future<void> inscriptionEmail({
    required String nom,
    required String email,
    required String motDePasse,
    String? nomEcole,
  }) async {
    await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(), password: motDePasse);
    await finaliserProfil(nom: nom, nomEcole: nomEcole);
  }

  // ---------------- Téléphone (code SMS) ----------------
  /// Envoie un code SMS au numéro (format E.164). Sur Android, la vérification
  /// peut aboutir automatiquement (voir [VerificationTelephone.dejaConnecte]).
  Future<VerificationTelephone> envoyerCode(String telephone) async {
    if (kIsWeb) {
      // reCAPTCHA invisible géré par Firebase.
      final res = await _auth.signInWithPhoneNumber(telephone);
      return VerificationTelephone._((code) => res.confirm(code));
    }

    final resultat = Completer<VerificationTelephone>();
    await _auth.verifyPhoneNumber(
      phoneNumber: telephone,
      verificationCompleted: (cred) async {
        await _auth.signInWithCredential(cred);
        if (!resultat.isCompleted) {
          resultat.complete(VerificationTelephone._((_) async {}, dejaConnecte: true));
        }
      },
      verificationFailed: (e) {
        if (!resultat.isCompleted) resultat.completeError(e);
      },
      codeSent: (verificationId, _) {
        if (resultat.isCompleted) return;
        resultat.complete(VerificationTelephone._((code) async {
          final cred = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: code);
          await _auth.signInWithCredential(cred);
        }));
      },
      codeAutoRetrievalTimeout: (_) {},
    );
    return resultat.future;
  }

  // ---------------- Profil ----------------
  String get _emailCourant => (_auth.currentUser?.email ?? '').toLowerCase();
  String get _telephoneCourant => _auth.currentUser?.phoneNumber ?? '';

  /// Invitation correspondant à l'e-mail ou au numéro du compte connecté.
  Future<Invitation?> invitationPourMoi() async {
    for (final id in [_emailCourant, _telephoneCourant].where((s) => s.isNotEmpty)) {
      final d = await _db.collection('invitations').doc(id).get();
      if (d.exists) return Invitation.fromMap(d.id, d.data()!);
    }
    return null;
  }

  /// Crée le profil du compte connecté : rejoint l'école de l'invitation s'il y
  /// en a une, sinon crée l'école [nomEcole] dont il devient la direction.
  Future<void> finaliserProfil({required String nom, String? nomEcole}) async {
    final user = _auth.currentUser!;
    final base = {
      'email': _emailCourant,
      'telephone': _telephoneCourant,
      'classeIds': <String>[],
      'eleveIds': <String>[],
      'creeLe': FieldValue.serverTimestamp(),
    };

    final invitation = await invitationPourMoi();
    if (invitation != null) {
      final batch = _db.batch()
        ..set(_db.collection('users').doc(user.uid), {
          ...base,
          'nom': nom.trim().isNotEmpty ? nom.trim() : invitation.nom,
          'role': invitation.role.name,
          'ecoleId': invitation.ecoleId,
          'classeIds': invitation.classeIds,
          'eleveIds': invitation.eleveIds,
          'invitation': invitation.identifiant,
        })
        ..delete(_db.collection('invitations').doc(invitation.identifiant));
      await batch.commit();
      return;
    }

    if (nomEcole == null || nomEcole.trim().isEmpty) {
      throw FirebaseAuthException(
        code: 'aucune-invitation',
        message: "Aucune invitation pour ce compte. Indiquez le nom de l'école pour en créer une.",
      );
    }

    final ecoleRef = _db.collection('ecoles').doc();
    final batch = _db.batch()
      ..set(ecoleRef, {
        'nom': nomEcole.trim(),
        'devise': 'USD',
        'indicatif': '+243',
        'systeme': 'rdc',
        'anneeScolaire': _anneeScolaireCourante(),
        'proprietaire': user.uid,
        'creeLe': FieldValue.serverTimestamp(),
      })
      ..set(_db.collection('users').doc(user.uid), {
        ...base,
        'nom': nom.trim(),
        'role': Role.admin.name,
        'ecoleId': ecoleRef.id,
      });
    await batch.commit();
  }

  Future<void> deconnexion() => _auth.signOut();

  static String _anneeScolaireCourante() {
    final now = DateTime.now();
    final debut = now.month >= 9 ? now.year : now.year - 1;
    return '$debut-${debut + 1}';
  }
}
