import 'api_helper.dart';

class NotificationRepository {
  Future<List<dynamic>> getNotifications() async {
    final uid = sb.user?.id;
    if (uid == null) return [];
    final data = await sb.from('notifications')
      .select('*')
      .eq('user_id', uid)
      .order('created_at', ascending: false)
      .limit(50);
    return data;
  }

  Future<int> getUnreadCount() async {
    try {
      final uid = sb.user?.id;
      if (uid == null) return 0;
      final data = await sb.from('notifications')
        .select('id')
        .eq('user_id', uid)
        .eq('is_read', false);
      return (data as List).length;
    } catch (_) {
    // TODO: log error
      return 0;
    }
  }

  Future<void> markAsRead(String id) async {
    await sb.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> markAllRead() async {
    final uid = sb.user?.id;
    if (uid == null) return;
    await sb.from('notifications').update({'is_read': true}).eq('user_id', uid).eq('is_read', false);
  }
}