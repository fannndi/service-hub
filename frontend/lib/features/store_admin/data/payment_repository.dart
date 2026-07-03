import 'api_helper.dart';

class StorePaymentRepository {
  String get storeId => sb.storeId ?? '';

  Future<Map<String, dynamic>> getPayments({String? status, int page = 1}) async {
    var query = sb.from('payments').select('*, orders:service_orders!inner(order_number, store_id)')
      .eq('orders.store_id', storeId);
    if (status != null) query = query.eq('status', status);
    final items = await query.order('created_at', ascending: false).range((page - 1) * 20, page * 20 - 1);
    return {'items': items, 'total': items.length};
  }

  Future<void> confirmPayment(String orderId, String paymentId) async {
    await sb.invoke('payments', body: {'order_id': orderId, 'payment_id': paymentId, 'action': 'confirm'});
  }
}
