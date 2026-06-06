import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/store_admin_providers.dart';
import '../../domain/store_admin_models.dart';
import '../screens/store_admin_screens.dart';

final storeAdminRoutes = <RouteBase>[
  GoRoute(path: '/login', builder: (_, __) => const StoreLoginScreen()),
  GoRoute(path: '/change-password', builder: (_, __) => const StoreChangePasswordScreen()),
  GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
  GoRoute(path: '/orders', builder: (_, __) => const OrderListScreen()),
  GoRoute(path: '/orders/:id', builder: (_, state) => OrderDetailScreen(orderId: state.pathParameters['id']!)),
  GoRoute(path: '/orders/:id/diagnosis', builder: (_, state) => DiagnosisScreen(orderId: state.pathParameters['id']!)),
  GoRoute(path: '/orders/:id/tracking', builder: (_, state) => TrackingScreen(orderId: state.pathParameters['id']!)),
  GoRoute(path: '/inventory', builder: (_, __) => const InventoryScreen()),
  GoRoute(path: '/inventory/new', builder: (_, __) => const SparepartFormScreen()),
  GoRoute(path: '/inventory/:id', builder: (_, state) => SparepartFormScreen(item: state.extra as Sparepart?)),
  GoRoute(path: '/customers', builder: (_, __) => const CustomersScreen()),
  GoRoute(path: '/payments', builder: (_, __) => const PaymentsScreen()),
  GoRoute(path: '/reviews', builder: (_, __) => const ReviewsScreen()),
  GoRoute(path: '/disputes', builder: (_, __) => const DisputesScreen()),
  GoRoute(path: '/disputes/:id', builder: (_, state) => DisputeDetailScreen(dispute: state.extra as DisputeCase)),
  GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
  GoRoute(path: '/settings', builder: (_, __) => const StoreSettingsScreen()),
  GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
];

final storeAdminRouterProvider = Provider<GoRouter>((ref) => GoRouter(
      initialLocation: '/dashboard',
      refreshListenable: _RouterRefresh(ref),
      redirect: (context, state) {
        final auth = ref.read(storeAuthControllerProvider);
        final session = auth.valueOrNull;
        final loc = state.matchedLocation;
        if (auth.isLoading) return null;
        if (session == null && loc != '/login') return '/login';
        if (session != null && session.isFirstLogin && loc != '/change-password') return '/change-password';
        if (session != null && loc == '/login') return '/dashboard';
        return null;
      },
      routes: storeAdminRoutes,
    ));

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this.ref) {
    ref.listen(storeAuthControllerProvider, (_, __) => notifyListeners());
  }
  final Ref ref;
}
