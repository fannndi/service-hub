import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/customer/presentation/routing/customer_router.dart';
import 'features/store_admin/presentation/routing/store_admin_router.dart';
import 'features/customer/application/customer_providers.dart';
import 'features/store_admin/application/store_admin_providers.dart';

void main() {
  runApp(const ProviderScope(child: ServisGadgetApp()));
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const _RoleSplash(),
      ),
      ...customerRoutes,
      ...storeAdminRoutes,
    ],
  );
});

class _RoleSplash extends ConsumerStatefulWidget {
  const _RoleSplash();

  @override
  ConsumerState<_RoleSplash> createState() => _RoleSplashState();
}

class _RoleSplashState extends ConsumerState<_RoleSplash> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    try {
      final storeAuth = ref.read(storeAuthControllerProvider);
      if (storeAuth.valueOrNull != null) {
        if (!mounted) return;
        context.go('/dashboard');
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
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', width: 120, errorBuilder: (_, __, ___) => const Icon(Icons.build, size: 80, color: Colors.teal)),
            const SizedBox(height: 24),
            Text('ServisGadget', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
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
