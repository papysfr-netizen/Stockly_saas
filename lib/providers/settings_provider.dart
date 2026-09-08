import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configuration immuable de la boutique
@immutable
class ShopSettings {
  final String nomBoutique;
  final String adresse;
  final String telephone;
  final String currency;

  const ShopSettings({
    this.nomBoutique = 'Ma Boutique',
    this.adresse = 'Goma, Nord-Kivu',
    this.telephone = '+243...',
    this.currency = '\$',
  });

  ShopSettings copyWith({
    String? nomBoutique,
    String? adresse,
    String? telephone,
    String? currency,
  }) {
    return ShopSettings(
      nomBoutique: nomBoutique ?? this.nomBoutique,
      adresse: adresse ?? this.adresse,
      telephone: telephone ?? this.telephone,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nomBoutique': nomBoutique,
      'adresse': adresse,
      'telephone': telephone,
      'currency': currency,
    };
  }

  factory ShopSettings.fromMap(Map<String, dynamic> map) {
    return ShopSettings(
      nomBoutique: map['nomBoutique']?.toString() ?? 'Ma Boutique',
      adresse: map['adresse']?.toString() ?? 'Goma, Nord-Kivu',
      telephone: map['telephone']?.toString() ?? '+243...',
      currency: map['currency']?.toString() ?? '\$',
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
          currency == other.currency;

  @override
  int get hashCode => Object.hash(nomBoutique, adresse, telephone, currency);

  @override
  String toString() =>
      'ShopSettings(nomBoutique: $nomBoutique, adresse: $adresse, telephone: $telephone, currency: $currency)';
}

/// Controller de gestion des paramètres du magasin (Riverpod 2.x)
class SettingsNotifier extends Notifier<ShopSettings> {
  @override
  ShopSettings build() => const ShopSettings();

  /// Met à jour les informations de la boutique
  void updateSettings({
    required String nom,
    required String adresse,
    required String phone,
    required String currency,
  }) {
    state = state.copyWith(
      nomBoutique: nom,
      adresse: adresse,
      telephone: phone,
      currency: currency,
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