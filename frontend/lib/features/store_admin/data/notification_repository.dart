import '../../../../core/api_client.dart';

class StoreNotificationRepository {
  Future<List<dynamic>> getNotifications({int page = 1}) async {
    try {
      final result = await ApiClient.instance.get('/store/notifications?page=$page');
      return (result['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final result = await ApiClient.instance.get('/store/notifications/unread-count');
      return result['count'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await ApiClient.instance.patch('/store/notifications/$id/read', {});
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await ApiClient.instance.patch('/store/notifications/read-all', {});
    } catch (_) {}
  }
}
