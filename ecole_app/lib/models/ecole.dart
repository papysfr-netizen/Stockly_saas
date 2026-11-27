import 'package:cloud_firestore/cloud_firestore.dart';

class Ecole {
  final String id;
  final String nom;
  final String adresse;
  final String telephone;
  final String devise;
  final String anneeScolaire;

  /// Indicatif téléphonique du pays (ex. +225), pour les numéros saisis en local.
  final String indicatif;

  /// Modèle du message de rappel d'impayé ({parent}, {eleve}, {classe}, {montant}, {ecole}).
  final String modeleRappel;

  const Ecole({
    required this.id,
    required this.nom,
    this.adresse = '',
    this.telephone = '',
    this.devise = 'FCFA',
    this.anneeScolaire = '',
    this.indicatif = '+225',
    this.modeleRappel = '',
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
      indicatif: m['indicatif'] ?? '+225',
      modeleRappel: m['modeleRappel'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'nom': nom,
        'adresse': adresse,
        'telephone': telephone,
        'devise': devise,
        'anneeScolaire': anneeScolaire,
        'indicatif': indicatif,
        'modeleRappel': modeleRappel,
      };

  Ecole copyWith({String? nom, String? adresse, String? telephone, String? devise, String? anneeScolaire, String? indicatif, String? modeleRappel}) =>
      Ecole(
        id: id,
        nom: nom ?? this.nom,
        adresse: adresse ?? this.adresse,
        telephone: telephone ?? this.telephone,
        devise: devise ?? this.devise,
        anneeScolaire: anneeScolaire ?? this.anneeScolaire,
        indicatif: indicatif ?? this.indicatif,
        modeleRappel: modeleRappel ?? this.modeleRappel,
      );
}
