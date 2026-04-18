import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/admin/admin_providers.dart';

class AdminStatsScreen extends ConsumerWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: statsAsync.when(
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatCard(
                'Chiffre d\'Affaires Total',
                '${stats['total_revenue'] ?? 0} €',
                Icons.trending_up,
                Colors.green,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSmallStatCard(
                      'Commandes',
                      '${stats['total_orders'] ?? 0}',
                      Icons.shopping_bag_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSmallStatCard(
                      'Clients',
                      '${stats['total_clients'] ?? 0}',
                      Icons.people_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Top Produits',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brunFonce),
              ),
              const SizedBox(height: 12),
              ...(stats['top_products'] as List? ?? []).map((p) => 
                _buildProductItem(p['monture__nom'] ?? 'Inconnu', '${p['total']} ventes')
              ),
              if ((stats['top_products'] as List? ?? []).isEmpty)
                const Text('Aucune donnée de vente pour le moment.', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brunFonce, AppColors.brunMoyen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.brunFonce.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
          Icon(icon, color: Colors.white30, size: 48),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.nude),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.brunMoyen),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.brunFonce)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }


  Widget _buildProductItem(String name, String sales) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.nude.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.nude, borderRadius: BorderRadius.circular(20)),
            child: Text(sales, style: const TextStyle(fontSize: 12, color: AppColors.brunFonce)),
          ),
        ],
      ),
    );
  }
}
