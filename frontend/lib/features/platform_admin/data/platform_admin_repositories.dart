import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/app_config.dart';
import '../../../network/api_client.dart';
import '../domain/platform_admin_models.dart';

class AdminSessionStorage {
  const AdminSessionStorage(this._storage);
  static const _tokenKey = 'admin_access_token';
  static const _refreshKey = 'admin_refresh_token';
  static const _sessionKey = 'admin_session';
  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: _tokenKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);
  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshKey, value: token);

  Future<void> saveSession(AdminSession session) async {
    await _storage.write(
        key: _sessionKey,
        value: '${session.id}|${session.username}|${session.fullName}');
  }

  Future<AdminSession?> readSession() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null || !raw.contains('|')) return null;
    final parts = raw.split('|');
    if (parts.length < 3) return null;
    return AdminSession(id: parts[0], username: parts[1], fullName: parts[2]);
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _sessionKey);
  }
}

class AdminApiClient {
  AdminApiClient(AppConfig config, AdminSessionStorage session)
      : dio = createAuthDio(
          baseUrl: config.apiBaseUrl,
          readAccessToken: () => session.readToken(),
          readRefreshToken: () => session.readRefreshToken(),
          onSaveTokens: (accessToken, refreshToken) async {
            await session.saveToken(accessToken);
            await session.saveRefreshToken(refreshToken);
          },
          onClearSession: () => session.clear(),
          refreshEndpoint: '/platform/refresh',
        );

  final Dio dio;

  static Map<String, dynamic> unwrap(Object? body) {
    if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
      return body['data'] as Map<String, dynamic>;
    }
    if (body is Map<String, dynamic>) return body;
    return <String, dynamic>{};
  }
}

class AdminRepository {
  AdminRepository(this._api, this._session);
  final AdminApiClient _api;
  final AdminSessionStorage _session;

  Future<AdminLoginResult> login(String username, String password) async {
    final response = await _api.dio.post('/platform/login',
        data: {'username': username, 'password': password});
    final result =
        AdminLoginResult.fromJson(AdminApiClient.unwrap(response.data));
    await _session.saveToken(result.accessToken);
    if (result.refreshToken != null) {
      await _session.saveRefreshToken(result.refreshToken!);
    }
    await _session.saveSession(result.admin);
    return result;
  }

  Future<List<StoreListItem>> listStores() async {
    final response = await _api.dio.get('/platform/stores');
    final data = response.data;
    final list = data is Map ? (data['data'] ?? data['items'] ?? []) : data;
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(StoreListItem.fromJson)
          .toList();
    }
    return [];
  }

  Future<void> createStore({
    required String storeName,
    required String address,
    required String storePhone,
    required String adminName,
    required String adminPhone,
    required String password,
    required bool handlesAndroid,
    required bool handlesIos,
  }) async {
    await _api.dio.post('/platform/stores', data: {
      'storeName': storeName,
      'address': address,
      'storePhone': storePhone,
      'adminName': adminName,
      'adminPhone': adminPhone,
      'password': password,
      'handlesAndroid': handlesAndroid,
      'handlesIos': handlesIos,
    });
  }

  Future<void> updateStore({
    required String storeId,
    String? storeName,
    String? address,
    String? phoneNumber,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (storeName != null) data['storeName'] = storeName;
    if (address != null) data['address'] = address;
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
    if (isActive != null) data['isActive'] = isActive;
    await _api.dio.patch('/platform/stores/$storeId', data: data);
  }

  Future<List<UserListItem>> listUsers() async {
    final response = await _api.dio.get('/platform/users');
    final data = response.data;
    final list = data is Map ? (data['data'] ?? data['items'] ?? []) : data;
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(UserListItem.fromJson)
          .toList();
    }
    return [];
  }

  Future<void> updateUser({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? address,
    String? accountStatus,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['fullName'] = fullName;
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
    if (address != null) data['address'] = address;
    if (accountStatus != null) data['accountStatus'] = accountStatus;
    await _api.dio.patch('/platform/users/$userId', data: data);
  }

  Future<void> changeUserPassword(String userId, String newPassword) async {
    await _api.dio.patch('/platform/users/$userId/password',
        data: {'newPassword': newPassword});
  }

  Future<List<StoreAdminListItem>> listStoreAdmins() async {
    final response = await _api.dio.get('/platform/store-admins');
    final data = response.data;
    final list = data is Map ? (data['data'] ?? data['items'] ?? []) : data;
    if (list is List) {
      return list
          .whereType<Map<String, dynamic>>()
          .map(StoreAdminListItem.fromJson)
          .toList();
    }
    return [];
  }

  Future<void> changeStoreAdminPassword(
      String adminId, String newPassword) async {
    await _api.dio.patch('/platform/store-admins/$adminId/password',
        data: {'newPassword': newPassword});
  }

  Future<void> logout() async {
    await _session.clear();
  }
}
