import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Apparence choisie sur cet appareil : automatique (selon le téléphone), claire ou sombre.
class ApparenceNotifier extends StateNotifier<ThemeMode> {
  ApparenceNotifier() : super(ThemeMode.system) {
    _charger();
  }

  static const _cle = 'apparence';

  Future<void> _charger() async {
    try {
      final p = await SharedPreferences.getInstance();
      state = ThemeMode.values.firstWhere((m) => m.name == p.getString(_cle), orElse: () => ThemeMode.system);
    } catch (_) {
      // Stockage indisponible (navigation privée…) : on reste en automatique.
    }
  }

  Future<void> choisir(ThemeMode mode) async {
    state = mode;
    try {
      await (await SharedPreferences.getInstance()).setString(_cle, mode.name);
    } catch (_) {}
  }
}

final apparenceProvider = StateNotifierProvider<ApparenceNotifier, ThemeMode>((ref) => ApparenceNotifier());
