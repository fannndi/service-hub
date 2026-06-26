import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class GuestBookingSuccessScreen extends StatelessWidget {
  const GuestBookingSuccessScreen({
    super.key,
    required this.orderNumber,
  });

  final String orderNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Berhasil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.check_circle_rounded, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Pesanan berhasil dibuat!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Simpan nomor pesanan ini untuk cek status.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(children: [
                  Text('Nomor Pesanan', style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  SelectableText(orderNumber, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: orderNumber));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nomor pesanan disalin')));
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Salin'),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: scheme.primaryContainer.withAlpha(80),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Icon(Icons.info_outline, color: scheme.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Kamu bisa cek status pesanan kapan saja pakai nomor di atas. '
                      'Setelah toko menerima perangkat, akun kamu bisa diaktifkan.',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/guest/track/$orderNumber'),
              icon: const Icon(Icons.search),
              label: const Text('Cek Status Pesanan'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/welcome'),
              child: const Text('Kembali ke Beranda'),
            ),
          ],
        ),
      ),
    );
  }
}
