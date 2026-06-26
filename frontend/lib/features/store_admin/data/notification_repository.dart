import 'api_helper.dart';

class StoreNotificationRepository {
  String get storeId => sb.storeId ?? '';

  Future<List<dynamic>> getNotifications({int page = 1}) async {
    try {
      final data = await sb.from('notifications').select('*').eq('store_id', storeId).order('created_at', ascending: false).limit(50);
      return data;
    } catch (_) {
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final data = await sb.from('notifications').select('id').eq('store_id', storeId).eq('is_read', false);
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markAsRead(String id) async {
    await sb.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> markAllRead() async {
    await sb.from('notifications').update({'is_read': true}).eq('store_id', storeId).eq('is_read', false);
  }
}
