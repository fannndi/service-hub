import 'package:go_router/go_router.dart';

import '../../domain/store_admin_models.dart';
import '../screens/store_login_screen.dart';
import '../screens/store_change_password_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/order_list_screen.dart';
import '../screens/order_detail_screen.dart';
import '../screens/diagnosis_screen.dart';
import '../screens/tracking_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/sparepart_form_screen.dart';
import '../screens/customers_screen.dart';
import '../screens/payments_screen.dart';
import '../screens/reviews_screen.dart';
import '../screens/disputes_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/store_settings_screen.dart';
import '../screens/analytics_screen.dart';

final storeAdminRoutes = <RouteBase>[
  GoRoute(path: '/store-login', builder: (_, __) => const StoreLoginScreen()),
  GoRoute(
      path: '/store/change-password',
      builder: (_, __) => const StoreChangePasswordScreen()),
  GoRoute(
      path: '/store/dashboard', builder: (_, __) => const DashboardScreen()),
  GoRoute(path: '/store/orders', builder: (_, __) => const OrderListScreen()),
  GoRoute(
      path: '/store/orders/:id',
      builder: (_, state) =>
          OrderDetailScreen(orderId: state.pathParameters['id'] ?? '')),
  GoRoute(
      path: '/store/orders/:id/diagnosis',
      builder: (_, state) =>
          DiagnosisScreen(orderId: state.pathParameters['id'] ?? '')),
  GoRoute(
      path: '/store/orders/:id/tracking',
      builder: (_, state) =>
          TrackingScreen(orderId: state.pathParameters['id'] ?? '')),
  GoRoute(
      path: '/store/inventory', builder: (_, __) => const InventoryScreen()),
  GoRoute(
      path: '/store/inventory/new',
      builder: (_, __) => const SparepartFormScreen()),
  GoRoute(
      path: '/store/inventory/:id',
      builder: (_, state) =>
          SparepartFormScreen(item: state.extra as Sparepart?)),
  GoRoute(
      path: '/store/customers', builder: (_, __) => const CustomersScreen()),
  GoRoute(path: '/store/payments', builder: (_, __) => const PaymentsScreen()),
  GoRoute(path: '/store/reviews', builder: (_, __) => const ReviewsScreen()),
  GoRoute(path: '/store/disputes', builder: (_, __) => const DisputesScreen()),
  GoRoute(
      path: '/store/disputes/:id',
      builder: (_, state) =>
          DisputeDetailScreen(dispute: state.extra as DisputeCase)),
  GoRoute(
      path: '/store/notifications',
      builder: (_, __) => const NotificationsScreen()),
  GoRoute(
      path: '/store/settings', builder: (_, __) => const StoreSettingsScreen()),
  GoRoute(
      path: '/store/analytics', builder: (_, __) => const AnalyticsScreen()),
];
