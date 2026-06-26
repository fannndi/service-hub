import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/platform_admin_providers.dart';
import '../../../../core/widgets/address_dropdowns.dart';
import '../../../../core/api_client.dart';
import '../../domain/platform_admin_models.dart';
import '../../../../ui/theme/app_theme.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../ui/widgets/servis_snackbar.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _showBroadcastDialog(BuildContext context) {
    final roleCtrl = TextEditingController(text: 'customer');
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(context.l10n.broadcastNotification),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                initialValue: 'customer',
                decoration: InputDecoration(labelText: context.l10n.target, isDense: true),
                items: [
                  DropdownMenuItem(value: 'customer', child: Text(context.l10n.allCustomers)),
                  DropdownMenuItem(value: 'store_admin', child: Text(context.l10n.allStoreAdmins)),
                ],
                onChanged: (v) => setD(() => roleCtrl.text = v ?? 'customer'),
              ),
              const SizedBox(height: 12),
              TextField(controller: titleCtrl, decoration: InputDecoration(labelText: context.l10n.title, isDense: true)),
              const SizedBox(height: 12),
              TextField(controller: msgCtrl, maxLines: 4, decoration: InputDecoration(labelText: context.l10n.message, isDense: true, alignLabelWithHint: true)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.cancel)),
            FilledButton.icon(
              onPressed: loading
                  ? null
                  : () async {
                      if (titleCtrl.text.trim().isEmpty || msgCtrl.text.trim().isEmpty) return;
                      setD(() => loading = true);
                      try {
                        await ApiClient.instance.post('/notifications/broadcast', {
                          'role': roleCtrl.text,
                          'title': titleCtrl.text.trim(),
                          'message': msgCtrl.text.trim(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) showServisSnackbar(context, context.l10n.broadcastSent, type: SnackbarType.success);
                      } catch (e) {
                        if (context.mounted) showServisSnackbar(context, context.l10n.failed.replaceFirst('{error}', '$e'), type: SnackbarType.error);
                      } finally {
                        setD(() => loading = false);
                      }
                    },
              icon: loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, size: 18),
              label: Text(context.l10n.send),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.platformAdmin),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined),
            tooltip: context.l10n.broadcastNotification,
            onPressed: () => _showBroadcastDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(adminAuthProvider.notifier).logout();
              if (context.mounted) context.go('/admin/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(icon: const Icon(Icons.store), text: context.l10n.stores),
            Tab(icon: const Icon(Icons.people), text: context.l10n.customers),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _StoresTab(),
          _CustomersTab(),
        ],
      ),
    );
  }
}

class _StoresTab extends ConsumerStatefulWidget {
  const _StoresTab();
  @override
  ConsumerState<_StoresTab> createState() => _StoresTabState();
}

class _StoresTabState extends ConsumerState<_StoresTab> {
  final _storeName = TextEditingController();
  final _storePhone = TextEditingController();
  final _adminName = TextEditingController();
  final _adminPhone = TextEditingController();
  final _password = TextEditingController();
  final _addressKey = GlobalKey<AddressDropdownsState>();
  bool _android = true;
  bool _ios = true;
  bool _loading = false;
  bool _showCreate = false;

  List<String> _validationErrors = [];
  bool _validated = false;

  @override
  void dispose() {
    _storeName.dispose();
    _storePhone.dispose();
    _adminName.dispose();
    _adminPhone.dispose();
    _password.dispose();
    super.dispose();
  }

  List<String> _validate() {
    final errors = <String>[];
    if (_storeName.text.trim().isEmpty) errors.add(context.l10n.storeNameRequired);
    if (_storeName.text.trim().length < 3) {
      errors.add(context.l10n.storeNameMinLength);
    }
    if (!(_addressKey.currentState?.isValid ?? false)) {
      errors.add(context.l10n.addressIncomplete);
    }
    if (_storePhone.text.trim().isEmpty) errors.add(context.l10n.storePhoneRequired);
    if (_adminName.text.trim().isEmpty) errors.add(context.l10n.adminNameRequired);
    if (_adminPhone.text.trim().isEmpty) errors.add(context.l10n.adminPhoneRequired);
    if (_password.text.isEmpty) errors.add(context.l10n.passwordRequired);
    if (_password.text.length < 8) errors.add(context.l10n.passwordMinLength);
    if (!_android && !_ios) errors.add(context.l10n.selectDeviceType);
    return errors;
  }

  Future<void> _create() async {
    final errors = _validate();
    if (errors.isNotEmpty) {
      setState(() { _validationErrors = errors; _validated = true; });
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(adminStoreRepositoryProvider).createStore(
            storeName: _storeName.text.trim(),
            address: _addressKey.currentState!.addressString,
            storePhone: '08${_storePhone.text.trim()}',
            adminName: _adminName.text.trim(),
            adminPhone: '08${_adminPhone.text.trim()}',
            password: _password.text,
            handlesAndroid: _android,
            handlesIos: _ios,
          );
      ref.invalidate(storeListProvider);
      ref.invalidate(storeAdminListProvider);
      setState(() {
        _showCreate = false;
        _validated = false;
        _validationErrors = [];
        _storeName.clear();
        _storePhone.clear();
        _adminName.clear();
        _adminPhone.clear();
        _password.clear();
        _addressKey.currentState?.clear();
      });
      if (mounted) {
        showServisSnackbar(context, context.l10n.storeCreated, type: SnackbarType.success);
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(Object e) {
    String msg = context.l10n.failed.replaceFirst('{error}', '');
    if (e.toString().contains('DioException')) {
      final m = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(e.toString());
      msg = m?.group(1) ?? context.l10n.checkFormContent;
    } else { msg = e.toString(); }
    if (mounted) {
      showServisSnackbar(context, msg, type: SnackbarType.error);
    }
  }

  void _editStore(StoreListItem store) {
    final nameCtrl = TextEditingController(text: store.storeName);
    final addrCtrl = TextEditingController(text: store.address);
    final phoneCtrl = TextEditingController(text: store.phoneNumber);
    bool active = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(context.l10n.editStore),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: context.l10n.storeName, isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: addrCtrl, decoration: InputDecoration(labelText: context.l10n.address, isDense: true)),
              const SizedBox(height: 8),
              TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: context.l10n.phoneNumber, isDense: true)),
              const SizedBox(height: 8),
              Row(children: [
                Text(context.l10n.active),
                Switch(value: active, onChanged: (v) => setD(() => active = v)),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.cancel)),
            FilledButton(onPressed: () async {
              try {
                await ref.read(adminStoreRepositoryProvider).updateStore(
                  storeId: store.id,
                  storeName: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                  address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
                  phoneNumber: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  isActive: active,
                );
                ref.invalidate(storeListProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) { _showError(e); }
            }, child: Text(context.l10n.save)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stores = ref.watch(storeListProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: () => setState(() { _showCreate = !_showCreate; _validated = false; _validationErrors = []; }),
          icon: Icon(_showCreate ? Icons.close : Icons.add),
          label: Text(_showCreate ? context.l10n.cancel : context.l10n.createNewStore),
        ),
        if (_showCreate) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.createNewStore, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextField(controller: _storeName, decoration: InputDecoration(labelText: context.l10n.storeName, isDense: true)),
                  const SizedBox(height: 12),
                  Text(context.l10n.address, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  AddressDropdowns(key: _addressKey),
                  const SizedBox(height: 12),
                  TextField(controller: _storePhone, keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: context.l10n.storePhone, prefixText: '08', isDense: true)),
                  const SizedBox(height: 12),
                  const Divider(),
                  Text(context.l10n.storeAdmin, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextField(controller: _adminName, decoration: InputDecoration(labelText: context.l10n.adminName, isDense: true)),
                  const SizedBox(height: 8),
                  TextField(controller: _adminPhone, keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: context.l10n.adminPhone, prefixText: '08', isDense: true)),
                  const SizedBox(height: 8),
                  TextField(controller: _password,
                    decoration: InputDecoration(labelText: context.l10n.adminPassword, isDense: true, helperText: context.l10n.minLength8)),
                  const SizedBox(height: 12),
                  const Divider(),
                  Text(context.l10n.deviceType, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Row(children: [
                    FilterChip(label: Text(context.l10n.android), selected: _android,
                      onSelected: (v) => setState(() { _android = v; _validated = false; })),
                    const SizedBox(width: 8),
                    FilterChip(label: Text(context.l10n.iphoneIos), selected: _ios,
                      onSelected: (v) => setState(() { _ios = v; _validated = false; })),
                  ]),
                  if (_validated && _validationErrors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200)),
                      child: Column(children: [
                        Row(children: [const Icon(Icons.error, color: Colors.red, size: 18), const SizedBox(width: 8),
                          Text(context.l10n.fixThese, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700))]),
                        ..._validationErrors.map((e) => Padding(
                          padding: const EdgeInsets.only(left: 26, top: 2),
                          child: Text('- $e', style: TextStyle(color: Colors.red.shade700, fontSize: 13)))),
                      ]),
                    ),
                  ],
                  if (_validated && _validationErrors.isEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200)),
                      child: Column(children: [
                        Row(children: [const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 8), Text(context.l10n.valid, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700))]),
                        Padding(padding: const EdgeInsets.only(left: 26, top: 4),
                          child: Text('Nama: ${_storeName.text.trim()} | Admin: ${_adminName.text.trim()} | Android: $_android iOS: $_ios', style: const TextStyle(fontSize: 12))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(onPressed: () { setState(() { _validationErrors = _validate(); _validated = true; }); },
                      icon: const Icon(Icons.fact_check), label: Text(context.l10n.checkData))),
                    const SizedBox(width: 8),
                    Expanded(child: FilledButton.icon(onPressed: (_loading || !_validated || _validationErrors.isNotEmpty) ? null : _create,
                      icon: _loading ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white))
                        : const Icon(Icons.save), label: Text(context.l10n.createStoreButton))),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 8),
        Text(context.l10n.storeList, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        stores.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(context.l10n.failed.replaceFirst('{error}', '$e')),
          data: (list) => list.isEmpty
              ? Padding(padding: const EdgeInsets.all(16), child: Text(context.l10n.noStores))
              : Column(children: list.map((store) {
                  final dt = store.deviceTypes;
                  final android = dt?['android'] as bool? ?? true;
                  final ios = dt?['ios'] as bool? ?? true;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(store.storeName, style: theme.textTheme.titleSmall)),
                          IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _editStore(store)),
                        ]),
                        Text(store.address, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                        Text(store.phoneNumber, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Chip(label: Text(context.l10n.android, style: TextStyle(fontSize: 11, color: android ? AppColors.success : AppColors.error)),
                            backgroundColor: android ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1)),
                          const SizedBox(width: 4),
                          Chip(label: Text(context.l10n.iphoneIos, style: TextStyle(fontSize: 11, color: ios ? AppColors.success : AppColors.error)),
                            backgroundColor: ios ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1)),
                          const Spacer(),
                          Row(children: [const Icon(Icons.star, size: 14, color: AppColors.warning), const SizedBox(width: 2),
                            Text(store.ratingAvg.toStringAsFixed(1), style: theme.textTheme.bodySmall)]),
                        ]),
                        if (store.admins.isNotEmpty)
                          Padding(padding: const EdgeInsets.only(top: 4),
                            child: Text('Admin: ${store.admins.map((a) => a['fullName']).join(', ')}',
                              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary))),
                      ]),
                    ),
                  );
                }).toList()),
        ),
      ],
    );
  }
}

class _CustomersTab extends ConsumerStatefulWidget {
  const _CustomersTab();
  @override
  ConsumerState<_CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends ConsumerState<_CustomersTab> {
  void _editUser(UserListItem user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phoneNumber);
    final addrCtrl = TextEditingController(text: user.address ?? '');
    String status = user.accountStatus;
    final pwCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.editCustomer),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: context.l10n.name, isDense: true)),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: context.l10n.phoneNumber, isDense: true)),
            const SizedBox(height: 8),
            TextField(controller: addrCtrl, decoration: InputDecoration(labelText: context.l10n.address, isDense: true), maxLines: 2),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: status,
              decoration: InputDecoration(labelText: context.l10n.status, isDense: true),
              items: const [DropdownMenuItem(value: 'active', child: Text('Active')), DropdownMenuItem(value: 'suspended', child: Text('Suspended')), DropdownMenuItem(value: 'deleted', child: Text('Deleted'))],
              onChanged: (v) => status = v ?? 'active',
              borderRadius: const BorderRadius.all(Radius.circular(14)),
            ),
            const Divider(),
            TextField(controller: pwCtrl, decoration: InputDecoration(labelText: context.l10n.newPasswordOptional, isDense: true), obscureText: true),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () async {
            try {
              final repo = ref.read(adminUserRepositoryProvider);
              await repo.updateUser(
                userId: user.id,
                fullName: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                phoneNumber: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
                accountStatus: status,
              );
              if (pwCtrl.text.isNotEmpty && pwCtrl.text.length >= 6) {
                await repo.changeUserPassword(user.id, pwCtrl.text);
              }
              ref.invalidate(userListProvider);
              if (mounted) {
                showServisSnackbar(context, context.l10n.customerUpdated, type: SnackbarType.success);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            } catch (e) {
              String msg = context.l10n.failed.replaceFirst('{error}', '');
              if (e.toString().contains('DioException')) {
                final m = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(e.toString());
                msg = m?.group(1) ?? context.l10n.checkFormContent;
              } else { msg = e.toString(); }
              if (mounted) {
                showServisSnackbar(context, msg, type: SnackbarType.error);
              }
            }
          }, child: Text(context.l10n.save)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final users = ref.watch(userListProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(context.l10n.customerList, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        users.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(context.l10n.failed.replaceFirst('{error}', '$e')),
          data: (list) => list.isEmpty
              ? Padding(padding: const EdgeInsets.all(16), child: Text(context.l10n.noCustomers))
              : Column(children: list.map((u) {
                  final isNew = u.isFirstLogin;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(u.fullName, style: theme.textTheme.titleSmall)),
                          IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _editUser(u)),
                        ]),
                        Row(children: [const Icon(Icons.phone, size: 14, color: AppColors.textSecondary), const SizedBox(width: 4),
                          Text(u.phoneNumber, style: theme.textTheme.bodySmall)]),
                        if (u.plainPassword != null)
                          Row(children: [const Icon(Icons.key, size: 14, color: AppColors.warning), const SizedBox(width: 4),
                            Text(context.l10n.passwordLabel.replaceFirst('{password}', u.plainPassword ?? ''), style: theme.textTheme.bodySmall?.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600))]),
                        if (u.address != null && u.address!.isNotEmpty)
                          Text(u.address!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Row(children: [
                          _badge(u.accountStatus),
                          const SizedBox(width: 8),
                          if (isNew)
                            _badge('BARU', AppColors.primary),
                          if (u.isFirstLogin)
                            _badge('first login', AppColors.accent),
                        ]),
                        Text(context.l10n.joinedDate.replaceFirst('{date}', u.createdAt.substring(0, 10)), style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 11)),
                      ]),
                    ),
                  );
                }).toList()),
        ),
      ],
    );
  }

  Widget _badge(String text, [Color? color]) {
    final c = color ??
        (text == 'active' ? AppColors.success : text == 'suspended' ? AppColors.error : AppColors.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
    );
  }
}
