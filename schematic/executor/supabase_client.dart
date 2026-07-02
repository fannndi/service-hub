import 'dart:convert';
import 'dart:io';

class AgentSupabaseClient {
  final String supabaseUrl;
  final String anonKey;
  final String? serviceRoleKey;
  final String? managementToken;
  final String? projectRef;

  String? _accessToken;
  AgentSupabaseClient({
    required this.supabaseUrl,
    required this.anonKey,
    this.serviceRoleKey,
    this.managementToken,
    this.projectRef,
  });

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'apikey': anonKey,
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  Map<String, String> get _serviceHeaders => {
        'Content-Type': 'application/json',
        'apikey': anonKey,
        if (serviceRoleKey != null)
          'Authorization': 'Bearer $serviceRoleKey',
      };

  Future<String> login(String email, String password) async {
    final res = await _post(
      '$supabaseUrl/auth/v1/token?grant_type=password',
      body: {'email': email, 'password': password},
      useAnon: true,
    );
    _accessToken = res['access_token'] as String?;
    if (_accessToken == null) throw Exception('Login failed: $res');
    return _accessToken!;
  }

  Future<Map<String, dynamic>> invoke(String functionName, Map<String, dynamic> body) async {
    final url = '$supabaseUrl/functions/v1/$functionName';
    // Use access token if logged in, otherwise use anon key as Bearer token
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'apikey': anonKey,
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken'
    };
    final res = await _httpPost(url, body: body, headers: headers);
    return res;
  }

  Future<List<dynamic>> query(String table, String select, {Map<String, dynamic>? filters}) {
    // Will be implemented for direct DB queries
    throw UnimplementedError('Use invoke for now');
  }

  Future<dynamic> rpc(String function, {Map<String, dynamic>? params}) async {
    final url = '$supabaseUrl/rest/v1/rpc/$function';
    return _post(url, body: params ?? {}, useServiceRole: false);
  }

  Future<Map<String, dynamic>> adminQuery(String sql) async {
    if (serviceRoleKey != null) {
      // Direct DB query via Supabase REST API with service_role key
      final url = '$supabaseUrl/rest/v1/rpc/';
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'apikey': anonKey,
        'Authorization': 'Bearer $serviceRoleKey',
      };
      final res = await _httpPost('$supabaseUrl/rest/v1/rpc/', body: {'query': sql}, headers: headers);
      return {'success': true, 'data': res};
    }
    if (managementToken != null && projectRef != null) {
      final url = 'https://api.supabase.com/v1/projects/$projectRef/database/query';
      final res = await _httpPost(url,
        body: {'query': sql},
        headers: {'Authorization': 'Bearer $managementToken', 'Content-Type': 'application/json'},
      );
      return {'success': true, 'data': res};
    }
    throw Exception('Service role key or management token required for admin query');
  }

  Future<String> getUserEmail(String role, String phone) async {
    switch (role) {
      case 'customer':
        return '${phone}@customer.servisgadget.com';
      case 'store_admin':
        return '${phone}@store.servisgadget.com';
      case 'platform_admin':
        return '$phone@servisgadget.com';
      default:
        throw Exception('Unknown role: $role');
    }
  }

  Future<Map<String, dynamic>> _post(String url,
      {Map<String, dynamic>? body, bool useAnon = false, bool useServiceRole = false}) async {
    final headers = useServiceRole
        ? _serviceHeaders
        : useAnon
            ? {'Content-Type': 'application/json', 'apikey': anonKey}
            : _headers;
    return _httpPost(url, body: body, headers: headers);
  }

  Future<Map<String, dynamic>> _httpPost(String url,
      {Map<String, dynamic>? body, required Map<String, String> headers}) async {
    final client = HttpClient();
    try {
      final req = await client.postUrl(Uri.parse(url));
      headers.forEach((k, v) => req.headers.set(k, v));
      if (body != null) {
        req.write(jsonEncode(body));
      }
      final res = await req.close();
      final responseBody = await res.transform(utf8.decoder).join();
      if (responseBody.isEmpty) return {};
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is List) return {'data': decoded};
      return {'data': decoded};
    } finally {
      client.close();
    }
  }
}
