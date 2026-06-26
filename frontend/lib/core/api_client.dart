import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._();

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/v1',
  );

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl$path');
    final response = await http
        .post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      final err = data['error'] as Map<String, dynamic>?;
      throw ApiException(
        err?['code'] as String? ?? 'UNKNOWN',
        err?['user_message'] as String? ?? 'Terjadi kesalahan',
        response.statusCode,
      );
    }
    return data['data'] as Map<String, dynamic>? ?? data;
  }
}

class ApiException implements Exception {
  ApiException(this.code, this.message, this.statusCode);
  final String code;
  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
