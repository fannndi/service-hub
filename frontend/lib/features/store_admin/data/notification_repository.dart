import 'api_helper.dart';

class StoreNotificationRepository {
  String get storeId => sb.storeId ?? '';

  Future<List<dynamic>> getNotifications({int page = 1}) async {
    final items = await sb.from('service_tracking').select('*, orders:service_orders!inner(store_id)')
      .eq('orders.store_id', storeId).order('created_at', ascending: false).limit(50);
    return items;
  }
}
