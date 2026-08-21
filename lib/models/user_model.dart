import 'package:cloud_firestore/cloud_firestore.dart';

/// Rôles utilisateur disponibles dans l'application
enum UserRole {
  gerant,
  chefBoutique,
  comptable,
  caissier,
}

class UserModel {
  final String uid;
  final String email;
  final String nom;
  final UserRole role;
  final bool estActif;
  final DateTime? dateCreation;
  final String entrepriseId;

  UserModel({
    required this.uid,
    required this.email,
    required this.nom,
    this.role = UserRole.caissier,
    this.estActif = true,
    this.dateCreation,
    this.entrepriseId = '',
  });

  // ================= GETTERS DE PERMISSIONS =================
  bool get isGerant => role == UserRole.gerant;
  bool get isChefBoutique => role == UserRole.chefBoutique;
  bool get isComptable => role == UserRole.comptable;
  bool get isCaissier => role == UserRole.caissier;

  /// Accès d'administration globale ou de gestion des stocks/prix
  bool get isAdmin => isGerant || isChefBoutique;
  
  /// Accès aux modules financiers et rapports
  bool get canAccessFinance => isGerant || isComptable;

  // ================= CONVERSIONS & FACTORIES =================
  factory UserModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime? parsedDate;
    if (map['dateCreation'] != null) {
      if (map['dateCreation'] is Timestamp) {
        parsedDate = (map['dateCreation'] as Timestamp).toDate();
      } else if (map['dateCreation'] is String) {
        parsedDate = DateTime.tryParse(map['dateCreation'] as String);
      }
    }

    UserRole parsedRole = UserRole.caissier;
    switch (map['role']?.toString().toLowerCase()) {
      case 'gerant':
      case 'admin':
      case 'owner':
        parsedRole = UserRole.gerant;
        break;
      case 'chefboutique':
      case 'chef_boutique':
        parsedRole = UserRole.chefBoutique;
        break;
      case 'comptable':
        parsedRole = UserRole.comptable;
        break;
      case 'caissier':
      default:
        parsedRole = UserRole.caissier;
        break;
    }

    return UserModel(
      uid: id ?? map['uid'] ?? '',
      email: map['email'] ?? '',
      nom: map['nom'] ?? '',
      role: parsedRole,
      estActif: map['estActif'] ?? true,
      dateCreation: parsedDate,
      entrepriseId: map['entrepriseId'] ?? '',
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json, [String? id]) =>
      UserModel.fromMap(json, id);

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nom': nom,
      'role': role.name,
      'estActif': estActif,
      'entrepriseId': entrepriseId,
      'dateCreation': dateCreation != null
          ? Timestamp.fromDate(dateCreation!)
          : FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  UserModel copyWith({
    String? uid,
    String? email,
    String? nom,
    UserRole? role,
    bool? estActif,
    DateTime? dateCreation,
    String? entrepriseId,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      role: role ?? this.role,
      estActif: estActif ?? this.estActif,
      dateCreation: dateCreation ?? this.dateCreation,
      entrepriseId: entrepriseId ?? this.entrepriseId,
    );
  }
}