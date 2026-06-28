import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/order_status.dart';
import '../../../../core/supabase_service.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../shared_widgets/status_badge.dart';
import '../../domain/models/tracking_entry.dart';
import '../../../../ui/widgets/modern_card.dart';
import '../widgets/customer_widgets.dart';
import 'package:m3_expressive/m3_expressive.dart';

class GuestTrackingScreen extends StatefulWidget {
  const GuestTrackingScreen({super.key, this.initialOrderNumber});
  final String? initialOrderNumber;

  @override
  State<GuestTrackingScreen> createState() => _GuestTrackingScreenState();
}

class _GuestTrackingScreenState extends State<GuestTrackingScreen> {
  final _orderCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialOrderNumber != null) {
      _orderCtl.text = widget.initialOrderNumber!;
    }
  }

  @override
  void dispose() {
    _orderCtl.dispose();
    _phoneCtl.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    final order = _orderCtl.text.trim();
    final phone = _phoneCtl.text.trim();
    if (order.isEmpty || phone.isEmpty) {
      setState(() => _error = context.l10n.enterOrderAndPhone);
      return;
    }
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final sb = SupabaseService.instance;
      final data = await sb.invoke('guest', body: {'action': 'track', 'order_number': order, 'phone_number': phone});
      if (data is! Map<String, dynamic>) throw Exception('Invalid response');
      final credData = await sb.invoke('guest', body: {'action': 'credentials', 'order_id': data['order_number'], 'phone_number': phone});
      if (credData is! Map<String, dynamic>) throw Exception('Invalid response');
      if (!mounted) return;
      setState(() { _result = {...data, ...credData}; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is Map ? (e['message'] as String? ?? 'Gagal. Coba lagi.') : 'Gagal. Coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.checkOrder),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go("/welcome"),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(context.l10n.orderTracking, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _orderCtl,
              decoration: InputDecoration(
                labelText: context.l10n.orderNumber,
                prefixIcon: const Icon(Icons.receipt_long),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: context.l10n.whatsappNumber,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _loading ? null : _track,
                icon: _loading
                    ? SizedBox(width: 18, height: 18, child: M3LoadingIndicator(size: 20, color: Colors.white))
                    : const Icon(Icons.search),
                label: Text(_loading ? context.l10n.searching : context.l10n.checkOrderButton),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
            ],
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildResult(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResult(ThemeData theme) {
    final status = OrderStatus.fromJson(_result?['status']);
    final canActivate = _result?['can_activate'] as bool? ?? false;
    final isActivated = _result?['is_activated'] as bool? ?? false;
    final hasCredential = _result?['has_credential'] as bool? ?? false;
    final phone = _result?['phone_number'] as String? ?? '';
    final fullName = _result?['full_name'] as String? ?? '';
    final maskedPass = _result?['masked_password'] as String?;
    final rawTracking = (_result?['tracking'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ModernCard(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('Nomor Pesanan ${_result?['order_number'] as String? ?? ''}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
              StatusBadge(label: status.label),
            ]),
            const SizedBox(height: 8),
            Text('${_result?['brand']} ${_result?['device_model']}', style: theme.textTheme.bodyMedium),
            Text(_result?['store_name'] as String? ?? '', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ]),
        ),
      if (rawTracking.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text(context.l10n.trackingHistory, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        OrderStatusTimeline(
          entries: rawTracking.map((t) => TrackingEntry(
            id: '',
            status: OrderStatus.fromJson(t['status']),
            note: t['note'] as String?,
            createdAt: t['created_at'] != null ? DateTime.parse(t['created_at'] as String) : DateTime.now(),
          )).toList(),
        ),
      ],
      if (hasCredential && !isActivated) ...[
        const SizedBox(height: 24),
        _CredentialCard(
          theme: theme,
          fullName: fullName,
          phoneNumber: phone,
          maskedPassword: maskedPass ?? '••••••',
          canActivate: canActivate,
          onActivate: canActivate
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.accountAlreadyActive)),
                  );
                  context.go('/login');
                }
              : null,
        ),
      ],
      if (isActivated) ...[
        const SizedBox(height: 24),
        ModernCard(
          padding: const EdgeInsets.all(16),
          color: Colors.green.shade50,
          child: Row(children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.l10n.accountActive, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.green.shade800)),
                const SizedBox(height: 4),
                Text(context.l10n.accountActiveMessage, style: theme.textTheme.bodySmall),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: () => context.go('/login'), child: Text(context.l10n.loginNow)),
      ],
      const SizedBox(height: 24),
      OutlinedButton(onPressed: () => context.go('/welcome'), child: Text(context.l10n.back)),
    ]);
  }
}

class _CredentialCard extends StatelessWidget {
  const _CredentialCard({
    required this.theme,
    required this.fullName,
    required this.phoneNumber,
    required this.maskedPassword,
    required this.canActivate,
    this.onActivate,
  });

  final ThemeData theme;
  final String fullName;
  final String phoneNumber;
  final String maskedPassword;
  final bool canActivate;
  final VoidCallback? onActivate;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return ModernCard(
      padding: const EdgeInsets.all(16),
      color: canActivate ? Colors.green.shade50 : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(canActivate ? Icons.check_circle : Icons.access_time, color: canActivate ? Colors.green : Colors.orange, size: 22),
          const SizedBox(width: 8),
          Text(context.l10n.servisGadgetAccount, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 16),
        _row(context.l10n.name, fullName),
        _row(context.l10n.username, phoneNumber),
        _row(context.l10n.password, maskedPassword),
        const SizedBox(height: 16),
        if (canActivate)
          FilledButton.icon(
            onPressed: onActivate,
            icon: const Icon(Icons.login, size: 18),
            label: Text(context.l10n.linkAccount),
            style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
          )
        else
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.l10n.waitingForStore, style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange.shade700)),
            const SizedBox(height: 4),
            Text(context.l10n.waitingForActivationMessage, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ]),
      ]),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      SizedBox(width: 80, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
      Expanded(child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
    ]),
  );
}
