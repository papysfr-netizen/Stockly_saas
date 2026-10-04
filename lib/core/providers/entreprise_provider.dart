import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_provider.dart' show settingsProvider, ShopSettings;

class Entreprise {
  final String id;
  final String nom;
  final String adresse;
  final String telephone;
  final String devise;
  final String rccm;
  final String idNat;
  final String nif;

  const Entreprise({
    this.id = 'default_entreprise',
    this.nom = 'Stockly Pro',
    this.adresse = 'Goma, RDC',
    this.telephone = '',
    this.devise = '\$',
    this.rccm = 'GOM/RCCM/...', // Ajouté pour tes documents officiels
    this.idNat = '...',
    this.nif = '...',
  });

  // Méthode utile pour copier et modifier facilement des champs
  Entreprise copyWith({
    String? id,
    String? nom,
    String? adresse,
    String? telephone,
    String? devise,
    String? rccm,
    String? idNat,
    String? nif,
  }) {
    return Entreprise(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      adresse: adresse ?? this.adresse,
      telephone: telephone ?? this.telephone,
      devise: devise ?? this.devise,
      rccm: rccm ?? this.rccm,
      idNat: idNat ?? this.idNat,
      nif: nif ?? this.nif,
    );
  }
}

/// StateNotifier pour gérer les modifications de l'entreprise
class EntrepriseNotifier extends StateNotifier<Entreprise> {
  EntrepriseNotifier() : super(const Entreprise());

  void mettreAJour(Entreprise nouvelleEntreprise) {
    state = nouvelleEntreprise;
  }

  void modifierNom(String nom) {
    state = state.copyWith(nom: nom);
  }

  void modifierCoordonnees({required String adresse, required String telephone}) {
    state = state.copyWith(adresse: adresse, telephone: telephone);
  }

  void modifierMentionsLegales({required String rccm, required String idNat, required String nif}) {
    state = state.copyWith(rccm: rccm, idNat: idNat, nif: nif);
  }

  /// 🏪 Recopie les vraies infos de la boutique (lues dans Firebase par settingsProvider).
  /// Un champ vide ne remplace pas la valeur actuelle.
  void synchroniserAvec(ShopSettings s) {
    String garder(String nouveau, String actuel) =>
        nouveau.trim().isEmpty ? actuel : nouveau.trim();

    state = state.copyWith(
      nom: (s.nomBoutique.trim().isEmpty || s.nomBoutique == 'Ma Boutique')
          ? state.nom
          : s.nomBoutique.trim(),
      adresse: garder(s.adresse, state.adresse),
      telephone: garder(s.telephone, state.telephone),
      devise: garder(s.currency, state.devise),
      rccm: garder(s.rccm, state.rccm),
      idNat: garder(s.idNat, state.idNat),
      nif: garder(s.nif, state.nif),
    );
  }
}

/// Le provider global.
/// 🏪 Il suit automatiquement les infos de la boutique enregistrées dans Firebase
/// (entreprises/{id} → infosBoutique), pour TOUS les rôles, dès la connexion.
final entrepriseProvider = StateNotifierProvider<EntrepriseNotifier, Entreprise>((ref) {
  final notifier = EntrepriseNotifier();

  ref.listen<ShopSettings>(
    settingsProvider,
    (_, infos) => notifier.synchroniserAvec(infos),
    fireImmediately: true,
  );

  return notifier;
});