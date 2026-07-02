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
    // Use service_role key as apikey to bypass RLS (works with sb_secret_ format)
    if (serviceRoleKey != null) {
      final client = HttpClient();
      try {
        // For raw SQL, use the Supabase Management API if token works
        if (managementToken != null && projectRef != null) {
          final url = 'https://api.supabase.com/v1/projects/$projectRef/database/query';
          final req = await client.postUrl(Uri.parse(url));
          req.headers.set('Authorization', 'Bearer $managementToken');
          req.headers.set('Content-Type', 'application/json');
          req.write(jsonEncode({'query': sql}));
          final res = await req.close();
          if (res.statusCode == 200) {
            final body = await res.transform(utf8.decoder).join();
            return {'success': true, 'data': body.isEmpty ? [] : jsonDecode(body)};
          }
        }
        // Fallback: use REST Data API with service_role as apikey (table queries only)
        throw Exception('Admin SQL query via service_role key requires Management API token');
      } finally {
        client.close();
      }
    }
    throw Exception('Service role key or management token required for admin query');
  }

  /// Query a table directly with service_role privileges (bypass RLS)
  Future<List<dynamic>> adminTable(String table, {String? select, Map<String, dynamic>? filters, int? limit}) async {
    if (serviceRoleKey == null) throw Exception('Service role key required');
    final client = HttpClient();
    try {
      var url = '$supabaseUrl/rest/v1/$table?select=${select ?? '*'}';
      if (limit != null) url += '&limit=$limit';
      if (filters != null) {
        for (final e in filters.entries) {
          url += '&${e.key}=eq.${e.value}';
        }
      }
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set('apikey', serviceRoleKey!);
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      if (body.isEmpty) return [];
      final decoded = jsonDecode(body);
      return decoded is List ? decoded : [decoded];
    } finally {
      client.close();
    }
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
