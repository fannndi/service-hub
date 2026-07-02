import 'supabase_client.dart';

class WarmUpper {
  static const _functionsToWarm = [
    'guest',
    'orders',
    'payments',
    'midtrans',
    'disputes',
    'reviews',
    'notifications',
    'admin',
    'store-applications',
  ];

  static Future<void> warmAll(AgentSupabaseClient client) async {
    print('  🌡️  Warming up Edge Functions...');
    for (final fn in _functionsToWarm) {
      try {
        await client.invoke(fn, {'action': 'ping', '_warmup': true});
      } catch (_) {
        // Expected to fail — just warming up
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    print('  ✅ Warmup complete');
  }
}
