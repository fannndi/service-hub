import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/app_config.dart';
import '../../../network/api_client.dart';
import '../domain/store_admin_models.dart';

final storeAdminStorageProvider = Provider<StoreAdminSessionStorage>((ref) => StoreAdminSessionStorage());
final storeAdminDioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final storage = ref.watch(storeAdminStorageProvider);
  return createAuthDio(
    baseUrl: config.apiBaseUrl,
    readAccessToken: () => storage.readAccessToken(),
    readRefreshToken: () => storage.readRefreshToken(),
    onSaveTokens: (accessToken, refreshToken) => storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken),
    onClearSession: () => storage.clear(),
    refreshEndpoint: '/store/auth/refresh',
  );
});

final storeAuthRepositoryProvider = Provider<StoreAuthRepository>((ref) => StoreAuthRepository(ref.watch(storeAdminDioProvider), ref.watch(storeAdminStorageProvider)));
final storeOperationsRepositoryProvider = Provider<StoreOperationsRepository>((ref) => StoreOperationsRepository(ref.watch(storeAdminDioProvider)));

class StoreAdminSessionStorage {
  StoreAdminSessionStorage({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;

  static const _accessToken = 'store_access_token';
  static const _refreshToken = 'store_refresh_token';
  static const _adminId = 'store_admin_id';
  static const _adminName = 'store_admin_name';
  static const _phoneNumber = 'store_admin_phone';
  static const _storeId = 'store_id';
  static const _storeName = 'store_name';
  static const _isFirstLogin = 'store_is_first_login';

  Future<String?> readAccessToken() => _storage.read(key: _accessToken);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshToken);

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessToken, value: accessToken);
    await _storage.write(key: _refreshToken, value: refreshToken);
  }

  Future<void> saveLogin({required String accessToken, String? refreshToken, required StoreAdminSession session}) async {
    await _storage.write(key: _accessToken, value: accessToken);
    if (refreshToken != null) await _storage.write(key: _refreshToken, value: refreshToken);
    await _storage.write(key: _adminId, value: session.adminId);
    await _storage.write(key: _adminName, value: session.adminName);
    await _storage.write(key: _phoneNumber, value: session.phoneNumber);
    await _storage.write(key: _storeId, value: session.storeId);
    await _storage.write(key: _storeName, value: session.storeName);
    await _storage.write(key: _isFirstLogin, value: session.isFirstLogin.toString());
  }

  Future<StoreAdminSession?> restore() async {
    final token = await readAccessToken();
    if (token == null) return null;
    return StoreAdminSession.fromStorage({
      'adminId': await _storage.read(key: _adminId),
      'adminName': await _storage.read(key: _adminName),
      'phoneNumber': await _storage.read(key: _phoneNumber),
      'storeId': await _storage.read(key: _storeId),
      'storeName': await _storage.read(key: _storeName),
      'isFirstLogin': await _storage.read(key: _isFirstLogin),
    });
  }

  Future<void> markPasswordChanged() => _storage.write(key: _isFirstLogin, value: 'false');

  Future<void> clear() async {
    await Future.wait([
      for (final key in [_accessToken, _refreshToken, _adminId, _adminName, _phoneNumber, _storeId, _storeName, _isFirstLogin])
        _storage.delete(key: key),
    ]);
  }
}

class StoreAuthRepository {
  StoreAuthRepository(this._dio, this._storage);
  final Dio _dio;
  final StoreAdminSessionStorage _storage;

  Future<StoreAdminSession?> restoreSession() => _storage.restore();

  Future<StoreAdminSession> login({required String phoneNumber, required String password}) async {
    final response = await _dio.post<Map<String, dynamic>>('/store/auth/login', data: {'phoneNumber': phoneNumber, 'password': password});
    final raw = response.data ?? const {};
    final data = raw['data'] is Map<String, dynamic> ? raw['data'] as Map<String, dynamic> : raw;
    final token = (data['access_token'] ?? data['accessToken'])?.toString();
    if (token == null || token.isEmpty) throw StateError('Token store admin tidak tersedia dari API.');
    final session = StoreAdminSession.fromJson(data);
    await _storage.saveLogin(accessToken: token, refreshToken: (data['refresh_token'] ?? data['refreshToken'])?.toString(), session: session);
    return session;
  }

  Future<StoreAdminSession> changePassword(String oldPassword, String newPassword, StoreAdminSession session) async {
    await _dio.post('/store/auth/change-password', data: {'oldPassword': oldPassword, 'newPassword': newPassword});
    await _storage.markPasswordChanged();
    return session.copyWith(isFirstLogin: false);
  }

  Future<void> logout() async {
    try {
      await _dio.post('/store/auth/logout');
    } on DioException {
      // Logout tetap harus membersihkan session lokal walau endpoint belum tersedia.
    }
    await _storage.clear();
  }
}

class StoreOperationsRepository {
  StoreOperationsRepository(this._dio);
  final Dio _dio;

  Future<DashboardSummary> dashboard(StoreAdminSession? session) async {
    final response = await _dio.get<Map<String, dynamic>>('/store/dashboard/summary');
    final data = response.data ?? const {};
    if (data.isEmpty) return DashboardSummary.empty(session);
    return DashboardSummary.fromJson(data);
  }

  Future<PageResult<StoreOrder>> orders({String? status, String? query, int page = 1, int limit = 20, String? actionGroup}) async {
    final response = await _dio.get('/store/orders', queryParameters: {'status': status, 'q': query, 'page': page, 'limit': limit, 'actionGroup': actionGroup}..removeWhere((_, value) => value == null || value == ''));
    return _page(response.data, StoreOrder.fromJson);
  }

  Future<StoreOrder> orderDetail(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/store/orders/$id');
    return StoreOrder.fromJson(response.data ?? const {});
  }

  Future<StoreOrder> updateOrderStatus(String id, String action) async {
    final response = await _dio.post<Map<String, dynamic>>('/store/orders/$id/actions/$action');
    return StoreOrder.fromJson(response.data ?? const {});
  }

  Future<StoreOrder> submitDiagnosis(String orderId, Map<String, Object?> payload) async {
    final response = await _dio.post<Map<String, dynamic>>('/store/orders/$orderId/diagnosis', data: payload);
    return StoreOrder.fromJson(response.data ?? const {});
  }

  Future<List<TrackingEvent>> tracking(String orderId) async {
    final response = await _dio.get('/store/orders/$orderId/tracking');
    return _items(response.data).map(TrackingEvent.fromJson).toList();
  }

  Future<TrackingEvent> addTracking(String orderId, String title, String note, String status) async {
    final response = await _dio.post<Map<String, dynamic>>('/store/orders/$orderId/tracking', data: {'title': title, 'note': note, 'status': status});
    return TrackingEvent.fromJson(response.data ?? const {});
  }

  Future<PageResult<Sparepart>> spareparts({String? query, String? status, int page = 1, int limit = 30}) async {
    final response = await _dio.get('/store/spareparts', queryParameters: {'q': query, 'status': status, 'page': page, 'limit': limit}..removeWhere((_, value) => value == null || value == ''));
    return _page(response.data, Sparepart.fromJson);
  }

  Future<Sparepart> saveSparepart(Map<String, Object?> payload, {String? id}) async {
    final response = id == null ? await _dio.post<Map<String, dynamic>>('/store/spareparts', data: payload) : await _dio.patch<Map<String, dynamic>>('/store/spareparts/$id', data: payload);
    return Sparepart.fromJson(response.data ?? const {});
  }

  Future<PageResult<CustomerProfile>> customers({String? query, int page = 1}) async {
    final response = await _dio.get('/store/customers', queryParameters: {'q': query, 'page': page}..removeWhere((_, value) => value == null || value == ''));
    return _page(response.data, CustomerProfile.fromJson);
  }

  Future<PageResult<PaymentRecord>> payments({String? status, int page = 1}) async {
    final response = await _dio.get('/store/payments', queryParameters: {'status': status, 'page': page}..removeWhere((_, value) => value == null || value == ''));
    return _page(response.data, PaymentRecord.fromJson);
  }

  Future<void> confirmPayment(String orderId, String paymentId) async => _dio.post('/store/orders/$orderId/payments/$paymentId/confirm');

  Future<PageResult<ReviewItem>> reviews({int page = 1}) async {
    final response = await _dio.get('/store/reviews', queryParameters: {'page': page});
    return _page(response.data, ReviewItem.fromJson);
  }

  Future<void> respondReview(String reviewId, String response) async => _dio.post('/store/reviews/$reviewId/response', data: {'response': response});

  Future<PageResult<DisputeCase>> disputes({String? status, int page = 1}) async {
    final response = await _dio.get('/store/disputes', queryParameters: {'status': status, 'page': page}..removeWhere((_, value) => value == null || value == ''));
    return _page(response.data, DisputeCase.fromJson);
  }

  Future<void> resolveDispute(String disputeId, bool accept, String reason) async => _dio.post('/store/disputes/$disputeId/respond', data: {'decision': accept ? 'store_accepted' : 'store_rejected', 'storeResponse': reason});

  Future<PageResult<NotificationItem>> notifications({int page = 1}) async {
    final response = await _dio.get('/store/notifications', queryParameters: {'page': page});
    return _page(response.data, NotificationItem.fromJson);
  }

  Future<Map<String, dynamic>> storeProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/store/profile');
    return response.data ?? const {};
  }

  Future<void> updateStoreProfile(Map<String, Object?> payload) async => _dio.patch('/store/profile', data: payload);

  Future<DashboardSummary> analytics(StoreAdminSession? session) async {
    final response = await _dio.get<Map<String, dynamic>>('/store/analytics');
    return response.data == null ? DashboardSummary.empty(session) : DashboardSummary.fromJson(response.data!);
  }

  Future<Map<String, String>> presignUpload(String fileName, String mimeType, String folder) async {
    final response = await _dio.post<Map<String, dynamic>>('/uploads/presign', data: {'fileName': fileName, 'mimeType': mimeType, 'folder': folder});
    return (response.data ?? const {}).map((key, value) => MapEntry(key, value.toString()));
  }
}

PageResult<T> _page<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
  final data = raw is Map ? raw.cast<String, dynamic>() : const <String, dynamic>{};
  final source = data['items'] ?? data['data'] ?? raw;
  final list = _items(source).map(parse).toList();
  return PageResult(items: list, page: _int(data['page'], fallback: 1), limit: _int(data['limit'], fallback: list.length), total: _int(data['total'], fallback: list.length));
}

List<Map<String, dynamic>> _items(Object? raw) => raw is List ? raw.whereType<Map>().map((item) => item.cast<String, dynamic>()).toList() : const [];
int _int(Object? value, {int fallback = 0}) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? fallback;
