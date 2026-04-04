import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../products/product.dart';
import '../theme/app_theme.dart';
import 'payment_method_screen.dart';

/// Confirmation visuelle après paiement (aucun appel serveur ici).
class PaymentConfirmationScreen extends StatefulWidget {
  const PaymentConfirmationScreen({
    super.key,
    required this.product,
    required this.method,
  });

  final Product product;
  final PaymentUiMethod method;

  @override
  State<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  String _methodLabel(PaymentUiMethod m) {
    switch (m) {
      case PaymentUiMethod.applePay:
        return 'Apple Pay';
      case PaymentUiMethod.amex:
        return 'American Express';
      case PaymentUiMethod.visa:
        return 'Visa';
      case PaymentUiMethod.mastercard:
        return 'Mastercard';
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.65, curve: Curves.elasticOut),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final price = NumberFormat.simpleCurrency(locale: 'fr_FR')
        .format(widget.product.priceEur);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: Semantics(
                  button: true,
                  label: 'Fermer',
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).popUntil(
                      (route) => route.isFirst,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _scale,
                      child: Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.nude,
                          border: Border.all(
                            color: AppColors.brownLight.withValues(alpha: 0.6),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.brownDark.withValues(alpha: 0.12),
                              blurRadius: 32,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 56,
                          color: AppColors.brownMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeTransition(
                      opacity: _fade,
                      child: Column(
                        children: [
                          Text(
                            'Paiement confirmé',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.brownDark,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Merci pour votre commande chez Esther.\n'
                            '${widget.product.name} · $price\n'
                            'via ${_methodLabel(widget.method)}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.brownDark
                                      .withValues(alpha: 0.78),
                                  height: 1.45,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              FadeTransition(
                opacity: _fade,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Retour à la boutique'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
