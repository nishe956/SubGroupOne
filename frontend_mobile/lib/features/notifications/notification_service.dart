import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import 'notification_model.dart';

class NotificationService {
  final ApiClient apiClient;

  NotificationService(this.apiClient);

  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await apiClient.get(ApiEndpoints.notifications);
      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((json) => AppNotification.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> markAsRead(int id) async {
    try {
      final response = await apiClient.patch(ApiEndpoints.markNotificationRead(id));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
