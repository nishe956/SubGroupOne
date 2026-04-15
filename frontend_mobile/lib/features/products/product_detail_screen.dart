import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../ar_try_on/ar_try_on_screen.dart';
import '../theme/app_theme.dart';
import '../../core/api/api_endpoints.dart';
import '../cart/cart_providers.dart';
import '../../screens/shop/checkout_screen.dart';
import 'product.dart';
import 'products_providers.dart';

/// Fiche produit — photo plein écran, description, prix, AR & favoris.
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  String _formatPrice(double eur) =>
      NumberFormat.simpleCurrency(locale: 'fr_FR').format(eur);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = product;
    final fav = ref.watch(favoritesProvider).contains(p.id);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: MediaQuery.of(context).size.height * 0.46,
            leading: Semantics(
              button: true,
              label: 'Retour',
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            actions: [
              Semantics(
                button: true,
                label: fav ? 'Retirer des favoris' : 'Ajouter aux favoris',
                child: IconButton(
                  icon: Icon(
                    fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: fav ? AppColors.brownMedium : AppColors.brownDark,
                  ),
                  onPressed: () =>
                      ref.read(favoritesProvider.notifier).toggle(p.id),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: p.heroTag,
                    child: p.imageAsset.startsWith('/media') || p.imageAsset.startsWith('http')
                      ? Image.network(
                          p.imageAsset.startsWith('/media')
                            ? '${ApiEndpoints.baseUrl.replaceAll(RegExp(r'/api/?$'), '')}${p.imageAsset}'
                            : p.imageAsset,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.nude,
                            child: Icon(Icons.visibility_outlined, size: 72, color: AppColors.brownMedium.withValues(alpha: 0.4)),
                          ),
                        )
                      : Container(
                          color: AppColors.nude,
                          child: Center(
                            child: Icon(Icons.visibility_outlined, size: 72, color: AppColors.brownMedium.withValues(alpha: 0.4)),
                          ),
                        ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 120,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.brownDark.withValues(alpha: 0.25),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom + Marque
                  Text(
                    p.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.brownDark,
                          height: 1.15,
                        ),
                  ),
                  if (p.reference != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      p.reference!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.brownMedium,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _formatPrice(p.priceEur),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.brownDark,
                                overflow: TextOverflow.ellipsis,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: p.stock > 0
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          p.stock > 0 ? '${p.stock} en stock' : 'Rupture',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.stock > 0
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFC62828),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Chips : Forme, Genre, Couleur
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _InfoChip(label: '🔲 Forme', value: p.category),
                      _InfoChip(label: '👤 Genre', value: p.gender),
                      if (p.couleur != null)
                        _InfoChip(label: '🎨 Couleur', value: p.couleur!),
                    ],
                  ),
                  if (p.description.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.brownDark,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      p.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.brownDark.withValues(alpha: 0.88),
                            height: 1.6,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        PageRouteBuilder<void>(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              ArTryOnScreen(product: p),
                          transitionsBuilder: (_, animation, _, child) =>
                              FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                          transitionDuration:
                              const Duration(milliseconds: 320),
                        ),
                      );
                    },
                    icon: const Icon(Icons.view_in_ar_rounded),
                    label: const Text('ESSAYER EN AR'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ref.read(cartProvider.notifier).addItem(p);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${p.name} ajouté au panier'),
                                behavior: SnackBarBehavior.floating,
                                action: SnackBarAction(
                                  label: 'VOIR',
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('PANIER'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => CheckoutScreen(singleProduct: p),
                              ),
                            );
                          },
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('ACHETER MAINTENANT'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip d'information pour la page de détails
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.nude,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.brownLight.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.brownMedium,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.brownDark,
            ),
          ),
        ],
      ),
    );
  }
}
