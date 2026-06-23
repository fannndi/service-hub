import 'api_helper.dart';

class NotificationRepository {
  Future<List<dynamic>> getNotifications() async {
    final data = await sb.from('service_tracking')
      .select('*, orders:service_orders!inner(store_id)')
      .eq('orders.user_id', sb.user!.id)
      .order('created_at', ascending: false)
      .limit(50);
    return data;
  }
}
