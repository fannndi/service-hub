import '../domain/store_admin_models.dart';
import '../../../core/supabase_service.dart';
import '../../../core/supabase_config.dart';

final sb = SupabaseService.instance;

class StoreAuthRepository {
  Future<StoreAdminSession> login(String phone, String password) async {
    final email = SupabaseConfig.buildStoreAdminEmail(phone);
    final response = await sb.signIn(email, password);
    final meta = response.user?.userMetadata ?? {};
    return StoreAdminSession(
      adminId: response.user!.id,
      adminName: meta['full_name'] as String? ?? 'Admin',
      phoneNumber: phone,
      storeId: meta['store_id'] as String? ?? '',
      storeName: '',
      isFirstLogin: meta['is_first_login'] as bool? ?? true,
    );
  }

  Future<void> changePassword(String oldPw, String newPw) => sb.updatePassword(newPw);

  Future<StoreAdminSession?> restoreSession() async {
    if (!sb.isLoggedIn || sb.role != 'store_admin') return null;
    final meta = sb.user?.userMetadata ?? {};
    return StoreAdminSession(
      adminId: sb.user!.id,
      adminName: meta['full_name'] as String? ?? 'Admin',
      phoneNumber: '',
      storeId: meta['store_id'] as String? ?? '',
      storeName: '',
      isFirstLogin: meta['is_first_login'] as bool? ?? true,
    );
  }
}

class StoreOperationsRepository {
  String get storeId => sb.storeId ?? '';

  Future<DashboardSummary> getDashboardSummary() async {
    final data = await sb.client.rpc('get_dashboard_summary', params: {'p_store_id': storeId});
    return DashboardSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getOrders({String? status, String? q, int page = 1, String? actionGroup}) async {
    var query = sb.from('service_orders').select('*, items:order_items(*), user:users(full_name, phone_number)')
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
      'created_by_id': sb.user!.id,
    });
  }

  Future<Map<String, dynamic>> getSpareparts({String? search, String? brand, String? deviceModel, String? partType, int page = 1}) async {
    var query = sb.from('spareparts').select('*').eq('store_id', storeId);
    if (search != null) query = query.ilike('part_name', '%$search%');
    if (brand != null) query = query.eq('brand', brand);
    if (deviceModel != null) query = query.eq('device_model', deviceModel);
    if (partType != null) query = query.eq('part_type', partType);
    final items = await query.order('created_at', ascending: false).range((page - 1) * 20, page * 20 - 1);
    return {'items': items, 'total': items.length};
  }

  Future<void> saveSparepart(Map<String, dynamic> data, {String? id}) async {
    if (id != null) {
      await sb.from('spareparts').update(data).eq('id', id);
    } else {
      await sb.from('spareparts').insert({...data, 'store_id': storeId});
    }
  }

  Future<void> adjustStock(String sparepartId, int delta) async {
    final item = await sb.from('spareparts').select('qty').eq('id', sparepartId).single();
    final newQty = (item['qty'] as int) + delta;
    await sb.from('spareparts').update({'qty': newQty}).eq('id', sparepartId);
  }

  Future<List<String>> getBrands() async {
    final data = await sb.from('spareparts').select('brand').eq('store_id', storeId);
    return (data as List).map((d) => d['brand'] as String).toSet().toList()..sort();
  }

  Future<List<String>> getDeviceModels(String? brand) async {
    var q = sb.from('spareparts').select('device_model').eq('store_id', storeId);
    if (brand != null) q = q.eq('brand', brand);
    final data = await q;
    return (data as List).map((d) => d['device_model'] as String).toSet().toList()..sort();
  }

  Future<Map<String, dynamic>> getCustomers({String? q, int page = 1}) async {
    final orders = await sb.from('service_orders').select('user_id')
      .eq('store_id', storeId);
    final userIds = (orders as List).map((o) => o['user_id'] as String).toSet().toList();
    if (userIds.isEmpty) return {'items': [], 'total': 0};
    var query = sb.from('users').select('*').inFilter('id', userIds);
    final items = await query;
    return {'items': items, 'total': items.length};
  }

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

  Future<Map<String, dynamic>> getReviews({int page = 1}) async {
    final items = await sb.from('reviews').select('*, users(full_name), orders!inner(store_id)')
      .eq('orders.store_id', storeId).order('created_at', ascending: false);
    return {'items': items, 'total': (items as List).length};
  }

  Future<void> respondReview(String reviewId, String response) async {}

  Future<Map<String, dynamic>> getDisputes({String? status, int page = 1}) async {
    var query = sb.from('disputes').select('*, users(full_name, phone_number)')
      .eq('store_id', storeId);
    if (status != null) query = query.eq('status', status);
    final items = await query.order('created_at', ascending: false);
    return {'items': items, 'total': (items as List).length};
  }

  Future<void> resolveDispute(String disputeId, bool accept, String reason) async {
    await sb.invoke('disputes', body: {
      'dispute_id': disputeId,
      'decision': accept ? 'store_accepted' : 'store_rejected',
      'store_response': reason,
    });
  }

  Future<List<dynamic>> getNotifications({int page = 1}) async {
    final items = await sb.from('service_tracking').select('*, orders:service_orders!inner(store_id)')
      .eq('orders.store_id', storeId).order('created_at', ascending: false).limit(50);
    return items;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final data = await sb.from('store_admins').select('*, stores(*)').eq('id', sb.user!.id).single();
    return data;
  }

  Future<void> updateProfile(Map<String, dynamic> payload) async {}

  Future<Map<String, dynamic>> getAnalytics() async {
    final data = await sb.client.rpc('get_analytics', params: {'p_store_id': storeId});
    return data as Map<String, dynamic>;
  }
}
