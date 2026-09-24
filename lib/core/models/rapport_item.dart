import 'package:flutter/material.dart';

/// 1. Enhanced Enum : embarque directement l'icône, le libellé et des utilitaires
enum TypeRapport {
  dettesClient('Dettes Clients', Icons.person_remove),
  dettesFournisseur('Dettes Fournisseurs', Icons.local_shipping),
  depenses('Dépenses', Icons.money_off),
  documents('Documents', Icons.description),
  transactions('Transactions', Icons.swap_horiz),
  livreCaisse('Livre de Caisse', Icons.account_balance_wallet),
  mouvementStock('Mouvements de Stock', Icons.inventory),
  profitsPertes('Profits & Pertes', Icons.analytics),
  reassort('Réassort', Icons.add_shopping_cart),
  ventesArticles('Ventes par Article', Icons.shopping_bag),
  ventesClient('Ventes par Client', Icons.people),
  ventesDate('Ventes par Date', Icons.calendar_today),
  ventesMois('Ventes par Mois', Icons.calendar_month),
  ventesUtilisateur('Ventes par Utilisateur', Icons.badge);

  final String label;
  final IconData icon;

  const TypeRapport(this.label, this.icon);

  /// Convertit une chaine de caractères en TypeRapport de façon sécurisée
  static TypeRapport fromString(String? name) {
    return TypeRapport.values.firstWhere(
      (e) => e.name.toLowerCase() == name?.trim().toLowerCase(),
      orElse: () => TypeRapport.transactions, // Valeur par défaut
    );
  }
}

/// 2. Modèle Immuable complet (parfait pour Riverpod & Firestore)
@immutable
class RapportItem {
  final String id;
  final String titre;
  final TypeRapport type;
  final bool estFavori;

  const RapportItem({
    required this.id,
    required this.titre,
    required this.type,
    this.estFavori = false,
  });

  /// Duplication avec modification d'état (ex: basculer le statut favori)
  RapportItem copyWith({
    String? id,
    String? titre,
    TypeRapport? type,
    bool? estFavori,
  }) {
    return RapportItem(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      type: type ?? this.type,
      estFavori: estFavori ?? this.estFavori,
    );
  }

  /// Desérialisation depuis une Map / JSON / Firestore
  factory RapportItem.fromMap(Map<String, dynamic> map, [String? docId]) {
    return RapportItem(
      id: docId ?? map['id']?.toString() ?? '',
      titre: map['titre']?.toString() ?? map['title']?.toString() ?? '',
      type: TypeRapport.fromString(map['type']?.toString()),
      estFavori: map['estFavori'] as bool? ?? map['isFavorite'] as bool? ?? false,
    );
  }

  /// Sérialisation vers une Map / JSON / Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titre': titre,
      'type': type.name,
      'estFavori': estFavori,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RapportItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          titre == other.titre &&
          type == other.type &&
          estFavori == other.estFavori;

  @override
  int get hashCode => Object.hash(id, titre, type, estFavori);

  @override
  String toString() {
    return 'RapportItem(id: $id, titre: $titre, type: ${type.name}, estFavori: $estFavori)';
  }
}