import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🌙 Apparence choisie : Automatique (suit le téléphone), Clair ou Sombre.
/// Le choix est gardé sur le téléphone.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _charger();
  }

  static const _cle = 'theme_mode';

  Future<void> _charger() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_cle);
      if (v == 'light') {
        state = ThemeMode.light;
      } else if (v == 'dark') {
        state = ThemeMode.dark;
      }
    } catch (_) {
      // Pas de mémoire disponible : on reste sur « Automatique »
    }
  }

  Future<void> choisir(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cle, mode.name);
    } catch (_) {}
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) => ThemeModeNotifier());
