import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/cart/cart_providers.dart';
import '../../features/products/product_detail_screen.dart';
import '../../core/api/api_endpoints.dart';
import 'checkout_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final total = ref.read(cartProvider.notifier).totalPrice;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Mon Panier', style: TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: cartItems.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      return _buildCartItem(context, ref, cartItems[index]);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal)),
                            Text('${total.toStringAsFixed(2)} €', 
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.brownMedium)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CheckoutScreen()),
                              );
                            },
                            child: const Text('PASSER LA COMMANDE'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 80, color: AppColors.brownLight.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('Votre panier est vide', style: TextStyle(fontSize: 18, color: AppColors.brownMedium)),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('Découvrir nos lunettes'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, WidgetRef ref, CartItem item) {
    final p = item.product;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: p.imageAsset.startsWith('/media') || p.imageAsset.startsWith('http')
                    ? Image.network(
                        p.imageAsset.startsWith('/media')
                            ? '${ApiEndpoints.baseUrl.replaceAll(RegExp(r'/api/?$'), '')}${p.imageAsset}'
                            : p.imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_outlined),
                      )
                    : const Icon(Icons.panorama_fish_eye, color: AppColors.brownLight),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brownDark)),
                Text(p.category, style: const TextStyle(color: AppColors.brownMedium, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text('${p.priceEur.toStringAsFixed(2)} €', 
                        style: const TextStyle(color: AppColors.brownMedium, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis)),
                    ),
                    const SizedBox(width: 8),
                    _QuantityControl(item: item, ref: ref),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final CartItem item;
  final WidgetRef ref;
  const _QuantityControl({required this.item, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => ref.read(cartProvider.notifier).removeOne(item.product.id),
          icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.brownMedium),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        IconButton(
          onPressed: () => ref.read(cartProvider.notifier).addItem(item.product),
          icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.brownMedium),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}
