import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/auth_provider.dart';
import '../profile/settings_screen.dart';
import '../auth/login_screen.dart';

class AdminDrawer extends ConsumerWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Drawer(
      backgroundColor: AppColors.cream,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.brunFonce),
            accountName: Text('${user?.firstName ?? "Admin"} ${user?.lastName ?? ""}'),
            accountEmail: Text(user?.email ?? 'admin@lunettes.com'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: AppColors.nude,
              child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 40),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined, color: AppColors.brunMoyen),
            title: const Text('Tableau de Bord'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: AppColors.brunMoyen),
            title: const Text('Paramètres'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const Divider(),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Déconnexion', style: TextStyle(color: AppColors.error)),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
