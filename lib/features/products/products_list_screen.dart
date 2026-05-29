import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../auth/login_screen.dart';
import '../ocr/ocr_scan_screen.dart';
import '../opticien/screens/opticien_login_screen.dart';
import '../theme/app_theme.dart';
import 'product.dart';
import 'product_detail_screen.dart';
import 'products_providers.dart';

class ProductsListScreen extends ConsumerStatefulWidget {
  const ProductsListScreen({super.key});

  @override
  ConsumerState<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen> {
  final _searchFocus = FocusNode();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatPrice(double eur) =>
      NumberFormat.simpleCurrency(locale: 'fr_FR').format(eur);

  void _openGenderFilters() {
    final active = ref.read(selectedGenderProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _GenderFiltersSheet(
        activeGender: active,
        onChanged: (g) => ref.read(selectedGenderProvider.notifier).state = g,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final products = ref.watch(filteredProductsProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);
    final selectedGender = ref.watch(selectedGenderProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Esther',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  color: AppColors.brownMedium,
                                ),
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: 'Ouvrir le scan de document',
                          child: IconButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const OcrScanScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.document_scanner_outlined),
                          ),
                        ),
                        // Bouton espace opticien
                        Semantics(
                          button: true,
                          label: 'Espace opticien',
                          child: IconButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const OpticienLoginScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.admin_panel_settings_outlined),
                            tooltip: 'Espace opticien',
                          ),
                        ),
                        // Bouton compte utilisateur
                        if (authState.status == AuthStatus.authenticated)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.account_circle_outlined),
                            tooltip: 'Mon compte',
                            onSelected: (value) {
                              if (value == 'logout') {
                                ref.read(authProvider.notifier).logout();
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                enabled: false,
                                child: Text(
                                  authState.user?.username ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.brownDark,
                                  ),
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'logout',
                                child: Text('Se déconnecter'),
                              ),
                            ],
                          )
                        else
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.login_rounded),
                            tooltip: 'Se connecter',
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Montures sélection',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.brownDark,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            onChanged: (v) => ref
                                .read(searchQueryProvider.notifier)
                                .state = v,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Rechercher une monture…',
                              prefixIcon: const Icon(Icons.search_rounded,
                                  color: AppColors.brownMedium),
                              suffixIcon: searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref
                                            .read(searchQueryProvider.notifier)
                                            .state = '';
                                      },
                                      tooltip: 'Effacer',
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Semantics(
                          button: true,
                          label: 'Filtres par genre',
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              OutlinedButton(
                                onPressed: _openGenderFilters,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.brownDark,
                                  side: const BorderSide(
                                    color: AppColors.brownLight,
                                    width: 1.2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text('Filtres'),
                              ),
                              if (selectedGender != null)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.brownMedium,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: kMainGlassCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final label = kMainGlassCategories[i];
                        final selected = selectedCat == label;
                        return _CategoryLuxeCard(
                          label: label,
                          selected: selected,
                          onTap: () {
                            ref.read(selectedCategoryProvider.notifier).state =
                                selected ? null : label;
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            if (productsState.status == ProductsStatus.loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.brownMedium,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: AppColors.brownMedium.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune monture ne correspond à votre recherche.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.brownDark.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.88,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final p = products[index];
                      final isFav = ref.watch(favoritesProvider).contains(p.id);
                      return _ProductCard(
                        product: p,
                        isFavorite: isFav,
                        priceLabel: _formatPrice(p.priceEur),
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder<void>(
                              pageBuilder: (ctx, animation, secondary) =>
                                  ProductDetailScreen(product: p),
                              transitionsBuilder:
                                  (ctx, animation, secondary, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        onToggleFavorite: () {
                          ref.read(favoritesProvider.notifier).toggle(p.id);
                        },
                      );
                    },
                    childCount: products.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _CategoryLuxeCard extends StatelessWidget {
  const _CategoryLuxeCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Catégorie $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 152,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: selected ? AppColors.brownMedium : AppColors.nude,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? AppColors.brownMedium
                    : AppColors.brownLight.withValues(alpha: 0.65),
                width: selected ? 1.8 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.brownDark.withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.15,
                      color: selected ? AppColors.cream : AppColors.brownDark,
                      fontSize: 13,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderFiltersSheet extends StatelessWidget {
  const _GenderFiltersSheet({
    required this.activeGender,
    required this.onChanged,
  });

  final String? activeGender;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.brownLight.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Genre',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.brownDark,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    onChanged(null);
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Réinitialiser',
                    style: TextStyle(
                      color: AppColors.brownMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Affinez la grille selon le port.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.brownDark.withValues(alpha: 0.65),
                  ),
            ),
            const SizedBox(height: 20),
            ...kGenderFilters.map((g) {
              final isOn = activeGender == g;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: isOn
                      ? AppColors.brownMedium.withValues(alpha: 0.18)
                      : AppColors.nude.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => onChanged(isOn ? null : g),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isOn
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: isOn
                                ? AppColors.brownMedium
                                : AppColors.brownLight,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            g,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.brownDark,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Appliquer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isFavorite,
    required this.priceLabel,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final Product product;
  final bool isFavorite;
  final String priceLabel;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Material(
        color: AppColors.nude,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.brownLight.withValues(alpha: 0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: product.heroTag,
                      child: Material(
                        color: AppColors.cream,
                        child: product.isNetworkImage
                            ? Image.network(
                                product.imageAsset,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => ColoredBox(
                                  color: AppColors.nude,
                                  child: Icon(
                                    Icons.hide_image_outlined,
                                    size: 36,
                                    color: AppColors.brownMedium.withValues(alpha: 0.45),
                                  ),
                                ),
                              )
                            : Image.asset(
                                product.imageAsset,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => ColoredBox(
                                  color: AppColors.nude,
                                  child: Icon(
                                    Icons.hide_image_outlined,
                                    size: 36,
                                    color: AppColors.brownMedium.withValues(alpha: 0.45),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Semantics(
                        button: true,
                        label: isFavorite
                            ? 'Retirer des favoris'
                            : 'Ajouter aux favoris',
                        child: Material(
                          color: AppColors.cream.withValues(alpha: 0.94),
                          shape: const CircleBorder(),
                          child: IconButton(
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            padding: EdgeInsets.zero,
                            iconSize: 19,
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFavorite
                                  ? AppColors.brownMedium
                                  : AppColors.brownDark,
                            ),
                            onPressed: onToggleFavorite,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: AppColors.cream.withValues(alpha: 0.72),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.22,
                          letterSpacing: -0.05,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brownDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          height: 1.1,
                          letterSpacing: 0.2,
                          fontWeight: FontWeight.w500,
                          color: AppColors.brownMedium.withValues(alpha: 0.88),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        priceLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1,
                          letterSpacing: 0.2,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brownMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
