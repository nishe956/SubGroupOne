import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
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

/// Catalogue statique — à remplacer par une source distante / repository.
final productsCatalogProvider = Provider<List<Product>>((ref) => _mockProducts);

/// Recherche textuelle (nom, catégorie, référence).
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Filtre catégorie : une des [kMainGlassCategories], ou `null` = toutes.
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Filtre genre : `Homme`, `Femme`, `Unisexe`, ou `null` = tous.
final selectedGenderFilterProvider = StateProvider<String?>((ref) => null);

/// Liste filtrée pour la grille.
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final all = ref.watch(productsCatalogProvider);
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

/// Correspondance : `product_XX.png` = ordre alphabétique des fichiers sources
/// après copie dans `assets/products/`.
List<Product> get _mockProducts => [
      Product(
        id: '1',
        name: 'Carrées Studio Silver',
        category: 'Carrées',
        gender: 'Unisexe',
        reference: 'CSS-220',
        description:
            'Monture optique carrée adoucie, pont fin et verres clairs. '
            'Lignes nettes inspirées du bureau contemporain, finitions satinées.',
        priceEur: 410,
        imageAsset: 'assets/products/product_01.png',
        heroGradient: [AppColors.brownMedium, AppColors.brownLight],
      ),
      Product(
        id: '2',
        name: 'Solaire Œil de Chat Stella',
        category: 'Œil de chat (ou Cat-eye)',
        gender: 'Femme',
        reference: 'OCS-778',
        description:
            'Grand solaire cat-eye, métal rose gold et verres teal semi-transparents. '
            'Silhouette architecturale pour un effet mode affirmé.',
        priceEur: 465,
        imageAsset: 'assets/products/product_02.png',
        heroGradient: [AppColors.brownLight, AppColors.nude],
      ),
      Product(
        id: '3',
        name: 'Carrées Statement Noir',
        category: 'Carrées',
        gender: 'Unisexe',
        reference: 'CSN-006',
        description:
            'Acétate noir glossy, forme carrée oversize soft. '
            'Accents métal discrets aux charnières pour une touche joaillière.',
        priceEur: 385,
        imageAsset: 'assets/products/product_03.png',
        heroGradient: [AppColors.brownDark, AppColors.brownMedium],
      ),
      Product(
        id: '4',
        name: 'Rondes Harmonie Dorée',
        category: 'Rondes',
        gender: 'Homme',
        reference: 'RHD-441',
        description:
            'Monture percée légère, pont et temples or poli. '
            'Courbes harmonieuses pour un port élégant au quotidien.',
        priceEur: 520,
        imageAsset: 'assets/products/product_04.png',
        heroGradient: [AppColors.brownMedium, AppColors.cream],
      ),
      Product(
        id: '5',
        name: 'Solaire Rectangle Crème',
        category: 'Lunettes de soleil',
        gender: 'Unisexe',
        reference: 'SRC-140',
        description:
            'Rectangle fin argenté, verres à dégradé discret. '
            'Look fresh et outdoor chic, idéal avec tonalités neutres.',
        priceEur: 445,
        imageAsset: 'assets/products/product_05.png',
        heroGradient: [AppColors.brownLight, AppColors.brownDark],
      ),
      Product(
        id: '6',
        name: 'Cat-Eye Tortoise Icône',
        category: 'Œil de chat (ou Cat-eye)',
        gender: 'Femme',
        reference: 'CTI-309',
        description:
            'Écaille chaude narrow vintage, verres ambrés. '
            'Allure rétro luxe, parfaite avec bijoux or.',
        priceEur: 430,
        imageAsset: 'assets/products/product_06.png',
        heroGradient: [AppColors.nude, AppColors.brownMedium],
      ),
      Product(
        id: '7',
        name: 'Rectangulaires Pureté',
        category: 'Rectangulaires',
        gender: 'Homme',
        reference: 'RTP-828',
        description:
            'Percée rectangle, métal argenté et confort maximal. '
            'Minimalisme premium pour visages structurés.',
        priceEur: 490,
        imageAsset: 'assets/products/product_07.png',
        heroGradient: [AppColors.cream, AppColors.brownLight],
      ),
      Product(
        id: '8',
        name: 'Grand Format Anti-Lumière',
        category: 'Anti-lumière bleue',
        gender: 'Homme',
        reference: 'GFA-552',
        description:
            'Masque lecture surdimensionné, verres prescription filtrant le bleu. '
            'Confort écran prolongé sans arrière-goût « gadget ».',
        priceEur: 360,
        imageAsset: 'assets/products/product_08.png',
        heroGradient: [AppColors.brownMedium, AppColors.nude],
      ),
      Product(
        id: '9',
        name: 'Lunettes de Vue Titane Invisible',
        category: 'Lunettes de vue',
        gender: 'Homme',
        reference: 'TIT-701',
        description:
            'Titane pur sans monture, B-titanium gravé sur le verre. '
            'Ultra-léger pour un luxe silencieux et technique.',
        priceEur: 595,
        imageAsset: 'assets/products/product_09.png',
        heroGradient: [AppColors.brownLight, AppColors.brownMedium],
      ),
      Product(
        id: '10',
        name: 'Anti-Lumière Bleue Bureau+',
        category: 'Anti-lumière bleue',
        gender: 'Unisexe',
        reference: 'ALB-204',
        description:
            'Forme browline contemporaine, reflet bleuté maîtrisé sur les verres. '
            'Esthétique studio et protection numérique tout la journée.',
        priceEur: 340,
        imageAsset: 'assets/products/product_10.png',
        heroGradient: [AppColors.nude, AppColors.brownDark],
      ),
      Product(
        id: '11',
        name: 'Aviateur Doré Signature',
        category: 'Aviateur',
        gender: 'Homme',
        reference: 'ADS-991',
        description:
            'Double pont revisité, or brossé et lignes aerodynamiques. '
            'Prestance masculine sans volume superflu.',
        priceEur: 455,
        imageAsset: 'assets/products/product_11.png',
        heroGradient: [AppColors.brownMedium, AppColors.brownDark],
      ),
      Product(
        id: '12',
        name: 'Rectangulaire Filigrane Or',
        category: 'Rectangulaires',
        gender: 'Unisexe',
        reference: 'RFO-118',
        description:
            'Rectangle percé, charnières à motifs et finition or poli. '
            'Pièce d’exception façon bijou optique.',
        priceEur: 680,
        imageAsset: 'assets/products/product_12.png',
        heroGradient: [AppColors.brownDark, AppColors.brownLight],
      ),
      Product(
        id: '13',
        name: 'Oversize Architecturale',
        category: 'Oversize',
        gender: 'Femme',
        reference: 'OSA-404',
        description:
            'Solaire géométrique XL, métal rose gold et verres translucides. '
            'Effet « masque » couture pour un impact immédiat.',
        priceEur: 515,
        imageAsset: 'assets/products/product_13.png',
        heroGradient: [AppColors.brownLight, AppColors.nude],
      ),
      Product(
        id: '14',
        name: 'Lunettes Rondes Classiques',
        category: 'Rondes',
        gender: 'Femme',
        reference: 'LRC-582',
        description:
            'Rond métal argent fin, inspiration vintage 58 mm. '
            'Élégance sobre pour le jour comme pour le soir.',
        priceEur: 375,
        imageAsset: 'assets/products/product_14.png',
        heroGradient: [AppColors.cream, AppColors.brownMedium],
      ),
    ];
