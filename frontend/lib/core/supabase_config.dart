class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  /// NestJS backend API URL (for Midtrans etc.)
  static const String backendUrl = String.fromEnvironment('BACKEND_URL', defaultValue: 'http://localhost:3000');

  static String buildCustomerEmail(String phone) =>
      '$phone@customer.servisgadget.com';
  static String buildStoreAdminEmail(String phone) =>
      '$phone@store.servisgadget.com';
  static String buildPlatformAdminEmail(String username) =>
      '$username@admin.servisgadget.com';
}
