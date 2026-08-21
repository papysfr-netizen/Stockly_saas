import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Types de rôles
enum UserRole { owner, admin, caissier }

extension UserRoleX on UserRole {
  bool get isAdminOrOwner => this == UserRole.admin || this == UserRole.owner;
  bool get isOwner => this == UserRole.owner;
  bool get isCaissier => this == UserRole.caissier;
}

// 2. Modèle de Profil Utilisateur (Contient le rôle, le nom, l'entreprise et les autorisations)
class UserProfile {
  final String uid;
  final String nom;
  final UserRole role;
  final String entrepriseId;
  final Map<String, bool> permissions;

  UserProfile({
    required this.uid,
    required this.nom,
    required this.role,
    required this.entrepriseId,
    required this.permissions,
  });

  factory UserProfile.empty() => UserProfile(
        uid: '',
        nom: '',
        role: UserRole.caissier,
        entrepriseId: '',
        permissions: {},
      );

  /// Vérifie si l'utilisateur a le droit d'effectuer une action
  bool can(String permissionKey) {
    if (role.isAdminOrOwner) return true; // Le propriétaire et l'admin ont tous les droits
    return permissions[permissionKey] ?? false;
  }
}

// 3. Stream d'état de connexion
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 4. StreamProvider du profil complet réactif
final userProfileProvider = StreamProvider<UserProfile>((ref) async* {
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.value;

  if (user == null) {
    yield UserProfile.empty();
    return;
  }

  yield* FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists || snapshot.data() == null) {
      return UserProfile.empty();
    }

    final data = snapshot.data()!;
    final String roleStr = (data['role'] ?? 'caissier').toString().toLowerCase();

    UserRole role;
    switch (roleStr) {
      case 'owner':
        role = UserRole.owner;
        break;
      case 'admin':
        role = UserRole.admin;
        break;
      default:
        role = UserRole.caissier;
    }

    // Récupération de la Map de permissions
    final rawPermissions = data['permissions'] as Map<String, dynamic>? ?? {};
    final permissionsMap = rawPermissions.map(
      (key, value) => MapEntry(key, value is bool ? value : false),
    );

    return UserProfile(
      uid: user.uid,
      nom: data['nom'] ?? data['displayName'] ?? user.displayName ?? '',
      role: role,
      entrepriseId: data['entrepriseId'] ?? '',
      permissions: permissionsMap,
    );
  });
});

// 5. Alias pour éviter l'erreur "Undefined name 'userRoleProvider'"
final userRoleProvider = userProfileProvider;