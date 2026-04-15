import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../products/product.dart';

/// Un article dans le panier (produit + quantité).
class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, this.quantity = 1});

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// Gère l'état du panier (ajouter, supprimer, vider, total).
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  /// Ajoute un produit au panier (ou incrémente sa quantité s'il s'y trouve déjà).
  void addItem(Product product) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index)
            state[i].copyWith(quantity: state[i].quantity + 1)
          else
            state[i]
      ];
    } else {
      state = [...state, CartItem(product: product)];
    }
  }

  /// Retire un produit (ou décrémente sa quantité).
  void removeOne(String productId) {
    final index = state.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      if (state[index].quantity > 1) {
        state = [
          for (int i = 0; i < state.length; i++)
            if (i == index)
              state[i].copyWith(quantity: state[i].quantity - 1)
            else
              state[i]
        ];
      } else {
        removeFromCart(productId);
      }
    }
  }

  /// Supprime complètement un produit du panier.
  void removeFromCart(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  /// Vide le panier (après une commande par exemple).
  void clear() {
    state = [];
  }

  /// Calcule le prix total cumulé du panier.
  double get totalPrice {
    return state.fold(0, (sum, item) => sum + (item.product.priceEur * item.quantity));
  }

  /// Nombre total d'articles dans le panier.
  int get itemCount {
    return state.fold(0, (sum, item) => sum + item.quantity);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
