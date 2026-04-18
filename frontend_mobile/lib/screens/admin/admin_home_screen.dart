import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/admin/admin_providers.dart';
import '../../features/auth/auth_provider.dart';
import 'assurance_management_screen.dart';
import 'add_product_screen.dart';
import '../../core/widgets/notification_bell.dart';

class AdminHomeScreen extends ConsumerWidget {
  final void Function(int)? onNavigateTab;
  
  const AdminHomeScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'admin';
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isAdmin),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildSectionTitle(isAdmin ? 'Surveillance Plateforme' : 'Aperçu Boutique'),
                  const SizedBox(height: 20),
                  statsAsync.when(
                    data: (stats) => GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.95,
                      children: isAdmin ? [
                         _buildStatCard('Total Revenu', '${stats['total_revenue'] ?? 0}€', Icons.monetization_on, Colors.green),
                         _buildStatCard('Utilisateurs', stats['total_clients']?.toString() ?? '0', Icons.people, Colors.blue),
                         _buildStatCard('Opticiens', stats['total_opticians']?.toString() ?? '0', Icons.badge, Colors.indigo),
                         _buildStatCard('Commandes', stats['total_orders']?.toString() ?? '0', Icons.shopping_bag, Colors.orange),
                         _buildStatCard('Stock Total', stats['total_products']?.toString() ?? '0', Icons.inventory_2, Colors.teal),
                         _buildStatCard('Total Scans', stats['total_prescriptions']?.toString() ?? '0', Icons.description_outlined, Colors.purple),
                      ] : [
                        _buildStatCard('Stock Lunettes', stats['products']?.toString() ?? '0', Icons.inventory_2, Colors.green),
                        _buildStatCard('Commandes', stats['orders']?.toString() ?? '0', Icons.shopping_bag, Colors.orange),
                        _buildStatCard('Scans OCR', stats['prescriptions']?.toString() ?? '0', Icons.document_scanner, Colors.purple),
                        _buildStatCard('Clients Liés', stats['clients']?.toString() ?? '0', Icons.group, Colors.blue),
                      ],
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) {
                      bool isAuthError = e.toString().contains('401');
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(isAuthError ? Icons.lock_clock : Icons.error_outline, color: Colors.red),
                            const SizedBox(height: 8),
                            Text(
                              isAuthError ? "Session expirée" : "Erreur de chargement",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAuthError 
                                ? "Veuillez vous reconnecter pour voir vos statistiques."
                                : "Impossible de récupérer les données. Vérifiez votre connexion.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.red[900]),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                if (isAuthError) {
                                  ref.read(authProvider.notifier).logout();
                                } else {
                                  ref.invalidate(adminStatsProvider);
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: Text(isAuthError ? "Se reconnecter" : "Réessayer", style: const TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  _buildSectionTitle('Actions Prioritaires'),
                  const SizedBox(height: 16),
                  if (isAdmin) ...[
                    _buildQuickAction(
                      context,
                      'Valider Partenariat Assurance',
                      'Vérifier les nouvelles demandes',
                      Icons.security,
                      AppColors.brownMedium,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssuranceManagementScreen())),
                    ),
                    _buildQuickAction(
                      context,
                      'Générer Rapport Mensuel',
                      'Exporter les données PDF',
                      Icons.picture_as_pdf_outlined,
                      AppColors.brownLight,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Génération du rapport en cours...')));
                        onNavigateTab?.call(2); // Allez vers les stats pour le moment
                      },
                    ),
                  ] else ...[
                    _buildQuickAction(
                      context,
                      'Ajouter une Lunette',
                      'Alimenter le stock',
                      Icons.add_photo_alternate_outlined,
                      AppColors.brownMedium,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen())),
                    ),
                    _buildQuickAction(
                      context,
                      'Vérifier Commandes',
                      'Prêt pour expédition',
                      Icons.local_shipping_outlined,
                      AppColors.brownLight,
                      onTap: () => onNavigateTab?.call(2), // L'index 'Commandes' est à la position 2 (Home, Stock, Orders, OCR)
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isAdmin) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.brownDark,
      actions: const [
        NotificationBell(color: Colors.white),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(isAdmin ? 'Portail Administrateur' : 'Espace Opticien',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.brownDark, AppColors.brownMedium],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.medical_services,
                size: 70, color: AppColors.nude.withValues(alpha: 0.5)),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: () {
          // Triggers the drawer of the parent Scaffold in AdminMainNavigation
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.brownDark,
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String title, String subtitle, IconData icon, Color color, {VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
