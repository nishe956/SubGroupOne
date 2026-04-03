import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aide & Support', style: TextStyle(color: AppColors.brunFonce)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brunMoyen),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comment pouvons-nous vous aider ?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            _buildFAQSection(),
            const SizedBox(height: 32),
            Text(
              'Contactez-nous',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _buildContactChannel(Icons.email_outlined, 'Email', 'support@glasses-mobile.com'),
            _buildContactChannel(Icons.phone_outlined, 'Téléphone', '+33 1 23 45 67 89'),
            _buildContactChannel(Icons.chat_bubble_outline, 'Chat en direct', 'Disponible 24/7'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Formulaire de contact envoyé')),
                );
              },
              child: const Text('Ouvrir un ticket de support'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      children: [
        _buildFAQItem('Comment fonctionne l\'essai virtuel ?', 
            'Utilisez votre caméra pour voir les montures sur votre visage en temps réel grâce à notre IA.'),
        _buildFAQItem('Quels sont les délais de livraison ?', 
            'Comptez 3 à 5 jours ouvrés pour les montures seules, et 7 à 10 jours pour des verres correcteurs.'),
        _buildFAQItem('Comment scanner mon ordonnance ?', 
            'Allez dans votre panier et choisissez "Scanner l\'ordonnance" pour extraire vos corrections automatiquement.'),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brunFonce)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(answer, style: const TextStyle(color: AppColors.noirDoux)),
        ),
      ],
    );
  }

  Widget _buildContactChannel(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppColors.brunMoyen),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brunFonce)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.brunClair)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.brunClair),
      onTap: () {},
    );
  }
}
