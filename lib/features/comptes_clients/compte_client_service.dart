import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/services/utilisateur_service.dart';

// ============================================================================
// 💰 COMPTE CLIENT (dépôts, avoirs, achats, retraits)
//
// entreprises/{id}/comptes_clients/{telephone normalisé}
//   telephone, nom, solde, totalDepots, totalUtilise, totalRetire, updatedAt
// entreprises/{id}/comptes_clients/{tel}/mouvements/{auto}
//   type ('depot' | 'avoir' | 'achat' | 'retrait'), montant (toujours positif),
//   sens (+1 crédit / -1 débit), soldeApres, description, venteId, retourId,
//   methode, date, par, parNom
//
// Comptabilité (SYSCOHADA) : l'argent du client est une DETTE de la boutique
// envers lui → compte 419100 « Clients, avances reçues ».
//   Dépôt   : 571 Caisse (ou 572 Mobile Money) au débit / 419100 au crédit
//   Retrait : 419100 au débit / 571 (ou 572) au crédit
//   Achat et avoir : écrits par la Caisse et l'écran de retour.
// ============================================================================

class CompteClientService {
  static const String compteAvances = '419100';
  static const String libelleAvances = 'Clients, avances reçues (comptes clients)';

  /// Téléphone normalisé (identifiant du compte) : chiffres seulement,
  /// indicatif RDC 243 ajouté aux numéros locaux (0...).
  static String normaliser(String telephone) {
    var n = telephone.replaceAll(RegExp(r'[^\d]'), '');
    if (n.startsWith('00')) n = n.substring(2);
    if (n.startsWith('0')) n = '243${n.substring(1)}';
    return n;
  }

  /// Un numéro est utilisable s'il a au moins 9 chiffres.
  static bool telephoneValide(String telephone) => normaliser(telephone).length >= 9;

  static DocumentReference<Map<String, dynamic>> compteRef(
      String entrepriseId, String telephone) {
    return FirebaseFirestore.instance
        .collection('entreprises')
        .doc(entrepriseId)
        .collection('comptes_clients')
        .doc(normaliser(telephone));
  }

  static double _nombre(dynamic v) => v is num ? v.toDouble() : 0.0;

  static double _arrondi(double v) => (v * 100).roundToDouble() / 100;

  /// Lit le compte : serveur d'abord (4 s), sinon le téléphone. null si absent.
  static Future<Map<String, dynamic>?> lireCompte(
      String entrepriseId, String telephone) async {
    if (!telephoneValide(telephone)) return null;
    final ref = compteRef(entrepriseId, telephone);
    try {
      final d = await ref.get().timeout(const Duration(seconds: 4));
      return d.exists ? d.data() : null;
    } catch (_) {
      try {
        final d = await ref.get(const GetOptions(source: Source.cache));
        return d.exists ? d.data() : null;
      } catch (_) {
        return null;
      }
    }
  }

  /// Solde disponible du client (0 si pas de compte).
  static Future<double> lireSolde(String entrepriseId, String telephone) async {
    final c = await lireCompte(entrepriseId, telephone);
    return _nombre(c?['solde']);
  }

  /// Ajoute DANS UN BATCH le mouvement et la mise à jour du solde (sans commit).
  /// [delta] positif = crédit (dépôt, avoir), négatif = débit (achat, retrait).
  static void ajouterMouvement(
    WriteBatch batch, {
    required String entrepriseId,
    required String telephone,
    required String nom,
    required String type,
    required double delta,
    required double soldeAvant,
    required String description,
    required Timestamp date,
    String? uid,
    String parNom = '',
    String methode = '',
    String? venteId,
    String? retourId,
  }) {
    final ref = compteRef(entrepriseId, telephone);
    final mvtRef = ref.collection('mouvements').doc(); // 🔒 ligne d'historique liée
    final montant = _arrondi(delta.abs());
    final credit = delta > 0;

    batch.set(
      ref,
      {
        'id': ref.id,
        'entrepriseId': entrepriseId,
        'telephone': telephone.trim(),
        if (nom.trim().isNotEmpty) 'nom': nom.trim(),
        'solde': FieldValue.increment(credit ? montant : -montant),
        if (type == 'depot' || type == 'avoir')
          'totalDepots': FieldValue.increment(montant),
        if (type == 'achat') 'totalUtilise': FieldValue.increment(montant),
        if (type == 'retrait') 'totalRetire': FieldValue.increment(montant),
        'updatedAt': date,
        'dernierMouvementId': mvtRef.id, // 🔒 le serveur pourra vérifier la trace
      },
      SetOptions(merge: true),
    );

    batch.set(mvtRef, {
      'id': mvtRef.id,
      'type': type,
      'montant': montant,
      'sens': credit ? 1 : -1,
      'soldeApres': _arrondi(soldeAvant + (credit ? montant : -montant)),
      'description': description,
      'methode': methode,
      'venteId': venteId,
      'retourId': retourId,
      'date': date,
      'par': uid,
      'parNom': parNom,
    });
  }

  static String _compteTresorerie(String methode) =>
      methode == 'Mobile Money' ? '572000' : '571000';

  static String _libelleTresorerie(String methode) =>
      methode == 'Mobile Money' ? 'Monnaie électronique (Mobile Money)' : 'Caisse';

  /// Dépôt d'argent par le client. Retourne false si l'envoi attend internet.
  static Future<bool> depot({
    required String entrepriseId,
    required String telephone,
    required String nom,
    required double montant,
    required String methode, // 'Espèces' | 'Mobile Money'
  }) {
    return _operationTresorerie(
      entrepriseId: entrepriseId,
      telephone: telephone,
      nom: nom,
      montant: montant,
      methode: methode,
      type: 'depot',
    );
  }

  /// Retrait : le client reprend une partie de son argent (gérant et patron).
  static Future<bool> retrait({
    required String entrepriseId,
    required String telephone,
    required String nom,
    required double montant,
    required String methode,
  }) {
    return _operationTresorerie(
      entrepriseId: entrepriseId,
      telephone: telephone,
      nom: nom,
      montant: montant,
      methode: methode,
      type: 'retrait',
    );
  }

  static Future<bool> _operationTresorerie({
    required String entrepriseId,
    required String telephone,
    required String nom,
    required double montant,
    required String methode,
    required String type,
  }) async {
    final m = _arrondi(montant);
    if (m <= 0) throw Exception('Montant invalide.');
    if (!telephoneValide(telephone)) throw Exception('Numéro de téléphone invalide.');

    final db = FirebaseFirestore.instance;
    final now = Timestamp.now();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final parNom = await nomUtilisateurConnecte();
    final soldeAvant = await lireSolde(entrepriseId, telephone);

    if (type == 'retrait' && m > soldeAvant + 0.005) {
      throw Exception('Solde insuffisant (disponible : ${soldeAvant.toStringAsFixed(2)}).');
    }

    final client = nom.trim().isEmpty ? telephone.trim() : nom.trim();
    final estDepot = type == 'depot';
    final batch = db.batch();

    ajouterMouvement(
      batch,
      entrepriseId: entrepriseId,
      telephone: telephone,
      nom: nom,
      type: type,
      delta: estDepot ? m : -m,
      soldeAvant: soldeAvant,
      description: estDepot ? 'Dépôt ($methode)' : 'Retrait ($methode)',
      date: now,
      uid: uid,
      parNom: parNom,
      methode: methode,
    );

    // Écriture comptable
    final ecritureRef = db
        .collection('entreprises')
        .doc(entrepriseId)
        .collection('ecritures_comptables')
        .doc();
    final tresorerie = {
      'accountCode': _compteTresorerie(methode),
      'accountLabel': _libelleTresorerie(methode),
      'debit': estDepot ? m : 0.0,
      'credit': estDepot ? 0.0 : m,
    };
    final avances = {
      'accountCode': compteAvances,
      'accountLabel': '$libelleAvances - $client',
      'debit': estDepot ? 0.0 : m,
      'credit': estDepot ? m : 0.0,
    };
    batch.set(ecritureRef, {
      'id': ecritureRef.id,
      'entrepriseId': entrepriseId,
      'reference': normaliser(telephone),
      'type': estDepot ? 'depot_client' : 'retrait_client',
      'description': estDepot
          ? 'Dépôt sur compte client - $client'
          : 'Retrait du compte client - $client',
      'date': now,
      'lines': estDepot ? [tresorerie, avances] : [avances, tresorerie],
      'montantEncaisse': estDepot ? m : 0.0,
      'montantDecaisse': estDepot ? 0.0 : m,
    });

    try {
      await batch.commit().timeout(const Duration(seconds: 6));
      return true;
    } on TimeoutException {
      return false; // gardé sur le téléphone, envoyé au retour d'internet
    }
  }
}
