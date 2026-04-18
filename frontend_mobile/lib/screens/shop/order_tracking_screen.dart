import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';

class OrderTrackingScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderTrackingScreen({super.key, required this.order});

  int _getStatusStep(String status) {
    switch (status) {
      case 'en_attente':
        return 0;
      case 'en_preparation':
        return 1;
      case 'expedier':
        return 2;
      case 'livrer':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusStep = _getStatusStep(order['statut'] ?? 'en_attente');
    final date = DateTime.parse(order['date_commande']);
    final formattedDate = DateFormat('dd MMMM yyyy à HH:mm').format(date);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Détails de la Commande', style: TextStyle(color: AppColors.brownDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brownMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            _buildInfoCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('N° de commande :', style: TextStyle(color: AppColors.brownMedium)),
                      Text('#${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brownDark)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Date :', style: TextStyle(color: AppColors.brownMedium)),
                      Text(formattedDate, style: const TextStyle(color: AppColors.brownDark)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Stepper Suivi
            const Text('Statut de livraison', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brownDark)),
            const SizedBox(height: 24),
            _buildTrackingStepper(statusStep),
            const SizedBox(height: 40),

            // Détails du produit
            const Text('Article commandé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brownDark)),
            const SizedBox(height: 16),
            _buildInfoCard(
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.remove_red_eye, color: AppColors.brownMedium, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order['monture_nom'] ?? 'Monture', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Text('Quantité: 1', style: TextStyle(color: AppColors.brownMedium)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Résumé Paiement
            const Text('Résumé du paiement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brownDark)),
            const SizedBox(height: 16),
            _buildInfoCard(
              child: Column(
                children: [
                  _buildPriceRow('Sous-total', '${order['prix_total']} €'),
                  if (double.parse(order['remise_famille'].toString()) > 0)
                    _buildPriceRow('Remise Famille', '- ${order['remise_famille']} €', isDiscount: true),
                  if (double.parse(order['part_assurance'].toString()) > 0)
                    _buildPriceRow('Prise en charge Assurance', '- ${order['part_assurance']} €', isInsurance: true),
                  const Divider(height: 32),
                  _buildPriceRow('Reste à payer', '${order['part_client']} €', isTotal: true),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('Adresse de livraison', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brownDark)),
            const SizedBox(height: 12),
            _buildInfoCard(
              child: Row(
                children: [
                   const Icon(Icons.location_on_outlined, color: AppColors.brownMedium),
                   const SizedBox(width: 12),
                   Expanded(child: Text(order['adresse_livraison'] ?? 'Adresse non spécifiée', style: const TextStyle(color: AppColors.brownDark))),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false, bool isDiscount = false, bool isInsurance = false}) {
    Color? textColor;
    if (isTotal) textColor = AppColors.brownDark;
    if (isDiscount) textColor = Colors.green;
    if (isInsurance) textColor = Colors.blue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label, 
              style: TextStyle(
                color: isTotal ? AppColors.brownDark : AppColors.brownMedium, 
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal
              )
            )
          ),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(color: textColor ?? AppColors.brownDark, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 18 : 14)),
        ],
      ),
    );
  }

  Widget _buildTrackingStepper(int currentStep) {
    final steps = [
      {'title': 'Commande reçue', 'desc': 'Votre commande est en attente de validation.'},
      {'title': 'En préparation', 'desc': 'L\'opticien prépare votre monture et vos verres.'},
      {'title': 'Expédiée', 'desc': 'Votre colis est en route vers chez vous.'},
      {'title': 'Livrée', 'desc': 'Le colis a été déposé à votre adresse.'},
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final isActive = index <= currentStep;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.brownMedium : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: isActive ? AppColors.brownMedium : AppColors.brownLight, width: 2),
                  ),
                  child: Center(
                    child: Icon(
                      index < currentStep ? Icons.check : Icons.circle,
                      size: index < currentStep ? 18 : 10,
                      color: index < currentStep ? Colors.white : (isActive ? Colors.white : AppColors.brownLight),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 50,
                    color: index < currentStep ? AppColors.brownMedium : AppColors.brownLight.withValues(alpha: 0.3),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    steps[index]['title']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isActive ? AppColors.brownDark : AppColors.brownLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[index]['desc']!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isActive ? AppColors.brownMedium : AppColors.brownLight.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
