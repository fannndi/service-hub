import '../domain/store_admin_models.dart';
import 'api_helper.dart';

class StoreOrderRepository {
  String get storeId => sb.storeId ?? '';

  Future<Map<String, dynamic>> getOrders({String? status, String? q, int page = 1, String? actionGroup}) async {
    final query = sb.from('service_orders').select('*, items:order_items(*), user:users(full_name, phone_number)')
      .eq('store_id', storeId);
    if (status != null) query = query.eq('status', status);
    if (q != null) query = query.or('order_number.ilike.%$q%,user.full_name.ilike.%$q%,device_model.ilike.%$q%');
    final items = await query.order('created_at', ascending: false).range((page - 1) * 20, page * 20 - 1);
    return {'items': items, 'total': items.length};
  }

  Future<StoreOrder> getOrderDetail(String orderId) async {
    final data = await sb.from('service_orders').select('*, items:order_items(*, sparepart:spareparts(*)), user:users(full_name, phone_number, credential_plain_enc), tracking:service_tracking(*), payments(*), disputes(*)')
      .eq('id', orderId).eq('store_id', storeId).single();
    return StoreOrder.fromJson(data);
  }

  Future<void> runAction(String orderId, String action) async {
    await sb.invoke('orders', body: {'order_id': orderId, 'action': 'status', 'status': action});
  }

  Future<void> submitDiagnosis(String orderId, Map<String, dynamic> payload) async {
    await sb.invoke('orders', body: {
      'order_id': orderId,
      'action': 'diagnosis',
      ...payload,
    });
  }

  Future<List<dynamic>> getTracking(String orderId) async {
    final data = await sb.from('service_tracking').select('*')
      .eq('order_id', orderId).order('created_at', ascending: false);
    return data;
  }

  Future<void> addTracking(String orderId, String title, String note, String status) async {
    await sb.from('service_tracking').insert({
      'order_id': orderId,
      'status': status,
      'note': '$title: $note',
      'created_by_type': 'store_admin',
      'created_by_id': (sb.user?.id ?? (throw Exception('Not authenticated'))),
    });
  }
}
