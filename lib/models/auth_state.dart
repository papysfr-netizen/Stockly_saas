/// État d'authentification de la caisse (POS)
sealed class PosAuthState {
  const PosAuthState();

  // Constructeurs de fabrique pour garder la même syntaxe d'instanciation
  factory PosAuthState.unauthenticated() = PosUnauthenticated;
  
  factory PosAuthState.locked({
    required String uid,
    required String email,
  }) = PosLocked;

  factory PosAuthState.unlocked({
    required String uid,
    required String email,
    required String role,
  }) = PosUnlocked;
}

/// Aucun utilisateur n'est connecté à Firebase
class PosUnauthenticated extends PosAuthState {
  const PosUnauthenticated();
}

/// Utilisateur connecté à Firebase, mais l'écran POS est verrouillé (attend le PIN)
class PosLocked extends PosAuthState {
  final String uid;
  final String email;

  const PosLocked({
    required this.uid,
    required this.email,
  });
}

/// Caisse déverrouillée et prête à l'emploi
class PosUnlocked extends PosAuthState {
  final String uid;
  final String email;
  final String role;

  const PosUnlocked({
    required this.uid,
    required this.email,
    required this.role,
  });
}