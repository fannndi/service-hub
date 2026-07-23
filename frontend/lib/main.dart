import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'ui/theme/app_theme.dart';
import 'features/customer/presentation/routing/customer_router.dart';
import 'features/store_admin/presentation/routing/store_admin_router.dart';
import 'features/platform_admin/presentation/routing/platform_admin_router.dart';
import 'core/supabase_service.dart';
import 'core/supabase_config.dart';
import 'core/l10n/app_localizations.dart';
import 'core/l10n/l10n_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  // Global error handler (ECC pattern #8: error handling)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  await SupabaseService.instance.init();
  runApp(const ProviderScope(child: ServisGadgetApp()));
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRefresh = _AuthRefresh();
  ref.onDispose(authRefresh.dispose);
  return GoRouter(
    initialLocation: SupabaseConfig.isConfigured ? '/welcome' : '/splash',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final user = SupabaseService.instance.user;
      final role = SupabaseService.instance.role;
      final meta = user?.userMetadata;
      final isFirstLogin = meta?['is_first_login'] as bool? ?? false;
      final loc = state.matchedLocation;
      final publicRoutes = {
        '/welcome',
        '/login',
        '/store-login',
        '/store-register',
        '/settings'
      };

      if (loc.startsWith('/guest/') || loc.startsWith('/booking-success/'))
        return null;
      if (loc == '/splash') return null;

      // Logged-in users redirected away from public entry points
      if (user != null && publicRoutes.contains(loc)) {
        if (role == 'platform_admin') return '/admin/dashboard';
        if (role == 'store_admin') return '/store/dashboard';
        if (role == 'customer') return '/home';
        return null;
      }

      if (loc.startsWith('/admin/')) {
        if (role != 'platform_admin' && loc != '/admin/login')
          return '/admin/login';
        if (role == 'platform_admin' && loc == '/admin/login')
          return '/admin/dashboard';
        return null;
      }

      if (loc.startsWith('/store/')) {
        if (role != 'store_admin' && loc != '/store-login')
          return '/store-login';
        if (role == 'store_admin' &&
            isFirstLogin &&
            loc != '/store/change-password') return '/store/change-password';
        if (role == 'store_admin' && loc == '/store-login')
          return '/store/dashboard';
        return null;
      }

      if (role == 'store_admin') {
        if (isFirstLogin && loc != '/store/change-password')
          return '/store/change-password';
        if (loc == '/store-login' || publicRoutes.contains(loc))
          return '/store/dashboard';
        return null;
      }

      if (role == 'customer') {
        if (isFirstLogin && loc != '/change-password')
          return '/change-password';
        if (publicRoutes.contains(loc)) return '/home';
        return null;
      }

      if (!publicRoutes.contains(loc) &&
          !loc.startsWith('/stores') &&
          !loc.startsWith('/booking/') &&
          !loc.startsWith('/service')) {
        return '/welcome';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const _InitSplash()),
      ...customerRoutes,
      ...storeAdminRoutes,
      ...adminRoutes,
    ],
  );
});

class _AuthRefresh extends ChangeNotifier {
  late final StreamSubscription _sub;
  _AuthRefresh() {
    _sub = SupabaseService.instance.onAuthStateChange
        .listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class _InitSplash extends ConsumerStatefulWidget {
  const _InitSplash();

  @override
  ConsumerState<_InitSplash> createState() => _InitSplashState();
}

class _InitSplashState extends ConsumerState<_InitSplash> {
  String _status = 'Memeriksa koneksi...';

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      if (!SupabaseConfig.isConfigured) {
        setState(() => _status = 'Supabase belum dikonfigurasi');
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        context.go('/welcome');
        return;
      }

      setState(() => _status = 'Memeriksa sesi...');
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      setState(() => _status = 'Siap ✓');
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      final role = SupabaseService.instance.role;
      if (role == 'platform_admin') {
        context.go('/admin/dashboard');
      } else if (role == 'store_admin') {
        context.go('/store/dashboard');
      } else if (role == 'customer') {
        context.go('/home');
      } else {
        context.go('/welcome');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Gagal memulai');
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.surfaceContainerHighest, scheme.surface],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.handyman_rounded, size: 64, color: scheme.primary),
              const SizedBox(height: 24),
              Text(context.l10n.appName, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 16),
              Text(
                _status,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _status.contains('✓')
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              if (!_status.contains('✓'))
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: scheme.primary,
                  ),
                ),
            ],
          ),
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
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'Service Me',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('id'), Locale('en')],
      builder: (context, widget) {
        ErrorWidget.builder = (details) => Material(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Theme.of(context).colorScheme.error),
                      const SizedBox(height: 16),
                      Text('Terjadi kesalahan',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(details.exceptionAsString(),
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            );
        return widget!;
      },
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
