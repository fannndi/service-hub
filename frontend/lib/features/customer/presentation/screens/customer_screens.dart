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

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_checkAuth);
  }

  Future<void> _checkAuth() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final token = await ref.read(customerSessionProvider).readAccessToken();
    if (!mounted) return;
    if (token == null) {
      context.go('/login');
      return;
    }
    try {
      final user =
          await ref.read(customerAuthProvider.notifier).restoreSession();
      if (!mounted) return;
      context.go(user.isFirstLogin ? '/change-password' : '/home');
    } catch (_) {
      await ref.read(customerSessionProvider).clearAll();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.handyman, size: 64),
            SizedBox(height: 16),
            Text('ServisGadget',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ]),
        ),
      );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.build, size: 80, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'ServisGadget',
                    style: theme.textTheme.headlineLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Servis smartphone cepat & terpercaya',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () => context.go('/service'),
                      icon: const Icon(Icons.build, size: 22),
                      label: const Text('Service Now',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/login'),
                          icon: const Icon(Icons.person_outline, size: 20),
                          label: const Text('Pelanggan'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/store-login'),
                          icon: const Icon(Icons.store_outlined, size: 20),
                          label: const Text('Toko'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/admin/login'),
                      icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
                      label: const Text('Admin'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final result = await ref
          .read(customerAuthProvider.notifier)
          .login(_phone.text, _password.text);
      if (!mounted) return;
      context.go(result.isFirstLogin ? '/change-password' : '/home');
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  shrinkWrap: true,
                  children: [
                    const Icon(Icons.handyman, size: 56),
                    const SizedBox(height: 16),
                    Text('Masuk ke ServisGadget',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text(
                        'Gunakan akun yang dikirim admin toko lewat WhatsApp.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'Nomor HP',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder()),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Nomor HP wajib diisi.'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure
                                ? Icons.visibility
                                : Icons.visibility_off)),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Password wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const CircularProgressIndicator()
                            : const Text('Masuk')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(customerAuthProvider.notifier)
          .changePassword(_old.text, _next.text);
      if (mounted) context.go('/home');
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => CustomerScaffold(
        title: 'Ganti Password',
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Material(
                  color: Colors.amber.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                          'Ganti password sementaramu sebelum melanjutkan.'))),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _old,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Password Lama', border: OutlineInputBorder()),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi.' : null),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _next,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Password Baru', border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.length < 8) return 'Minimal 8 karakter.';
                    if (v == _old.text)
                      return 'Password baru tidak boleh sama.';
                    return null;
                  }),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Konfirmasi Password Baru',
                      border: OutlineInputBorder()),
                  validator: (v) =>
                      v != _next.text ? 'Konfirmasi tidak sama.' : null),
              const SizedBox(height: 20),
              FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Simpan Password')),
            ],
          ),
        ),
      );
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(customerAuthProvider).valueOrNull;
    final summary = ref.watch(homeSummaryProvider);
    final recent = ref.watch(customerOrdersProvider('recent'));
    return CustomerScaffold(
      title: 'ServisGadget',
      actions: [
        IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_outlined)),
        IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline)),
      ],
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(homeSummaryProvider);
          ref.invalidate(customerOrdersProvider('recent'));
          ref.invalidate(featuredStoresProvider);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Halo, ${user?.fullName ?? 'Pelanggan'}!',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            summary.when(
              data: (data) => Row(children: [
                _SummaryTile(
                    label: 'Aktif', value: data.activeOrders.toString()),
                _SummaryTile(
                    label: 'Kupon', value: data.activeCoupons.toString()),
                _SummaryTile(
                    label: 'Garansi', value: data.activeWarranties.toString()),
              ]),
              loading: () => const SizedBox(
                  height: 88,
                  child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Ringkasan belum tersedia.')),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                    child: FilledButton.icon(
                        onPressed: () => context.push('/stores'),
                        icon: const Icon(Icons.build),
                        label: const Text('Servis'))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () => context.push('/orders'),
                        icon: const Icon(Icons.inventory_2),
                        label: const Text('Pesanan'))),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () => context.push('/coupons'),
                        icon: const Icon(Icons.local_offer),
                        label: const Text('Kupon'))),
              ]),
            ),
            SectionTitle('Pesanan Terbaru',
                action: TextButton(
                    onPressed: () => context.push('/orders'),
                    child: const Text('Lihat Semua'))),
            recent.when(
              data: (orders) => orders.isEmpty
                  ? const EmptyMessage('Belum ada pesanan.')
                  : Column(
                      children: orders
                          .map((order) => OrderCard(
                              order: order,
                              onTap: () => context.push('/orders/${order.id}')))
                          .toList()),
              loading: () =>
                  const SizedBox(height: 260, child: SkeletonList(count: 3)),
              error: (_, __) =>
                  const EmptyMessage('Pesanan belum bisa dimuat.'),
            ),
            Card(
              margin: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                    'Promo servis bulan ini: cek perangkat lebih cepat dan pantau progres langsung dari aplikasi.',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900)),
              Text(label)
            ]),
          ),
        ),
      );
}

class StoreListScreen extends ConsumerStatefulWidget {
  const StoreListScreen({super.key});
  @override
  ConsumerState<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends ConsumerState<StoreListScreen> {
  String _brand = 'All';
  final _model = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final stores =
        ref.watch(storeListProvider((brand: _brand, model: _model.text)));
    return CustomerScaffold(
      title: 'Pilih Toko',
      child: Column(children: [
        SizedBox(
          height: 54,
          child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                'All',
                'Samsung',
                'Apple',
                'Xiaomi',
                'Oppo',
                'Realme',
                'Vivo'
              ]
                  .map((brand) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                        child: FilterChip(
                            label: Text(brand),
                            selected: _brand == brand,
                            onSelected: (_) => setState(() => _brand = brand)),
                      ))
                  .toList()),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
              controller: _model,
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Cari model perangkat',
                  border: OutlineInputBorder()),
              onSubmitted: (_) => setState(() {})),
        ),
        Expanded(
            child: AsyncPage(
                value: stores,
                builder: (items) => items.isEmpty
                    ? const EmptyMessage('Toko tidak ditemukan.')
                    : ListView(
                        children: items
                            .map((store) => StoreCard(
                                store: store,
                                onTap: () =>
                                    context.push('/stores/${store.id}')))
                            .toList()))),
      ]),
    );
  }
}

class StoreDetailScreen extends ConsumerWidget {
  const StoreDetailScreen({super.key, required this.storeId});
  final String storeId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(storeDetailProvider(storeId));
    final spareparts = ref.watch(sparepartsProvider(storeId));
    return CustomerScaffold(
      title: 'Detail Toko',
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/booking/$storeId'),
          icon: const Icon(Icons.add),
          label: const Text('Buat Order')),
      child: AsyncPage(
        value: detail,
        builder: (store) => DefaultTabController(
          length: 2,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.storeName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text(store.address),
                    const SizedBox(height: 8),
                    Text(
                        'Rating ${store.ratingAvg.toStringAsFixed(1)} - ${store.phoneNumber}${store.verifiedAt != null ? ' - Verified' : ''}'),
                  ]),
            ),
            const TabBar(tabs: [Tab(text: 'Sparepart'), Tab(text: 'Ulasan')]),
            Expanded(
              child: TabBarView(children: [
                spareparts.when(
                  data: (items) => items.isEmpty
                      ? const EmptyMessage('Sparepart belum tersedia.')
                      : ListView(
                          children: items
                              .map((part) => ListTile(
                                  title: Text(part.partName),
                                  subtitle:
                                      Text('${part.brand} ${part.deviceModel}'),
                                  trailing: Text(part.availableQty <= 0
                                      ? 'Habis'
                                      : rupiah(part.price))))
                              .toList()),
                  loading: () => const SkeletonList(),
                  error: (_, __) =>
                      const EmptyMessage('Sparepart gagal dimuat.'),
                ),
                store.reviews.isEmpty
                    ? const EmptyMessage('Belum ada ulasan.')
                    : ListView(
                        children: store.reviews
                            .map((review) => ListTile(
                                title: Text('${review.rating}/5'),
                                subtitle:
                                    Text(review.comment ?? 'Tanpa komentar')))
                            .toList()),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class ServiceFlowScreen extends ConsumerStatefulWidget {
  const ServiceFlowScreen({super.key});
  @override
  ConsumerState<ServiceFlowScreen> createState() => _ServiceFlowScreenState();
}

class _ServiceFlowScreenState extends ConsumerState<ServiceFlowScreen> {
  final _pageController = PageController();
  int _step = 0;
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _complaint = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _coupon = TextEditingController();
  String _deviceType = 'android';
  String _serviceType = 'screen_replacement';
  String _delivery = 'walk_in';
  String? _selectedStoreId;
  String? _selectedPartId;
  double _estimateCost = 0;
  bool _loading = false;
  List<StoreMatchResult> _matchedStores = const [];

  final _serviceTypeLabels = const {
    'screen_replacement': 'Ganti Layar',
    'battery_replacement': 'Ganti Baterai',
    'charging_port': 'Port Charger',
    'camera': 'Kamera',
    'other': 'Lainnya',
  };

  @override
  void initState() {
    super.initState();
    final user = ref.read(customerAuthProvider).valueOrNull;
    if (user != null) {
      _name.text = user.fullName;
      _phone.text = user.phoneNumber;
      _address.text = user.address ?? '';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _brand.dispose();
    _model.dispose();
    _complaint.dispose();
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _coupon.dispose();
    super.dispose();
  }

  Future<void> _matchStores() async {
    if (_brand.text.isEmpty || _model.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(storeDiscoveryRepositoryProvider);
      _matchedStores = await repo.matchStores(
        brand: _brand.text.trim(),
        deviceModel: _model.text.trim(),
        partType: _serviceType,
      );
    } catch (_) {
      _matchedStores = const [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectStore(StoreMatchResult store) {
    setState(() {
      _selectedStoreId = store.storeId;
      _estimateCost = store.estimatedCost;
    });
  }

  Future<void> _createBooking() async {
    setState(() => _loading = true);
    try {
      final req = CreateOrderRequest(
        storeId: _selectedStoreId!,
        fullName: _name.text.trim(),
        phoneNumber: normalizePhone(_phone.text.trim()),
        deviceType: _deviceType,
        brand: _brand.text.trim(),
        deviceModel: _model.text.trim(),
        deliveryMethod: _delivery,
        deliveryAddress: _delivery == 'courier_pickup' ? _address.text.trim() : null,
        couponCode: _coupon.text.trim().isEmpty ? null : _coupon.text.trim(),
        items: [
          CreateOrderItemInput(
            serviceType: _serviceType,
            complaint: _complaint.text.trim(),
            sparepartId: _selectedPartId,
            price: _estimateCost,
          ),
        ],
      );
      final result = await ref.read(orderRepositoryProvider).createOrder(req);
      if (!mounted) return;
      context.go('/booking-success/${result.orderNumber}', extra: result.isNewCustomer);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(parseApiError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _nextStep() {
    if (_step >= 4) return;
    if (_step == 0 && (_brand.text.isEmpty || _model.text.isEmpty)) return;
    if (_step == 1 && _complaint.text.isEmpty) return;
    if (_step == 2 && _selectedStoreId == null) return;
    if (_step == 3 && (_name.text.isEmpty || _phone.text.isEmpty)) return;

    if (_step == 1) {
      _matchStores().then((_) {
        if (mounted) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          setState(() => _step = 2);
        }
      });
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _step += 1);
  }

  void _prevStep() {
    if (_step <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _step -= 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = ['Perangkat', 'Kerusakan', 'Toko', 'Data Diri', 'Konfirmasi'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Now'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: List.generate(steps.length, (i) {
                  final active = i == _step;
                  final done = i < _step;
                  return Expanded(
                    child: Column(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done ? theme.colorScheme.primary : active ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                        ),
                        child: Center(
                          child: done
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: active ? Colors.white : theme.colorScheme.onSurfaceVariant)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(steps[i], style: TextStyle(fontSize: 10, color: active || done ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                    ]),
                  );
                }),
              ),
            ),
            const Divider(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(theme),
                  _buildStep2(theme),
                  _buildStep3(theme),
                  _buildStep4(theme),
                  _buildStep5(theme),
                ],
              ),
            ),
            _buildBottomNav(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1(ThemeData theme) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('Pilih Jenis & Tipe Perangkat', style: theme.textTheme.titleLarge),
      const SizedBox(height: 8),
      Text('Pilih jenis smartphone lalu masukkan brand dan tipe perangkatmu.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 24),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'android', label: Text('Android'), icon: Icon(Icons.android)),
          ButtonSegment(value: 'ios', label: Text('iPhone / iOS'), icon: Icon(Icons.phone_iphone)),
        ],
        selected: {_deviceType},
        onSelectionChanged: (v) => setState(() => _deviceType = v.first),
        showSelectedIcon: false,
      ),
      const SizedBox(height: 24),
      TextField(
        controller: _brand, textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Brand Smartphone', hintText: 'Contoh: Samsung, Xiaomi, Apple', prefixIcon: Icon(Icons.branding_watermark)),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _model, textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Tipe Smartphone', hintText: 'Contoh: Galaxy S24 Ultra, iPhone 15 Pro', prefixIcon: Icon(Icons.smartphone)),
      ),
    ],
  );

  Widget _buildStep2(ThemeData theme) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('Jenis Kerusakan / Layanan', style: theme.textTheme.titleLarge),
      const SizedBox(height: 8),
      Text('Pilih jenis layanan yang dibutuhkan dan jelaskan keluhannya.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 24),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: _serviceTypeLabels.entries.map((e) => ChoiceChip(
          label: Text(e.value),
          selected: _serviceType == e.key,
          onSelected: (v) { if (v) setState(() => _serviceType = e.key); },
        )).toList(),
      ),
      const SizedBox(height: 24),
      TextField(
        controller: _complaint, maxLines: 4, textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Keluhan / Deskripsi Kerusakan',
          hintText: 'Jelaskan kerusakan yang dialami, contoh:\n- Layar retak dari pojok kiri bawah\n- Baterai cepat habis (health < 70%)\n- Bootloop, tidak bisa masuk home screen',
          prefixIcon: Padding(padding: EdgeInsets.only(bottom: 64), child: Icon(Icons.report_problem_outlined)),
          alignLabelWithHint: true,
        ),
      ),
    ],
  );

  Widget _buildStep3(ThemeData theme) {
    if (_loading && _matchedStores.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_matchedStores.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Rekomendasi Toko Mitra', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          const Icon(Icons.store_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Tidak ada toko yang cocok untuk perangkat ${_brand.text} ${_model.text} dengan layanan ini.', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          Text('Silakan periksa kembali brand, tipe, atau jenis layanan yang dipilih.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _prevStep,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Kembali'),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Pilih Toko Mitra', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('${_matchedStores.length} toko tersedia untuk perangkat kamu.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        ..._matchedStores.map((store) {
          final selected = store.storeId == _selectedStoreId;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: selected ? theme.colorScheme.primaryContainer : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: selected ? BorderSide(color: theme.colorScheme.primary) : BorderSide.none,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _selectStore(store),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(store.storeName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                    Row(children: [
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(store.ratingAvg.toStringAsFixed(1), style: theme.textTheme.bodyMedium),
                    ]),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(store.address, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${store.totalCompleted} servis selesai', style: theme.textTheme.labelSmall),
                  ),
                  const SizedBox(height: 8),
                  ...store.spareparts.map((sp) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(children: [
                      const Icon(Icons.build, size: 14),
                      const SizedBox(width: 8),
                      Expanded(child: Text(sp.partName, style: theme.textTheme.bodyMedium)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: sp.status == 'available' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(sp.status == 'available' ? 'Tersedia' : 'Preorder', style: TextStyle(fontSize: 11, color: sp.status == 'available' ? Colors.green : Colors.orange)),
                      ),
                      const SizedBox(width: 12),
                      Text(rupiah(sp.price), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ]),
                  )),
                  const Divider(height: 16),
                  Row(children: [
                    const Icon(Icons.info_outline, size: 16),
                    const SizedBox(width: 4),
                    Text('Estimasi awal: ${rupiah(store.estimatedCost)}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                  ]),
                ]),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep4(ThemeData theme) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('Data Diri & Pengiriman', style: theme.textTheme.titleLarge),
      const SizedBox(height: 24),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'walk_in', label: Text('Antar ke Toko'), icon: Icon(Icons.store)),
          ButtonSegment(value: 'courier_pickup', label: Text('Pickup Kurir'), icon: Icon(Icons.local_shipping)),
        ],
        selected: {_delivery},
        onSelectionChanged: (v) => setState(() => _delivery = v.first),
        showSelectedIcon: false,
      ),
      const SizedBox(height: 24),
      TextField(
        controller: _name, textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person_outline)),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _phone, keyboardType: TextInputType.phone,
        decoration: const InputDecoration(labelText: 'Nomor WhatsApp', prefixText: '08', prefixIcon: Icon(Icons.phone_outlined)),
      ),
      if (_delivery == 'courier_pickup') ...[
        const SizedBox(height: 16),
        TextField(
          controller: _address, maxLines: 2, textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Alamat Penjemputan', prefixIcon: Icon(Icons.location_on_outlined), alignLabelWithHint: true),
        ),
      ],
    ],
  );

  Widget _buildStep5(ThemeData theme) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text('Konfirmasi Booking', style: theme.textTheme.titleLarge),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _confirmRow(theme, 'Perangkat', '${_deviceType.toUpperCase()} - ${_brand.text} ${_model.text}'),
            const Divider(),
            _confirmRow(theme, 'Layanan', _serviceTypeLabels[_serviceType]!),
            const Divider(),
            _confirmRow(theme, 'Keluhan', _complaint.text),
            const Divider(),
            _confirmRow(theme, 'Nama', _name.text),
            const Divider(),
            _confirmRow(theme, 'WhatsApp', _phone.text),
            if (_delivery == 'courier_pickup') ...[
              const Divider(),
              _confirmRow(theme, 'Alamat', _address.text),
            ],
            const Divider(),
            _confirmRow(theme, 'Pengiriman', _delivery == 'walk_in' ? 'Antar ke Toko' : 'Pickup Kurir'),
            const Divider(height: 24),
            Row(children: [
              Text('Estimasi Biaya', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(rupiah(_estimateCost), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            ]),
            const SizedBox(height: 4),
            Text('* Estimasi bersifat sementara, dapat berubah setelah diagnosis teknisi.', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _coupon,
        decoration: const InputDecoration(labelText: 'Kode Kupon (opsional)', prefixIcon: Icon(Icons.local_offer_outlined), isDense: true),
      ),
    ],
  );

  Widget _confirmRow(ThemeData theme, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 80, child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
      Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
    ]),
  );

  Widget _buildBottomNav(ThemeData theme) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        if (_step > 0)
          Expanded(child: OutlinedButton.icon(
            onPressed: _loading ? null : _prevStep,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Kembali'),
          )),
        if (_step > 0) const SizedBox(width: 12),
        if (_step < 4)
          Expanded(child: FilledButton.icon(
            onPressed: _loading ? null : _nextStep,
            icon: const Icon(Icons.arrow_forward),
            label: Text(_step == 1 ? 'Cari Toko' : 'Lanjut'),
          )),
        if (_step == 4)
          Expanded(child: FilledButton.icon(
            onPressed: _loading ? null : _createBooking,
            icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),
            label: Text(_loading ? 'Membuat...' : 'Buat Booking'),
          )),
      ]),
    ),
  );
}

class BookingFormScreen extends ConsumerStatefulWidget {
  const BookingFormScreen({super.key, required this.storeId});
  final String storeId;
  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _complaint = TextEditingController();
  final _coupon = TextEditingController();
  final _address = TextEditingController();
  String _deviceType = 'android';
  String _delivery = 'walk_in';
  String _serviceType = 'screen_replacement';
  SparePart? _selectedPart;
  bool _loading = false;

  double get _estimate => _selectedPart?.price ?? 0;

  @override
  void initState() {
    super.initState();
    final user = ref.read(customerAuthProvider).valueOrNull;
    if (user != null) {
      _name.text = user.fullName;
      _phone.text = user.phoneNumber;
      _address.text = user.address ?? '';
    }
  }

  Future<void> _selectPart(List<SparePart> parts) async {
    final part = await showModalBottomSheet<SparePart>(
      context: context,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        children: parts
            .map((part) => ListTile(
                  enabled: part.availableQty > 0,
                  title: Text(part.partName),
                  subtitle: Text('${part.availableQty} tersedia'),
                  trailing: Text(rupiah(part.price)),
                  onTap: part.availableQty <= 0
                      ? null
                      : () => Navigator.pop(context, part),
                ))
            .toList(),
      ),
    );
    if (part != null) setState(() => _selectedPart = part);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final req = CreateOrderRequest(
        storeId: widget.storeId,
        fullName: _name.text,
        phoneNumber: normalizePhone(_phone.text),
        deviceType: _deviceType,
        brand: _brand.text,
        deviceModel: _model.text,
        deliveryMethod: _delivery,
        deliveryAddress: _delivery == 'courier_pickup' ? _address.text : null,
        couponCode: _coupon.text,
        items: [
          CreateOrderItemInput(
              serviceType: _serviceType,
              complaint: _complaint.text,
              sparepartId: _selectedPart?.id,
              price: _estimate)
        ],
      );
      final result = await ref.read(orderRepositoryProvider).createOrder(req);
      if (!mounted) return;
      context.go('/booking-success/${result.orderNumber}',
          extra: result.isNewCustomer);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spareparts =
        ref.watch(sparepartsProvider(widget.storeId)).valueOrNull ??
            const <SparePart>[];
    return CustomerScaffold(
      title: 'Buat Order',
      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(left: 32),
        child: FilledButton.icon(
            onPressed: _loading ? null : _submit,
            icon: const Icon(Icons.check),
            label: Text(_loading
                ? 'Membuat order...'
                : 'Estimasi ${rupiah(_estimate)} - Buat Order')),
      ),
      child: Form(
        key: _form,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              const SectionTitle('Info Pelanggan'),
              TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                      labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                  validator: _required),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Nomor HP', border: OutlineInputBorder()),
                  validator: _required),
              const SectionTitle('Info Perangkat'),
              SegmentedButton(
                  selected: {
                    _deviceType
                  },
                  segments: const [
                    ButtonSegment(value: 'android', label: Text('Android')),
                    ButtonSegment(value: 'ios', label: Text('iOS'))
                  ],
                  onSelectionChanged: (v) =>
                      setState(() => _deviceType = v.first)),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _brand,
                  decoration: const InputDecoration(
                      labelText: 'Brand', border: OutlineInputBorder()),
                  validator: _required),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _model,
                  decoration: const InputDecoration(
                      labelText: 'Model Device', border: OutlineInputBorder()),
                  validator: _required),
              const SectionTitle('Kerusakan'),
              DropdownButtonFormField(
                  value: _serviceType,
                  decoration: const InputDecoration(
                      labelText: 'Jenis Servis', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(
                        value: 'screen_replacement', child: Text('Layar')),
                    DropdownMenuItem(
                        value: 'battery_replacement', child: Text('Baterai')),
                    DropdownMenuItem(
                        value: 'charging_port', child: Text('Port')),
                    DropdownMenuItem(value: 'camera', child: Text('Kamera')),
                    DropdownMenuItem(value: 'other', child: Text('Lainnya')),
                  ],
                  onChanged: (v) => setState(() => _serviceType = v!)),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _complaint,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                      labelText: 'Deskripsi kerusakan',
                      border: OutlineInputBorder()),
                  validator: (v) => v == null || v.length < 10
                      ? 'Minimal 10 karakter.'
                      : null),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed:
                      spareparts.isEmpty ? null : () => _selectPart(spareparts),
                  icon: const Icon(Icons.inventory),
                  label: Text(_selectedPart?.partName ?? 'Pilih Sparepart')),
              const SectionTitle('Pengiriman'),
              SegmentedButton(
                  selected: {
                    _delivery
                  },
                  segments: const [
                    ButtonSegment(
                        value: 'walk_in', label: Text('Antar Sendiri')),
                    ButtonSegment(
                        value: 'courier_pickup', label: Text('Pickup Kurir'))
                  ],
                  onSelectionChanged: (v) =>
                      setState(() => _delivery = v.first)),
              if (_delivery == 'courier_pickup') ...[
                const SizedBox(height: 12),
                TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(
                        labelText: 'Alamat Pickup',
                        border: OutlineInputBorder()),
                    validator: _required),
              ],
              const SizedBox(height: 12),
              TextFormField(
                  controller: _coupon,
                  decoration: const InputDecoration(
                      labelText: 'Kode Kupon (opsional)',
                      border: OutlineInputBorder())),
            ]),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Wajib diisi.' : null;
}

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen(
      {super.key, required this.orderNumber, required this.isNewCustomer});
  final String orderNumber;
  final bool isNewCustomer;
  @override
  Widget build(BuildContext context) => CustomerScaffold(
        title: 'Order Berhasil',
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const Icon(Icons.check_circle, size: 84, color: Colors.green),
          const SizedBox(height: 16),
          Text('Order berhasil dibuat!',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SelectableText(orderNumber, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Text('Admin toko akan segera mengkonfirmasi perangkatmu.',
              textAlign: TextAlign.center),
          if (isNewCustomer)
            const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Card(
                    child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                            'Cek WhatsApp kamu. Admin toko akan mengirimkan informasi akun ServisGadget.')))),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: () => context.go('/orders'),
              child: const Text('Lihat Pesanan Saya')),
          OutlinedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Kembali ke Beranda')),
        ]),
      );
}

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});
  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  @override
  Widget build(BuildContext context) => const CustomerScaffold(
        title: 'Pesanan Saya',
        child: DefaultTabController(
          length: 3,
          child: Column(children: [
            TabBar(tabs: [
              Tab(text: 'Aktif'),
              Tab(text: 'Selesai'),
              Tab(text: 'Dibatalkan')
            ]),
            Expanded(
                child: TabBarView(children: [
              _OrderTab('active'),
              _OrderTab('completed'),
              _OrderTab('cancelled')
            ])),
          ]),
        ),
      );
}

class _OrderTab extends ConsumerWidget {
  const _OrderTab(this.group);
  final String group;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(customerOrdersProvider(group));
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(customerOrdersProvider(group)),
      child: AsyncPage(
          value: orders,
          builder: (items) => items.isEmpty
              ? const EmptyMessage('Tidak ada pesanan.')
              : ListView(
                  children: items
                      .map((order) => OrderCard(
                          order: order,
                          onTap: () => context.push('/orders/${order.id}')))
                      .toList())),
    );
  }
}

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderValue = ref.watch(orderDetailProvider(orderId));
    return CustomerScaffold(
      title: 'Detail Pesanan',
      child: AsyncPage(
        value: orderValue,
        builder: (order) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(orderDetailProvider(orderId)),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              Expanded(
                  child: SelectableText(order.orderNumber,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800))),
              StatusPill(order.status)
            ]),
            const SizedBox(height: 16),
            _InfoCard(title: 'Perangkat', rows: {
              'Brand': order.brand,
              'Model': order.deviceModel,
              'Jenis': order.deviceType,
              'Pengiriman': order.deliveryMethod,
              if (order.deliveryAddress != null)
                'Alamat': order.deliveryAddress!
            }),
            _InfoCard(title: 'Toko', rows: {
              'Nama': order.storeName ?? '-',
              'Alamat': order.storeAddress ?? '-',
              'Telepon': order.storePhone ?? '-'
            }),
            _InfoCard(title: 'Harga', rows: {
              'Estimasi': rupiah(order.totalEstimasi),
              if (order.discountAmount > 0)
                'Diskon': '-${rupiah(order.discountAmount)}',
              if (order.finalPrice != null) 'Final': rupiah(order.finalPrice!)
            }),
            const SectionTitle('Item Order'),
            ...order.items.map((item) => ListTile(
                title: Text(item.serviceType),
                subtitle: Text(item.complaint),
                trailing: Text(rupiah(item.finalItemPrice ?? item.itemPrice)))),
            if (order.slaDeadline != null)
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                          'Batas waktu: ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(order.slaDeadline!)}'))),
            if (order.status == OrderStatus.waitingApproval)
              DiagnosisApprovalCard(order: order),
            const SectionTitle('Tracking', action: null),
            OrderStatusTimeline(entries: order.tracking.take(3).toList()),
            TextButton(
                onPressed: () => context.push('/orders/$orderId/tracking'),
                child: const Text('Lihat Semua Tracking')),
            const SectionTitle('Pembayaran'),
            if (order.payments.isEmpty)
              const Text('Belum ada pembayaran.')
            else
              ...order.payments.map((p) => ListTile(
                  title: Text(rupiah(p.amount)),
                  subtitle: Text('${p.paymentMethod} - ${p.status}'))),
            _OrderActions(order: order),
          ]),
        ),
      ),
    );
  }
}

class DiagnosisApprovalCard extends ConsumerStatefulWidget {
  const DiagnosisApprovalCard({super.key, required this.order});
  final CustomerOrder order;
  @override
  ConsumerState<DiagnosisApprovalCard> createState() =>
      _DiagnosisApprovalCardState();
}

class _DiagnosisApprovalCardState extends ConsumerState<DiagnosisApprovalCard> {
  bool _loading = false;
  Future<void> _approve(bool approve) async {
    setState(() => _loading = true);
    try {
      if (approve) {
        await ref.read(orderRepositoryProvider).approveOrder(widget.order.id);
      } else {
        await ref.read(orderRepositoryProvider).rejectOrder(widget.order.id);
      }
      ref.invalidate(orderDetailProvider(widget.order.id));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Hasil Diagnosa',
                style: TextStyle(fontWeight: FontWeight.w900)),
            if (widget.order.diagnosisNote != null)
              Text(widget.order.diagnosisNote!),
            const SizedBox(height: 8),
            ...widget.order.items.map((item) => Text(
                '${item.serviceType}: ${rupiah(item.finalItemPrice ?? item.itemPrice)}')),
            if (widget.order.serviceFee != null)
              Text('Service Fee: ${rupiah(widget.order.serviceFee!)}'),
            const Divider(),
            Text('Total: ${rupiah(widget.order.finalPrice ?? 0)}',
                style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: FilledButton(
                      onPressed: _loading ? null : () => _approve(true),
                      child: const Text('Setuju'))),
              const SizedBox(width: 8),
              Expanded(
                  child: OutlinedButton(
                      onPressed: _loading ? null : () => _approve(false),
                      child: const Text('Tolak'))),
            ]),
          ]),
        ),
      );
}

class _OrderActions extends StatelessWidget {
  const _OrderActions({required this.order});
  final CustomerOrder order;
  @override
  Widget build(BuildContext context) => Column(children: [
        if (order.status == OrderStatus.waitingPayment)
          FilledButton.icon(
              onPressed: () => context.push('/orders/${order.id}/payment'),
              icon: const Icon(Icons.payment),
              label: const Text('Upload Bukti Bayar')),
        if (order.status == OrderStatus.completed && !order.reviewed)
          FilledButton.icon(
              onPressed: () => context.push('/orders/${order.id}/review'),
              icon: const Icon(Icons.star),
              label: const Text('Beri Ulasan')),
        if (order.status == OrderStatus.completed &&
            order.warrantyExpiredAt != null &&
            DateTime.now().isBefore(order.warrantyExpiredAt!))
          OutlinedButton.icon(
              onPressed: () =>
                  context.push('/orders/${order.id}/warranty-claim'),
              icon: const Icon(Icons.shield),
              label: const Text('Klaim Garansi')),
      ]);
}

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key, required this.orderId});
  final String orderId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(orderTrackingProvider(orderId));
    return CustomerScaffold(
      title: 'Tracking',
      child: tracking.when(
        data: (order) => ListView(padding: const EdgeInsets.all(16), children: [
          OrderStatusTimeline(entries: order.tracking),
          const SizedBox(height: 12),
          Text(
              'Diperbarui: ${DateFormat('HH:mm', 'id_ID').format(DateTime.now())}',
              textAlign: TextAlign.center),
        ]),
        loading: () => const SkeletonList(),
        error: (error, _) => Center(child: Text(parseApiError(error))),
      ),
    );
  }
}

class PaymentUploadScreen extends ConsumerStatefulWidget {
  const PaymentUploadScreen({super.key, required this.orderId});
  final String orderId;
  @override
  ConsumerState<PaymentUploadScreen> createState() =>
      _PaymentUploadScreenState();
}

class _PaymentUploadScreenState extends ConsumerState<PaymentUploadScreen> {
  final _amount = TextEditingController();
  String _method = 'transfer_bank';
  String _type = 'final_payment';
  XFile? _file;
  double _progress = 0;
  bool _loading = false;

  Future<void> _submit(CustomerOrder order) async {
    final amount =
        double.tryParse(_amount.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    if (amount <= 0) return;
    if (_method == 'transfer_bank' && _file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bukti transfer wajib diunggah.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final proofUrl = _file == null
          ? null
          : await ref.read(uploadRepositoryProvider).uploadFile(
              _file!, 'payments', (p) => setState(() => _progress = p));
      await ref.read(paymentRepositoryProvider).createPayment(
          orderId: order.id,
          amount: amount,
          method: _method,
          type: _type,
          proofUrl: proofUrl);
      ref.invalidate(orderDetailProvider(order.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Pembayaran dikirim, menunggu konfirmasi toko.')));
        context.pop();
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderValue = ref.watch(orderDetailProvider(widget.orderId));
    return CustomerScaffold(
      title: 'Pembayaran',
      child: AsyncPage(
        value: orderValue,
        builder: (order) {
          final confirmed = order.payments
              .where((p) => p.status == 'confirmed')
              .fold<double>(0, (sum, p) => sum + p.amount);
          final due = (order.finalPrice ?? order.totalEstimasi) - confirmed;
          if (_amount.text.isEmpty)
            _amount.text = due.clamp(0, double.infinity).toStringAsFixed(0);
          return ListView(padding: const EdgeInsets.all(16), children: [
            _InfoCard(title: 'Tagihan', rows: {
              'Order': order.orderNumber,
              'Final': rupiah(order.finalPrice ?? order.totalEstimasi),
              'Sudah Bayar': rupiah(confirmed),
              'Sisa': rupiah(due)
            }),
            DropdownButtonFormField(
                initialValue: _method,
                decoration:
                    const InputDecoration(labelText: 'Metode Pembayaran'),
                items: const [
                  DropdownMenuItem(
                      value: 'transfer_bank', child: Text('Transfer Bank')),
                  DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                  DropdownMenuItem(value: 'cash', child: Text('Tunai')),
                  DropdownMenuItem(value: 'ewallet', child: Text('E-Wallet')),
                ],
                onChanged: (v) => setState(() => _method = v!)),
            DropdownButtonFormField(
                initialValue: _type,
                decoration:
                    const InputDecoration(labelText: 'Jenis Pembayaran'),
                items: const [
                  DropdownMenuItem(value: 'deposit', child: Text('Uang Muka')),
                  DropdownMenuItem(
                      value: 'final_payment', child: Text('Pelunasan Final')),
                ],
                onChanged: (v) => setState(() => _type = v!)),
            TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nominal')),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: () async => setState(() => _file = null),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus Foto')),
            OutlinedButton.icon(
                onPressed: () async {
                  final picked = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 72,
                      maxWidth: 1600);
                  if (picked != null) setState(() => _file = picked);
                },
                icon: const Icon(Icons.image),
                label: Text(_file?.name ?? 'Ambil dari Galeri')),
            if (_file != null) Text('Dipilih: ${_file!.name}'),
            if (_progress > 0 && _progress < 1)
              LinearProgressIndicator(value: _progress),
            const SizedBox(height: 20),
            FilledButton(
                onPressed: _loading ? null : () => _submit(order),
                child: Text(_loading ? 'Mengirim...' : 'Kirim Pembayaran')),
          ]);
        },
      ),
    );
  }
}

class ReviewFormScreen extends ConsumerStatefulWidget {
  const ReviewFormScreen({super.key, required this.orderId});
  final String orderId;
  @override
  ConsumerState<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends ConsumerState<ReviewFormScreen> {
  final _comment = TextEditingController();
  int _rating = 5;
  bool _loading = false;
  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final result = await ref.read(reviewRepositoryProvider).createReview(
          orderId: widget.orderId, rating: _rating, comment: _comment.text);
      ref.invalidate(orderDetailProvider(widget.orderId));
      if (mounted) context.go('/review-success', extra: result);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => CustomerScaffold(
        title: 'Beri Ulasan',
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  5,
                  (index) => IconButton(
                      iconSize: 38,
                      onPressed: () => setState(() => _rating = index + 1),
                      icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber)))),
          Text(
              [
                '',
                'Sangat Buruk',
                'Buruk',
                'Biasa',
                'Bagus',
                'Sangat Bagus'
              ][_rating],
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextField(
              controller: _comment,
              maxLength: 500,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                  labelText: 'Komentar', border: OutlineInputBorder())),
          FilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'Mengirim...' : 'Kirim Ulasan')),
        ]),
      );
}

class ReviewSuccessScreen extends StatelessWidget {
  const ReviewSuccessScreen({super.key, required this.result});
  final ReviewResult result;
  @override
  Widget build(BuildContext context) => CustomerScaffold(
        title: 'Ulasan Berhasil',
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const Icon(Icons.celebration, size: 80, color: Colors.orange),
          Text('Ulasan berhasil dikirim!',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          if (result.coupon != null) CouponRewardBanner(coupon: result.coupon!),
          FilledButton(
              onPressed: () => context.go('/coupons'),
              child: const Text('Lihat Kupon Saya')),
          OutlinedButton(
              onPressed: () => context.go('/orders'),
              child: const Text('Kembali ke Pesanan')),
        ]),
      );
}

class WarrantyClaimScreen extends ConsumerStatefulWidget {
  const WarrantyClaimScreen({super.key, required this.orderId});
  final String orderId;
  @override
  ConsumerState<WarrantyClaimScreen> createState() =>
      _WarrantyClaimScreenState();
}

class _WarrantyClaimScreenState extends ConsumerState<WarrantyClaimScreen> {
  final _description = TextEditingController();
  String _type = 'warranty_claim';
  final _files = <XFile>[];
  bool _loading = false;

  Future<void> _submit() async {
    if (_description.text.length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deskripsi minimal 20 karakter.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final urls = <String>[];
      for (final file in _files) {
        urls.add(await ref
            .read(uploadRepositoryProvider)
            .uploadFile(file, 'evidence', null));
      }
      await ref.read(disputeRepositoryProvider).createDispute(
          orderId: widget.orderId,
          disputeType: _type,
          description: _description.text,
          evidenceUrls: urls);
      ref.invalidate(orderDetailProvider(widget.orderId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Klaim diterima. Admin toko akan merespons dalam 24 jam.')));
        context.pop();
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderDetailProvider(widget.orderId));
    return CustomerScaffold(
      title: 'Klaim Garansi',
      child: AsyncPage(
          value: order,
          builder: (data) {
            if (data.warrantyExpiredAt == null ||
                DateTime.now().isAfter(data.warrantyExpiredAt!)) {
              return EmptyMessage(
                  'Garansi sudah berakhir pada ${shortDate(data.warrantyExpiredAt)}.');
            }
            return ListView(padding: const EdgeInsets.all(16), children: [
              Text('Garansi aktif s/d ${shortDate(data.warrantyExpiredAt)}'),
              DropdownButtonFormField(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Jenis Masalah'),
                  items: const [
                    DropdownMenuItem(
                        value: 'warranty_claim', child: Text('Klaim Garansi')),
                    DropdownMenuItem(
                        value: 'service_quality',
                        child: Text('Kualitas Servis')),
                    DropdownMenuItem(
                        value: 'wrong_diagnosis',
                        child: Text('Diagnosa Salah')),
                    DropdownMenuItem(value: 'other', child: Text('Lainnya')),
                  ],
                  onChanged: (v) => setState(() => _type = v!)),
              TextField(
                  controller: _description,
                  minLines: 4,
                  maxLines: 7,
                  decoration: const InputDecoration(
                      labelText: 'Deskripsi Masalah',
                      border: OutlineInputBorder())),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed: _files.length >= 5
                      ? null
                      : () async {
                          final picked = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 72,
                              maxWidth: 1600);
                          if (picked != null)
                            setState(() => _files.add(picked));
                        },
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Tambah Foto')),
              Wrap(
                  spacing: 8,
                  children: _files
                      .map((file) => InputChip(
                          label: Text(file.name),
                          onDeleted: () => setState(() => _files.remove(file))))
                      .toList()),
              const SizedBox(height: 20),
              FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: Text(_loading ? 'Mengirim...' : 'Kirim Klaim')),
            ]);
          }),
    );
  }
}

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
      await ref
          .read(customerAuthProvider.notifier)
          .updateProfile(fullName: _name.text, address: _address.text);
      setState(() => _dirty = false);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(parseApiError(error))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(customerAuthProvider).valueOrNull;
    if (user != null && !_dirty && _name.text.isEmpty) {
      _name.text = user.fullName;
      _address.text = user.address ?? '';
    }
    return CustomerScaffold(
      title: 'Profil',
      child: ListView(padding: const EdgeInsets.all(16), children: [
        CircleAvatar(
            radius: 44,
            child: Text((user?.fullName.isNotEmpty ?? false)
                ? user!.fullName[0]
                : 'S')),
        const SizedBox(height: 16),
        TextFormField(
            controller: _name,
            decoration: const InputDecoration(
                labelText: 'Nama Lengkap', border: OutlineInputBorder()),
            onChanged: (_) => setState(() => _dirty = true)),
        const SizedBox(height: 12),
        TextFormField(
            initialValue: user?.phoneNumber ?? '-',
            readOnly: true,
            decoration: const InputDecoration(
                labelText: 'Nomor HP (tidak bisa diubah)',
                border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextFormField(
            controller: _address,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
                labelText: 'Alamat', border: OutlineInputBorder()),
            onChanged: (_) => setState(() => _dirty = true)),
        if (_dirty)
          FilledButton(
              onPressed: _loading ? null : _save, child: const Text('Simpan')),
        const Divider(),
        ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Pesanan Saya'),
            onTap: () => context.push('/orders')),
        ListTile(
            leading: const Icon(Icons.local_offer),
            title: const Text('Kupon Saya'),
            onTap: () => context.push('/coupons')),
        ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Preferensi Notifikasi'),
            onTap: () => context.push('/notification-preferences')),
        ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Ganti Password'),
            onTap: () => context.push('/change-password')),
        ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Sesi Login'),
            onTap: () => context.push('/sessions')),
        ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () async {
              await ref.read(customerAuthProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            }),
      ]),
    );
  }
}

class SimpleListScreens {
  const SimpleListScreens._();
}

class CouponsScreen extends ConsumerWidget {
  const CouponsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => CustomerScaffold(
        title: 'Kupon Saya',
        child: AsyncPage(
            value: ref.watch(couponsProvider),
            builder: (items) => items.isEmpty
                ? const EmptyMessage('Belum ada kupon.')
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: items
                        .map((coupon) => CouponRewardBanner(coupon: coupon))
                        .toList())),
      );
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => CustomerScaffold(
        title: 'Notifikasi',
        child: AsyncPage(
            value: ref.watch(notificationsProvider),
            builder: (items) => items.isEmpty
                ? const EmptyMessage('Belum ada notifikasi.')
                : ListView(
                    children: items
                        .map((item) => ListTile(
                            leading: Icon(item.isRead
                                ? Icons.mark_email_read
                                : Icons.mark_email_unread),
                            title: Text(item.title),
                            subtitle: Text(item.message),
                            onTap: () => context.push(
                                '/notifications/${item.id}',
                                extra: item)))
                        .toList())),
      );
}

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key, this.item});
  final NotificationItem? item;
  @override
  Widget build(BuildContext context) => CustomerScaffold(
      title: 'Detail Notifikasi',
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: item == null
              ? const EmptyMessage('Notifikasi tidak ditemukan.')
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item!.title,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(item!.message)
                ])));
}

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(notificationPreferenceProvider);
    return CustomerScaffold(
      title: 'Preferensi Notifikasi',
      child: enabled.when(
        data: (value) => SwitchListTile(
            title: const Text('Notifikasi WhatsApp dan aplikasi'),
            value: value,
            onChanged: (next) async {
              await ref
                  .read(customerSessionProvider)
                  .saveNotificationPreference(next);
              ref.invalidate(notificationPreferenceProvider);
            }),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const EmptyMessage('Preferensi belum bisa dimuat.'),
      ),
    );
  }
}

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});
  @override
  Widget build(BuildContext context) => const CustomerScaffold(
        title: 'Sesi Login',
        child: ListTile(
            leading: Icon(Icons.phone_android),
            title: Text('Perangkat ini'),
            subtitle: Text(
                'Sesi aktif saat ini. Logout dari profil untuk menghapus sesi.')),
      );
}

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});
  @override
  Widget build(BuildContext context) => CustomerScaffold(
      title: 'Keamanan',
      child: ListView(children: [
        ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Ganti Password'),
            onTap: () => context.push('/change-password')),
        const ListTile(
            leading: Icon(Icons.verified_user),
            title: Text('Nomor HP hanya dapat diubah melalui support.'))
      ]));
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});
  final String title;
  final Map<String, String> rows;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            ...rows.entries.map((row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 94, child: Text(row.key)),
                      Expanded(
                          child: Text(row.value,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)))
                    ]))),
          ]),
        ),
      );
}
