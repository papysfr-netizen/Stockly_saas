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

  /// Prix ACCORDÉ au client (USD) : c'est lui qui est encaissé
  final double prix;
  final int quantite;
  final int stock;

  /// 🏷️ Prix NORMAL du produit (USD) : pour voir la remise accordée
  final double prixNormal;

  /// Prix d'achat (USD, 0 = inconnu) : pour prévenir d'une vente à perte
  final double prixAchat;

  const CartItem({
    required this.id,
    required this.nom,
    required this.prix,
    required this.quantite,
    required this.stock,
    double? prixNormal,
    this.prixAchat = 0.0,
  }) : prixNormal = prixNormal ?? prix;

  double get totalPrice => prix * quantite;

  /// Le prix a-t-il été négocié ?
  bool get prixNegocie => (prix - prixNormal).abs() > 0.005;

  /// Remise totale accordée sur la ligne (USD)
  double get remiseTotale => (prixNormal - prix) * quantite;

  /// Vendu sous le prix d'achat ?
  bool get aPerte => prixAchat > 0 && prix < prixAchat - 0.005;

  CartItem copyWith({
    String? id,
    String? nom,
    double? prix,
    int? quantite,
    int? stock,
    double? prixNormal,
    double? prixAchat,
  }) {
    return CartItem(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prix: prix ?? this.prix,
      quantite: quantite ?? this.quantite,
      stock: stock ?? this.stock,
      prixNormal: prixNormal ?? this.prixNormal,
      prixAchat: prixAchat ?? this.prixAchat,
    );
  }
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  /// Ajoute un produit. S'il est déjà dans le panier, on augmente la quantité
  /// et on GARDE le prix déjà accordé.
  CartOperationResult addProduct(
    String id,
    String nom,
    double prix,
    int quantite,
    int stock, {
    double? prixNormal,
    double prixAchat = 0.0,
  }) {
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
          prixNormal: prixNormal,
          prixAchat: prixAchat,
        ),
      ];
      return CartOperationResult.success;
    }
  }

  /// 💬 Prix négocié : change le prix accordé d'une ligne (USD)
  void changerPrix(String id, double nouveauPrix) {
    if (nouveauPrix <= 0) return;
    final index = state.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final updatedList = List<CartItem>.from(state);
    updatedList[index] = state[index].copyWith(prix: nouveauPrix);
    state = updatedList;
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

/// Remise totale accordée sur tout le panier (USD)
final cartRemiseProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + item.remiseTotale);
});
