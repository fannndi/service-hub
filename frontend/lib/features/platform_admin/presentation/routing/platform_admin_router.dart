import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/platform_admin_providers.dart';
import '../screens/platform_admin_screens.dart';

final adminRoutes = <RouteBase>[
  GoRoute(path: '/admin/login', builder: (_, __) => const AdminLoginScreen()),
  GoRoute(path: '/admin/dashboard', builder: (_, __) => const AdminDashboardScreen()),
];

final adminRouterProvider = Provider<GoRouter>((ref) => GoRouter(
      initialLocation: '/admin/login',
      refreshListenable: _AdminRefresh(ref),
      redirect: (context, state) {
        final auth = ref.read(adminAuthProvider);
        final session = auth.valueOrNull;
        final loc = state.matchedLocation;
        if (auth.isLoading) return null;
        if (session == null && loc != '/admin/login') return '/admin/login';
        if (session != null && loc == '/admin/login') return '/admin/dashboard';
        return null;
      },
      routes: adminRoutes,
    ));

class _AdminRefresh extends ChangeNotifier {
  _AdminRefresh(this.ref) {
    ref.listen(adminAuthProvider, (_, __) => notifyListeners());
  }
  final Ref ref;
}
