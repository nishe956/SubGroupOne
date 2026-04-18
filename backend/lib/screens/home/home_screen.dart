import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/products/products_list_screen.dart';
import '../../features/ocr/ocr_scan_screen.dart';
import '../../features/ar_try_on/ar_try_on_screen.dart';
import '../../features/products/product.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.brownDark,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Esther Eyewear',
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
                            // Use a properly instantiated mock product for the AR demo
                            const demoProduct = Product(
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
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCategoryCard(context, 'Solaire', Icons.wb_sunny_outlined),
                        _buildCategoryCard(context, 'Optique', Icons.visibility_outlined),
                        _buildCategoryCard(context, 'Sport', Icons.sports_tennis_outlined),
                        _buildCategoryCard(context, 'Premium', Icons.star_border_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildSectionTitle(context, 'Nouveautés'),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildProductCard(
                      context, 'Modèle Elite ${index + 1}', '159.00 €');
                },
                childCount: 4,
              ),
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

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon) {
    return GestureDetector(
      onTap: () {
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
            Icon(icon, color: AppColors.brownDark),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.brownDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, String name, String price) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Center(
                  child: Icon(Icons.panorama_fish_eye,
                      size: 40, color: AppColors.brownLight)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.brownDark)),
                const SizedBox(height: 4),
                Text(price,
                    style: const TextStyle(
                        color: AppColors.brownMedium,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
