import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 1. Modèle immuable avec sérialisation complète et comparaison par valeur
class CartItem {
  final String id;
  final String nom;
  final double prix;
  final int quantite;

  const CartItem({
    required this.id,
    required this.nom,
    required this.prix,
    required this.quantite,
  });

  double get totalPrice => prix * quantite;

  CartItem copyWith({
    String? id,
    String? nom,
    double? prix,
    int? quantite,
  }) {
    return CartItem(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prix: prix ?? this.prix,
      quantite: quantite ?? this.quantite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prix': prix,
      'quantite': quantite,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      prix: (map['prix'] as num?)?.toDouble() ?? 0.0,
      quantite: (map['quantite'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.id == id &&
        other.nom == nom &&
        other.prix == prix &&
        other.quantite == quantite;
  }

  @override
  int get hashCode => Object.hash(id, nom, prix, quantite);
}

/// 2. Notifier moderne Riverpod 2.x
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => const [];

  void addProduct(String id, String nom, double prix, [int quantite = 1]) {
    final index = state.indexWhere((item) => item.id == id);

    if (index != -1) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index)
            state[i].copyWith(quantite: state[i].quantite + quantite)
          else
            state[i]
      ];
    } else {
      state = [
        ...state,
        CartItem(id: id, nom: nom, prix: prix, quantite: quantite)
      ];
    }
  }

  void decrementProduct(String id) {
    final index = state.indexWhere((item) => item.id == id);
    if (index == -1) return;

    if (state[index].quantite > 1) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index)
            state[i].copyWith(quantite: state[i].quantite - 1)
          else
            state[i]
      ];
    } else {
      removeProduct(id);
    }
  }

  void updateQuantity(String id, int quantite) {
    if (quantite <= 0) {
      removeProduct(id);
      return;
    }
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(quantite: quantite) else item
    ];
  }

  void removeProduct(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void clear() {
    state = const [];
  }
}

/// 3. Providers réactifs isolés
final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

/// Provider dérivé : Montant total (re-render ciblé de la caisse)
final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + item.totalPrice);
});

/// Provider dérivé : Nombre total d'articles (pour le badge d'icône panier)
final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantite);
});