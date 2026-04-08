import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conditions d\'utilisation', style: TextStyle(color: AppColors.brunFonce)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brunMoyen),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('1. Acceptation des Conditions'),
            _buildParagraph(
                'En accédant à cette application, vous acceptez d\'être lié par ces conditions d\'utilisation, toutes les lois et réglementations applicables, et acceptez que vous êtes responsable du respect de toutes les lois locales applicables.'),
            const SizedBox(height: 24),
            _buildSectionTitle('2. Utilisation de l\'IA'),
            _buildParagraph(
                'L\'outil d\'essai virtuel est fourni à titre indicatif pour vous aider dans votre choix. Bien que nous utilisions une technologie de pointe, le rendu final peut varier légèrement de la réalité. La décision finale d\'achat vous appartient.'),
            const SizedBox(height: 24),
            _buildSectionTitle('3. Commandes et Paiements'),
            _buildParagraph(
                'Toutes les commandes sont sujettes à la validation de votre ordonnance par un opticien diplômé. Les prix sont indiqués en euros et incluent toutes les taxes applicables.'),
            const SizedBox(height: 24),
            _buildSectionTitle('4. Retours et Garanties'),
            _buildParagraph(
                'Les verres correcteurs étant des produits personnalisés selon vos besoins spécifiques, ils ne peuvent faire l\'objet d\'un droit de rétractation standard, sauf en cas de défaut de fabrication manifeste.'),
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
