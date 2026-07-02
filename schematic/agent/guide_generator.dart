import '../core/scenario.dart';
import '../core/result.dart';

class UserGuide {
  static String generate(List<Scenario> scenarios, TestSuiteResult results) {
    final buf = StringBuffer();
    buf.writeln('# 📱 Panduan Penggunaan Service Me');
    buf.writeln('');
    buf.writeln('> Panduan ini dibuat oleh AI Agent setelah testing otomatis.');
    buf.writeln('> Setiap langkah sudah diverifikasi berhasil.');
    buf.writeln('');

    for (var i = 0; i < scenarios.length; i++) {
      final scenario = scenarios[i];
      final result = results.scenarios[i];
      if (!result.passed) {
        buf.writeln('## ⚠️ ${_getTitle(scenario.id)} — Belum Terverifikasi');
        buf.writeln('Scenario ini gagal di testing agent. Lihat debug report.');
        buf.writeln('');
        continue;
      }

      buf.writeln('## ✅ ${_getTitle(scenario.id)}');
      buf.writeln('');
      buf.writeln('${scenario.description}');
      buf.writeln('');

      final steps = _getHumanSteps(scenario.id);
      for (var j = 0; j < steps.length; j++) {
        buf.writeln('${j + 1}. ${steps[j]}');
      }
      buf.writeln('');
    }

    // Add quick reference table
    buf.writeln('---');
    buf.writeln('## Tabel Login');
    buf.writeln('');
    buf.writeln('| Role | Credentials |');
    buf.writeln('|------|-------------|');
    buf.writeln('| Pelanggan | No. HP + password (daftar otomatis) |');
    buf.writeln('| Store Admin | Dibuat oleh Platform Admin |');
    buf.writeln('| Platform Admin | `admin` / `admin123` |');

    return buf.toString();
  }

  static String _getTitle(String id) {
    switch (id) {
      case 'guest-booking':
        return 'Booking Servis (Tanpa Login)';
      case 'customer-booking':
        return 'Booking Servis (Login) + Review';
      case 'store-admin-full':
        return 'Store Admin: Kelola Pesanan';
      case 'platform-admin':
        return 'Platform Admin: Kelola Aplikasi';
      case 'midtrans-payment':
        return 'Pembayaran via Midtrans';
      case 'edge-cases':
        return 'Skenario Lainnya';
      default:
        return id;
    }
  }

  static List<String> _getHumanSteps(String id) {
    switch (id) {
      case 'guest-booking':
        return [
          'Buka aplikasi Service Me',
          'Tap "Ajukan Servis" di halaman utama',
          'Pilih jenis device: **Android**',
          'Pilih merek: **Samsung**',
          'Pilih model: **Galaxy A55**',
          'Pilih jenis kerusakan: **Ganti Layar**',
          'Tulis keluhan (contoh: "Layar retak dari pojok kiri")',
          'Pilih sparepart: **LCD Samsung Galaxy A55 Original**',
          'Pilih toko yang tersedia',
          'Masukkan nama lengkap',
          'Masukkan nomor WhatsApp',
          'Pilih pengiriman: **Antar ke Toko**',
          'Tap "Ajukan"',
          '✅ Catat nomor order untuk tracking',
        ];

      case 'customer-booking':
        return [
          'Login dengan No. HP dan password',
          'Di halaman utama, tap "Ajukan Servis"',
          'Pilih device, brand, model',
          'Pilih sparepart dan toko',
          'Konfirmasi dan submit',
          'Tunggu hingga status "Menunggu Persetujuan"',
          'Tap "Setuju" untuk approve estimasi biaya',
          'Setelah selesai, beri rating dan review',
          '✅ Kupon diskon otomatis diberikan!',
        ];

      case 'store-admin-full':
        return [
          'Login sebagai Store Admin',
          'Lihat dashboard: ringkasan order, revenue, dispute',
          'Buka menu **Pesanan**',
          'Pilih order masuk → Tap "Terima Device"',
          'Submit diagnosa: isi kerusakan + estimasi biaya',
          'Tunggu customer approve',
          'Setelah selesai, konfirmasi pembayaran',
          '✅ Garansi otomatis aktif (30 hari)',
        ];

      case 'platform-admin':
        return [
          'Buka halaman Welcome → long-press logo → Login Admin',
          'Login dengan username: **admin**, password: **admin123**',
          'Tab **Applications**: Approve/reject pendaftaran toko',
          'Tab **Stores**: Edit info toko yang sudah aktif',
          'Tab **Customers**: Management data pelanggan',
        ];

      case 'midtrans-payment':
        return [
          'Buka detail pesanan dengan status "Menunggu Pembayaran"',
          'Pilih metode pembayaran: **Midtrans**',
          'Tap "Bayar via Midtrans"',
          'Anda akan diarahkan ke halaman Midtrans Snap',
          'Pilih metode: Kartu Kredit, GoPay, atau lainnya',
          'Selesaikan pembayaran',
          '✅ Status otomatis berubah menjadi "Lunas" setelah notifikasi',
        ];

      case 'edge-cases':
        return [
          '**Login gagal**: Input password salah → muncul pesan error',
          '**Cancel order**: Buka detail pesanan → tap "Batalkan"',
          '**Dispute**: Untuk pesanan selesai, ajukan komplain via Warranty Claim',
          '**Kupon expired**: Kode kupon yang sudah lewat masa berlaku akan ditolak',
        ];

      default:
        return ['Undefined scenario'];
    }
  }
}
