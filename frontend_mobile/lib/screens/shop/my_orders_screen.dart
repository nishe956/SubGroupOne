import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../features/commandes/commande_service.dart';
import 'order_tracking_screen.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  late Future<List<dynamic>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = ref.read(orderServiceProvider).getUserOrders();
  }

  void _refreshOrders() {
    setState(() {
      _ordersFuture = ref.read(orderServiceProvider).getUserOrders();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'livrer':
        return Colors.green;
      case 'expedier':
        return Colors.blue;
      case 'en_preparation':
        return Colors.orange;
      case 'en_attente':
        return Colors.grey;
      default:
        return AppColors.brownMedium;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'livrer':
        return 'Livrée';
      case 'expedier':
        return 'Expédiée';
      case 'en_preparation':
        return 'En cours de préparation';
      case 'en_attente':
        return 'En attente';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Mes Commandes', style: TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brownMedium),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshOrders(),
        child: FutureBuilder<List<dynamic>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.brownLight),
                    const SizedBox(height: 16),
                    const Text('Aucune commande trouvée', style: TextStyle(color: AppColors.brownMedium, fontSize: 16)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('BOUTIQUE'),
                    ),
                  ],
                ),
              );
            }

            final orders = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final dateStr = order['date_commande'];
                final date = DateTime.parse(dateStr);
                final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
                final status = order['statut'];

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderTrackingScreen(order: order),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Commande #${order['id']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brownDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getStatusText(status),
                                  style: TextStyle(color: _getStatusColor(status), fontSize: 11, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(formattedDate, style: const TextStyle(color: AppColors.brownLight, fontSize: 13)),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.cream,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.remove_red_eye_outlined, color: AppColors.brownMedium),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order['monture_nom'] ?? 'Produit',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text('Qté: ${order['quantite']}', style: const TextStyle(color: AppColors.brownMedium, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(
                              '${double.parse(order['prix_total'].toString()).toStringAsFixed(2)} €',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brownDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Détails & Suivi', style: TextStyle(color: AppColors.brownMedium, fontWeight: FontWeight.bold, fontSize: 13)),
                            Icon(Icons.chevron_right, size: 18, color: AppColors.brownMedium),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
