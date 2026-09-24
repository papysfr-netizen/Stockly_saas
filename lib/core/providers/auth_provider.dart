import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider exposant l'instance globale de Firebase Auth
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Stream écouteur direct des changements d'état Firebase Auth
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Classe représentant l'état de l'authentification
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier qui gère les actions d'authentification (Connexion, Déconnexion)
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth;

  AuthNotifier(this._auth) : super(const AuthState(isLoading: true)) {
    // Écoute automatique de l'état Firebase au démarrage
    _auth.authStateChanges().listen((user) {
      state = AuthState(user: user, isLoading: false);
    });
  }

  /// Connexion via Email & Mot de passe
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _translateFirebaseError(e.code),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Une erreur inattendue est survenue.',
      );
      return false;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
    state = const AuthState(user: null, isLoading: false);
  }

  /// Helper pour afficher des messages d'erreur lisibles
  String _translateFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Identifiants incorrects.';
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'too-many-requests':
        return 'Trop de tentatives échouées. Réessayez plus tard.';
      default:
        return 'Erreur de connexion ($code).';
    }
  }
}

/// Provider principal d'authentification accessible dans toute l'application
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return AuthNotifier(auth);
});