import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:stockly_saas/core/providers/settings_provider.dart';

/// Lit les infos du magasin (Paramètres) depuis Firestore,
/// pour les documents imprimés (rapports, reçus...).
/// Fonctionne hors ligne : si le réseau ne répond pas en 3 s,
/// lit la copie gardée sur le téléphone.
class BoutiqueInfoService {
  static Future<DocumentSnapshot<Map<String, dynamic>>> _lireDoc(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      return await ref.get().timeout(const Duration(seconds: 3));
    } catch (_) {
      return await ref.get(const GetOptions(source: Source.cache));
    }
  }

  /// Renvoie les infos du magasin, ou null si indisponibles.
  static Future<ShopSettings?> charger() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      final firestore = FirebaseFirestore.instance;
      final userDoc = await _lireDoc(firestore.collection('users').doc(uid));
      final entrepriseId = userDoc.data()?['entrepriseId']?.toString() ?? '';
      if (entrepriseId.isEmpty) return null;

      final entDoc =
          await _lireDoc(firestore.collection('entreprises').doc(entrepriseId));
      final data = entDoc.data();
      if (data == null) return null;

      return ShopSettings.fromEntreprise(data);
    } catch (e) {
      debugPrint('[Stockly] Infos boutique indisponibles : $e');
      return null;
    }
  }

  /// Garde la valeur enregistrée si elle existe, sinon celle de secours.
  static String choisir(String? enregistre, String secours) {
    final valeur = enregistre?.trim() ?? '';
    return valeur.isNotEmpty ? valeur : secours;
  }
}
