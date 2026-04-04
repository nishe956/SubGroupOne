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
            ExpansionTile(
              title: const Text('Comment fonctionne l\'essai virtuel ?', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brunFonce)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: const Text('Utilisez votre caméra pour voir les montures sur votre visage en temps réel grâce à notre IA.', 
                      style: TextStyle(color: AppColors.noirDoux)),
                ),
              ],
            ),
            ExpansionTile(
              title: const Text('Quels sont les délais de livraison ?', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brunFonce)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: const Text('Comptez 3 à 5 jours ouvrés pour les montures seules, et 7 à 10 jours pour des verres correcteurs.', 
                      style: TextStyle(color: AppColors.noirDoux)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Contactez-nous',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email_outlined, color: AppColors.brunMoyen),
              title: const Text('Email', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brunFonce)),
              subtitle: const Text('support@glasses-mobile.com', style: TextStyle(color: AppColors.brunClair)),
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined, color: AppColors.brunMoyen),
              title: const Text('Téléphone', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brunFonce)),
              subtitle: const Text('+33 1 23 45 67 89', style: TextStyle(color: AppColors.brunClair)),
            ),
          ],
        ),
      ),
    );
  }
}
