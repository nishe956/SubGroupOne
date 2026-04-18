import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/auth_provider.dart';
import '../profile/settings_screen.dart';
import '../auth/login_screen.dart';
import '../admin/optician_management_screen.dart';
import '../admin/assurance_management_screen.dart';
import '../admin/system_logs_screen.dart';

class AdminDrawer extends ConsumerWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isOptician = user?.role == 'opticien';
    final isAdmin = user?.role == 'admin';

    return Drawer(
      backgroundColor: AppColors.cream,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.brunFonce),
            accountName: Text('${user?.firstName ?? "Compte"} ${user?.lastName ?? ""}'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.nude,
              child: Icon(
                isAdmin ? Icons.admin_panel_settings : Icons.medical_services, 
                color: Colors.white, 
                size: 40
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined, color: AppColors.brunMoyen),
            title: const Text('Tableau de Bord'),
            onTap: () => Navigator.pop(context),
          ),
          
          if (isOptician) ...[
            const Divider(),
            _buildDrawerItem(context, Icons.inventory_2_outlined, 'Gestion Stock', null),
            _buildDrawerItem(context, Icons.shopping_bag_outlined, 'Commandes Clients', null),
            _buildDrawerItem(context, Icons.assignment_outlined, 'Ordonnances', null),
          ],

          if (isAdmin) ...[
            const Divider(),
            _buildDrawerItem(context, Icons.badge_outlined, 'Gestion Opticiens', const OpticianManagementScreen()),
            _buildDrawerItem(context, Icons.security, 'Gestion Assurances', const AssuranceManagementScreen()),
            _buildDrawerItem(context, Icons.history, 'Logs Système', const SystemLogsScreen()),
          ],

          const Divider(),
          _buildDrawerItem(context, Icons.settings_outlined, 'Paramètres', const SettingsScreen()),
          
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

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, Widget? destination) {
    return ListTile(
      leading: Icon(icon, color: AppColors.brunMoyen),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        if (destination != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
        }
      },
    );
  }
}
