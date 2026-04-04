import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../ar_try_on/ar_try_on_screen.dart';
import '../payment/payment_method_screen.dart';
import '../theme/app_theme.dart';
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
                    child: Image.asset(
                      p.imageAsset,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => ColoredBox(
                        color: AppColors.nude,
                        child: Icon(
                          Icons.hide_image_outlined,
                          size: 72,
                          color:
                              AppColors.brownMedium.withValues(alpha: 0.4),
                        ),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Catégorie',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    letterSpacing: 1.5,
                                    color: AppColors.brownMedium,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.nude,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.brownLight
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                              child: Text(
                                p.category,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.brownDark,
                                      height: 1.3,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Genre',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    letterSpacing: 1.5,
                                    color: AppColors.brownMedium,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cream,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.brownLight
                                      .withValues(alpha: 0.65),
                                ),
                              ),
                              child: Text(
                                p.gender,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.brownDark,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    p.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.brownDark,
                          height: 1.15,
                        ),
                  ),
                  if (p.reference != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Réf. ${p.reference}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.brownMedium,
                          ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    _formatPrice(p.priceEur),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.brownDark,
                        ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    p.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.brownDark.withValues(alpha: 0.88),
                          height: 1.5,
                        ),
                  ),
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
                          pageBuilder: (_, __, ___) =>
                              ArTryOnScreen(product: p),
                          transitionsBuilder: (_, animation, __, child) =>
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
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PaymentMethodScreen(product: p),
                        ),
                      );
                    },
                    child: const Text('Acheter — paiement'),
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
