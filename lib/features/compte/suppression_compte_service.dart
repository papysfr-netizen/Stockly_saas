// 🗑️ Suppression du compte (exigée par Google Play)
//
// - Un EMPLOYÉ supprime son accès : son profil et son compte de connexion.
//   Les ventes qu'il a faites restent dans les registres de l'entreprise.
// - Le PATRON supprime TOUTE l'entreprise : produits, ventes, dettes,
//   comptabilité, clients, dépenses, profils des employés, puis son compte.
//
// Les règles du serveur n'autorisent ces effacements que si l'entreprise est
// marquée « enSuppression » par son propriétaire (voir firestore.rules).
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Pourquoi la suppression n'a pas pu se faire
enum ErreurSuppression {
  motDePasseIncorrect,
  reconnexionRequise,
  pasDeConnexion,
  inconnue,
}

class SuppressionException implements Exception {
  final ErreurSuppression raison;
  final String detail;
  const SuppressionException(this.raison, [this.detail = '']);
  @override
  String toString() => 'SuppressionException($raison) $detail';
}

class SuppressionCompteService {
  SuppressionCompteService._();

  /// Parties de l'entreprise effacées (celles qui n'existent pas sont ignorées)
  static const sousCollections = [
    'produits',
    'ventes',
    'creances',
    'dettes',
    'ecritures_comptables',
    'comptes_clients',
    'boutiques',
    'transferts',
    'retours',
    'clotures',
    'soldes_mensuels',
    'arrivages',
    'journal',
    'clients',
    'fournisseurs',
    'mouvements_stock',
    'livraisons',
    'inventaires',
    'categories',
  ];

  static const _paquet = 300;
  static const _delai = Duration(seconds: 20);

  /// Le compte se connecte-t-il avec un mot de passe ? (sinon : par SMS)
  static bool get aMotDePasse => FirebaseAuth.instance.currentUser?.email?.isNotEmpty ?? false;

  /// Vérifie l'identité (Google l'exige avant d'effacer un compte)
  static Future<void> _verifierIdentite(User user, String motDePasse) async {
    if (user.email != null && user.email!.isNotEmpty) {
      try {
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: user.email!, password: motDePasse),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'network-request-failed') {
          throw const SuppressionException(ErreurSuppression.pasDeConnexion);
        }
        throw const SuppressionException(ErreurSuppression.motDePasseIncorrect);
      }
      return;
    }
    // Connexion par SMS : il faut s'être connecté il y a moins de 5 minutes
    final derniere = user.metadata.lastSignInTime;
    if (derniere == null || DateTime.now().difference(derniere) > const Duration(minutes: 5)) {
      throw const SuppressionException(ErreurSuppression.reconnexionRequise);
    }
  }

  /// Efface les documents d'une requête par paquets (connexion obligatoire)
  static Future<void> _effacerTout(Query<Map<String, dynamic>> requete,
      {Future<void> Function(DocumentSnapshot<Map<String, dynamic>>)? avant}) async {
    final db = FirebaseFirestore.instance;
    while (true) {
      final lot = await requete.limit(_paquet).get(const GetOptions(source: Source.server)).timeout(_delai);
      if (lot.docs.isEmpty) return;
      final batch = db.batch();
      for (final d in lot.docs) {
        if (avant != null) await avant(d);
        batch.delete(d.reference);
      }
      await batch.commit().timeout(_delai);
      if (lot.docs.length < _paquet) return;
    }
  }

  /// Supprime le compte connecté. [progression] reçoit un texte court à afficher.
  static Future<void> supprimer({
    required String motDePasse,
    void Function(int fait, int total)? progression,
  }) async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) throw const SuppressionException(ErreurSuppression.inconnue);
    final db = FirebaseFirestore.instance;

    await _verifierIdentite(user, motDePasse);

    try {
      final profilRef = db.collection('users').doc(user.uid);
      final profil = await profilRef.get(const GetOptions(source: Source.server)).timeout(_delai);
      final entId = (profil.data()?['entrepriseId'] ?? '').toString();

      var estProprietaire = false;
      DocumentReference<Map<String, dynamic>>? entRef;
      if (entId.isNotEmpty) {
        entRef = db.collection('entreprises').doc(entId);
        final ent = await entRef.get(const GetOptions(source: Source.server)).timeout(_delai);
        estProprietaire = ent.exists && ent.data()?['ownerId'] == user.uid;
      }

      if (estProprietaire && entRef != null) {
        final ent = entRef;
        final total = sousCollections.length + 3;
        var fait = 0;
        progression?.call(fait, total);

        // 1. Marquer l'entreprise : le serveur autorise alors l'effacement
        await ent.update({
          'enSuppression': true,
          'suppressionDemandeeLe': FieldValue.serverTimestamp(),
        }).timeout(_delai);

        // 2. Toutes les parties de l'entreprise
        for (final nom in sousCollections) {
          await _effacerTout(
            ent.collection(nom),
            // Comptes clients : leurs mouvements d'abord
            avant: nom == 'comptes_clients'
                ? (d) => _effacerTout(d.reference.collection('mouvements'))
                : null,
          );
          progression?.call(++fait, total);
        }

        // 3. Dépenses et profils des employés
        await _effacerTout(db.collection('depenses').where('entrepriseId', isEqualTo: entId));
        progression?.call(++fait, total);
        final employes = await db
            .collection('users')
            .where('entrepriseId', isEqualTo: entId)
            .get(const GetOptions(source: Source.server))
            .timeout(_delai);
        final batch = db.batch();
        for (final e in employes.docs) {
          if (e.id != user.uid) batch.delete(e.reference);
        }
        await batch.commit().timeout(_delai);
        progression?.call(++fait, total);

        // 4. L'entreprise elle-même
        await ent.delete().timeout(_delai);
        progression?.call(++fait, total);
      }

      // 5. Son profil, puis son compte de connexion
      await profilRef.delete().timeout(_delai);
      await user.delete();
    } on TimeoutException {
      throw const SuppressionException(ErreurSuppression.pasDeConnexion);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw const SuppressionException(ErreurSuppression.reconnexionRequise);
      }
      throw SuppressionException(ErreurSuppression.inconnue, e.code);
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        throw const SuppressionException(ErreurSuppression.pasDeConnexion);
      }
      throw SuppressionException(ErreurSuppression.inconnue, e.code);
    }
    await auth.signOut();
  }
}
