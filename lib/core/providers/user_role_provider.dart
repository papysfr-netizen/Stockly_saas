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

  /// Ajouter / modifier des produits, gérer le stock (selon le RÔLE seul).
  /// Pour tenir compte des autorisations du patron, utiliser profile.can(...).
  bool get peutGererStock => isOwner || isGerant;

  /// Voir la comptabilité, les bénéfices, les dépenses et les rapports (RÔLE seul)
  bool get peutVoirFinances => isOwner || isGerant;

  /// Gérer l'équipe et les paramètres sensibles (Propriétaire seulement)
  bool get peutGererEquipe => isOwner;
}

// ================= 1 bis. AUTORISATIONS RÉGLABLES PAR LE PATRON =================
/// Clés enregistrées dans users/{uid}.permissions (Map<String, bool>).
///
/// Règle :
///  - Propriétaire : tout, toujours.
///  - Gérant  : tout AUTORISÉ par défaut ; le patron peut RETIRER.
///  - Caissier : tout INTERDIT par défaut ; le patron peut DONNER.
class Permissions {
  static const String voirFinances = 'voirFinances';
  static const String retours = 'retours';
  static const String gererStock = 'gererStock';
  static const String remisesRetraits = 'remisesRetraits';
  static const String maintenance = 'maintenance';

  /// Ancienne clé (Caisse : bouton « Nouveau produit ») : suit « Gérer le stock ».
  static const String ancienneAjoutProduit = 'canAddProduct';

  /// Ordre d'affichage dans l'écran Équipe.
  static const List<String> toutes = [
    voirFinances,
    retours,
    gererStock,
    remisesRetraits,
    maintenance,
  ];

  static const Map<String, String> titres = {
    voirFinances: 'Voir les finances',
    retours: 'Retours et annulations',
    gererStock: 'Gérer le stock',
    remisesRetraits: 'Remises et retraits',
    maintenance: 'Maintenance des données',
  };

  static const Map<String, String> descriptions = {
    voirFinances: 'P&L, comptabilité, prix d\'achat et marges.',
    retours: 'Enregistrer un retour ou annuler une vente non retirée.',
    gererStock: 'Ajouter, modifier, supprimer des produits, importer un fichier.',
    remisesRetraits: 'Retirer de l\'argent d\'un compte client (et les remises, plus tard).',
    maintenance: 'Paramètres : rattraper les coûts, fusionner les doublons.',
  };
}

// ================= 2. MODÈLE DE PROFIL IMMUABLE =================
@immutable
class UserProfile {
  final String uid;
  final String nom;
  final UserRole role;
  final String entrepriseId;
  final Map<String, bool> permissions;
  /// Boutique de travail (vide = boutique principale)
  final String boutiqueId;

  const UserProfile({
    required this.uid,
    required this.nom,
    required this.role,
    required this.entrepriseId,
    required this.permissions,
    this.boutiqueId = '',
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
      boutiqueId: data['boutiqueId']?.toString() ?? '',
      permissions: rawPermissions.map(
        (key, value) => MapEntry(key, value is bool ? value : false),
      ),
    );
  }

  /// Valeur par défaut d'une autorisation selon le rôle
  /// (gérant : oui ; caissier : non).
  /// (« Maintenance » : non par défaut, même pour le gérant.)
  static bool valeurParDefaut(UserRole role, [String? cle]) =>
      cle == Permissions.maintenance ? role.isOwner : (role.isOwner || role.isGerant);

  /// L'utilisateur a-t-il cette autorisation ?
  ///  - Propriétaire : toujours oui.
  ///  - Sinon : ce que le patron a choisi, ou la valeur par défaut du rôle.
  bool can(String permissionKey) {
    if (role.isOwner) return true;
    // L'ancienne clé « canAddProduct » suit désormais « Gérer le stock ».
    final cle = permissionKey == Permissions.ancienneAjoutProduit
        ? Permissions.gererStock
        : permissionKey;
    return permissions[cle] ?? valeurParDefaut(role, cle);
  }

  // Raccourcis lisibles
  bool get peutVoirFinances => can(Permissions.voirFinances);
  bool get peutFaireRetours => can(Permissions.retours);
  bool get peutGererStock => can(Permissions.gererStock);
  bool get peutRemisesRetraits => can(Permissions.remisesRetraits);
  bool get peutMaintenance => can(Permissions.maintenance);

  UserProfile copyWith({
    String? uid,
    String? nom,
    UserRole? role,
    String? entrepriseId,
    Map<String, bool>? permissions,
    String? boutiqueId,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      nom: nom ?? this.nom,
      role: role ?? this.role,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      permissions: permissions ?? this.permissions,
      boutiqueId: boutiqueId ?? this.boutiqueId,
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
          boutiqueId == other.boutiqueId &&
          mapEquals(permissions, other.permissions);

  @override
  int get hashCode => Object.hash(
        uid,
        nom,
        role,
        entrepriseId,
        boutiqueId,
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
