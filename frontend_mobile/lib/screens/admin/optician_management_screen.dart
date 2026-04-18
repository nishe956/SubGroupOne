import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/admin/admin_providers.dart';
import '../../../core/widgets/empty_state_widget.dart';
import 'widgets/add_user_dialog.dart';

class OpticianManagementScreen extends ConsumerWidget {
  const OpticianManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opticiansAsync = ref.watch(adminUsersProvider('opticien'));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.brunFonce),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Gestion Opticiens', style: TextStyle(color: AppColors.brunFonce, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context, 
          builder: (_) => const AddUserDialog(initialRole: 'opticien')
        ),
        backgroundColor: AppColors.brunMoyen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: opticiansAsync.when(
        data: (opticians) => opticians.isEmpty 
          ? const EmptyStateWidget(
              icon: Icons.badge_outlined, 
              title: 'Aucun opticien', 
              message: 'Ajoutez votre premier opticien pour commencer à gérer vos points de vente.'
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: opticians.length,
              itemBuilder: (context, index) {
                final optician = opticians[index];
                return _buildOpticianCard(context, ref, optician);
              },
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildOpticianCard(BuildContext context, WidgetRef ref, AdminUser optician) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.nude),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.cream,
            child: Icon(Icons.badge, color: AppColors.brunMoyen),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${optician.firstName ?? ""} ${optician.lastName ?? ""}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(optician.email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Supprimer'),
                  content: Text('Voulez-vous supprimer l\'opticien ${optician.email} ?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oui', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(adminServiceProvider).deleteUser(optician.id);
                ref.invalidate(adminUsersProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opticien supprimé')));
                }
              }
            }, 
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent)
          ),
        ],
      ),
    );
  }
}
