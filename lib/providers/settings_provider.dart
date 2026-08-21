import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShopSettings {
  final String nomBoutique;
  final String adresse;
  final String telephone;
  final String currency;

  ShopSettings({
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
}

class SettingsNotifier extends StateNotifier<ShopSettings> {
  SettingsNotifier() : super(ShopSettings());

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

final settingsProvider = StateNotifierProvider<SettingsNotifier, ShopSettings>((ref) {
  return SettingsNotifier();
});

final currencyProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).currency;
});