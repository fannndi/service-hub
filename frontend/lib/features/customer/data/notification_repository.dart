import 'api_helper.dart';

class NotificationRepository {
  Future<List<dynamic>> getNotifications() async {
    final data = await sb.from('notifications')
      .select('*')
      .eq('user_id', sb.user!.id)
      .order('created_at', ascending: false)
      .limit(50);
    return data;
  }

  Future<int> getUnreadCount() async {
    try {
      final data = await sb.from('notifications')
        .select('id')
        .eq('user_id', sb.user!.id)
        .eq('is_read', false);
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markAsRead(String id) async {
    await sb.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> markAllRead() async {
    await sb.from('notifications').update({'is_read': true}).eq('user_id', sb.user!.id).eq('is_read', false);
  }
}
