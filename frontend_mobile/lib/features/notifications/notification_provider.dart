import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_model.dart';
import 'notification_service.dart';
import '../../core/api/api_client.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _service;

  NotificationNotifier(this._service) : super(NotificationState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notifs = await _service.getNotifications();
      state = state.copyWith(notifications: notifs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(int id) async {
    final success = await _service.markAsRead(id);
    if (success) {
      // Met à jour l'état local pour un feedback immédiat
      state = state.copyWith(
        notifications: state.notifications.map((n) {
          if (n.id == id) {
            return AppNotification(
              id: n.id,
              titre: n.titre,
              message: n.message,
              isRead: true,
              typeNotif: n.typeNotif,
              timestamp: n.timestamp,
              relatedId: n.relatedId,
            );
          }
          return n;
        }).toList(),
      );
    }
  }
}

final notificationServiceProvider = Provider((ref) {
  final client = ref.watch(apiClientProvider);
  return NotificationService(client);
});

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return NotificationNotifier(service);
});
