import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/cart/cart_providers.dart';
import '../../features/commandes/commande_service.dart';
import '../../features/products/product.dart';
import '../../features/auth/auth_provider.dart';
import '../profile/edit_profile_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final Product? singleProduct;
  const CheckoutScreen({super.key, this.singleProduct});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _addressController = TextEditingController();
  bool _isLoading = false;
  bool _useInsurance = false;
  
  // Nouveaux états
  String _typeLivraison = 'expedition'; // expedition, domicile
  String _modePaiement = 'orange_money'; // orange_money, paypal, carte_bancaire, espece
  bool _isAchatFamilial = false;
  int _nbMembres = 1;
  int _nbLunettes = 1;

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
      success = await orderService.createOrder(
        productId: int.parse(widget.singleProduct!.id),
        quantity: 1,
        address: _addressController.text,
        isAssuranceUtilisee: _useInsurance,
        typeLivraison: _typeLivraison,
        modePaiement: _modePaiement,
        nbMembres: _isAchatFamilial ? _nbMembres : 1,
        nbLunettes: _isAchatFamilial ? _nbLunettes : 1,
      );
    } else {
      final cartItems = ref.read(cartProvider);
      success = await orderService.processFullCart(
        cartItems, 
        _addressController.text,
        isAssuranceUtilisee: _useInsurance,
        typeLivraison: _typeLivraison,
        modePaiement: _modePaiement,
        nbMembres: _isAchatFamilial ? _nbMembres : 1,
        nbLunettes: _isAchatFamilial ? _nbLunettes : 1,
      );
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
    final user = ref.watch(authProvider).user;
    final double subTotal;
    final int itemCount;

    if (widget.singleProduct != null) {
      subTotal = widget.singleProduct!.priceEur;
      itemCount = 1;
    } else {
      subTotal = ref.watch(cartProvider.notifier).totalPrice;
      itemCount = ref.watch(cartProvider.notifier).itemCount;
    }

    // Calculs de réduction locaux (cohérents avec le backend)
    double familyDiscount = 0;
    if (_isAchatFamilial && _nbLunettes > 1) {
      double tauxRemise = (0.10 + (_nbLunettes - 1) * 0.05).clamp(0, 0.25);
      familyDiscount = subTotal * tauxRemise;
    } else if (user?.codeFamille != null && user!.codeFamille!.isNotEmpty) {
      familyDiscount = subTotal * 0.15;
    }

    double insurancePart = 0;
    if (_useInsurance && user?.assuranceNom != null) {
      insurancePart = (subTotal - familyDiscount) * 0.80;
    }

    final deliveryFee = _typeLivraison == 'expedition' ? 5.00 : 0.00;
    final totalClient = subTotal - familyDiscount - insurancePart + deliveryFee;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Récapitulatif Commande', style: TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brownMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Résumé du paiement'),
            const SizedBox(height: 16),
            _buildInfoRow('Articles ($itemCount)', '${subTotal.toStringAsFixed(2)} €'),
            
            if (familyDiscount > 0)
              _buildInfoRow('Remise Famille', '- ${familyDiscount.toStringAsFixed(2)} €', color: Colors.green),
              
            if (insurancePart > 0)
              _buildInfoRow('Prise en charge Assurance (80%)', '- ${insurancePart.toStringAsFixed(2)} €', color: Colors.blue),
              
            _buildInfoRow('Livraison', deliveryFee > 0 ? '${deliveryFee.toStringAsFixed(2)} €' : 'Gratuite'),
            const Divider(height: 32),
            _buildInfoRow('Reste à payer', '${totalClient.toStringAsFixed(2)} €', isBold: true),
            
            const SizedBox(height: 32),
            _buildSectionTitle('1. Mode de Livraison'),
            const SizedBox(height: 12),
            _buildModernCard(
              child: RadioGroup<String>(
                groupValue: _typeLivraison,
                onChanged: (val) {
                  setState(() {
                    _typeLivraison = val!;
                    // Forcer un mode de paiement valide si "Espèces" était sélectionné
                    if (_modePaiement == 'espece') _modePaiement = 'orange_money';
                  });
                },
                child: const Column(
                  children: [
                    RadioListTile<String>(
                      title: Text('Expédition (La Poste / Relais)'),
                      subtitle: Text('Livraison sécurisée avec suivi en ligne'),
                      value: 'expedition',
                      activeColor: AppColors.brownMedium,
                    ),
                    RadioListTile<String>(
                      title: Text('Livraison Domicile (Ville)'),
                      subtitle: Text('Paiement à la livraison possible'),
                      value: 'domicile',
                      activeColor: AppColors.brownMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            _buildSectionTitle('2. Mode de Paiement'),
            const SizedBox(height: 12),
            _buildPaymentMethods(),

            const SizedBox(height: 32),
            _buildSectionTitle('3. Pack Familial'),
            const SizedBox(height: 12),
            _buildFamilyPackSection(),

            const SizedBox(height: 32),
            _buildSectionTitle('4. Assurance & Tiers-payant'),
            const SizedBox(height: 12),
            
            if (user?.assuranceNom != null && user!.assuranceNom!.isNotEmpty)
              _buildModernCard(
                child: SwitchListTile(
                  title: const Text('Utiliser mon assurance', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brownDark)),
                  subtitle: Text('Compagnie: ${user.assuranceNom}'),
                  value: _useInsurance,
                  activeThumbColor: AppColors.brownMedium,
                  onChanged: (val) => setState(() => _useInsurance = val),
                  secondary: const Icon(Icons.security, color: AppColors.brownMedium),
                ),
              )
            else
              _buildModernCard(
                child: ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.brownMedium),
                  title: const Text('Infos assurance manquantes', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Complétez votre profil pour bénéficier du tiers-payant.'),
                  onTap: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const EditProfileScreen())
                  ),
                ),
              ),

            const SizedBox(height: 24),
            _buildSectionTitle('Adresse de livraison'),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              maxLines: 2,
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
            
            const SizedBox(height: 48),
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
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brownMedium),
    );
  }

  Widget _buildModernCard({required Widget child}) {
    return Container(
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
      child: child,
    );
  }

  Widget _buildPaymentMethods() {
    return _buildModernCard(
      child: RadioGroup<String>(
        groupValue: _modePaiement,
        onChanged: (val) => setState(() => _modePaiement = val!),
        child: Column(
          children: [
            const RadioListTile<String>(
              title: Text('Orange Money / Mobile Money'),
              value: 'orange_money',
              activeColor: AppColors.brownMedium,
              secondary: Icon(Icons.phone_android, color: Colors.orange),
            ),
            const RadioListTile<String>(
              title: Text('PayPal'),
              value: 'paypal',
              activeColor: AppColors.brownMedium,
              secondary: Icon(Icons.payment, color: Colors.blue),
            ),
            const RadioListTile<String>(
              title: Text('Carte Bancaire'),
              value: 'carte_bancaire',
              activeColor: AppColors.brownMedium,
              secondary: Icon(Icons.credit_card, color: AppColors.brownMedium),
            ),
            if (_typeLivraison == 'domicile')
              const RadioListTile<String>(
                title: Text('Espèces à la livraison'),
                value: 'espece',
                activeColor: AppColors.brownMedium,
                secondary: Icon(Icons.money, color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyPackSection() {
    return _buildModernCard(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Achat Pack Familial', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brownDark)),
            subtitle: const Text('Bénéficiez de remises groupées'),
            value: _isAchatFamilial,
            activeThumbColor: AppColors.brownMedium,
            onChanged: (val) => setState(() => _isAchatFamilial = val),
            secondary: const Icon(Icons.group_add, color: AppColors.brownMedium),
          ),
          if (_isAchatFamilial)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                   Row(
                     children: [
                       const Expanded(child: Text('Nombre de membres :')),
                       IconButton(onPressed: () => setState(() => _nbMembres = (_nbMembres > 1 ? _nbMembres - 1 : 1)), icon: const Icon(Icons.remove_circle_outline)),
                       Text('$_nbMembres', style: const TextStyle(fontWeight: FontWeight.bold)),
                       IconButton(onPressed: () => setState(() => _nbMembres++), icon: const Icon(Icons.add_circle_outline)),
                     ],
                   ),
                   Row(
                     children: [
                       const Expanded(child: Text('Nombre de paires :')),
                       IconButton(onPressed: () => setState(() => _nbLunettes = (_nbLunettes > 1 ? _nbLunettes - 1 : 1)), icon: const Icon(Icons.remove_circle_outline)),
                       Text('$_nbLunettes', style: const TextStyle(fontWeight: FontWeight.bold)),
                       IconButton(onPressed: () => setState(() => _nbLunettes++), icon: const Icon(Icons.add_circle_outline)),
                     ],
                   ),
                   const Text(
                     'Astuce : La remise augmente avec le nombre de paires !',
                     style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.brownMedium),
                   ),
                   const SizedBox(height: 8),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label, 
              style: TextStyle(
                color: isBold ? AppColors.brownDark : AppColors.brownMedium, 
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal
              )
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(color: color ?? AppColors.brownDark, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 20 : 15)),
        ],
      ),
    );
  }
}
