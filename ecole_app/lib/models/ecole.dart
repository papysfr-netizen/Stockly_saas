import 'package:cloud_firestore/cloud_firestore.dart';

class Ecole {
  final String id;
  final String nom;
  final String adresse;
  final String telephone;
  final String devise;
  final String anneeScolaire;

  const Ecole({
    required this.id,
    required this.nom,
    this.adresse = '',
    this.telephone = '',
    this.devise = 'FCFA',
    this.anneeScolaire = '',
  });

  factory Ecole.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Ecole(
      id: doc.id,
      nom: m['nom'] ?? '',
      adresse: m['adresse'] ?? '',
      telephone: m['telephone'] ?? '',
      devise: m['devise'] ?? 'FCFA',
      anneeScolaire: m['anneeScolaire'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'nom': nom,
        'adresse': adresse,
        'telephone': telephone,
        'devise': devise,
        'anneeScolaire': anneeScolaire,
      };

  Ecole copyWith({String? nom, String? adresse, String? telephone, String? devise, String? anneeScolaire}) =>
      Ecole(
        id: id,
        nom: nom ?? this.nom,
        adresse: adresse ?? this.adresse,
        telephone: telephone ?? this.telephone,
        devise: devise ?? this.devise,
        anneeScolaire: anneeScolaire ?? this.anneeScolaire,
      );
}
