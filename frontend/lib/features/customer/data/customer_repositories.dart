import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/app_config.dart';
import '../domain/customer_models.dart';

String normalizePhone(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('62')) return '+$digits';
  if (digits.startsWith('0')) return '+62${digits.substring(1)}';
  return '+62$digits';
}

String parseApiError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final errorBody = data['error'];
      if (errorBody is Map<String, dynamic>) {
        final userMessage = errorBody['user_message'];
        if (userMessage is String && userMessage.isNotEmpty) return userMessage;
        return _codeToMessage(errorBody['code'] as String?);
      }
    }
  }
  return 'Terjadi kesalahan. Coba lagi nanti.';
}

String _codeToMessage(String? code) => switch (code) {
      'INVALID_CREDENTIALS' => 'Nomor HP atau password salah.',
      'ACCOUNT_LOCKED' => 'Akun terkunci sementara.',
      'ACCOUNT_SUSPENDED' => 'Akun dinonaktifkan. Hubungi support.',
      'PASSWORD_SAME_AS_OLD' => 'Password baru tidak boleh sama dengan yang lama.',
      'STOCK_UNAVAILABLE' => 'Stok sparepart habis, pilih sparepart lain.',
      'STORE_NOT_ACTIVE' => 'Toko tidak aktif.',
      'PROOF_REQUIRED' => 'Bukti pembayaran wajib diunggah.',
      'DUPLICATE_REVIEW' => 'Kamu sudah memberikan ulasan.',
      'WARRANTY_EXPIRED' => 'Masa garansi sudah berakhir.',
      'DISPUTE_ALREADY_ACTIVE' => 'Sudah ada klaim aktif.',
      _ => 'Terjadi kesalahan. Coba lagi nanti.',
    };

class CustomerSessionStorage {
  const CustomerSessionStorage(this._storage);
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _cachedProfileKey = 'customer_cached_profile';
  static const _cachedSettingsKey = 'customer_notifications_enabled';
  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  Future<void> cacheProfile(CustomerUser user) => _storage.write(key: _cachedProfileKey, value: '${user.fullName}|${user.phoneNumber}|${user.address ?? ''}');
  Future<String?> readCachedProfile() => _storage.read(key: _cachedProfileKey);
  Future<void> saveNotificationPreference(bool enabled) => _storage.write(key: _cachedSettingsKey, value: enabled ? '1' : '0');
  Future<bool> readNotificationPreference() async => (await _storage.read(key: _cachedSettingsKey)) != '0';

  Future<void> clearAll() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

class CustomerApiClient {
  CustomerApiClient(AppConfig config, this._session)
      : publicDio = Dio(BaseOptions(baseUrl: config.apiBaseUrl, connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 20))),
        authDio = Dio(BaseOptions(baseUrl: config.apiBaseUrl, connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 20))) {
    authDio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _session.readAccessToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode != 401) {
          handler.next(error);
          return;
        }
        final refresh = await _session.readRefreshToken();
        if (refresh == null) {
          handler.next(error);
          return;
        }
        try {
          final response = await publicDio.post('/auth/refresh', data: {'refresh_token': refresh});
          final data = unwrap(response.data);
          await _session.saveTokens(readString(data, 'access_token', 'accessToken'), readString(data, 'refresh_token', 'refreshToken'));
          final token = await _session.readAccessToken();
          error.requestOptions.headers['Authorization'] = 'Bearer $token';
          handler.resolve(await authDio.fetch(error.requestOptions));
        } catch (_) {
          await _session.clearAll();
          handler.next(error);
        }
      },
    ));
  }

  final CustomerSessionStorage _session;
  final Dio publicDio;
  final Dio authDio;

  static Map<String, dynamic> unwrap(Object? body) {
    if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) return body['data'] as Map<String, dynamic>;
    if (body is Map<String, dynamic>) return body;
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> unwrapList(Object? body) {
    final data = body is Map<String, dynamic> ? body['data'] : body;
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    if (data is Map<String, dynamic> && data['items'] is List) return (data['items'] as List).whereType<Map<String, dynamic>>().toList();
    return const [];
  }
}

class CustomerAuthRepository {
  CustomerAuthRepository(this._api, this._session);
  final CustomerApiClient _api;
  final CustomerSessionStorage _session;

  Future<LoginResult> login(String phone, String password) async {
    final response = await _api.publicDio.post('/auth/login', data: {'phone_number': normalizePhone(phone), 'password': password});
    final result = LoginResult.fromJson(CustomerApiClient.unwrap(response.data));
    await _session.saveTokens(result.accessToken, result.refreshToken);
    await _session.cacheProfile(result.user);
    return result;
  }

  Future<CustomerUser> getMe() async {
    final response = await _api.authDio.get('/me');
    final user = CustomerUser.fromJson(CustomerApiClient.unwrap(response.data));
    await _session.cacheProfile(user);
    return user;
  }

  Future<HomeSummary> getSummary() async {
    final response = await _api.authDio.get('/me/summary');
    return HomeSummary.fromJson(CustomerApiClient.unwrap(response.data));
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _api.authDio.post('/auth/change-password', data: {'old_password': oldPassword, 'new_password': newPassword});
  }

  Future<CustomerUser> updateProfile({required String fullName, String? address, String? avatarUrl}) async {
    final response = await _api.authDio.patch('/me', data: {'full_name': fullName, 'address': address, if (avatarUrl != null) 'avatar_url': avatarUrl});
    final user = CustomerUser.fromJson(CustomerApiClient.unwrap(response.data));
    await _session.cacheProfile(user);
    return user;
  }

  Future<void> logout() async {
    final refresh = await _session.readRefreshToken();
    if (refresh != null) {
      try {
        await _api.authDio.post('/auth/logout', data: {'refresh_token': refresh});
      } catch (_) {}
    }
    await _session.clearAll();
  }
}

class StoreDiscoveryRepository {
  StoreDiscoveryRepository(this._api);
  final CustomerApiClient _api;

  Future<List<ServiceStore>> getStores({String? brand, String? deviceModel, int page = 1}) async {
    final response = await _api.authDio.get('/stores', queryParameters: {'page': page, 'limit': 20, if (brand != null && brand != 'All') 'brand': brand, if (deviceModel != null && deviceModel.isNotEmpty) 'deviceModel': deviceModel});
    return CustomerApiClient.unwrapList(response.data).map(ServiceStore.fromJson).toList();
  }

  Future<ServiceStore> getStore(String id) async {
    final response = await _api.authDio.get('/stores/$id');
    return ServiceStore.fromJson(CustomerApiClient.unwrap(response.data));
  }

  Future<List<SparePart>> getSpareparts(String storeId) async {
    final response = await _api.authDio.get('/store/spareparts', queryParameters: {'storeId': storeId});
    return CustomerApiClient.unwrapList(response.data).map(SparePart.fromJson).toList();
  }
}

class OrderRepository {
  OrderRepository(this._api);
  final CustomerApiClient _api;

  Future<CreateOrderResult> createOrder(CreateOrderRequest request) async {
    final response = await _api.publicDio.post('/orders', data: request.toJson());
    return CreateOrderResult.fromJson(CustomerApiClient.unwrap(response.data));
  }

  Future<List<CustomerOrder>> getMyOrders({String? status, int page = 1, int limit = 20}) async {
    final response = await _api.authDio.get('/me/orders', queryParameters: {'page': page, 'limit': limit, if (status != null) 'status': status});
    return CustomerApiClient.unwrapList(response.data).map(CustomerOrder.fromJson).toList();
  }

  Future<CustomerOrder> getOrderDetail(String orderId) async {
    final response = await _api.authDio.get('/orders/$orderId');
    return CustomerOrder.fromJson(CustomerApiClient.unwrap(response.data));
  }

  Future<CustomerOrder> getOrderProgress(String orderId) async {
    final response = await _api.authDio.get('/me/orders/$orderId/progress');
    return CustomerOrder.fromJson(CustomerApiClient.unwrap(response.data));
  }

  Future<void> approveOrder(String orderId) => _api.authDio.post('/orders/$orderId/approve').then((_) {});
  Future<void> rejectOrder(String orderId) => _api.authDio.post('/orders/$orderId/reject').then((_) {});
}

class UploadRepository {
  UploadRepository(this._api);
  final CustomerApiClient _api;

  Future<String> uploadFile(XFile file, String folder, void Function(double progress)? onProgress) async {
    final mimeType = _guessMime(file.name);
    final presign = await _api.authDio.post('/uploads/presign', data: {'fileName': file.name, 'mimeType': mimeType, 'folder': folder});
    final data = CustomerApiClient.unwrap(presign.data);
    final uploadUrl = readString(data, 'uploadUrl', 'upload_url');
    final fileUrl = readString(data, 'fileUrl', 'file_url');
    final diskFile = File(file.path);
    await Dio().put(
      uploadUrl,
      data: diskFile.openRead(),
      options: Options(headers: {'Content-Type': mimeType, 'Content-Length': await diskFile.length()}),
      onSendProgress: (sent, total) {
        if (total > 0) onProgress?.call(sent / total);
      },
    );
    return fileUrl;
  }

  String _guessMime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

class PaymentRepository {
  PaymentRepository(this._api);
  final CustomerApiClient _api;

  Future<void> createPayment({required String orderId, required double amount, required String method, required String type, String? proofUrl}) async {
    await _api.authDio.post('/orders/$orderId/payments', data: {'amount': amount, 'paymentMethod': method, 'paymentType': type, if (proofUrl != null) 'proofUrl': proofUrl});
  }
}

class ReviewRepository {
  ReviewRepository(this._api);
  final CustomerApiClient _api;

  Future<ReviewResult> createReview({required String orderId, required int rating, String? comment}) async {
    final response = await _api.authDio.post('/orders/$orderId/reviews', data: {'rating': rating, if (comment != null && comment.isNotEmpty) 'comment': comment});
    return ReviewResult.fromJson(CustomerApiClient.unwrap(response.data));
  }

  Future<List<CouponReward>> getCoupons() async {
    final response = await _api.authDio.get('/me/coupons');
    return CustomerApiClient.unwrapList(response.data).map(CouponReward.fromJson).toList();
  }
}

class DisputeRepository {
  DisputeRepository(this._api);
  final CustomerApiClient _api;

  Future<void> createDispute({required String orderId, required String disputeType, required String description, required List<String> evidenceUrls}) async {
    await _api.authDio.post('/orders/$orderId/disputes', data: {'disputeType': disputeType, 'description': description, 'evidenceUrls': evidenceUrls});
  }
}

class NotificationRepository {
  NotificationRepository(this._api);
  final CustomerApiClient _api;

  Future<List<NotificationItem>> getNotifications() async {
    final response = await _api.authDio.get('/me/notifications');
    return CustomerApiClient.unwrapList(response.data).map(NotificationItem.fromJson).toList();
  }
}
