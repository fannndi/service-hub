import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._();

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/v1',
  );

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl$path');
    final response = await http
        .post(url, headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> get(String path) async {
    final url = Uri.parse('$_baseUrl$path');
    final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 15));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl$path');
    final response = await http
        .patch(url, headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
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
