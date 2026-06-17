import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  final String apiBaseUrl;

  const AppConfig({required this.apiBaseUrl});
}

final appConfigProvider = Provider<AppConfig>((ref) {
  return const AppConfig(apiBaseUrl: EnvironmentService.currentUrl);
});

class EnvironmentService {
  static const _key = 'app_environment';
  static String _currentEnv = 'local';

  static const Map<String, String> _urls = {
    'local': 'http://10.0.2.2:3000/v1',
    'production': 'https://api.servisgadget.com/v1',
  };

  static String get currentEnv => _currentEnv;

  static String get currentUrl => _urls[_currentEnv] ?? _urls['local']!;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentEnv = prefs.getString(_key) ?? 'local';
  }

  static Future<void> setEnvironment(String env) async {
    _currentEnv = env;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, env);
  }
}
