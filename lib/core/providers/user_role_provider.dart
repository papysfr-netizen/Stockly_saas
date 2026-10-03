import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ================= 1. RÔLES (SYSTÈME UNIQUE) =================
/// Les 3 rôles de Stockly :
///  - owner    : Propriétaire (tout)
///  - gerant   : Gérant (stock, ventes, dépenses, dettes, rapports)
///  - caissier : Caissier (caisse + consultation du stock)
enum UserRole {
  owner('Propriétaire'),
  gerant('Gérant'),
  caissier('Caissier');

  /// Nom affiché à l'écran
  final String label;

  const UserRole(this.label);

  /// Convertit la valeur Firestore en rôle.
  /// Accepte les anciennes valeurs et les variantes (accents, majuscules).
  static UserRole fromString(String? value) {
    switch (_normaliser(value)) {
      case 'owner':
      case 'proprietaire':
      case 'patron':
        return UserRole.owner;
      case 'gerant':
      case 'admin':
      case 'administrateur':
      case 'chefboutique':
      case 'chef_boutique':
      case 'chef':
      case 'comptable':
        return UserRole.gerant;
      case 'caissier':
      default:
        return UserRole.caissier;
    }
  }

  /// Met en minuscules, enlève les espaces et les accents.
  static String _normaliser(String? value) {
    if (value == null) return '';
    var v = value.toLowerCase().trim();
    const accents = {
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'à': 'a', 'â': 'a',
      'î': 'i', 'ï': 'i',
      'ô': 'o',
      'û': 'u', 'ù': 'u',
      'ç': 'c',
    };
    accents.forEach((avec, sans) {
      v = v.replaceAll(avec, sans);
    });
    return v;
  }
}

extension UserRoleX on UserRole {
  bool get isOwner => this == UserRole.owner;
  bool get isGerant => this == UserRole.gerant;
  bool get isCaissier => this == UserRole.caissier;

  /// Propriétaire ou Gérant (ancien nom conservé pour compatibilité)
  bool get isAdminOrOwner => isOwner || isGerant;

  /// Ajouter / modifier des produits, gérer le stock
  bool get peutGererStock => isOwner || isGerant;

  /// Voir la comptabilité, les bénéfices, les dépenses et les rapports
  bool get peutVoirFinances => isOwner || isGerant;

  /// Gérer l'équipe et les paramètres sensibles (Propriétaire seulement)
  bool get peutGererEquipe => isOwner;
}

// ================= 2. MODÈLE DE PROFIL IMMUABLE =================
@immutable
class UserProfile {
  final String uid;
  final String nom;
  final UserRole role;
  final String entrepriseId;
  final Map<String, bool> permissions;

  const UserProfile({
    required this.uid,
    required this.nom,
    required this.role,
    required this.entrepriseId,
    required this.permissions,
  });

  factory UserProfile.empty() => const UserProfile(
        uid: '',
        nom: '',
        role: UserRole.caissier,
        entrepriseId: '',
        permissions: {},
      );

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    User user,
  ) {
    if (!snapshot.exists || snapshot.data() == null) {
      debugPrint(
        '[Stockly] Profil introuvable dans users/${user.uid} '
        '-> rôle caissier par défaut',
      );
      return UserProfile.empty().copyWith(
        uid: user.uid,
        nom: user.displayName ?? '',
      );
    }

    final data = snapshot.data()!;
    final rawPermissions = data['permissions'] as Map<String, dynamic>? ?? {};
    final role = UserRole.fromString(data['role']?.toString());

    debugPrint(
      '[Stockly] Rôle Firestore brut : "${data['role']}" '
      '-> rôle appli : ${role.name}',
    );

    return UserProfile(
      uid: user.uid,
      nom: data['nom'] ?? data['displayName'] ?? user.displayName ?? '',
      role: role,
      entrepriseId: data['entrepriseId']?.toString() ?? '',
      permissions: rawPermissions.map(
        (key, value) => MapEntry(key, value is bool ? value : false),
      ),
    );
  }

  /// Le Propriétaire et le Gérant ont toutes les permissions fines ;
  /// le Caissier seulement celles cochées par le Propriétaire.
  bool can(String permissionKey) {
    if (role.isAdminOrOwner) return true;
    return permissions[permissionKey] ?? false;
  }

  UserProfile copyWith({
    String? uid,
    String? nom,
    UserRole? role,
    String? entrepriseId,
    Map<String, bool>? permissions,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      nom: nom ?? this.nom,
      role: role ?? this.role,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      permissions: permissions ?? this.permissions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          nom == other.nom &&
          role == other.role &&
          entrepriseId == other.entrepriseId &&
          mapEquals(permissions, other.permissions);

  @override
  int get hashCode => Object.hash(
        uid,
        nom,
        role,
        entrepriseId,
        Object.hashAll(permissions.entries),
      );
}

// ================= 3. PROVIDERS D'INJECTION DE DÉPENDANCES =================
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// ================= 4. FLUX D'AUTHENTIFICATION & PROFIL =================
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final userProfileProvider = StreamProvider<UserProfile>((ref) {
  final authAsync = ref.watch(authStateProvider);

  return authAsync.when(
    data: (user) {
      if (user == null) {
        return Stream.value(UserProfile.empty());
      }
      return ref
          .watch(firestoreProvider)
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) => UserProfile.fromFirestore(doc, user));
    },
    loading: () => Stream.value(UserProfile.empty()),
    error: (_, __) => Stream.value(UserProfile.empty()),
  );
});

// ================= 5. PROVIDERS CIBLÉS ET TYPÉS =================

/// Extrait uniquement le rôle actif (`AsyncValue<UserRole>`)
final userRoleProvider = Provider<AsyncValue<UserRole>>((ref) {
  return ref.watch(userProfileProvider).whenData((profile) => profile.role);
});

/// Extrait l'ID de l'entreprise avec suppression des re-rendus inutiles
final entrepriseIdProvider = Provider<String>((ref) {
  return ref.watch(
    userProfileProvider.select((async) => async.value?.entrepriseId ?? ''),
  );
});