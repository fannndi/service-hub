import 'dart:async';

import 'package:dio/dio.dart';

import '../core/json_helpers.dart';

Dio createApiClient(String baseUrl, {Future<String?> Function()? readToken}) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
  ));

  if (readToken != null) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await readToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
    ));
  }

  return dio;
}

/// Creates a Dio instance with auth interceptor and automatic token refresh.
/// Use this for features that need 401 → refresh → retry logic.
Dio createAuthDio({
  required String baseUrl,
  required Future<String?> Function() readAccessToken,
  required Future<String?> Function() readRefreshToken,
  required Future<void> Function(String accessToken, String refreshToken) onSaveTokens,
  required Future<void> Function() onClearSession,
  String refreshEndpoint = '/auth/refresh',
}) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
  ));

  Completer<void>? refreshCompleter;

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await readAccessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode != 401) {
        handler.next(error);
        return;
      }

      if (refreshCompleter != null) {
        await refreshCompleter!.future;
        final newToken = await readAccessToken();
        if (newToken != null) {
          error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          handler.resolve(await dio.fetch(error.requestOptions));
        } else {
          handler.next(error);
        }
        return;
      }

      refreshCompleter = Completer<void>();

      try {
        final refresh = await readRefreshToken();
        if (refresh == null) {
          handler.next(error);
          return;
        }
        final publicDio = Dio(BaseOptions(baseUrl: baseUrl));
        final response = await publicDio.post(refreshEndpoint, data: {'refresh_token': refresh});
        final data = unwrap(response.data);
        final newAccess = readString(data, 'access_token', 'accessToken');
        final newRefresh = readString(data, 'refresh_token', 'refreshToken');
        await onSaveTokens(newAccess, newRefresh);
        error.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
        handler.resolve(await dio.fetch(error.requestOptions));
      } catch (_) {
        await onClearSession();
        handler.next(error);
      } finally {
        refreshCompleter!.complete();
        refreshCompleter = null;
      }
    },
  ));

  return dio;
}

/// Unwrap API response envelope: { "data": { ... } } → { ... }
Map<String, dynamic> unwrap(Object? body) {
  if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
    return body['data'] as Map<String, dynamic>;
  }
  if (body is Map<String, dynamic>) return body;
  return <String, dynamic>{};
}

/// Unwrap list from API response: { "data": [...] } or { "data": { "items": [...] } }
List<Map<String, dynamic>> unwrapList(Object? body) {
  final data = body is Map<String, dynamic> ? body['data'] : body;
  if (data is List) return data.whereType<Map<String, dynamic>>().toList();
  if (data is Map<String, dynamic> && data['items'] is List) {
    return (data['items'] as List).whereType<Map<String, dynamic>>().toList();
  }
  return const [];
}
