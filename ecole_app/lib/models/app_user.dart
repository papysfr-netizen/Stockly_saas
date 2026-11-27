import 'package:cloud_firestore/cloud_firestore.dart';

enum Role { admin, secretariat, enseignant, parent }

extension RoleX on Role {
  String get label => switch (this) {
        Role.admin => 'Direction',
        Role.secretariat => 'Secrétariat / comptable',
        Role.enseignant => 'Enseignant',
        Role.parent => 'Parent',
      };

  static Role parse(String? v) =>
      Role.values.firstWhere((r) => r.name == v, orElse: () => Role.parent);
}

class AppUser {
  final String uid;
  final String email;
  final String nom;
  final Role role;
  final String ecoleId;

  /// Pour un enseignant : les classes qui lui sont confiées.
  final List<String> classeIds;

  /// Pour un parent : ses enfants.
  final List<String> eleveIds;

  const AppUser({
    required this.uid,
    required this.email,
    required this.nom,
    required this.role,
    required this.ecoleId,
    this.classeIds = const [],
    this.eleveIds = const [],
  });

  bool get isAdmin => role == Role.admin;
  bool get canManageEleves => role == Role.admin || role == Role.secretariat;
  bool get canManagePaiements => role == Role.admin || role == Role.secretariat;
  bool get canSaisirNotes => role == Role.admin || role == Role.enseignant;
  bool get canFairePresences => role == Role.admin || role == Role.enseignant;

  /// Un enseignant ne voit que ses classes ; la direction voit tout.
  bool peutAccederClasse(String classeId) =>
      role != Role.enseignant || classeIds.contains(classeId);

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      email: m['email'] ?? '',
      nom: m['nom'] ?? '',
      role: RoleX.parse(m['role']),
      ecoleId: m['ecoleId'] ?? '',
      classeIds: List<String>.from(m['classeIds'] ?? const []),
      eleveIds: List<String>.from(m['eleveIds'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'nom': nom,
        'role': role.name,
        'ecoleId': ecoleId,
        'classeIds': classeIds,
        'eleveIds': eleveIds,
      };
}

/// Invitation créée par la direction : quand la personne crée son compte
/// avec cet e-mail, elle rejoint l'école avec le rôle prévu.
class Invitation {
  final String email;
  final String nom;
  final Role role;
  final String ecoleId;
  final List<String> classeIds;
  final List<String> eleveIds;

  const Invitation({
    required this.email,
    required this.nom,
    required this.role,
    required this.ecoleId,
    this.classeIds = const [],
    this.eleveIds = const [],
  });

  factory Invitation.fromMap(Map<String, dynamic> m) => Invitation(
        email: m['email'] ?? '',
        nom: m['nom'] ?? '',
        role: RoleX.parse(m['role']),
        ecoleId: m['ecoleId'] ?? '',
        classeIds: List<String>.from(m['classeIds'] ?? const []),
        eleveIds: List<String>.from(m['eleveIds'] ?? const []),
      );

  Map<String, dynamic> toMap() => {
        'email': email,
        'nom': nom,
        'role': role.name,
        'ecoleId': ecoleId,
        'classeIds': classeIds,
        'eleveIds': eleveIds,
        'creeLe': FieldValue.serverTimestamp(),
      };
}
