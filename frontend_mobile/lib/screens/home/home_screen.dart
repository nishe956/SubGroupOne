import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/api/api_endpoints.dart';
import '../../features/products/products_list_screen.dart';
import '../../features/products/products_providers.dart';
import '../../features/products/product_detail_screen.dart';
import '../../features/ocr/ocr_scan_screen.dart';
import '../../features/ar_try_on/ar_try_on_screen.dart';
import '../../features/products/product.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsCatalogProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.brownDark,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Smart Vision',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.brownDark, AppColors.brownMedium],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.remove_red_eye_outlined,
                      size: 80, color: AppColors.nude),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Expérience IA'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildIAButton(
                          context,
                          'Essai Virtuel',
                          Icons.face_retouching_natural,
                          AppColors.brownMedium,
                          () {
                            // Use the first product from the list for the AR demo if available
                            final firstProduct = productsAsync.value?.firstOrNull;
                            
                            final demoProduct = firstProduct ?? const Product(
                              id: 'demo-1',
                              name: 'Modèle Signature',
                              category: 'Luxe',
                              gender: 'Unisexe',
                              description: 'Version de démonstration pour l\'essai virtuel.',
                              priceEur: 189.0,
                              imageAsset: 'assets/products/product_01.png',
                              heroGradient: [AppColors.brownMedium, AppColors.brownLight],
                            );
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ArTryOnScreen(product: demoProduct)));
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildIAButton(
                          context,
                          'Scanner Prescription',
                          Icons.document_scanner,
                          AppColors.brownLight,
                          () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const OcrScanScreen()));
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  _buildSectionHeader(context, 'Nos Collections', () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProductsListScreen()));
                  }),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  ref.watch(availableCategoriesProvider).isEmpty
                      ? const Center(child: Text('Aucune collection disponible'))
                      : SizedBox(
                          height: 110,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: ref.watch(availableCategoriesProvider).length,
                            itemBuilder: (context, index) {
                              final category = ref.watch(availableCategoriesProvider)[index];
                              IconData iconData = Icons.visibility_outlined;
                              if (category.toLowerCase().contains('soleil')) {
                                iconData = Icons.wb_sunny_outlined;
                              } else if (category.toLowerCase().contains('vue')) {
                                iconData = Icons.visibility_outlined;
                              } else if (category.toLowerCase().contains('sport')) {
                                iconData = Icons.sports_tennis_outlined;
                              } else if (category.toLowerCase().contains('premium')) {
                                iconData = Icons.star_border_outlined;
                              } else {
                                iconData = Icons.panorama_fish_eye;
                              }
                              return _buildCategoryCard(context, ref, category, iconData);
                            },
                          ),
                        ),
                  const SizedBox(height: 40),
                  _buildSectionTitle(context, 'Nouveautés'),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          productsAsync.when(
            data: (products) {
              // On prend les 4 lunettes les plus récentes (tri par ID décroissant)
              final latestProducts = [...products]..sort((a, b) => b.id.compareTo(a.id));
              final displayProducts = latestProducts.take(4).toList();

              if (displayProducts.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text('Aucun produit disponible pour le moment.'),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.78,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = displayProducts[index];
                      return _PremiumProductCard(product: product);
                    },
                    childCount: displayProducts.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, stack) => SliverToBoxAdapter(
              child: Center(child: Text('Erreur: $e')),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.brownDark,
          ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionTitle(context, title),
        TextButton(
          onPressed: onSeeAll,
          child: const Text('Voir tout',
              style: TextStyle(color: AppColors.brownMedium)),
        ),
      ],
    );
  }

  Widget _buildIAButton(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, WidgetRef ref, String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        // On applique le filtre de catégorie avant de naviguer
        ref.read(selectedCategoryProvider.notifier).state = title;
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ProductsListScreen()));
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.nude.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.brownMedium, size: 24),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.brownDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _PremiumProductCard extends StatelessWidget {
  final Product product;
  const _PremiumProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder<void>(
            pageBuilder: (context, animation, secondaryAnimation) => ProductDetailScreen(product: product),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                   Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Hero(
                      tag: product.heroTag,
                      child: product.imageAsset.startsWith('/media') || product.imageAsset.startsWith('http')
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            child: Image.network(
                              product.imageAsset.startsWith('/media')
                                ? '${ApiEndpoints.baseUrl.replaceAll(RegExp(r'/api/?$'), '')}${product.imageAsset}'
                                : product.imageAsset,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(Icons.broken_image_outlined, size: 32, color: AppColors.brownLight),
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.panorama_fish_eye, size: 40, color: AppColors.brownLight),
                          ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_border, size: 16, color: AppColors.brownMedium),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: -0.2,
                      color: AppColors.brownDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.category,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.brownMedium.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${product.priceEur.toStringAsFixed(0)} €',
                    style: const TextStyle(
                      color: AppColors.brownMedium,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
