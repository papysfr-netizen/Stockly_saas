// lib/core/services/equipe_service.dart

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

/// Gestion des comptes de l'équipe (Gérants et Caissiers).
/// Le propriétaire crée le compte avec un identifiant simple : pas besoin d'e-mail.
class EquipeService {
  static const String _domaine = 'stockly.app';
  static const String _nomAppSecondaire = 'creationEquipe';

  /// Minuscules, sans accents, sans espaces : lettres et chiffres seulement.
  static String nettoyer(String texte) {
    const avec = 'àâäáãéèêëíìîïóòôöõúùûüçñ';
    const sans = 'aaaaaeeeeiiiiooooouuuucn';
    var t = texte.toLowerCase().trim();
    for (var i = 0; i < avec.length; i++) {
      t = t.replaceAll(avec[i], sans[i]);
    }
    return t.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Code court de la boutique (6 caractères), pour rendre l'identifiant unique.
  static String codeBoutique(String entrepriseId) {
    final c = entrepriseId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return c.substring(0, min(6, c.length));
  }

  /// Identifiant de connexion complet : "grace" -> "grace.nhgkxz"
  static String loginPour(String identifiant, String entrepriseId) =>
      '${nettoyer(identifiant)}.${codeBoutique(entrepriseId)}';

  /// Adresse technique utilisée par Firebase : "grace.nhgkxz@stockly.app"
  static String emailPourLogin(String login) => '${login.trim().toLowerCase()}@$_domaine';

  /// Deuxième connexion Firebase, cachée : permet de créer un compte
  /// SANS déconnecter le propriétaire.
  static Future<FirebaseApp> _appSecondaire() async {
    for (final app in Firebase.apps) {
      if (app.name == _nomAppSecondaire) return app;
    }
    return Firebase.initializeApp(
      name: _nomAppSecondaire,
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  /// Crée le compte d'un membre et son profil. Renvoie l'identifiant de connexion.
  static Future<String> creerMembre({
    required String entrepriseId,
    required String nom,
    required String identifiant,
    required String motDePasse,
    required String role, // 'gerant' ou 'caissier'
  }) async {
    final login = loginPour(identifiant, entrepriseId);
    final email = emailPourLogin(login);

    final app = await _appSecondaire();
    final authSecondaire = FirebaseAuth.instanceFor(app: app);

    UserCredential cred;
    try {
      cred = await authSecondaire.createUserWithEmailAndPassword(
        email: email,
        password: motDePasse,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_messageErreur(e));
    }

    final nouveau = cred.user!;
    try {
      // Le profil est écrit par le PROPRIÉTAIRE (connexion principale) :
      // les règles de sécurité l'autorisent pour un Gérant ou un Caissier.
      await FirebaseFirestore.instance.collection('users').doc(nouveau.uid).set({
        'uid': nouveau.uid,
        'nom': nom.trim(),
        'email': email,
        'identifiant': login,
        'role': role,
        'entrepriseId': entrepriseId,
        'estActif': true,
        'permissions': {
          'canGiveDiscount': false,
        },
        'creePar': FirebaseAuth.instance.currentUser?.uid,
        'dateCreation': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Le profil n'a pas pu être créé : on supprime le compte pour ne rien laisser à moitié.
      try {
        await nouveau.delete();
      } catch (_) {}
      await authSecondaire.signOut();
      throw Exception('Le profil n\'a pas pu être enregistré : $e');
    }

    await authSecondaire.signOut();
    return login;
  }

  static Future<void> changerRole(String uid, String role) =>
      FirebaseFirestore.instance.collection('users').doc(uid).update({'role': role});

  static Future<void> changerActif(String uid, bool actif) =>
      FirebaseFirestore.instance.collection('users').doc(uid).update({'estActif': actif});

  static Future<void> changerPermission(String uid, String cle, bool valeur) =>
      FirebaseFirestore.instance.collection('users').doc(uid).update({'permissions.$cle': valeur});

  static String _messageErreur(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Cet identifiant est déjà utilisé. Choisissez-en un autre.';
      case 'weak-password':
        return 'Mot de passe trop faible : 6 caractères minimum.';
      case 'invalid-email':
        return 'Identifiant invalide : utilisez seulement des lettres et des chiffres.';
      case 'network-request-failed':
        return 'Pas de connexion internet. La création d\'un compte demande internet.';
      default:
        return 'Création impossible (${e.code}).';
    }
  }
}