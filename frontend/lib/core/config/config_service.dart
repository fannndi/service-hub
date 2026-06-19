import 'package:dio/dio.dart';
import '../app_config.dart';

class AppConfigData {
  final String environment;
  final bool maintenanceMode;
  final String maintenanceMessage;
  final String version;

  const AppConfigData({
    required this.environment,
    required this.maintenanceMode,
    required this.maintenanceMessage,
    required this.version,
  });

  factory AppConfigData.fromJson(Map<String, dynamic> json) {
    return AppConfigData(
      environment: json['environment'] as String? ?? 'local',
      maintenanceMode: json['maintenanceMode'] as bool? ?? false,
      maintenanceMessage: json['maintenanceMessage'] as String? ?? 'Sedang Maintenance',
      version: json['version'] as String? ?? '1.0.0',
    );
  }

  static const defaultOffline = AppConfigData(
    environment: 'local',
    maintenanceMode: true,
    maintenanceMessage: 'Sedang Maintenance',
    version: '0.0.0',
  );
}

class ConfigService {
  static const _timeout = Duration(seconds: 10);

  static Future<AppConfigData> fetch() async {
    final url = EnvironmentService.currentUrl;
    final dio = Dio(BaseOptions(baseUrl: url, connectTimeout: _timeout, receiveTimeout: _timeout));
    final response = await dio.get('/config');
    final data = response.data;
    final body = data is Map<String, dynamic> && data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return AppConfigData.fromJson(body);
  }
}
