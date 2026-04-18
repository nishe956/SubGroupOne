import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/admin/admin_providers.dart';
import '../../../core/widgets/empty_state_widget.dart';
import 'widgets/add_assurance_dialog.dart';

class AssuranceManagementScreen extends ConsumerWidget {
  const AssuranceManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assurancesAsync = ref.watch(adminAssurancesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.brunFonce),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Partenaires Assurances', style: TextStyle(color: AppColors.brunFonce, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddAssuranceDialog(),
        ),
        backgroundColor: AppColors.brunMoyen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: assurancesAsync.when(
        data: (assurances) => assurances.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.security, 
              title: 'Aucune assurance', 
              message: 'Gérez vos partenariats avec les assureurs ici.'
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: assurances.length,
              itemBuilder: (context, index) {
                final assurance = assurances[index];
                return _buildAssuranceCard(context, ref, assurance);
              },
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildAssuranceCard(BuildContext context, WidgetRef ref, Map<String, dynamic> assurance) {
    final name = assurance['nom'] ?? 'Sans nom';
    final rate = 'Taux: ${assurance['taux_couverture_defaut']}%';
    const icon = Icons.business_center;
    const color = Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.nude),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(icon, color: color),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(rate),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Supprimer'),
                content: Text('Voulez-vous retirer le partenaire $name ?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oui', style: TextStyle(color: Colors.red))),
                ],
              ),
            );

            if (confirm == true) {
              await ref.read(adminServiceProvider).deleteAssurance(assurance['id']);
              ref.invalidate(adminAssurancesProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partenaire supprimé')));
              }
            }
          },
        ),
      ),
    );
  }
}
