class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static String buildCustomerEmail(String phone) =>
      '$phone@customer.servisgadget.com';
  static String buildStoreAdminEmail(String phone) =>
      '$phone@store.servisgadget.com';
  static String buildPlatformAdminEmail(String username) =>
      '$username@admin.servisgadget.com';
}
