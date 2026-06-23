import '../../../core/supabase_service.dart';

final sb = SupabaseService.instance;

String parseApiError(Object error) {
  final msg = error.toString();
  if (msg.contains('STOCK_UNAVAILABLE')) return 'Stok sparepart tidak tersedia.';
  if (msg.contains('COUPON_INVALID')) return 'Kupon tidak valid.';
  if (msg.contains('ORDER_NOT_FOUND')) return 'Pesanan tidak ditemukan.';
  if (msg.contains('STORE_NOT_ACTIVE')) return 'Toko tidak aktif.';
  return 'Terjadi kesalahan. Coba lagi.';
}
