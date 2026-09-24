import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/auth_state.dart';

class AuthController extends StateNotifier<PosAuthState> {
  AuthController() : super(const PosAuthState.unauthenticated());

  /// Définit l'utilisateur verrouillé lors de la sélection ou connexion initiale
  void setLockedUser(String uid, String email) {
    state = PosAuthState.locked(uid: uid, email: email);
  }

  /// Vérification du code PIN avec logs de débogage
  Future<bool> unlockWithPin(
    String enteredPin,
    String expectedPin,
    String role,
  ) async {
    final cleanEntered = enteredPin.trim();
    final cleanExpected = expectedPin.trim();

    debugPrint("PIN Saisi : '$cleanEntered' (longueur: ${cleanEntered.length})");
    debugPrint("PIN Attendu (Firestore) : '$cleanExpected'");

    if (cleanEntered == cleanExpected) {
      debugPrint("Succès ! Déverrouillage en cours...");

      // Récupération de l'UID et de l'email via le Pattern Matching Dart 3
      final (currentUid, currentEmail) = switch (state) {
        PosLocked(:final uid, :final email) => (uid, email),
        _ => ('', ''),
      };

      state = PosAuthState.unlocked(
        uid: currentUid,
        email: currentEmail,
        role: role,
      );
      return true;
    }

    debugPrint("Échec : PIN incorrect.");
    return false;
  }

  /// Verrouille la session courante si l'utilisateur est déverrouillé
  void lock() {
    if (state case PosUnlocked(:final uid, :final email)) {
      state = PosAuthState.locked(uid: uid, email: email);
    }
  }

  /// Déconnecte complètement l'utilisateur
  void signOut() {
    state = const PosAuthState.unauthenticated();
  }

  /// Enregistre l'activité utilisateur (utilisé pour les timeouts d'inactivité)
  void registerUserActivity() {
    // Logique optionnelle d'actualisation du timer d'inactivité
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, PosAuthState>((ref) {
  return AuthController();
});