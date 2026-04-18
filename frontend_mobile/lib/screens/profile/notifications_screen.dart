import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../features/notifications/notification_provider.dart';
import '../../features/notifications/notification_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Notifications', 
          style: TextStyle(color: AppColors.brownDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brownMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(notificationProvider.notifier).refresh(),
          ),
        ],
      ),
      body: state.isLoading && state.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(notificationProvider.notifier).refresh(),
              child: state.notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.notifications.length,
                      itemBuilder: (context, index) {
                        final notification = state.notifications[index];
                        return _NotificationCard(notification: notification);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: AppColors.brownLight.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'Aucune notification',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brownDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vous recevrez des alertes ici.',
            style: TextStyle(color: AppColors.brownMedium),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('dd MMM, HH:mm').format(notification.timestamp);
    
    IconData iconData;
    Color iconColor;
    
    switch (notification.typeNotif) {
      case 'commande':
        iconData = Icons.shopping_bag_outlined;
        iconColor = Colors.orange;
        break;
      case 'stock':
        iconData = Icons.inventory_2_outlined;
        iconColor = Colors.red;
        break;
      case 'ordonnance':
        iconData = Icons.description_outlined;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.notifications_outlined;
        iconColor = AppColors.brownMedium;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white.withValues(alpha: 0.8) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: notification.isRead ? null : Border.all(color: iconColor.withValues(alpha: 0.3), width: 1),
      ),
      child: ListTile(
        onTap: () {
          if (!notification.isRead) {
            ref.read(notificationProvider.notifier).markAsRead(notification.id);
          }
          // On pourrait ajouter une navigation vers relatedId ici si nécessaire
        },
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                notification.titre,
                style: TextStyle(
                  fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                  color: AppColors.brownDark,
                ),
              ),
            ),
            Text(
              dateStr,
              style: TextStyle(fontSize: 11, color: AppColors.brownLight),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            notification.message,
            style: TextStyle(color: AppColors.brownMedium, fontSize: 13),
          ),
        ),
        trailing: !notification.isRead 
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
            )
          : null,
      ),
    );
  }
}
