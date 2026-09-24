import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    this.adresse = 'Goma, Nord-Kivu',
    this.telephone = '+243...',
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
      adresse: map['adresse']?.toString() ?? 'Goma, Nord-Kivu',
      telephone: map['telephone']?.toString() ?? '+243...',
      currency: map['currency']?.toString() ?? '\$',
      rccm: map['rccm']?.toString() ?? '',
      idNat: map['idNat']?.toString() ?? '',
      nif: map['nif']?.toString() ?? '',
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

/// Controller de gestion des paramètres du magasin (Riverpod 2.x)
class SettingsNotifier extends Notifier<ShopSettings> {
  @override
  ShopSettings build() => const ShopSettings();

  /// Met à jour les informations de la boutique et les mentions légales
  void updateSettings({
    required String nom,
    required String adresse,
    required String phone,
    required String currency,
    required String rccm,
    required String idNat,
    required String nif,
  }) {
    state = state.copyWith(
      nomBoutique: nom,
      adresse: adresse,
      telephone: phone,
      currency: currency,
      rccm: rccm,
      idNat: idNat,
      nif: nif,
    );
  }
}

/// Provider principal des paramètres
final settingsProvider =
    NotifierProvider<SettingsNotifier, ShopSettings>(SettingsNotifier.new);

/// Provider dérivé ciblé pour la devise d'affichage
final currencyProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider.select((settings) => settings.currency));
});