import 'package:flutter/foundation.dart';
import '../../../core/supabase_service.dart';

class AdminNotificationRepository {
  final sb = SupabaseService.instance;

  Future<List<dynamic>> getNotifications({String? type, int page = 1}) async {
    try {
      const limit = 20;
      var q = sb.from('notifications').select('*');
      if (type != null && type != 'all') {
        q = q.eq('type', type);
      }
      final data = await q.order('created_at', ascending: false).range((page - 1) * limit, page * limit - 1);
      return data;
    } catch (e) {
      debugPrint('getNotifications error: $e');
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final data = await sb.from('notifications').select('id').eq('role', 'platform_admin').eq('is_read', false);
      return (data as List).length;
    } catch (e) {
      debugPrint('getUnreadCount error: $e');
      return 0;
    }
  }

  Future<void> markAsRead(String id) async {
    await sb.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> markAllRead() async {
    await sb.from('notifications').update({'is_read': true}).eq('role', 'platform_admin').eq('is_read', false);
  }

  Future<int> getRecentStoreApplications() async {
    try {
      final data = await sb.from('store_applications').select('id').eq('status', 'pending');
      return (data as List).length;
    } catch (e) {
      debugPrint('getRecentStoreApplications error: $e');
      return 0;
    }
  }
}
