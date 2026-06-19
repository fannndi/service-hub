import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  final String apiBaseUrl;

  const AppConfig({required this.apiBaseUrl});
}

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig(apiBaseUrl: EnvironmentService.currentUrl);
});

class EnvironmentService {
  static const _key = 'app_url_cache';
  static const _tunnelUrl = 'https://raw.githubusercontent.com/fannndi/service-hub/refs/heads/main/tunel.txt';
  static const _defaultUrl = 'http://10.0.2.2:3000/v1';
  static const _retryCount = 3;
  static const _retryDelay = Duration(seconds: 2);

  static String _currentUrl = _defaultUrl;
  static bool _isMaintenance = false;

  static String get currentUrl => _currentUrl;
  static bool get isMaintenance => _isMaintenance;

  static Future<void> init() async {
    for (var i = 0; i < _retryCount; i++) {
      try {
        final dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ));
        final resp = await dio.get<String>(_tunnelUrl);
        if (resp.statusCode == 200 && resp.data != null) {
          final url = resp.data.toString().trim();
          if (url.startsWith('http://') || url.startsWith('https://')) {
            _currentUrl = url;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_key, url);
            return;
          }
        }
      } catch (_) {
        if (i < _retryCount - 1) {
          await Future.delayed(_retryDelay);
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_key);
    if (cached != null && cached.startsWith('http')) {
      _currentUrl = cached;
      return;
    }

    _isMaintenance = true;
  }
}
