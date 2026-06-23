import 'api_helper.dart';

class StoreCustomerRepository {
  String get storeId => sb.storeId ?? '';

  Future<Map<String, dynamic>> getCustomers({String? q, int page = 1}) async {
    final orders = await sb.from('service_orders').select('user_id')
      .eq('store_id', storeId);
    final userIds = (orders as List).map((o) => o['user_id'] as String).toSet().toList();
    if (userIds.isEmpty) return {'items': [], 'total': 0};
    var query = sb.from('users').select('*').inFilter('id', userIds);
    final items = await query;
    return {'items': items, 'total': items.length};
  }
}
