import 'package:shared_preferences/shared_preferences.dart';

/// 🖨️ Réglages de l'imprimante, gardés dans CE téléphone
/// (chaque téléphone a sa propre imprimante).
class ReglagesImprimante {
  static const String _clePapier = 'imprimante_papier_mm';
  static const String _cleMode = 'imprimante_mode';

  /// Largeur du papier : 58 ou 80 (mm)
  final int papierMm;

  /// 'android'  = fenêtre d'impression Android
  /// 'partager' = le reçu part en PDF (WhatsApp, Bluetooth, e-mail…)
  final String mode;

  const ReglagesImprimante({this.papierMm = 80, this.mode = 'android'});

  bool get papier58 => papierMm == 58;
  bool get partagerPdf => mode == 'partager';

  ReglagesImprimante copyWith({int? papierMm, String? mode}) =>
      ReglagesImprimante(papierMm: papierMm ?? this.papierMm, mode: mode ?? this.mode);

  static Future<ReglagesImprimante> charger() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return ReglagesImprimante(
        papierMm: prefs.getInt(_clePapier) == 58 ? 58 : 80,
        mode: prefs.getString(_cleMode) == 'partager' ? 'partager' : 'android',
      );
    } catch (_) {
      return const ReglagesImprimante();
    }
  }

  Future<void> enregistrer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_clePapier, papierMm);
    await prefs.setString(_cleMode, mode);
  }
}
