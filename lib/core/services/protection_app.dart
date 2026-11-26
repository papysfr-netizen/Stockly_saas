// 🛡️ Firebase App Check : seule la VRAIE application Nguli (installée depuis le
// Play Store) peut parler à Firebase et à l'IA. Une application modifiée, un script
// ou quelqu'un qui copierait la configuration Firebase serait refusé, et le quota
// gratuit de l'IA est protégé.
//
// PRÉPARÉ MAIS ÉTEINT : Play Integrity ne fonctionne qu'une fois l'application
// publiée sur le Play Store. Pour l'allumer : fabriquer l'APK/AAB avec
//   --dart-define=APP_CHECK=true
// puis suivre docs/app_check_activation.md (étapes dans la console Firebase).
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

class ProtectionApp {
  ProtectionApp._();

  static const bool active = bool.fromEnvironment('APP_CHECK', defaultValue: false);

  /// À appeler juste après Firebase.initializeApp. Ne bloque jamais le démarrage.
  static Future<void> demarrer() async {
    if (!active || kIsWeb) return;
    try {
      await FirebaseAppCheck.instance.activate(
        // En test sur ordinateur : jeton de débogage ; sur les téléphones : Play Integrity
        androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
      );
      await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
    } catch (e) {
      debugPrint('App Check non démarré : $e');
    }
  }

  /// L'IA Gemini, protégée par App Check quand il est allumé
  static FirebaseAI ia() => FirebaseAI.googleAI(appCheck: active ? FirebaseAppCheck.instance : null);
}
