import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../providers/user_role_provider.dart';

// Les rôles sont définis à UN SEUL endroit : user_role_provider.dart.
// On les ré-exporte pour les fichiers qui importent seulement ce modèle.
export '../providers/user_role_provider.dart' show UserRole, UserRoleX;

/// Modèle immuable représentant un utilisateur
@immutable
class UserModel {
  final String uid;
  final String email;
  final String nom;
  final UserRole role;
  final bool estActif;
  final DateTime? dateCreation;
  final String entrepriseId;

  const UserModel({
    required this.uid,
    required this.email,
    required this.nom,
    this.role = UserRole.caissier,
    this.estActif = true,
    this.dateCreation,
    this.entrepriseId = '',
  });

  // ================= GETTERS DE PERMISSIONS =================
  bool get isOwner => role.isOwner;
  bool get isGerant => role.isGerant;
  bool get isCaissier => role.isCaissier;

  /// Propriétaire ou Gérant : gestion du stock et des prix
  bool get isAdmin => role.peutGererStock;

  /// Propriétaire ou Gérant : comptabilité, bénéfices, rapports
  bool get canAccessFinance => role.peutVoirFinances;

  /// Propriétaire seulement : équipe et paramètres sensibles
  bool get canManageTeam => role.peutGererEquipe;

  // ================= HELPER DATE =================
  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value);
    } else if (value is DateTime) {
      return value;
    }
    return null;
  }

  // ================= CONVERSIONS & FACTORIES =================
  factory UserModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return UserModel(
      uid: id ?? map['uid']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      nom: map['nom']?.toString() ?? '',
      role: UserRole.fromString(map['role']?.toString()),
      estActif: map['estActif'] as bool? ?? true,
      dateCreation: _parseDate(map['dateCreation']),
      entrepriseId: map['entrepriseId']?.toString() ?? '',
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json, [String? id]) =>
      UserModel.fromMap(json, id);

  /// Construction directe depuis un DocumentSnapshot Firestore
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(data, doc.id);
  }

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          nom == other.nom &&
          role == other.role &&
          estActif == other.estActif &&
          dateCreation == other.dateCreation &&
          entrepriseId == other.entrepriseId;

  @override
  int get hashCode => Object.hash(
        uid,
        email,
        nom,
        role,
        estActif,
        dateCreation,
        entrepriseId,
      );

  @override
  String toString() {
    return 'UserModel(uid: $uid, nom: $nom, email: $email, role: ${role.name}, estActif: $estActif, entrepriseId: $entrepriseId)';
  }
}