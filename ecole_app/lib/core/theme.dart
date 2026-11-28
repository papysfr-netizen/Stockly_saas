import 'package:flutter/material.dart';

const _graine = Color(0xFF1E5AA8);

/// Couleurs d'état (réussite, attention, danger…), lisibles en clair et en sombre.
@immutable
class CouleursEtat extends ThemeExtension<CouleursEtat> {
  const CouleursEtat({
    required this.succes,
    required this.attention,
    required this.danger,
    required this.info,
    required this.neutre,
    required this.bandeau,
    required this.surBandeau,
  });

  final Color succes, attention, danger, info, neutre;

  /// Bandeau d'information (ex. « Démonstration »).
  final Color bandeau, surBandeau;

  static const clair = CouleursEtat(
    succes: Color(0xFF2E7D32),
    attention: Color(0xFFB45309),
    danger: Color(0xFFC62828),
    info: Color(0xFF1565C0),
    neutre: Color(0xFF546E7A),
    bandeau: Color(0xFFFFECB3),
    surBandeau: Color(0xFF3E2C00),
  );

  static const sombre = CouleursEtat(
    succes: Color(0xFF81C784),
    attention: Color(0xFFFFB74D),
    danger: Color(0xFFEF9A9A),
    info: Color(0xFF90CAF9),
    neutre: Color(0xFFB0BEC5),
    bandeau: Color(0xFF4A3B12),
    surBandeau: Color(0xFFFFE8A3),
  );

  @override
  CouleursEtat copyWith({Color? succes, Color? attention, Color? danger, Color? info, Color? neutre, Color? bandeau, Color? surBandeau}) =>
      CouleursEtat(
        succes: succes ?? this.succes,
        attention: attention ?? this.attention,
        danger: danger ?? this.danger,
        info: info ?? this.info,
        neutre: neutre ?? this.neutre,
        bandeau: bandeau ?? this.bandeau,
        surBandeau: surBandeau ?? this.surBandeau,
      );

  @override
  CouleursEtat lerp(CouleursEtat? other, double t) {
    if (other == null) return this;
    return CouleursEtat(
      succes: Color.lerp(succes, other.succes, t)!,
      attention: Color.lerp(attention, other.attention, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      neutre: Color.lerp(neutre, other.neutre, t)!,
      bandeau: Color.lerp(bandeau, other.bandeau, t)!,
      surBandeau: Color.lerp(surBandeau, other.surBandeau, t)!,
    );
  }
}

extension CouleursEtatX on BuildContext {
  CouleursEtat get etat => Theme.of(this).extension<CouleursEtat>() ?? CouleursEtat.clair;
}

ThemeData buildTheme([Brightness luminosite = Brightness.light]) {
  final scheme = ColorScheme.fromSeed(seedColor: _graine, brightness: luminosite);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: 'Roboto',
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    cardTheme: const CardThemeData(margin: EdgeInsets.symmetric(vertical: 4)),
    extensions: [luminosite == Brightness.dark ? CouleursEtat.sombre : CouleursEtat.clair],
  );
}
