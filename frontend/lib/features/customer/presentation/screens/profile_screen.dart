import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/supabase_service.dart';
import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/modern_card.dart';
import '../../../../ui/widgets/servis_snackbar.dart';
import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../widgets/customer_widgets.dart';
import 'package:m3_expressive/m3_expressive.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  bool _dirty = false;
  bool _loading = false;

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(customerAuthProvider.notifier).updateProfile(fullName: _name.text, address: _address.text);
      setState(() => _dirty = false);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(parseApiError(error))));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = ref.watch(customerAuthProvider).valueOrNull;
    if (user != null && !_dirty && _name.text.isEmpty) {
      _name.text = user.fullName;
      _address.text = user.address ?? '';
    }
    return CustomerScaffold(
      title: context.l10n.profile,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Center(
                child: Text(
                  (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0] : 'S',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: scheme.primary),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ModernCard(
            child: Column(
              children: [
                TextFormField(
                    controller: _name,
                    decoration: InputDecoration(labelText: context.l10n.fullName),
                    onChanged: (_) => setState(() => _dirty = true)),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                    initialValue: user?.phoneNumber ?? '-',
                    readOnly: true,
                    decoration: InputDecoration(labelText: context.l10n.phoneNumberReadOnly)),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                    controller: _address,
                    minLines: 2, maxLines: 4,
                    decoration: InputDecoration(labelText: context.l10n.address),
                    onChanged: (_) => setState(() => _dirty = true)),
                if (_dirty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                        onPressed: _loading ? null : _save,
                        child: _loading ? M3LoadingIndicator(size: 20, color: Colors.white) : Text(context.l10n.save)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ModernCard(
            child: Column(
              children: [
                ListTile(
                    leading: Icon(Icons.receipt_long_outlined, color: scheme.onSurfaceVariant),
                    title: Text(context.l10n.myOrders),
                    trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                    onTap: () => context.push('/orders')),
                Divider(height: 1, color: scheme.outlineVariant),
                ListTile(
                    leading: Icon(Icons.local_offer_outlined, color: scheme.onSurfaceVariant),
                    title: Text(context.l10n.myCoupons),
                    trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                    onTap: () => context.push('/coupons')),
                Divider(height: 1, color: scheme.outlineVariant),
                ListTile(
                    leading: Icon(Icons.notifications_outlined, color: scheme.onSurfaceVariant),
                    title: Text(context.l10n.notificationPreferences),
                    trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                    onTap: () => context.push('/notification-preferences')),
                Divider(height: 1, color: scheme.outlineVariant),
                ListTile(
                    leading: Icon(Icons.lock_outline, color: scheme.onSurfaceVariant),
                    title: Text(context.l10n.changePassword),
                    trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                    onTap: () => context.push('/change-password')),
                Divider(height: 1, color: scheme.outlineVariant),
                ListTile(
                    leading: Icon(Icons.devices_outlined, color: scheme.onSurfaceVariant),
                    title: Text(context.l10n.loginSessions),
                    trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                    onTap: () => context.push('/sessions')),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ModernCard(
            child: ListTile(
              leading: Icon(Icons.logout, color: scheme.error),
              title: Text(context.l10n.logout, style: TextStyle(color: scheme.error)),
              onTap: () async {
                await ref.read(customerAuthProvider.notifier).logout();
                if (context.mounted) context.go('/welcome');
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ModernCard(
            child: ListTile(
              leading: Icon(Icons.delete_forever, color: scheme.error),
              title: Text('Hapus Akun', style: TextStyle(color: scheme.error)),
              subtitle: Text('Hapus data akun dan riwayat pesanan', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hapus Akun'),
                    content: const Text('Semua data Anda akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus Akun Saya')),
                    ],
                  ),
                );
                if (confirm != true || !context.mounted) return;
                try {
                  await SupabaseService.instance.invoke('admin', body: {'action': 'delete-account'});
                  await ref.read(customerAuthProvider.notifier).logout();
                  if (context.mounted) showServisSnackbar(context, 'Akun berhasil dihapus', type: SnackbarType.success);
                  if (context.mounted) context.go('/welcome');
                } catch (e) {
                  if (context.mounted) showServisSnackbar(context, 'Gagal hapus akun: hubungi admin', type: SnackbarType.error);
                }
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
