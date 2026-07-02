import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:functions_client/functions_client.dart';
import 'supabase_config.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._();
  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  }

  User? get user => client.auth.currentUser;
  String? get role => user?.userMetadata?['role'] as String?;
  String? get storeId => user?.userMetadata?['store_id'] as String?;
  bool get isLoggedIn => client.auth.currentSession != null;

  Stream<AuthState> get onAuthStateChange => client.auth.onAuthStateChange;

  Future<AuthResponse> signIn(String email, String password) async {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Reset auth state for clean restart (integration tests).
  Future<void> reset() async {
    await client.auth.signOut();
  }

  Future<void> updatePassword(String newPassword) async {
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // Read + Filter: SupabaseQueryBuilder.select() returns PostgrestFilterBuilder with .eq/.neq/.gt/.lt etc
  SupabaseQueryBuilder from(String table) => client.from(table);

  Future<dynamic> rpc(String function, {Map<String, dynamic>? params}) async {
    return client.rpc(function, params: params);
  }

  Future<dynamic> invoke(String name, {Object? body}) async {
    try {
      final response = await client.functions.invoke(name, body: body);
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) return data['data'];
        final error = data['error'] as Map? ?? {};
        throw Exception(error['message'] as String? ?? 'Unknown error');
      }
      return response.data;
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map<String, dynamic>) {
        final error = details['error'] as Map? ?? {};
        throw Exception(error['message'] as String? ?? e.reasonPhrase ?? 'Unknown error');
      }
      throw Exception(e.reasonPhrase ?? 'Unknown error');
    }
  }
}
