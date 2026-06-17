import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/app_config.dart';
import 'core/config/config_service.dart';
import 'features/customer/presentation/routing/customer_router.dart';
import 'features/store_admin/presentation/routing/store_admin_router.dart';
import 'features/platform_admin/presentation/routing/platform_admin_router.dart';
import 'features/customer/application/customer_providers.dart';
import 'features/store_admin/application/store_admin_providers.dart';
import 'features/platform_admin/application/platform_admin_providers.dart';
import 'features/maintenance/maintenance_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvironmentService.init();
  runApp(const ProviderScope(child: ServisGadgetApp()));
}
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AppRefresh(ref),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final publicRoutes = {'/splash', '/welcome', '/login', '/store-login', '/service', '/stores', '/maintenance'};

      final storeAuth = ref.read(storeAuthControllerProvider);
      final custAuth = ref.read(customerAuthProvider);
      final adminAuth = ref.read(adminAuthProvider);

      if (storeAuth.isLoading || custAuth.isLoading) return null;

      if (loc == '/maintenance') return null;

      if (loc.startsWith('/admin/')) {
        if (adminAuth.isLoading) return null;
        final adminUser = adminAuth.valueOrNull;
        if (adminUser == null && loc != '/admin/login') return '/admin/login';
        if (adminUser != null && loc == '/admin/login') return '/admin/dashboard';
        return null;
      }

      if (loc.startsWith('/store/')) {
        final storeUser = storeAuth.valueOrNull;
        if (storeUser == null && loc != '/store-login') return '/store-login';
        if (storeUser != null && storeUser.isFirstLogin && loc != '/store/change-password') return '/store/change-password';
        if (storeUser != null && loc == '/store-login') return '/store/dashboard';
        return null;
      }

      final storeUser = storeAuth.valueOrNull;
      final custUser = custAuth.valueOrNull;

      if (storeUser != null) {
        if (storeUser.isFirstLogin && loc != '/store/change-password') return '/store/change-password';
        if (loc == '/store-login' || publicRoutes.contains(loc)) return '/store/dashboard';
        return null;
      }

      if (custUser != null) {
        if (custUser.isFirstLogin && loc != '/change-password') return '/change-password';
        if (publicRoutes.contains(loc)) return '/home';
        return null;
      }

      if (!publicRoutes.contains(loc) && !loc.startsWith('/stores/') && !loc.startsWith('/booking/')) {
        return '/welcome';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const _InitSplash(),
      ),
      GoRoute(
        path: '/maintenance',
        builder: (_, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          return MaintenanceScreen(
            message: extras['message'] as String? ?? 'Sedang Maintenance',
            isOffline: extras['isOffline'] as bool? ?? false,
          );
        },
      ),
      ...customerRoutes,
      ...storeAdminRoutes,
      ...adminRoutes,
    ],
  );
});

class _AppRefresh extends ChangeNotifier {
  _AppRefresh(this.ref) {
    ref.listen(storeAuthControllerProvider, (_, __) => notifyListeners());
    ref.listen(customerAuthProvider, (_, __) => notifyListeners());
    ref.listen(adminAuthProvider, (_, __) => notifyListeners());
  }
  final Ref ref;
}

class _InitSplash extends StatefulWidget {
  const _InitSplash();

  @override
  State<_InitSplash> createState() => _InitSplashState();
}

class _InitSplashState extends State<_InitSplash> {
  String _status = 'Menghubungkan ke server...';

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      setState(() => _status = 'Memeriksa koneksi...');

      final config = await ConfigService.fetch();

      if (!mounted) return;

      if (config.maintenanceMode) {
        setState(() => _status = 'Sistem dalam perbaikan');
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        context.go('/maintenance', extra: {
          'message': config.maintenanceMessage,
          'isOffline': false,
        });
        return;
      }

      setState(() => _status = 'Terhubung ✓');
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;
      _checkAuth();
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Koneksi tidak ditemukan');
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      context.go('/maintenance', extra: {
        'message': 'Sedang Maintenance',
        'isOffline': true,
      });
    }
  }

  Future<void> _checkAuth() async {
    if (!mounted) return;

    try {
      final storeAuth = ref.read(storeAuthControllerProvider);
      if (storeAuth.valueOrNull != null) {
        if (!mounted) return;
        context.go('/store/dashboard');
        return;
      }
    } catch (_) {}

    try {
      final custAuth = ref.read(customerAuthProvider);
      if (custAuth.valueOrNull != null) {
        if (!mounted) return;
        context.go('/home');
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 120,
              errorBuilder: (_, __, ___) => const Icon(Icons.build, size: 80, color: Colors.teal),
            ),
            const SizedBox(height: 24),
            Text(
              'ServisGadget',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              _status,
              style: TextStyle(
                fontSize: 14,
                color: _status.contains('✓')
                    ? Colors.green
                    : _status.contains('tidak ditemukan') || _status.contains('perbaikan')
                        ? Colors.orange
                        : Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            if (!_status.contains('✓') && !_status.contains('tidak ditemukan') && !_status.contains('perbaikan'))
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class ServisGadgetApp extends ConsumerWidget {
  const ServisGadgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'ServisGadget',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.dark, useMaterial3: true),
      routerConfig: router,
    );
  }
}
