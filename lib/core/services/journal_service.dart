import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Journal « qui a fait quoi ».
/// Chaque action importante ajoute une ligne dans
///   entreprises/{entrepriseId}/journal
/// avec : qui (nom + uid), quoi (action + détails), combien, où (boutique), quand.

/// Les types d'actions notées dans le journal.
class ActionsJournal {
  static const String vente = 'vente';
  static const String retour = 'retour';
  static const String annulation = 'annulation';
  static const String produitAjoute = 'produit_ajoute';
  static const String produitModifie = 'produit_modifie';
  static const String produitSupprime = 'produit_supprime';
  static const String transfert = 'transfert';
  static const String import = 'import';
  static const String paiementDette = 'paiement_dette';
  static const String depense = 'depense';
  static const String compteClient = 'compte_client';

  /// Nom affiché à l'écran pour chaque action.
  static const Map<String, String> titres = {
    vente: 'Vente',
    retour: 'Retour',
    annulation: 'Annulation',
    produitAjoute: 'Produit ajouté',
    produitModifie: 'Produit modifié',
    produitSupprime: 'Produit supprimé',
    transfert: 'Transfert',
    import: 'Import de fichier',
    paiementDette: 'Paiement de dette',
    depense: 'Dépense',
    compteClient: 'Compte client',
  };

  static String titre(String action) => titres[action] ?? action;
}

// Nom de la personne connectée, gardé en mémoire pour ne pas le relire à chaque fois.
String? _uidEnMemoire;
String? _nomEnMemoire;

Future<String> _nomUtilisateur(FirebaseFirestore db, User u) async {
  if (_uidEnMemoire == u.uid && (_nomEnMemoire ?? '').isNotEmpty) {
    return _nomEnMemoire!;
  }
  var nom = '';
  try {
    final doc = await db.collection('users').doc(u.uid).get();
    final d = doc.data();
    nom = (d?['nom'] ?? d?['displayName'] ?? '').toString().trim();
  } catch (_) {
    // Hors connexion sans cache : on prend le nom du compte plus bas.
  }
  if (nom.isEmpty) nom = (u.displayName ?? u.email ?? 'Inconnu').trim();
  _uidEnMemoire = u.uid;
  _nomEnMemoire = nom;
  return nom;
}

/// Ajoute une ligne au journal.
///
/// - N'empêche JAMAIS l'action : toute erreur est ignorée.
/// - Hors connexion : la ligne est gardée et part quand Internet revient.
/// - À appeler SANS attendre (pas de await) pour ne pas ralentir la vente.
Future<void> noterJournal({
  required String entrepriseId,
  required String action,
  required String details,
  String? boutiqueId,
  num? montant,
  String? reference,
}) async {
  try {
    if (entrepriseId.isEmpty) return;
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    final db = FirebaseFirestore.instance;
    final nom = await _nomUtilisateur(db, u);

    final ligne = <String, dynamic>{
      'action': action,
      'details': details,
      'userId': u.uid,
      'userNom': nom,
      'boutiqueId': boutiqueId ?? '',
      // Heure du téléphone : sert à trier, même hors connexion.
      'dateLocale': Timestamp.now(),
      // Heure du serveur : remplie quand la ligne arrive en ligne.
      'date': FieldValue.serverTimestamp(),
    };
    if (montant != null) ligne['montant'] = montant;
    if (reference != null && reference.isNotEmpty) ligne['reference'] = reference;

    unawaited(
      db
          .collection('entreprises')
          .doc(entrepriseId)
          .collection('journal')
          .add(ligne)
          .then((_) {}, onError: (Object e) {
        debugPrint('[Journal] Écriture impossible : $e');
      }),
    );
  } catch (e) {
    debugPrint('[Journal] Erreur ignorée : $e');
  }
}
