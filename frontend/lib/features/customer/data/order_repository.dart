import '../domain/customer_models.dart';
import 'api_helper.dart';

class OrderRepository {
  Future<CreateOrderResult> createOrder(CreateOrderRequest req) async {
    final result = await sb.invoke('orders', body: {
      'action': 'orders',
      'store_id': req.storeId,
      'device_type': req.deviceType,
      'brand': req.brand,
      'device_model': req.deviceModel,
      'delivery_method': req.deliveryMethod,
      'delivery_address': req.deliveryAddress,
      'customer_name': req.fullName,
      'phone_number': req.phoneNumber,
      'items': req.items.map((i) => {
        'service_type': i.serviceType,
        'complaint': i.complaint,
        'sparepart_id': i.sparepartId,
        'item_price': i.itemPrice,
      }).toList(),
      'coupon_code': req.couponCode,
    });
    if (result is! Map<String, dynamic>) throw Exception('Invalid response');
    final data = result;
    return CreateOrderResult(
      id: data['order_id'] as String? ?? '',
      orderNumber: data['order_number'] as String? ?? '',
      status: OrderStatus.fromJson(data['status']),
      totalEstimasi: (data['total_estimasi'] as num? ?? 0).toDouble(),
      isNewCustomer: data['is_new_customer'] as bool? ?? false,
      message: data['message'] as String? ?? '',
    );
  }

  Future<List<CustomerOrder>> getOrders({String? status, int page = 1}) async {
    final uid = sb.user?.id;
    if (uid == null) throw Exception('Not authenticated');
    final q = sb.from('service_orders').select('*, items:order_items(*)')
      .eq('user_id', uid);
    if (status != null && status != 'all') {
      if (status == 'active') {
        q = q.not('status', 'in', '("completed","cancelled")');
      } else {
        q = q.eq('status', status);
      }
    }
    final data = await q
      .order('created_at', ascending: false)
      .range((page - 1) * 20, page * 20 - 1);
    return data.map((json) => CustomerOrder.fromJson(json)).toList();
  }

  Future<CustomerOrder> getDetail(String orderId) async {
    final uid = sb.user?.id;
    if (uid == null) throw Exception('Not authenticated');
    final data = await sb.from('service_orders').select('*, items:order_items(*, sparepart:spareparts(*)), tracking:service_tracking(*), payments(*), store:stores(store_name, address, phone_number)')
      .eq('id', orderId).eq('user_id', uid).single();
    return CustomerOrder.fromJson(data);
  }

  Future<Map<String, dynamic>> getProgress(String orderId) async {
    final data = await sb.from('service_tracking').select('*').eq('order_id', orderId).order('created_at', ascending: false);
    return {'entries': data};
  }

  Future<void> approve(String orderId) async {
    await sb.invoke('orders', body: {'order_id': orderId, 'action': 'approve'});
  }

  Future<void> reject(String orderId) async {
    await sb.invoke('orders', body: {'order_id': orderId, 'action': 'reject'});
  }

  Future<dynamic> approveOrder(String orderId) => approve(orderId);
  Future<dynamic> rejectOrder(String orderId) => reject(orderId);
}