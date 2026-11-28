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
  final String telephone; // E.164, pour les comptes créés par numéro de téléphone
  final String nom;
  final Role role;
  final String ecoleId;

  /// Pour un enseignant : les classes qui lui sont confiées.
  final List<String> classeIds;

  /// Pour un parent : ses enfants.
  final List<String> eleveIds;

  const AppUser({
    required this.uid,
    required this.nom,
    required this.role,
    required this.ecoleId,
    this.email = '',
    this.telephone = '',
    this.classeIds = const [],
    this.eleveIds = const [],
  });

  String get identifiant => email.isNotEmpty ? email : telephone;

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
      telephone: m['telephone'] ?? '',
      nom: m['nom'] ?? '',
      role: RoleX.parse(m['role']),
      ecoleId: m['ecoleId'] ?? '',
      classeIds: List<String>.from(m['classeIds'] ?? const []),
      eleveIds: List<String>.from(m['eleveIds'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'telephone': telephone,
        'nom': nom,
        'role': role.name,
        'ecoleId': ecoleId,
        'classeIds': classeIds,
        'eleveIds': eleveIds,
      };
}

/// Invitation créée par l'école. Identifiée par l'e-mail (en minuscules) ou
/// le numéro de téléphone (E.164) de la personne : quand elle crée son compte
/// avec cet identifiant, elle rejoint l'école avec le rôle prévu.
class Invitation {
  final String identifiant;
  final String nom;
  final Role role;
  final String ecoleId;
  final List<String> classeIds;
  final List<String> eleveIds;

  const Invitation({
    required this.identifiant,
    required this.nom,
    required this.role,
    required this.ecoleId,
    this.classeIds = const [],
    this.eleveIds = const [],
  });

  bool get parTelephone => identifiant.startsWith('+');

  factory Invitation.fromMap(String id, Map<String, dynamic> m) => Invitation(
        identifiant: id,
        nom: m['nom'] ?? '',
        role: RoleX.parse(m['role']),
        ecoleId: m['ecoleId'] ?? '',
        classeIds: List<String>.from(m['classeIds'] ?? const []),
        eleveIds: List<String>.from(m['eleveIds'] ?? const []),
      );

  Map<String, dynamic> toMap() => {
        'identifiant': identifiant,
        'nom': nom,
        'role': role.name,
        'ecoleId': ecoleId,
        'classeIds': classeIds,
        'eleveIds': eleveIds,
        'creeLe': FieldValue.serverTimestamp(),
      };
}
