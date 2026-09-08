import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CartOperationResult {
  success,
  stockLimitReached,
  outOfStock,
  error,
}

class CartItem {
  final String id;
  final String nom;
  final double prix;
  final int quantite;
  final int stock;

  const CartItem({
    required this.id,
    required this.nom,
    required this.prix,
    required this.quantite,
    required this.stock,
  });

  double get totalPrice => prix * quantite;

  CartItem copyWith({
    String? id,
    String? nom,
    double? prix,
    int? quantite,
    int? stock,
  }) {
    return CartItem(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prix: prix ?? this.prix,
      quantite: quantite ?? this.quantite,
      stock: stock ?? this.stock,
    );
  }
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  CartOperationResult addProduct(
    String id,
    String nom,
    double prix,
    int quantite,
    int stock,
  ) {
    final index = state.indexWhere((item) => item.id == id);

    if (index != -1) {
      final itemActuel = state[index];
      if (itemActuel.quantite + quantite > stock) {
        return CartOperationResult.stockLimitReached;
      }
      final updatedList = List<CartItem>.from(state);
      updatedList[index] = itemActuel.copyWith(
        quantite: itemActuel.quantite + quantite,
      );
      state = updatedList;
      return CartOperationResult.success;
    } else {
      if (quantite > stock) {
        return CartOperationResult.stockLimitReached;
      }
      state = [
        ...state,
        CartItem(
          id: id,
          nom: nom,
          prix: prix,
          quantite: quantite,
          stock: stock,
        ),
      ];
      return CartOperationResult.success;
    }
  }

  void decrementProduct(String id) {
    final index = state.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final item = state[index];
    if (item.quantite > 1) {
      final updatedList = List<CartItem>.from(state);
      updatedList[index] = item.copyWith(quantite: item.quantite - 1);
      state = updatedList;
    } else {
      removeProduct(id);
    }
  }

  void removeProduct(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void clearCart() {
    state = [];
  }
}

// Providers
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantite);
});

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + item.totalPrice);
});