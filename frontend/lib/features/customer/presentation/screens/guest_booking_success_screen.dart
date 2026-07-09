import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/supabase_service.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../ui/widgets/servis_dialog.dart';

class GuestBookingSuccessScreen extends StatefulWidget {
  const GuestBookingSuccessScreen({
    super.key,
    required this.orderNumber,
    this.tempPassword,
    this.phoneNumber,
  });

  final String orderNumber;
  final String? tempPassword;
  final String? phoneNumber;

  @override
  State<GuestBookingSuccessScreen> createState() => _GuestBookingSuccessScreenState();
}

class _GuestBookingSuccessScreenState extends State<GuestBookingSuccessScreen> {
  bool _activated = false;
  bool _checking = true;
  @override
  void initState() {
    super.initState();
    _checkActivation();
  }

  Future<void> _checkActivation() async {
    try {
      final result = await SupabaseService.instance.invoke('guest', body: {
        'action': 'credentials',
        'order_id': widget.orderNumber,
        'phone_number': widget.phoneNumber ?? '',
      });
      final data = Map<String, dynamic>.from(result as Map? ?? {});
      if (mounted) setState(() {
        _activated = data['is_activated'] == true;
        _checking = false;
      });
    } catch (e) {
      if (mounted) setState(() => _checking = false);
    }
  }

  String get _saveFormat {
    final order = widget.orderNumber;
    final phone = widget.phoneNumber ?? '';
    return '$order | $phone';
  }

  Future<void> _copyAll() async {
    await Clipboard.setData(ClipboardData(text: _saveFormat));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text(context.l10n.orderNumberAndPhoneCopied),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<bool> _confirmExit() async {
    final result = await showServisConfirmDialog(context,
      title: 'Nomor Order Disimpan?',
      message: 'Apakah nomor order ${widget.orderNumber} sudah kamu catat?\n\n'
          'Kamu bisa cek status pesanan nanti dari halaman utama.',
      confirmLabel: 'Ya, sudah disimpan',
      cancelLabel: 'Belum, salin dulu',
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasPw = widget.tempPassword?.isNotEmpty ?? false;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_activated) { context.go('/welcome'); return; }
        final ok = await _confirmExit();
        if (ok && mounted) context.go('/welcome');
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.bookingSuccess),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 16),
              Icon(Icons.check_circle_rounded, size: 80, color: _activated ? Colors.green : Colors.orange),
              const SizedBox(height: 16),
              Text(
                _activated ? 'Akun Aktif!' : 'Pesanan Dibuat',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                _activated
                    ? 'Kamu sudah bisa login dengan kredensial di bawah.'
                    : 'Simpan kredensial di bawah. Akun akan aktif setelah toko menerima perangkat.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(children: [
                    Text(context.l10n.orderNumber, style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    SelectableText(widget.orderNumber, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.orderNumber));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.orderNumberCopied)));
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text(context.l10n.copy),
                    ),
                    if (widget.phoneNumber != null) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _copyAll,
                        icon: const Icon(Icons.copy_all, size: 18),
                        label: const Text(context.l10n.copyAll),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.teal,
                        ),
                      ),
                    ],
                  ]),
                ),
              ),
              if (widget.phoneNumber != null && hasPw) ...[
                const SizedBox(height: 16),
                Card(
                  color: _activated ? Colors.green.shade50 : Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(_activated ? Icons.check_circle : Icons.key, size: 20, color: _activated ? Colors.green : Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _activated ? 'Akun Aktif' : 'Akun Sementara (Belum Aktif)',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: _activated ? Colors.green.shade800 : Colors.orange.shade800),
                          ),
                        ),
                        if (_activated)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                            child: Text(context.l10n.activeLabel, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                      ]),
                      const SizedBox(height: 12),
                      _row(theme, context.l10n.username, widget.phoneNumber ?? ''),
                      _row(theme, context.l10n.password, widget.tempPassword ?? ''),
                      const SizedBox(height: 8),
                      Text(
                        _activated
                            ? 'Gunakan kredensial di atas untuk login.'
                            : 'Kredensial ini akan aktif setelah toko menerima perangkatmu.',
                        style: theme.textTheme.bodySmall?.copyWith(color: _activated ? Colors.green.shade700 : Colors.orange.shade700),
                      ),
                    ]),
                  ),
                ),
                if (_activated) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.login),
                    label: Text(context.l10n.loginNow),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/guest/track/${widget.orderNumber}'),
                icon: const Icon(Icons.search),
                label: Text(context.l10n.checkOrderStatus),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 12),
              _checking
                  ? const Center(child: Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))))
                  : TextButton.icon(
                      onPressed: () async {
                        if (_activated) { context.go('/welcome'); return; }
                        final ok = await _confirmExit();
                        if (ok && mounted) context.go('/welcome');
                      },
                      icon: Icon(_activated ? Icons.home : Icons.lock, size: 18),
                      label: Text(_activated ? context.l10n.home : 'Kredensial Belum Tersimpan'),
                      style: TextButton.styleFrom(foregroundColor: _activated ? null : Colors.grey),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      SizedBox(width: 80, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
      Expanded(child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
    ]),
  );
}
