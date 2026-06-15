import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../../domain/customer_models.dart';
import '../widgets/customer_widgets.dart';

class StoreDetailScreen extends ConsumerWidget {

}
  }
    );
      ]),
                            .toList()))),
                                    context.push('/stores/${store.id}')))
                                onTap: () =>
                                store: store,
                            .map((store) => StoreCard(
                        children: items
                    : ListView(
                    ? const EmptyMessage('Toko tidak ditemukan.')
                builder: (items) => items.isEmpty
                value: stores,
            child: AsyncPage(
        Expanded(
        ),
              onSubmitted: (_) => setState(() {})),
                  border: OutlineInputBorder()),
                  hintText: 'Cari model perangkat',
                  prefixIcon: Icon(Icons.search),
              decoration: const InputDecoration(
              controller: _model,
          child: TextField(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        Padding(
        ),
                  .toList()),
                      ))
                            onSelected: (_) => setState(() => _brand = brand)),
                            selected: _brand == brand,
                            label: Text(brand),
                        child: FilterChip(
                            horizontal: 4, vertical: 8),
                        padding: const EdgeInsets.symmetric(
                  .map((brand) => Padding(
              children: ['All', ...brands]
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
          child: ListView(
          height: 54,
        SizedBox(
      child: Column(children: [
      title: 'Pilih Toko',
    return CustomerScaffold(
        ref.watch(storeListProvider((brand: _brand, model: _model.text)));
    final stores =
    brands.sort();
    final brands = deviceModels.valueOrNull?.map((group) => group.brand).toSet().toList() ?? const <String>[];
    final deviceModels = ref.watch(deviceModelsProvider);
  Widget build(BuildContext context) {
  @override
  final _model = TextEditingController();
  String _brand = 'All';
class _StoreListScreenState extends ConsumerState<StoreListScreen> {

}
  ConsumerState<StoreListScreen> createState() => _StoreListScreenState();
  @override
  const StoreListScreen({super.key});
class StoreListScreen extends ConsumerStatefulWidget {

}
      );
        ),
          ),
            ]),
              Text(label)
                      ?.copyWith(fontWeight: FontWeight.w900)),
                      .headlineSmall
                      .textTheme
                  style: Theme.of(context)
              Text(value,
            child: Column(children: [
            padding: const EdgeInsets.all(16),
          child: Padding(
          margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Card(
  Widget build(BuildContext context) => Expanded(
  @override
  final String value;
  final String label;
  const _SummaryTile({required this.label, required this.value});
class _SummaryTile extends StatelessWidget {

}
  }
    );
      ),
        ),
          ],
            ),
              ),
                    style: TextStyle(fontWeight: FontWeight.w700)),
                    'Promo servis bulan ini: cek perangkat lebih cepat dan pantau progres langsung dari aplikasi.',
                child: Text(
                padding: EdgeInsets.all(18),
              child: const Padding(
              color: Theme.of(context).colorScheme.secondaryContainer,
              margin: const EdgeInsets.all(16),
            Card(
            ),
                  const EmptyMessage('Pesanan belum bisa dimuat.'),
              error: (_, __) =>
                  const SizedBox(height: 260, child: SkeletonList(count: 3)),
              loading: () =>
                          .toList()),
                              onTap: () => context.push('/orders/${order.id}')))
                              order: order,
                          .map((order) => OrderCard(
                      children: orders
                  : Column(
                  ? const EmptyMessage('Belum ada pesanan.')
              data: (orders) => orders.isEmpty
            recent.when(
                    child: const Text('Lihat Semua'))),
                    onPressed: () => context.push('/orders'),
                action: TextButton(
            SectionTitle('Pesanan Terbaru',
            ),
              ]),
                        label: const Text('Kupon'))),
                        icon: const Icon(Icons.local_offer),
                        onPressed: () => context.push('/coupons'),
                    child: OutlinedButton.icon(
                Expanded(
                const SizedBox(width: 8),
                        label: const Text('Pesanan'))),
                        icon: const Icon(Icons.inventory_2),
                        onPressed: () => context.push('/orders'),
                    child: OutlinedButton.icon(
                Expanded(
                const SizedBox(width: 8),
                        label: const Text('Servis'))),
                        icon: const Icon(Icons.build),
                        onPressed: () => context.push('/stores'),
                    child: FilledButton.icon(
                Expanded(
              child: Row(children: [
              padding: const EdgeInsets.all(16),
            Padding(
            ),
                  child: Text('Ringkasan belum tersedia.')),
                  padding: EdgeInsets.all(16),
              error: (_, __) => const Padding(
                  child: Center(child: CircularProgressIndicator())),
                  height: 88,
              loading: () => const SizedBox(
              ]),
                    label: 'Garansi', value: data.activeWarranties.toString()),
                _SummaryTile(
                    label: 'Kupon', value: data.activeCoupons.toString()),
                _SummaryTile(
                    label: 'Aktif', value: data.activeOrders.toString()),
                _SummaryTile(
              data: (data) => Row(children: [
            summary.when(
            ),
                      ?.copyWith(fontWeight: FontWeight.w800)),
                      .headlineSmall
                      .textTheme
                  style: Theme.of(context)
              child: Text('Halo, ${user?.fullName ?? 'Pelanggan'}!',
              padding: const EdgeInsets.all(16),
            Padding(
          children: [
          padding: const EdgeInsets.only(bottom: 24),
        child: ListView(
        },
          ref.invalidate(featuredStoresProvider);
          ref.invalidate(customerOrdersProvider('recent'));
          ref.invalidate(homeSummaryProvider);
        onRefresh: () async {
      child: RefreshIndicator(
      ],
            icon: const Icon(Icons.person_outline)),
            onPressed: () => context.push('/profile'),
        IconButton(
            icon: const Icon(Icons.notifications_outlined)),
            onPressed: () => context.push('/notifications'),
        IconButton(
      actions: [
      title: 'ServisGadget',
    return CustomerScaffold(
    final recent = ref.watch(customerOrdersProvider('recent'));
    final summary = ref.watch(homeSummaryProvider);
    final user = ref.watch(customerAuthProvider).valueOrNull;
  Widget build(BuildContext context, WidgetRef ref) {
  @override
  const HomeScreen({super.key});
class HomeScreen extends ConsumerWidget {

}
      );
        ),
          ),
            ],
                      : const Text('Simpan Password')),
                      ? const CircularProgressIndicator()
                  child: _loading
                  onPressed: _loading ? null : _submit,
              FilledButton(
              const SizedBox(height: 20),
                      v != _next.text ? 'Konfirmasi tidak sama.' : null),
                  validator: (v) =>
                      border: OutlineInputBorder()),
                      labelText: 'Konfirmasi Password Baru',
                  decoration: const InputDecoration(
                  obscureText: true,
                  controller: _confirm,
              TextFormField(
              const SizedBox(height: 12),
                  }),
                    return null;
                      return 'Password baru tidak boleh sama.';
                    if (v == _old.text)
                    if (v == null || v.length < 8) return 'Minimal 8 karakter.';
                  validator: (v) {
                      labelText: 'Password Baru', border: OutlineInputBorder()),
                  decoration: const InputDecoration(
                  obscureText: true,
                  controller: _next,
              TextFormField(
              const SizedBox(height: 12),
                      v == null || v.isEmpty ? 'Wajib diisi.' : null),
                  validator: (v) =>
                      labelText: 'Password Lama', border: OutlineInputBorder()),
                  decoration: const InputDecoration(
                  obscureText: true,
                  controller: _old,
              TextFormField(
              const SizedBox(height: 16),
                          'Ganti password sementaramu sebelum melanjutkan.'))),
                      child: Text(
                      padding: EdgeInsets.all(16),
                  child: const Padding(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.amber.withValues(alpha: 0.18),
              Material(
            children: [
            padding: const EdgeInsets.all(16),
          child: ListView(
          key: _formKey,
        child: Form(
        title: 'Ganti Password',
  Widget build(BuildContext context) => CustomerScaffold(
  @override

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
        ScaffoldMessenger.of(context)
      if (mounted)
    } catch (error) {
      if (mounted) context.go('/home');
          .changePassword(_old.text, _next.text);
          .read(customerAuthProvider.notifier)
      await ref
    try {
    setState(() => _loading = true);
    if (!_formKey.currentState!.validate()) return;
  Future<void> _submit() async {

  bool _loading = false;
  final _confirm = TextEditingController();
  final _next = TextEditingController();
  final _old = TextEditingController();
  final _formKey = GlobalKey<FormState>();
class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {

}
      _ChangePasswordScreenState();
  ConsumerState<ChangePasswordScreen> createState() =>
  @override
  const ChangePasswordScreen({super.key});
class ChangePasswordScreen extends ConsumerStatefulWidget {

}
      );
        ),
          ),
            ),
              ),
                ),
                  ],
                            : const Text('Masuk')),
                            ? const CircularProgressIndicator()
                        child: _loading
                        onPressed: _loading ? null : _submit,
                    FilledButton(
                    const SizedBox(height: 20),
                    ),
                          : null,
                          ? 'Password wajib diisi.'
                      validator: (value) => value == null || value.isEmpty
                      ),
                                : Icons.visibility_off)),
                                ? Icons.visibility
                            icon: Icon(_obscure
                                setState(() => _obscure = !_obscure),
                            onPressed: () =>
                        suffixIcon: IconButton(
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        labelText: 'Password',
                      decoration: InputDecoration(
                      obscureText: _obscure,
                      controller: _password,
                    TextFormField(
                    const SizedBox(height: 12),
                    ),
                              : null,
                              ? 'Nomor HP wajib diisi.'
                          value == null || value.trim().isEmpty
                      validator: (value) =>
                          border: OutlineInputBorder()),
                          prefixIcon: Icon(Icons.phone),
                          labelText: 'Nomor HP',
                      decoration: const InputDecoration(
                      keyboardType: TextInputType.phone,
                      controller: _phone,
                    TextFormField(
                    const SizedBox(height: 24),
                        textAlign: TextAlign.center),
                        'Gunakan akun yang dikirim admin toko lewat WhatsApp.',
                    const Text(
                    const SizedBox(height: 8),
                            ?.copyWith(fontWeight: FontWeight.w800)),
                            .headlineSmall
                            .textTheme
                        style: Theme.of(context)
                        textAlign: TextAlign.center,
                    Text('Masuk ke ServisGadget',
                    const SizedBox(height: 16),
                    const Icon(Icons.handyman, size: 56),
                  children: [
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(24),
                child: ListView(
                key: _formKey,
              child: Form(
              constraints: const BoxConstraints(maxWidth: 420),
            child: ConstrainedBox(
          child: Center(
        body: SafeArea(
  Widget build(BuildContext context) => Scaffold(
  @override

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
        ScaffoldMessenger.of(context)
      if (mounted)
    } catch (error) {
      context.go(result.isFirstLogin ? '/change-password' : '/home');
      if (!mounted) return;
          .login(_phone.text, _password.text);
          .read(customerAuthProvider.notifier)
      final result = await ref
    try {
    setState(() => _loading = true);
    if (!_formKey.currentState!.validate()) return;
  Future<void> _submit() async {

  bool _loading = false;
  bool _obscure = true;
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _formKey = GlobalKey<FormState>();
class _LoginScreenState extends ConsumerState<LoginScreen> {

}
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
  @override
  const LoginScreen({super.key});
class LoginScreen extends ConsumerStatefulWidget {

}
  }
    );
      ),
        ),
          ),
            ),
              ),
                ],
                  const SizedBox(height: 32),
                  ),
                    ),
                      label: const Text('Admin'),
                      icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
                      onPressed: () => context.push('/admin/login'),
                    child: OutlinedButton.icon(
                    width: double.infinity,
                  SizedBox(
                  const SizedBox(height: 12),
                  ),
                    ],
                      ),
                        ),
                          label: const Text('Toko'),
                          icon: const Icon(Icons.store_outlined, size: 20),
                          onPressed: () => context.push('/store-login'),
                        child: OutlinedButton.icon(
                      Expanded(
                      const SizedBox(width: 12),
                      ),
                        ),
                          label: const Text('Pelanggan'),
                          icon: const Icon(Icons.person_outline, size: 20),
                          onPressed: () => context.push('/login'),
                        child: OutlinedButton.icon(
                      Expanded(
                    children: [
                  Row(
                  const SizedBox(height: 14),
                  ),
                    ),
                          style: TextStyle(fontSize: 16)),
                      label: const Text('Service Now',
                      icon: const Icon(Icons.build, size: 22),
                      onPressed: () => context.go('/service'),
                    child: FilledButton.icon(
                    height: 52,
                    width: double.infinity,
                  SizedBox(
                  const SizedBox(height: 48),
                  ),
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    style: theme.textTheme.bodyLarge
                    'Servis smartphone cepat & terpercaya',
                  Text(
                  const SizedBox(height: 8),
                  ),
                        ?.copyWith(fontWeight: FontWeight.w800),
                    style: theme.textTheme.headlineLarge
                    'ServisGadget',
                  Text(
                  const SizedBox(height: 16),
                  Icon(Icons.build, size: 80, color: theme.colorScheme.primary),
                children: [
                mainAxisSize: MainAxisSize.min,
              child: Column(
              padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Padding(
            constraints: const BoxConstraints(maxWidth: 420),
          child: ConstrainedBox(
        child: Center(
      body: SafeArea(
    return Scaffold(
    final theme = Theme.of(context);
  Widget build(BuildContext context) {
  @override

  const WelcomeScreen({super.key});
class WelcomeScreen extends StatelessWidget {

}
      );
        ),
          ]),
            CircularProgressIndicator(),
            SizedBox(height: 24),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text('ServisGadget',
            SizedBox(height: 16),
            Icon(Icons.handyman, size: 64),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        body: Center(
  Widget build(BuildContext context) => const Scaffold(
  @override

  }
    }
      if (mounted) context.go('/login');
      await ref.read(customerSessionProvider).clearAll();
    } catch (_) {
      context.go(user.isFirstLogin ? '/change-password' : '/home');
      if (!mounted) return;
          await ref.read(customerAuthProvider.notifier).restoreSession();
      final user =
    try {
    }
      return;
      context.go('/login');
    if (token == null) {
    if (!mounted) return;
    final token = await ref.read(customerSessionProvider).readAccessToken();
    await Future<void>.delayed(const Duration(milliseconds: 600));
  Future<void> _checkAuth() async {

  }
    Future.microtask(_checkAuth);
    super.initState();
  void initState() {
  @override
class _SplashScreenState extends ConsumerState<SplashScreen> {

}
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
  @override

  const SplashScreen({super.key});
class SplashScreen extends ConsumerStatefulWidget {

import '../widgets/customer_widgets.dart';
import '../../domain/customer_models.dart';
import '../../data/customer_repositories.dart';
import '../../application/customer_providers.dart';

import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
}

}
  }
    );
      ),
        ),
          ]),
            ),
              ]),
                            .toList()),
                                    Text(review.comment ?? 'Tanpa komentar')))
                                subtitle:
                                title: Text('${review.rating}/5'),
                            .map((review) => ListTile(
                        children: store.reviews
                    : ListView(
                    ? const EmptyMessage('Belum ada ulasan.')
                store.reviews.isEmpty
                ),
                      const EmptyMessage('Sparepart gagal dimuat.'),
                  error: (_, __) =>
                  loading: () => const SkeletonList(),
                              .toList()),
                                      : rupiah(part.price))))
                                      ? 'Habis'
                                  trailing: Text(part.availableQty <= 0
                                      Text('${part.brand} ${part.deviceModel}'),
                                  subtitle:
                                  title: Text(part.partName),
                              .map((part) => ListTile(
                          children: items
                      : ListView(
                      ? const EmptyMessage('Sparepart belum tersedia.')
                  data: (items) => items.isEmpty
                spareparts.when(
              child: TabBarView(children: [
            Expanded(
            const TabBar(tabs: [Tab(text: 'Sparepart'), Tab(text: 'Ulasan')]),
            ),
                  ]),
                        'Rating ${store.ratingAvg.toStringAsFixed(1)} - ${store.phoneNumber}${store.verifiedAt != null ? ' - Verified' : ''}'),
                    Text(
                    const SizedBox(height: 8),
                    Text(store.address),
                            ?.copyWith(fontWeight: FontWeight.w800)),
                            .headlineSmall
                            .textTheme
                        style: Theme.of(context)
                    Text(store.storeName,
                  children: [
                  crossAxisAlignment: CrossAxisAlignment.start,
              child: Column(
              padding: const EdgeInsets.all(16),
            Padding(
          child: Column(children: [
          length: 2,
        builder: (store) => DefaultTabController(
        value: detail,
      child: AsyncPage(
          label: const Text('Buat Order')),
          icon: const Icon(Icons.add),
          onPressed: () => context.push('/booking/$storeId'),
      floatingActionButton: FloatingActionButton.extended(
      title: 'Detail Toko',
    return CustomerScaffold(
    final spareparts = ref.watch(sparepartsProvider(storeId));
    final detail = ref.watch(storeDetailProvider(storeId));
  Widget build(BuildContext context, WidgetRef ref) {
  @override
  final String storeId;
  const StoreDetailScreen({super.key, required this.storeId});
class StoreDetailScreen extends ConsumerWidget {

}
  }
    );
      ]),
                            .toList()))),
                                    context.push('/stores/${store.id}')))
                                onTap: () =>
                                store: store,
                            .map((store) => StoreCard(
                        children: items
                    : ListView(
                    ? const EmptyMessage('Toko tidak ditemukan.')
                builder: (items) => items.isEmpty
                value: stores,
            child: AsyncPage(
        Expanded(
        ),
              onSubmitted: (_) => setState(() {})),
                  border: OutlineInputBorder()),
                  hintText: 'Cari model perangkat',
                  prefixIcon: Icon(Icons.search),
              decoration: const InputDecoration(
              controller: _model,
          child: TextField(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        Padding(
        ),
                  .toList()),
                      ))
                            onSelected: (_) => setState(() => _brand = brand)),
                            selected: _brand == brand,
                            label: Text(brand),
                        child: FilterChip(
                            horizontal: 4, vertical: 8),
                        padding: const EdgeInsets.symmetric(
                  .map((brand) => Padding(
              children: ['All', ...brands]
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
          child: ListView(
          height: 54,
        SizedBox(
      child: Column(children: [
      title: 'Pilih Toko',
    return CustomerScaffold(
        ref.watch(storeListProvider((brand: _brand, model: _model.text)));
    final stores =
    brands.sort();
    final brands = deviceModels.valueOrNull?.map((group) => group.brand).toSet().toList() ?? const <String>[];
    final deviceModels = ref.watch(deviceModelsProvider);
  Widget build(BuildContext context) {
  @override
  final _model = TextEditingController();
  String _brand = 'All';
class _StoreListScreenState extends ConsumerState<StoreListScreen> {

}
  ConsumerState<StoreListScreen> createState() => _StoreListScreenState();
  @override
  const StoreListScreen({super.key});
class StoreListScreen extends ConsumerStatefulWidget {

}
      );
        ),
          ),
            ]),
              Text(label)
                      ?.copyWith(fontWeight: FontWeight.w900)),
                      .headlineSmall
                      .textTheme
                  style: Theme.of(context)
              Text(value,
            child: Column(children: [
            padding: const EdgeInsets.all(16),
          child: Padding(
          margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Card(
  Widget build(BuildContext context) => Expanded(
  @override
  final String value;
  final String label;
  const _SummaryTile({required this.label, required this.value});
class _SummaryTile extends StatelessWidget {

}
  }
    );
      ),
        ),
          ],
            ),
              ),
                    style: TextStyle(fontWeight: FontWeight.w700)),
                    'Promo servis bulan ini: cek perangkat lebih cepat dan pantau progres langsung dari aplikasi.',
                child: Text(
                padding: EdgeInsets.all(18),
              child: const Padding(
              color: Theme.of(context).colorScheme.secondaryContainer,
              margin: const EdgeInsets.all(16),
            Card(
            ),
                  const EmptyMessage('Pesanan belum bisa dimuat.'),
              error: (_, __) =>
                  const SizedBox(height: 260, child: SkeletonList(count: 3)),
              loading: () =>
                          .toList()),
                              onTap: () => context.push('/orders/${order.id}')))
                              order: order,
                          .map((order) => OrderCard(
                      children: orders
                  : Column(
                  ? const EmptyMessage('Belum ada pesanan.')
              data: (orders) => orders.isEmpty
            recent.when(
                    child: const Text('Lihat Semua'))),
                    onPressed: () => context.push('/orders'),
                action: TextButton(
            SectionTitle('Pesanan Terbaru',
            ),
              ]),
                        label: const Text('Kupon'))),
                        icon: const Icon(Icons.local_offer),
                        onPressed: () => context.push('/coupons'),
                    child: OutlinedButton.icon(
                Expanded(
                const SizedBox(width: 8),
                        label: const Text('Pesanan'))),
                        icon: const Icon(Icons.inventory_2),
                        onPressed: () => context.push('/orders'),
                    child: OutlinedButton.icon(
                Expanded(
                const SizedBox(width: 8),
                        label: const Text('Servis'))),
                        icon: const Icon(Icons.build),
                        onPressed: () => context.push('/stores'),
                    child: FilledButton.icon(
                Expanded(
              child: Row(children: [
              padding: const EdgeInsets.all(16),
            Padding(
            ),
                  child: Text('Ringkasan belum tersedia.')),
                  padding: EdgeInsets.all(16),
              error: (_, __) => const Padding(
                  child: Center(child: CircularProgressIndicator())),
                  height: 88,
              loading: () => const SizedBox(
              ]),
                    label: 'Garansi', value: data.activeWarranties.toString()),
                _SummaryTile(
                    label: 'Kupon', value: data.activeCoupons.toString()),
                _SummaryTile(
                    label: 'Aktif', value: data.activeOrders.toString()),
                _SummaryTile(
              data: (data) => Row(children: [
            summary.when(
            ),
                      ?.copyWith(fontWeight: FontWeight.w800)),
                      .headlineSmall
                      .textTheme
                  style: Theme.of(context)
              child: Text('Halo, ${user?.fullName ?? 'Pelanggan'}!',
              padding: const EdgeInsets.all(16),
            Padding(
          children: [
          padding: const EdgeInsets.only(bottom: 24),
        child: ListView(
        },
          ref.invalidate(featuredStoresProvider);
          ref.invalidate(customerOrdersProvider('recent'));
          ref.invalidate(homeSummaryProvider);
        onRefresh: () async {
      child: RefreshIndicator(
      ],
            icon: const Icon(Icons.person_outline)),
            onPressed: () => context.push('/profile'),
        IconButton(
            icon: const Icon(Icons.notifications_outlined)),
            onPressed: () => context.push('/notifications'),
        IconButton(
      actions: [
      title: 'ServisGadget',
    return CustomerScaffold(
    final recent = ref.watch(customerOrdersProvider('recent'));
    final summary = ref.watch(homeSummaryProvider);
    final user = ref.watch(customerAuthProvider).valueOrNull;
  Widget build(BuildContext context, WidgetRef ref) {
  @override
  const HomeScreen({super.key});
class HomeScreen extends ConsumerWidget {

}
      );
        ),
          ),
            ],
                      : const Text('Simpan Password')),
                      ? const CircularProgressIndicator()
                  child: _loading
                  onPressed: _loading ? null : _submit,
              FilledButton(
              const SizedBox(height: 20),
                      v != _next.text ? 'Konfirmasi tidak sama.' : null),
                  validator: (v) =>
                      border: OutlineInputBorder()),
                      labelText: 'Konfirmasi Password Baru',
                  decoration: const InputDecoration(
                  obscureText: true,
                  controller: _confirm,
              TextFormField(
              const SizedBox(height: 12),
                  }),
                    return null;
                      return 'Password baru tidak boleh sama.';
                    if (v == _old.text)
                    if (v == null || v.length < 8) return 'Minimal 8 karakter.';
                  validator: (v) {
                      labelText: 'Password Baru', border: OutlineInputBorder()),
                  decoration: const InputDecoration(
                  obscureText: true,
                  controller: _next,
              TextFormField(
              const SizedBox(height: 12),
                      v == null || v.isEmpty ? 'Wajib diisi.' : null),
                  validator: (v) =>
                      labelText: 'Password Lama', border: OutlineInputBorder()),
                  decoration: const InputDecoration(
                  obscureText: true,
                  controller: _old,
              TextFormField(
              const SizedBox(height: 16),
                          'Ganti password sementaramu sebelum melanjutkan.'))),
                      child: Text(
                      padding: EdgeInsets.all(16),
                  child: const Padding(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.amber.withValues(alpha: 0.18),
              Material(
            children: [
            padding: const EdgeInsets.all(16),
          child: ListView(
          key: _formKey,
        child: Form(
        title: 'Ganti Password',
  Widget build(BuildContext context) => CustomerScaffold(
  @override

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
        ScaffoldMessenger.of(context)
      if (mounted)
    } catch (error) {
      if (mounted) context.go('/home');
          .changePassword(_old.text, _next.text);
          .read(customerAuthProvider.notifier)
      await ref
    try {
    setState(() => _loading = true);
    if (!_formKey.currentState!.validate()) return;
  Future<void> _submit() async {

  bool _loading = false;
  final _confirm = TextEditingController();
  final _next = TextEditingController();
  final _old = TextEditingController();
  final _formKey = GlobalKey<FormState>();
class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {

}
      _ChangePasswordScreenState();
  ConsumerState<ChangePasswordScreen> createState() =>
  @override
  const ChangePasswordScreen({super.key});
class ChangePasswordScreen extends ConsumerStatefulWidget {

}
      );
        ),
          ),
            ),
              ),
                ),
                  ],
                            : const Text('Masuk')),
                            ? const CircularProgressIndicator()
                        child: _loading
                        onPressed: _loading ? null : _submit,
                    FilledButton(
                    const SizedBox(height: 20),
                    ),
                          : null,
                          ? 'Password wajib diisi.'
                      validator: (value) => value == null || value.isEmpty
                      ),
                                : Icons.visibility_off)),
                                ? Icons.visibility
                            icon: Icon(_obscure
                                setState(() => _obscure = !_obscure),
                            onPressed: () =>
                        suffixIcon: IconButton(
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        labelText: 'Password',
                      decoration: InputDecoration(
                      obscureText: _obscure,
                      controller: _password,
                    TextFormField(
                    const SizedBox(height: 12),
                    ),
                              : null,
                              ? 'Nomor HP wajib diisi.'
                          value == null || value.trim().isEmpty
                      validator: (value) =>
                          border: OutlineInputBorder()),
                          prefixIcon: Icon(Icons.phone),
                          labelText: 'Nomor HP',
                      decoration: const InputDecoration(
                      keyboardType: TextInputType.phone,
                      controller: _phone,
                    TextFormField(
                    const SizedBox(height: 24),
                        textAlign: TextAlign.center),
                        'Gunakan akun yang dikirim admin toko lewat WhatsApp.',
                    const Text(
                    const SizedBox(height: 8),
                            ?.copyWith(fontWeight: FontWeight.w800)),
                            .headlineSmall
                            .textTheme
                        style: Theme.of(context)
                        textAlign: TextAlign.center,
                    Text('Masuk ke ServisGadget',
                    const SizedBox(height: 16),
                    const Icon(Icons.handyman, size: 56),
                  children: [
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(24),
                child: ListView(
                key: _formKey,
              child: Form(
              constraints: const BoxConstraints(maxWidth: 420),
            child: ConstrainedBox(
          child: Center(
        body: SafeArea(
  Widget build(BuildContext context) => Scaffold(
  @override

  }
    }
      if (mounted) setState(() => _loading = false);
    } finally {
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
        ScaffoldMessenger.of(context)
      if (mounted)
    } catch (error) {
      context.go(result.isFirstLogin ? '/change-password' : '/home');
      if (!mounted) return;
          .login(_phone.text, _password.text);
          .read(customerAuthProvider.notifier)
      final result = await ref
    try {
    setState(() => _loading = true);
    if (!_formKey.currentState!.validate()) return;
  Future<void> _submit() async {

  bool _loading = false;
  bool _obscure = true;
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _formKey = GlobalKey<FormState>();
class _LoginScreenState extends ConsumerState<LoginScreen> {

}
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
  @override
  const LoginScreen({super.key});
class LoginScreen extends ConsumerStatefulWidget {

}
  }
    );
      ),
        ),
          ),
            ),
              ),
                ],
                  const SizedBox(height: 32),
                  ),
                    ),
                      label: const Text('Admin'),
                      icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
                      onPressed: () => context.push('/admin/login'),
                    child: OutlinedButton.icon(
                    width: double.infinity,
                  SizedBox(
                  const SizedBox(height: 12),
                  ),
                    ],
                      ),
                        ),
                          label: const Text('Toko'),
                          icon: const Icon(Icons.store_outlined, size: 20),
                          onPressed: () => context.push('/store-login'),
                        child: OutlinedButton.icon(
                      Expanded(
                      const SizedBox(width: 12),
                      ),
                        ),
                          label: const Text('Pelanggan'),
                          icon: const Icon(Icons.person_outline, size: 20),
                          onPressed: () => context.push('/login'),
                        child: OutlinedButton.icon(
                      Expanded(
                    children: [
                  Row(
                  const SizedBox(height: 14),
                  ),
                    ),
                          style: TextStyle(fontSize: 16)),
                      label: const Text('Service Now',
                      icon: const Icon(Icons.build, size: 22),
                      onPressed: () => context.go('/service'),
                    child: FilledButton.icon(
                    height: 52,
                    width: double.infinity,
                  SizedBox(
                  const SizedBox(height: 48),
                  ),
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    style: theme.textTheme.bodyLarge
                    'Servis smartphone cepat & terpercaya',
                  Text(
                  const SizedBox(height: 8),
                  ),
                        ?.copyWith(fontWeight: FontWeight.w800),
                    style: theme.textTheme.headlineLarge
                    'ServisGadget',
                  Text(
                  const SizedBox(height: 16),
                  Icon(Icons.build, size: 80, color: theme.colorScheme.primary),
                children: [
                mainAxisSize: MainAxisSize.min,
              child: Column(
              padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Padding(
            constraints: const BoxConstraints(maxWidth: 420),
          child: ConstrainedBox(
        child: Center(
      body: SafeArea(
    return Scaffold(
    final theme = Theme.of(context);
  Widget build(BuildContext context) {
  @override

  const WelcomeScreen({super.key});
class WelcomeScreen extends StatelessWidget {

}
      );
        ),
          ]),
            CircularProgressIndicator(),
            SizedBox(height: 24),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text('ServisGadget',
            SizedBox(height: 16),
            Icon(Icons.handyman, size: 64),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        body: Center(
  Widget build(BuildContext context) => const Scaffold(
  @override

  }
    }
      if (mounted) context.go('/login');
      await ref.read(customerSessionProvider).clearAll();
    } catch (_) {
      context.go(user.isFirstLogin ? '/change-password' : '/home');
      if (!mounted) return;
          await ref.read(customerAuthProvider.notifier).restoreSession();
      final user =
    try {
    }
      return;
      context.go('/login');
    if (token == null) {
    if (!mounted) return;
    final token = await ref.read(customerSessionProvider).readAccessToken();
    await Future<void>.delayed(const Duration(milliseconds: 600));
  Future<void> _checkAuth() async {

  }
    Future.microtask(_checkAuth);
    super.initState();
  void initState() {
  @override
class _SplashScreenState extends ConsumerState<SplashScreen> {

}
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
  @override

  const SplashScreen({super.key});
class SplashScreen extends ConsumerStatefulWidget {

import '../widgets/customer_widgets.dart';
import '../../domain/customer_models.dart';
import '../../data/customer_repositories.dart';
import '../../application/customer_providers.dart';

import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
}

