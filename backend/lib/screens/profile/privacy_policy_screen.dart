import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Politique de confidentialité', style: TextStyle(color: AppColors.brunFonce)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brunMoyen),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('1. Introduction'),
            _buildParagraph(
                'Votre confidentialité est notre priorité. Cette politique explique comment nous recueillons, utilisons et protégeons vos données personnelles dans le cadre de l\'utilisation de notre application de vente de verres correcteurs.'),
            const SizedBox(height: 24),
            _buildSectionTitle('2. Données IA & Biométrie'),
            _buildParagraph(
                'Pour permettre l\'essai virtuel de montures, notre application utilise la caméra de votre appareil pour effectuer une reconnaissance faciale. Ces données sont traitées en temps réel sur votre appareil et ne sont jamais stockées sur nos serveurs sans votre consentement explicite.'),
            const SizedBox(height: 24),
            _buildSectionTitle('3. Données Médicales'),
            _buildParagraph(
                'Lors du scan de votre ordonnance (OCR), nous extrayons vos informations de correction visuelle. Ces données sont strictement utilisées pour personnaliser vos verres et sont partagées uniquement avec votre opticien traitant et votre assureur pour la prise en charge.'),
            const SizedBox(height: 24),
            _buildSectionTitle('4. Vos Droits'),
            _buildParagraph(
                'Conformément au RGPD, vous disposez d\'un droit d\'accès, de rectification et de suppression de vos données personnelles. Vous pouvez exercer ces droits à tout moment via les paramètres de votre compte.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.brunFonce,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.noirDoux,
        fontSize: 14,
        height: 1.5,
      ),
    );
  }
}
