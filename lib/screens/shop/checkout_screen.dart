import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commande', style: TextStyle(color: AppColors.brunFonce)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Résumé', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            _buildInfoRow('Sous-total', '258.00 €'),
            _buildInfoRow('Livraison', '5.00 €'),
            const Divider(height: 32),
            _buildInfoRow('Total', '263.00 €', isBold: true),
            const SizedBox(height: 40),
            Text('Adresse de livraison', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(hintText: 'Adresse complète'),
            ),
            const SizedBox(height: 40),
            Text('Paiement', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.brunClair),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.credit_card, color: AppColors.brunMoyen),
                  SizedBox(width: 16),
                  Text('**** **** **** 1234', style: TextStyle(color: AppColors.brunFonce)),
                ],
              ),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Succès'),
                    content: const Text('Votre commande a été passée avec succès !'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                        child: const Text('Retour'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Confirmer le paiement'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.brunClair, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: AppColors.brunFonce, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14)),
        ],
      ),
    );
  }
}
