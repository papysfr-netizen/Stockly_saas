import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'user_role_provider.dart';

/// Configuration immuable de la boutique
@immutable
class ShopSettings {
  final String nomBoutique;
  final String adresse;
  final String telephone;
  final String currency;
  final String rccm;
  final String idNat;
  final String nif;

  const ShopSettings({
    this.nomBoutique = 'Ma Boutique',
    this.adresse = '',
    this.telephone = '',
    this.currency = '\$',
    this.rccm = '',
    this.idNat = '',
    this.nif = '',
  });

  ShopSettings copyWith({
    String? nomBoutique,
    String? adresse,
    String? telephone,
    String? currency,
    String? rccm,
    String? idNat,
    String? nif,
  }) {
    return ShopSettings(
      nomBoutique: nomBoutique ?? this.nomBoutique,
      adresse: adresse ?? this.adresse,
      telephone: telephone ?? this.telephone,
      currency: currency ?? this.currency,
      rccm: rccm ?? this.rccm,
      idNat: idNat ?? this.idNat,
      nif: nif ?? this.nif,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nomBoutique': nomBoutique,
      'adresse': adresse,
      'telephone': telephone,
      'currency': currency,
      'rccm': rccm,
      'idNat': idNat,
      'nif': nif,
    };
  }

  factory ShopSettings.fromMap(Map<String, dynamic> map) {
    return ShopSettings(
      nomBoutique: map['nomBoutique']?.toString() ?? 'Ma Boutique',
      adresse: map['adresse']?.toString() ?? '',
      telephone: map['telephone']?.toString() ?? '',
      currency: map['currency']?.toString() ?? '\$',
      rccm: map['rccm']?.toString() ?? '',
      idNat: map['idNat']?.toString() ?? '',
      nif: map['nif']?.toString() ?? '',
    );
  }

  /// Lit le document entreprises/{id}.
  /// Priorité au champ 'infosBoutique' ; sinon, reprend le nom et le
  /// téléphone saisis à la création de l'entreprise.
  factory ShopSettings.fromEntreprise(Map<String, dynamic> data) {
    final infos = data['infosBoutique'];
    if (infos is Map<String, dynamic>) {
      return ShopSettings.fromMap(infos);
    }
    return ShopSettings(
      nomBoutique: data['nom']?.toString() ?? 'Ma Boutique',
      telephone: data['telephone']?.toString() ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopSettings &&
          runtimeType == other.runtimeType &&
          nomBoutique == other.nomBoutique &&
          adresse == other.adresse &&
          telephone == other.telephone &&
          currency == other.currency &&
          rccm == other.rccm &&
          idNat == other.idNat &&
          nif == other.nif;

  @override
  int get hashCode => Object.hash(
        nomBoutique,
        adresse,
        telephone,
        currency,
        rccm,
        idNat,
        nif,
      );

  @override
  String toString() =>
      'ShopSettings(nomBoutique: $nomBoutique, adresse: $adresse, telephone: $telephone, currency: $currency, rccm: $rccm, idNat: $idNat, nif: $nif)';
}

/// Paramètres du magasin, synchronisés avec Firestore
/// (entreprises/{entrepriseId}, champ 'infosBoutique').
/// Fonctionne hors ligne grâce au cache Firestore.
class SettingsNotifier extends Notifier<ShopSettings> {
  @override
  ShopSettings build() {
    final entrepriseId = ref.watch(entrepriseIdProvider);
    if (entrepriseId.isEmpty) return const ShopSettings();

    final abonnement = FirebaseFirestore.instance
        .collection('entreprises')
        .doc(entrepriseId)
        .snapshots()
        .listen(
      (doc) {
        final data = doc.data();
        if (data != null) {
          state = ShopSettings.fromEntreprise(data);
        }
      },
      onError: (e) =>
          debugPrint('[Nguli] Lecture des infos boutique impossible : $e'),
    );
    ref.onDispose(abonnement.cancel);

    return const ShopSettings();
  }

  /// Enregistre les infos du magasin dans Firestore.
  /// Renvoie true si c'est enregistré (sur le serveur, ou sur le
  /// téléphone en attendant le réseau), false en cas d'échec.
  Future<bool> updateSettings({
    required String nom,
    required String adresse,
    required String phone,
    required String currency,
    required String rccm,
    required String idNat,
    required String nif,
  }) async {
    final nouveau = state.copyWith(
      nomBoutique: nom.trim(),
      adresse: adresse.trim(),
      telephone: phone.trim(),
      currency: currency,
      rccm: rccm.trim(),
      idNat: idNat.trim(),
      nif: nif.trim(),
    );
    state = nouveau;

    final entrepriseId = ref.read(entrepriseIdProvider);
    if (entrepriseId.isEmpty) {
      debugPrint('[Nguli] Infos boutique non enregistrées : entreprise inconnue');
      return false;
    }

    try {
      final ecriture = FirebaseFirestore.instance
          .collection('entreprises')
          .doc(entrepriseId)
          .set({'infosBoutique': nouveau.toMap()}, SetOptions(merge: true));

      // Hors ligne : Firestore garde l'écriture sur le téléphone
      // et l'enverra dès que le réseau revient.
      await ecriture.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      debugPrint('[Nguli] Infos boutique gardées sur le téléphone, envoi en attente du réseau');
    } catch (e) {
      debugPrint('[Nguli] Erreur enregistrement infos boutique : $e');
      return false;
    }
    return true;
  }
}

/// Provider principal des paramètres
final settingsProvider =
    NotifierProvider<SettingsNotifier, ShopSettings>(SettingsNotifier.new);

/// Provider dérivé ciblé pour la devise d'affichage
final currencyProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider.select((settings) => settings.currency));
});