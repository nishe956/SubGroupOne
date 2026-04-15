import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/auth_provider.dart';
import '../auth/login_screen.dart';
import 'settings_screen.dart';

import 'help_support_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(authProvider).user;
    final userName = userState?.firstName != null && userState?.lastName != null 
        ? '${userState!.firstName} ${userState.lastName}' 
        : 'Utilisateur';
    final userEmail = userState?.email ?? 'email@introuvable.com';

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
            Text(userName, style: Theme.of(context).textTheme.headlineMedium),
            Text(userEmail, style: const TextStyle(color: AppColors.brunClair)),
            const SizedBox(height: 40),
            _buildProfileItem(context, Icons.history, 'Mes Commandes'),
            _buildProfileItem(context, Icons.favorite_border, 'Favoris'),
            _buildProfileItem(context, Icons.description_outlined, 'Mes Ordonnances'),
            _buildProfileItem(
              context,
              Icons.help_outline,
              'Aide & Support',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Déconnexion', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, IconData icon, String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}
