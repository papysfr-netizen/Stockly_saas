import 'package:flutter/foundation.dart';

/// État d'authentification de la caisse (POS)
@immutable
sealed class PosAuthState {
  const PosAuthState();

  // Constructeurs de fabrique 'const'
  const factory PosAuthState.unauthenticated() = PosUnauthenticated;

  const factory PosAuthState.locked({
    required String uid,
    required String email,
  }) = PosLocked;

  const factory PosAuthState.unlocked({
    required String uid,
    required String email,
    required String role,
  }) = PosUnlocked;

  // --- Getters utilitaires ---
  bool get isUnauthenticated => this is PosUnauthenticated;
  bool get isLocked => this is PosLocked;
  bool get isUnlocked => this is PosUnlocked;

  /// Récupère l'UID courant s'il existe
  String? get uid => switch (this) {
        PosUnauthenticated() => null,
        PosLocked(:final uid) => uid,
        PosUnlocked(:final uid) => uid,
      };

  /// Récupère l'email courant s'il existe
  String? get email => switch (this) {
        PosUnauthenticated() => null,
        PosLocked(:final email) => email,
        PosUnlocked(:final email) => email,
      };
}

/// Aucun utilisateur n'est connecté
final class PosUnauthenticated extends PosAuthState {
  const PosUnauthenticated();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosUnauthenticated && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'PosAuthState.unauthenticated()';
}

/// Utilisateur connecté à Firebase, mais l'écran POS est verrouillé (attend le code PIN)
final class PosLocked extends PosAuthState {
  @override
  final String uid;
  @override
  final String email;

  const PosLocked({
    required this.uid,
    required this.email,
  });

  PosLocked copyWith({
    String? uid,
    String? email,
  }) {
    return PosLocked(
      uid: uid ?? this.uid,
      email: email ?? this.email,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosLocked &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email;

  @override
  int get hashCode => Object.hash(uid, email);

  @override
  String toString() => 'PosAuthState.locked(uid: $uid, email: $email)';
}

/// Caisse déverrouillée et prête pour les transactions
final class PosUnlocked extends PosAuthState {
  @override
  final String uid;
  @override
  final String email;
  final String role;

  const PosUnlocked({
    required this.uid,
    required this.email,
    required this.role,
  });

  PosUnlocked copyWith({
    String? uid,
    String? email,
    String? role,
  }) {
    return PosUnlocked(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosUnlocked &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          role == other.role;

  @override
  int get hashCode => Object.hash(uid, email, role);

  @override
  String toString() =>
      'PosAuthState.unlocked(uid: $uid, email: $email, role: $role)';
}