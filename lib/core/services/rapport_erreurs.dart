import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// 🩺 Rapport de plantages « maison » (remplace Crashlytics, retiré car il
/// bloquait le démarrage sur certains téléphones).
///
/// Chaque erreur inattendue de l'application est enregistrée dans la
/// collection Firestore `rapports_erreurs` (lisible dans la console Firebase).
/// Hors ligne, le rapport part plus tard, comme les ventes.
///
/// Règles de prudence :
///  - jamais d'exception : un rapport raté ne doit JAMAIS gêner l'utilisateur ;
///  - au plus [maxParSession] rapports par lancement, et une seule fois
///    la même erreur (une boucle d'erreurs ne doit pas coûter cher) ;
///  - seulement si quelqu'un est connecté (exigé par les règles Firestore).
class RapportErreurs {
  RapportErreurs._();

  static const int maxParSession = 20;
  static const int _maxMessage = 1000;
  static const int _maxPile = 4000;

  static final Set<String> _dejaEnvoyees = {};

  /// Enregistre une erreur. [contexte] = où elle s'est produite (facultatif).
  static Future<void> envoyer(
    Object erreur,
    StackTrace? pile, {
    String contexte = '',
    bool fatale = false,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final message = _couper('$erreur', _maxMessage);
      final lignes = (pile?.toString() ?? '').split('\n').take(25).join('\n');
      final empreinte = '$message|${lignes.split('\n').take(3).join('|')}';
      if (_dejaEnvoyees.length >= maxParSession || !_dejaEnvoyees.add(empreinte)) {
        return;
      }

      await FirebaseFirestore.instance.collection('rapports_erreurs').add({
        'uid': uid,
        'message': message,
        'pile': _couper(lignes, _maxPile),
        'contexte': _couper(contexte, 200),
        'fatale': fatale,
        'plateforme': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'date': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Stockly] Rapport d\'erreur non envoyé : $e');
    }
  }

  static String _couper(String texte, int max) =>
      texte.length <= max ? texte : texte.substring(0, max);

  /// Pour les tests : oublie les erreurs déjà envoyées.
  @visibleForTesting
  static void reinitialiser() => _dejaEnvoyees.clear();
}
