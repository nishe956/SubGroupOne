import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../products/product.dart';
import '../theme/app_theme.dart';
import 'payment_confirmation_screen.dart';

/// Méthode de paiement sélectionnée.
enum PaymentUiMethod { applePay, amex, visa, mastercard }

/// Choix des moyens de paiement — cartes façon « carte physique » luxe.
/// UI pure — méthode sélectionnée gérée localement avec setState.
class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key, required this.product});

  final Product product;

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  PaymentUiMethod _selected = PaymentUiMethod.visa;

  String _formatPrice(double eur) =>
      NumberFormat.simpleCurrency(locale: 'fr_FR').format(eur);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          // Récapitulatif commande
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.nude,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.brownLight.withValues(alpha: 0.55),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Récapitulatif',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.product.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  _formatPrice(widget.product.priceEur),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Moyen de paiement',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _PaymentOptionCard(
            selected: _selected == PaymentUiMethod.applePay,
            title: 'Apple Pay',
            subtitle: 'Règlement express sécurisé',
            leading: Icons.apple_rounded,
            accent: AppColors.brownDark,
            onTap: () => setState(() => _selected = PaymentUiMethod.applePay),
          ),
          const SizedBox(height: 12),
          _PaymentOptionCard(
            selected: _selected == PaymentUiMethod.amex,
            title: 'American Express',
            subtitle: '••••  ······  1002',
            leading: Icons.credit_card_rounded,
            accent: const Color(0xFF2E77AB),
            onTap: () => setState(() => _selected = PaymentUiMethod.amex),
          ),
          const SizedBox(height: 12),
          _PaymentOptionCard(
            selected: _selected == PaymentUiMethod.visa,
            title: 'Visa',
            subtitle: 'Débit · Signature Or',
            leading: Icons.credit_card_rounded,
            accent: const Color(0xFF1A4B8C),
            onTap: () => setState(() => _selected = PaymentUiMethod.visa),
          ),
          const SizedBox(height: 12),
          _PaymentOptionCard(
            selected: _selected == PaymentUiMethod.mastercard,
            title: 'Mastercard',
            subtitle: '••••  ······  8891',
            leading: Icons.credit_card_rounded,
            accent: AppColors.brownMedium,
            onTap: () => setState(() => _selected = PaymentUiMethod.mastercard),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                PageRouteBuilder<void>(
                  pageBuilder: (_, __, ___) => PaymentConfirmationScreen(
                    product: widget.product,
                    method: _selected,
                  ),
                  transitionsBuilder: (_, animation, __, child) =>
                      FadeTransition(opacity: animation, child: child),
                  transitionDuration: const Duration(milliseconds: 340),
                ),
              );
            },
            child: const Text('Valider le paiement'),
          ),
        ],
      ),
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  const _PaymentOptionCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.accent,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final IconData leading;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.0 : 0.985,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Material(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(22),
        elevation: selected ? 2 : 0,
        shadowColor: AppColors.brownDark.withValues(alpha: 0.12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? AppColors.brownMedium
                    : AppColors.brownLight.withValues(alpha: 0.45),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.85),
                        AppColors.brownDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(leading, color: AppColors.cream, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.brownDark.withValues(alpha: 0.65),
                            ),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: selected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          key: ValueKey('on'),
                          color: AppColors.brownMedium,
                          size: 28,
                        )
                      : Icon(
                          Icons.radio_button_off_rounded,
                          key: const ValueKey('off'),
                          color: AppColors.brownLight.withValues(alpha: 0.85),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
