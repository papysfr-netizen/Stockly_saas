import 'package:flutter_riverpod/flutter_riverpod.dart';

class Entreprise {
  final String id;
  final String nom;
  final String adresse;
  final String telephone;
  final String devise;

  const Entreprise({
    this.id = 'default_entreprise', // Identifiant par défaut de l'entreprise
    this.nom = 'Stockly Pro',
    this.adresse = '',
    this.telephone = '',
    this.devise = '\$',
  });
}

/// Provider qui fournit les informations de l'entreprise/boutique
final entrepriseProvider = Provider<Entreprise>((ref) {
  return const Entreprise(
    id: 'default_entreprise',
    nom: 'Stockly Pro',
    adresse: '',
    telephone: '',
    devise: '\$',
  );
});