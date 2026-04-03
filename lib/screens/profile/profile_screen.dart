import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil', style: TextStyle(color: AppColors.brunFonce)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.brunMoyen),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.nudeSable,
              child: Icon(Icons.person, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text('Jean Dupont', style: Theme.of(context).textTheme.headlineMedium),
            const Text('jean.dupont@email.com', style: TextStyle(color: AppColors.brunClair)),
            const SizedBox(height: 40),
            _buildProfileItem(Icons.history, 'Mes Commandes'),
            _buildProfileItem(Icons.favorite_border, 'Favoris'),
            _buildProfileItem(Icons.description_outlined, 'Mes Ordonnances'),
            _buildProfileItem(Icons.help_outline, 'Aide & Support'),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Déconnexion', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.brunMoyen),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.brunFonce)),
          const Spacer(),
          const Icon(Icons.chevron_right, color: AppColors.brunClair),
        ],
      ),
    );
  }
}
