import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../features/admin/admin_providers.dart';
import '../../../core/widgets/empty_state_widget.dart';
import 'widgets/add_user_dialog.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider('client'));

    return Scaffold(
      backgroundColor: AppColors.cream,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context, 
          builder: (_) => const AddUserDialog(initialRole: 'client')
        ),
        backgroundColor: AppColors.brunMoyen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: usersAsync.when(
        data: (users) => users.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.people_outline,
              title: 'Aucun utilisateur',
              message: 'Les nouveaux comptes créés apparaîtront ici automatiquement.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return _UserCard(user: user);
              },
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final AdminUser user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text('${user.firstName ?? ""} ${user.lastName ?? ""}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                _RoleBadge(role: user.role),
                const SizedBox(width: 8),
                if (!user.isActive)
                  const Text('Désactivé', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'deactivate') {
              await ref.read(adminServiceProvider).deactivateUser(user.id);
              ref.invalidate(adminUsersProvider);
            } else if (value.startsWith('role_')) {
              final newRole = value.replaceFirst('role_', '');
              await ref.read(adminServiceProvider).updateUserRole(user.id, newRole);
              ref.invalidate(adminUsersProvider);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'role_client', child: Text('Rôle: Client')),
            const PopupMenuItem(value: 'role_opticien', child: Text('Rôle: Opticien')),
            const PopupMenuItem(value: 'role_admin', child: Text('Rôle: Admin')),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'deactivate',
              child: Text('Désactiver Compte', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (role) {
      case 'admin': color = AppColors.error; break;
      case 'opticien': color = Colors.blue; break;
      default: color = AppColors.brownMedium;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
