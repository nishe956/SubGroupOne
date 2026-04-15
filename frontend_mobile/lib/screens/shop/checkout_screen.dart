import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/cart/cart_providers.dart';
import '../../features/commandes/commande_service.dart';
import '../../features/products/product.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final Product? singleProduct;
  const CheckoutScreen({super.key, this.singleProduct});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _processOrder() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner votre adresse de livraison')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final orderService = ref.read(orderServiceProvider);
    bool success = false;

    if (widget.singleProduct != null) {
      // Commande directe pour un produit
      success = await orderService.createOrder(
        productId: int.parse(widget.singleProduct!.id),
        quantity: 1,
        address: _addressController.text,
      );
    } else {
      // Commande du panier complet
      final cartItems = ref.read(cartProvider);
      success = await orderService.processFullCart(cartItems, _addressController.text);
      if (success) {
        ref.read(cartProvider.notifier).clear();
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la commande. Veuillez réessayer.')),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Commande Réussie !'),
        content: const Text('Votre commande a été passée avec succès. Vous recevrez un e-mail de confirmation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text('RETOUR À L\'ACCUEIL'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(cartProvider);
    final double subTotal;
    final int itemCount;

    if (widget.singleProduct != null) {
      subTotal = widget.singleProduct!.priceEur;
      itemCount = 1;
    } else {
      subTotal = ref.read(cartProvider.notifier).totalPrice;
      itemCount = ref.read(cartProvider.notifier).itemCount;
    }

    const deliveryFee = 5.00;
    final total = subTotal + deliveryFee;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Récapitulatif Commande', style: TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Résumé'),
            const SizedBox(height: 16),
            _buildInfoRow('Articles ($itemCount)', '${subTotal.toStringAsFixed(2)} €'),
            _buildInfoRow('Livraison', '${deliveryFee.toStringAsFixed(2)} €'),
            const Divider(height: 32),
            _buildInfoRow('Total à payer', '${total.toStringAsFixed(2)} €', isBold: true),
            
            const SizedBox(height: 40),
            _buildSectionTitle('Adresse de livraison'),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Votre adresse complète...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            _buildSectionTitle('Paiement'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.brownLight.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.credit_card, color: AppColors.brownMedium),
                  SizedBox(width: 16),
                  Text('Paiement à la livraison', style: TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _isLoading ? null : _processOrder,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('CONFIRMER LA COMMANDE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brownDark),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isBold ? AppColors.brownDark : AppColors.brownMedium, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: AppColors.brownDark, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14)),
        ],
      ),
    );
  }
}
