import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/api/api_endpoints.dart';
import '../../features/products/product.dart';
import '../../features/products/products_providers.dart';
import '../../features/products/product_detail_screen.dart';

class MyFavoritesScreen extends ConsumerWidget {
  const MyFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final productsAsync = ref.watch(productsCatalogProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Mes Favoris', style: TextStyle(color: AppColors.brownDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brownMedium),
      ),
      body: productsAsync.when(
        data: (products) {
          final favoriteProducts = products.where((p) => favorites.contains(p.id)).toList();

          if (favoriteProducts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border, size: 80, color: AppColors.brownLight),
                    SizedBox(height: 16),
                    Text(
                      'Aucun favori',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brownDark),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Vous n\'avez pas encore ajouté de montures à vos favoris.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.brownMedium),
                    ),
                  ],
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: favoriteProducts.length,
            itemBuilder: (context, index) {
              final product = favoriteProducts[index];
              return _FavoriteProductCard(product: product);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _FavoriteProductCard extends ConsumerWidget {
  final Product product;

  const _FavoriteProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
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
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: product.imageAsset.startsWith('/media') || product.imageAsset.startsWith('http')
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        ref.read(favoritesProvider.notifier).toggle(product.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite, size: 18, color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.brownDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.priceEur.toStringAsFixed(0)} €',
                    style: const TextStyle(color: AppColors.brownMedium, fontWeight: FontWeight.bold),
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
