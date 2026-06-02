import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  final String apiBaseUrl;
}

final appConfigProvider = Provider<AppConfig>((ref) {
  const value = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000/v1');
  return const AppConfig(apiBaseUrl: value);
});
