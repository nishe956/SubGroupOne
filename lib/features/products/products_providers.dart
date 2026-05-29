import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/montures_service.dart';
import 'product.dart';
import 'products_data.dart';

// ─── Constantes ───────────────────────────────────────────────────────────────

/// Les 9 catégories principales de montures.
const List<String> kMainGlassCategories = [
  'Lunettes de vue',
  'Lunettes de soleil',
  'Anti-lumière bleue',
  'Rondes',
  'Rectangulaires',
  'Carrées',
  'Œil de chat (ou Cat-eye)',
  'Aviateur',
  'Oversize',
];

/// Filtres genre disponibles.
const List<String> kGenderFilters = ['Homme', 'Femme', 'Unisexe'];

// ─── État des produits ────────────────────────────────────────────────────────

enum ProductsStatus { initial, loading, loaded, error }

class ProductsState {
  const ProductsState({
    this.status = ProductsStatus.initial,
    this.products = const [],
    this.error,
  });

  final ProductsStatus status;
  final List<Product> products;
  final String? error;

  ProductsState copyWith({
    ProductsStatus? status,
    List<Product>? products,
    String? error,
  }) {
    return ProductsState(
      status: status ?? this.status,
      products: products ?? this.products,
      error: error,
    );
  }
}

/// Notifier qui charge les produits depuis l'API, avec fallback sur les mock.
class ProductsNotifier extends StateNotifier<ProductsState> {
  ProductsNotifier() : super(const ProductsState()) {
    loadProducts();
  }

  /// Charge les produits depuis le backend Django.
  /// En cas d'échec réseau, utilise les données mock locales.
  Future<void> loadProducts() async {
    state = state.copyWith(status: ProductsStatus.loading);

    try {
      final result = await MonturesService.lister();

      if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
        final products = result.data!
            .map((json) => Product.fromApi(json as Map<String, dynamic>))
            .toList();
        state = ProductsState(
          status: ProductsStatus.loaded,
          products: products,
        );
        return;
      }
    } catch (_) {
      // Erreur réseau → fallback mock
    }

    // Fallback : données locales
    state = ProductsState(
      status: ProductsStatus.loaded,
      products: kMockProducts,
    );
  }

  /// Force le rechargement depuis l'API.
  Future<void> refresh() => loadProducts();
}

final productsProvider =
    StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  return ProductsNotifier();
});

// ─── Filtres ──────────────────────────────────────────────────────────────────

/// Catégorie sélectionnée dans la liste (null = toutes).
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Requête de recherche textuelle.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Filtre genre sélectionné (null = tous).
final selectedGenderProvider = StateProvider<String?>((ref) => null);

/// Liste filtrée calculée à partir des providers précédents.
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final productsState = ref.watch(productsProvider);
  final category = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final gender = ref.watch(selectedGenderProvider);

  return productsState.products.where((p) {
    final matchesCat = category == null || p.category == category;
    final matchesGender = gender == null ||
        p.gender.toLowerCase() == gender.toLowerCase();
    final matchesQuery = query.isEmpty ||
        p.name.toLowerCase().contains(query) ||
        p.category.toLowerCase().contains(query) ||
        (p.reference?.toLowerCase().contains(query) ?? false) ||
        (p.marque?.toLowerCase().contains(query) ?? false);
    return matchesCat && matchesGender && matchesQuery;
  }).toList();
});

// ─── Favoris ─────────────────────────────────────────────────────────────────

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({});

  void toggle(String id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id};
    }
  }

  bool isFavorite(String id) => state.contains(id);
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) => FavoritesNotifier(),
);
