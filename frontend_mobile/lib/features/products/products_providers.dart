import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'product.dart';

/// Les 9 catégories principales — libellés **strictement** comme demandé.
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

/// Genres disponibles pour le filtre « Filtres ».
const List<String> kGenderFilters = ['Homme', 'Femme', 'Unisexe'];

/// Catalogue distant — on récupère via l'API.
final productsCatalogProvider = FutureProvider<List<Product>>((ref) async {
  try {
    final response = await apiClient.get(ApiEndpoints.getProducts);
    if (response.statusCode == 200) {
      final List data = response.data;
      return data.map((json) => Product.fromJson(json)).toList();
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Retourne la liste des catégories réellement présentes en base de données.
final availableCategoriesProvider = Provider<List<String>>((ref) {
  final catalogAsync = ref.watch(productsCatalogProvider);
  return catalogAsync.when(
    data: (products) {
      final categoriesSet = products.map((p) => p.category).toSet();
      final sortedList = categoriesSet.toList()..sort();
      return sortedList;
    },
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});

/// Recherche textuelle (nom, catégorie, référence).
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Filtre catégorie : une des [kMainGlassCategories], ou `null` = toutes.
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Filtre genre : `Homme`, `Femme`, `Unisexe`, ou `null` = tous.
final selectedGenderFilterProvider = StateProvider<String?>((ref) => null);

/// Liste filtrée pour la grille.
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final catalogAsync = ref.watch(productsCatalogProvider);
  
  return catalogAsync.when(
    data: (all) {
      final q = ref.watch(searchQueryProvider).trim().toLowerCase();
      final cat = ref.watch(selectedCategoryProvider);
      final gender = ref.watch(selectedGenderFilterProvider);

      return all.where((p) {
        final matchesQuery = q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            (p.reference?.toLowerCase().contains(q) ?? false);
        final matchesCat = cat == null || p.category == cat;
        final matchesGender =
            gender == null || p.gender.toLowerCase() == gender.toLowerCase();
        return matchesQuery && matchesCat && matchesGender;
      }).toList();
    },
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});

/// IDs favoris.
class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void toggle(String productId) {
    final next = {...state};
    if (next.contains(productId)) {
      next.remove(productId);
    } else {
      next.add(productId);
    }
    state = next;
  }

  bool containsId(String id) => state.contains(id);
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);
