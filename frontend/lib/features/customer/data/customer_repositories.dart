import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/customer_models.dart';
import '../../../core/supabase_service.dart';
import '../../../core/supabase_config.dart';

final sb = SupabaseService.instance;

String parseApiError(Object error) {
  final msg = error.toString();
  if (msg.contains('STOCK_UNAVAILABLE')) return 'Stok sparepart tidak tersedia.';
  if (msg.contains('COUPON_INVALID')) return 'Kupon tidak valid.';
  if (msg.contains('ORDER_NOT_FOUND')) return 'Pesanan tidak ditemukan.';
  if (msg.contains('STORE_NOT_ACTIVE')) return 'Toko tidak aktif.';
  return 'Terjadi kesalahan. Coba lagi.';
}

class StoreDiscoveryRepository {
  Future<List<ServiceStore>> getStores({String? brand, String? model}) async {
    var q = sb.from('stores').select('*').eq('is_active', true);
    if (brand != null && brand != 'All') q = q.eq('brand', brand);
    if (model != null && model.isNotEmpty) q = q.ilike('device_model', '%$model%');
    final data = await q.order('created_at', ascending: false).limit(20);
    return data.map((json) => ServiceStore.fromJson(json)).toList();
  }

  Future<List<DeviceModelGroup>> getDeviceModels() async {
    final data = await sb.client.rpc('get_device_models');
    return (data as List).map((json) => DeviceModelGroup.fromJson(json)).toList();
  }

  Future<List<StoreMatchResult>> matchStores({required String brand, required String deviceModel, required String partType}) async {
    final data = await sb.from('stores').select('''
      id, store_name, address, phone_number, rating_avg,
      spareparts!inner(brand, device_model, part_type, part_name, price, qty, qty_reserved)
    ''').eq('is_active', true).eq('spareparts.brand', brand).eq('spareparts.device_model', deviceModel).eq('spareparts.part_type', partType);
    return data.map((json) => StoreMatchResult.fromJson(json)).toList();
  }

  Future<ServiceStore> getDetail(String storeId) async {
    final data = await sb.from('stores').select('*, reviews(*, users(full_name))').eq('id', storeId).single();
    return ServiceStore.fromJson(data);
  }

  Future<List<SparePart>> getSpareparts(String storeId) async {
    final data = await sb.from('spareparts').select('*').eq('store_id', storeId).eq('status', 'available');
    return data.map((json) => SparePart.fromJson(json)).toList();
  }
}

class OrderRepository {
  Future<CreateOrderResult> createOrder(CreateOrderRequest req) async {
    final result = await sb.invoke('orders', body: {
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
    final data = result as Map<String, dynamic>;
    return CreateOrderResult(orderNumber: data['order_number'] as String, isNewCustomer: false);
  }

  Future<List<CustomerOrder>> getOrders({String? status, int page = 1}) async {
    var q = sb.from('service_orders').select('*, items:order_items(*)')
      .eq('user_id', sb.user!.id)
      .order('created_at', ascending: false)
      .range((page - 1) * 20, page * 20 - 1);
    if (status != null && status != 'all') q = q.eq('status', status);
    final data = await q;
    return data.map((json) => CustomerOrder.fromJson(json)).toList();
  }

  Future<CustomerOrder> getDetail(String orderId) async {
    final data = await sb.from('service_orders').select('*, items:order_items(*, sparepart:spareparts(*)), tracking:service_tracking(*), payments(*), store:stores(store_name, address, phone_number)')
      .eq('id', orderId).eq('user_id', sb.user!.id).single();
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

class CustomerAuthRepository {
  Future<CustomerUser> login(String phone, String password) async {
    final email = SupabaseConfig.buildCustomerEmail(phone);
    final response = await sb.signIn(email, password);
    final meta = response.user?.userMetadata ?? {};
    return CustomerUser(
      id: response.user!.id,
      fullName: meta['full_name'] as String? ?? 'Pelanggan',
      phoneNumber: phone,
      isFirstLogin: meta['is_first_login'] as bool? ?? true,
    );
  }

  Future<void> logout() => sb.signOut();

  Future<void> changePassword(String oldPw, String newPw) => sb.updatePassword(newPw);

  Future<CustomerUser?> restoreSession() async {
    if (!sb.isLoggedIn) return null;
    final meta = sb.user?.userMetadata ?? {};
    return CustomerUser(
      id: sb.user!.id,
      fullName: meta['full_name'] as String? ?? 'Pelanggan',
      phoneNumber: meta['phone'] as String? ?? '',
      isFirstLogin: meta['is_first_login'] as bool? ?? true,
    );
  }

  Future<void> updateProfile({String? fullName, String? address}) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (address != null) updates['address'] = address;
    if (updates.isNotEmpty) {
      await sb.from('users').update(updates).eq('id', sb.user!.id);
    }
  }
}

class PaymentRepository {
  Future<void> createPayment(String orderId, {required int amount, required String paymentMethod, required String paymentType, String? proofUrl}) async {
    await sb.from('payments').insert({
      'order_id': orderId,
      'user_id': sb.user!.id,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_type': paymentType,
      'proof_url': proofUrl,
    });
  }
}

class ReviewRepository {
  Future<void> createReview(String orderId, {required int rating, String? comment}) async {
    final order = await sb.from('service_orders').select('store_id').eq('id', orderId).single();
    await sb.from('reviews').insert({
      'order_id': orderId,
      'user_id': sb.user!.id,
      'store_id': order['store_id'],
      'rating': rating,
    });
    await sb.rpc('update_rating_avg', params: {'p_store_id': order['store_id']});
  }

  Future<List<CouponReward>> getCoupons() async {
    final data = await sb.from('coupons').select('*').eq('user_id', sb.user!.id).eq('is_used', false);
    return (data as List).map((json) => CouponReward.fromJson(json)).toList();
  }
}

class DisputeRepository {
  Future<void> createDispute(String orderId, {required String disputeType, required String description, List<String>? evidenceUrls}) async {
    await sb.from('disputes').insert({
      'order_id': orderId,
      'user_id': sb.user!.id,
      'dispute_type': disputeType,
      'description': description,
      'evidence_urls': evidenceUrls ?? [],
    });
  }
}

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

class SessionRepository {
  Future<List<dynamic>> getSessions() async => [];
  Future<void> revokeSession(String id) async {}
  Future<void> logoutAll() async {}
}

class UploadRepository {
  Future<String> getPresignedUrl(String fileName, String mimeType, String folder) async {
    final path = '$folder/${sb.user!.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await sb.client.storage.from('uploads').upload(path, Stream.value([]));
    final url = sb.client.storage.from('uploads').getPublicUrl(path);
    return url;
  }
}
