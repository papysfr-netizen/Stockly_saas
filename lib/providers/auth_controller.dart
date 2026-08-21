import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_state.dart'; // Importation de l'état en Dart classique

class AuthController extends StateNotifier<PosAuthState> {
  AuthController() : super(PosAuthState.unauthenticated());

  // Méthode pour simuler ou définir l'état verrouillé avec l'utilisateur connecté
  void setLockedUser(String uid, String email) {
    state = PosAuthState.locked(uid: uid, email: email);
  }

  // Méthode de vérification du code PIN avec logs de débogage
  Future<bool> unlockWithPin(String enteredPin, String expectedPin, String role) async {
    debugPrint("PIN Saisi : '$enteredPin' (longueur: ${enteredPin.length})");
    debugPrint("PIN Attendu (Firestore) : '$expectedPin'");

    if (enteredPin == expectedPin) {
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

  void lock() {
    // Si l'état actuel est déverrouillé, on passe en verrouillé avec `if case`
    if (state case PosUnlocked(:final uid, :final email)) {
      state = PosAuthState.locked(uid: uid, email: email);
    }
  }

  void signOut() {
    state = PosAuthState.unauthenticated();
  }

  // Méthode pour enregistrer l'activité de l'utilisateur
  void registerUserActivity() {
    // Optionnel : ajouter de la logique d'activité si besoin
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, PosAuthState>((ref) {
  return AuthController();
});