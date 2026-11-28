import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/format.dart';

class Eleve {
  final String id;
  final String matricule;
  final String nom;
  final String prenom;
  final DateTime? dateNaissance;
  final String sexe; // 'M' ou 'F'
  final String classeId;
  final String parentNom;
  final String parentTelephone;
  final String parentEmail;
  final bool actif;
  final DateTime? dateInscription;

  const Eleve({
    required this.id,
    required this.matricule,
    required this.nom,
    required this.prenom,
    required this.classeId,
    this.dateNaissance,
    this.sexe = 'M',
    this.parentNom = '',
    this.parentTelephone = '',
    this.parentEmail = '',
    this.actif = true,
    this.dateInscription,
  });

  String get nomComplet => '$nom $prenom';

  factory Eleve.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Eleve(
      id: doc.id,
      matricule: m['matricule'] ?? '',
      nom: m['nom'] ?? '',
      prenom: m['prenom'] ?? '',
      dateNaissance: readDate(m['dateNaissance']),
      sexe: m['sexe'] ?? 'M',
      classeId: m['classeId'] ?? '',
      parentNom: m['parentNom'] ?? '',
      parentTelephone: m['parentTelephone'] ?? '',
      parentEmail: m['parentEmail'] ?? '',
      actif: m['actif'] ?? true,
      dateInscription: readDate(m['dateInscription']),
    );
  }

  Map<String, dynamic> toMap() => {
        'matricule': matricule,
        'nom': nom,
        'prenom': prenom,
        'dateNaissance': dateNaissance == null ? null : Timestamp.fromDate(dateNaissance!),
        'sexe': sexe,
        'classeId': classeId,
        'parentNom': parentNom,
        'parentTelephone': parentTelephone,
        'parentEmail': parentEmail.trim().toLowerCase(),
        'actif': actif,
        'dateInscription': Timestamp.fromDate(dateInscription ?? DateTime.now()),
      };
}
