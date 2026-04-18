import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../features/admin/admin_providers.dart';
import '../../../core/widgets/empty_state_widget.dart';

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: ordersAsync.when(
        data: (orders) => orders.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.shopping_bag_outlined,
              title: 'Aucune commande',
              message: 'Les commandes passées par les clients s\'afficheront ici en temps réel.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _OrderCard(order: order);
              },
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = DateTime.parse(order['date_commande']);
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
    final status = order['statut'] ?? 'en_preparation';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text('Commande #${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Le $formattedDate'),
        trailing: _StatusBadge(status: status),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Client: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        order['user_email'] ?? 'Utilisateur Inconnu',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${order['prix_total']} €', style: const TextStyle(color: AppColors.brunMoyen, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 32),
                const Text('Mettre à jour le statut:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statusButton(context, ref, 'en_preparation', 'Préparation'),
                    _statusButton(context, ref, 'expedier', 'Expédiée'),
                    _statusButton(context, ref, 'livrer', 'Livrée'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusButton(BuildContext context, WidgetRef ref, String slug, String label) {
    final currentStatus = order['statut'];
    final isSelected = currentStatus == slug;

    return OutlinedButton(
      onPressed: isSelected ? null : () async {
        await ref.read(adminServiceProvider).updateOrderStatus(order['id'], slug);
        ref.invalidate(adminOrdersProvider);
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.brunMoyen : null,
        foregroundColor: isSelected ? Colors.white : AppColors.brunMoyen,
        side: BorderSide(color: AppColors.brunMoyen),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    switch (status) {
      case 'en_preparation': label = 'Préparation'; color = Colors.orange; break;
      case 'expedier': label = 'Expédiée'; color = Colors.blue; break;
      case 'livrer': label = 'Livrée'; color = AppColors.success; break;
      default: label = 'Inconnu'; color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
