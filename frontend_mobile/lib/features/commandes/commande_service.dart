import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../cart/cart_providers.dart';

class OrderService {
  final ApiClient apiClient;

  OrderService(this.apiClient);

  /// Crée une commande pour un produit spécifique.
  Future<bool> createOrder({
    required int productId,
    required int quantity,
    String address = '',
    String notes = '',
    bool isAssuranceUtilisee = false,
    String typeLivraison = 'expedition',
    String modePaiement = 'carte_bancaire',
    int nbMembres = 1,
    int nbLunettes = 1,
  }) async {
    try {
      final response = await apiClient.post(ApiEndpoints.createOrder, data: {
        'monture': productId,
        'quantite': quantity,
        'adresse_livraison': address,
        'notes': notes,
        'is_assurance_utilisee': isAssuranceUtilisee,
        'type_livraison': typeLivraison,
        'mode_paiement': modePaiement,
        'nb_membres_famille': nbMembres,
        'nb_lunettes_famille': nbLunettes,
      });

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Traite le panier complet en envoyant une commande par article.
  Future<bool> processFullCart(
    List<CartItem> cartItems, 
    String address, {
    bool isAssuranceUtilisee = false,
    String typeLivraison = 'expedition',
    String modePaiement = 'carte_bancaire',
    int nbMembres = 1,
    int nbLunettes = 1,
  }) async {
    if (cartItems.isEmpty) return true;

    try {
      // Pour une compatibilité totale avec le backend actuel qui gère 1 produit par commande.
      for (final item in cartItems) {
        final success = await createOrder(
          productId: int.parse(item.product.id),
          quantity: item.quantity,
          address: address,
          isAssuranceUtilisee: isAssuranceUtilisee,
          typeLivraison: typeLivraison,
          modePaiement: modePaiement,
          nbMembres: nbMembres,
          nbLunettes: nbLunettes,
        );
        if (!success) return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Récupère l'historique des commandes de l'utilisateur.
  Future<List<dynamic>> getUserOrders() async {
    try {
      final response = await apiClient.get(ApiEndpoints.myOrders);
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

final orderServiceProvider = Provider<OrderService>((ref) {
  final client = ref.watch(apiClientProvider);
  return OrderService(client);
});
