import '../executor/supabase_client.dart';

class StateInspector {
  final AgentSupabaseClient client;

  StateInspector(this.client);

  Future<Map<String, dynamic>> inspectOrder(String orderId) async {
    try {
      final res = await client.adminQuery(
        "SELECT id, order_number, status, payment_status, "
        "final_price, total_estimasi, created_at, completed_at "
        "FROM service_orders WHERE id = '$orderId'",
      );
      return res;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> inspectUser(String userId) async {
    try {
      final res = await client.adminQuery(
        "SELECT id, full_name, phone_number, account_status "
        "FROM users WHERE id = '$userId'",
      );
      return res;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> inspectStore(String storeId) async {
    try {
      final res = await client.adminQuery(
        "SELECT id, store_name, rating_avg, total_completed, is_active "
        "FROM stores WHERE id = '$storeId'",
      );
      return res;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<List<String>> diagnoseError(Object error) async {
    final causes = <String>[];
    final msg = error.toString().toLowerCase();

    if (msg.contains('401') || msg.contains('unauthorized')) {
      causes.add('AUTH_ERROR: JWT token tidak valid atau expired');
      causes.add('  → Cek apakah user sudah login dengan role yang benar');
      causes.add('  → Cek apakah password/email sesuai');
    }
    if (msg.contains('403') || msg.contains('forbidden')) {
      causes.add('FORBIDDEN: User tidak punya akses ke resource ini');
      causes.add('  → Cek RLS policy untuk role ini');
      causes.add('  → Cek apakah user_id match dengan resource');
    }
    if (msg.contains('404') || msg.contains('not found')) {
      causes.add('NOT_FOUND: Data yang diminta tidak ada');
      causes.add('  → Cek apakah ID yang digunakan valid');
      causes.add('  → Cek apakah data sudah di-seed');
    }
    if (msg.contains('invalid status transition') ||
        msg.contains('INVALID_STATUS_TRANSITION')) {
      causes.add('STATE_ERROR: Transisi status tidak valid');
      causes.add('  → Cek state machine: waiting_device → device_received → diagnosing → ...');
      causes.add('  → Pastikan tidak loncat status');
    }
    if (msg.contains('timeout')) {
      causes.add('TIMEOUT: Cold start atau server sibuk');
      causes.add('  → Coba jalankan ulang (warmup sudah dilakukan)');
      causes.add('  → Cek koneksi internet');
    }
    if (msg.contains('violates foreign key')) {
      causes.add('FK_ERROR: Referensi data tidak valid');
      causes.add('  → Pastikan ID store/sparepart/user benar-benar ada');
    }
    if (msg.contains('duplicate') || msg.contains('unique constraint')) {
      causes.add('DUPLICATE: Data sudah ada (unique constraint)');
      causes.add('  → Coba gunakan data yang berbeda');
    }

    if (causes.isEmpty) {
      causes.add('UNKNOWN_ERROR: ${error.toString().substring(0, 200)}');
    }

    return causes;
  }
}
