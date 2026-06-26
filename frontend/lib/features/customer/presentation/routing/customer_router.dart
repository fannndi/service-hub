import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/customer_models.dart';
import '../screens/welcome_screen.dart';
import '../screens/login_screen.dart';
import '../screens/service_flow_screen.dart';
import '../screens/change_password_screen.dart';
import '../screens/home_screen.dart';
import '../screens/store_list_screen.dart';
import '../screens/store_detail_screen.dart';
import '../screens/booking_form_screen.dart';
import '../screens/booking_success_screen.dart';
import '../screens/guest_booking_success_screen.dart';
import '../screens/guest_tracking_screen.dart';
import '../screens/order_list_screen.dart';
import '../screens/order_detail_screen.dart';
import '../screens/tracking_screen.dart';
import '../screens/payment_upload_screen.dart';
import '../screens/review_form_screen.dart';
import '../screens/warranty_claim_screen.dart';
import '../screens/review_success_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sessions_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/coupons_screen.dart';
import '../screens/security_screen.dart';

final customerRoutes = <RouteBase>[
  GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
  GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
  GoRoute(path: '/service', builder: (_, __) => const ServiceFlowScreen()),
  GoRoute(
      path: '/change-password',
      builder: (_, __) => const ChangePasswordScreen()),
  GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
  GoRoute(path: '/stores', builder: (_, __) => const StoreListScreen()),
  GoRoute(
      path: '/stores/:id',
      builder: (_, state) =>
          StoreDetailScreen(storeId: state.pathParameters['id']!)),
  GoRoute(
      path: '/booking/:storeId',
      builder: (_, state) =>
          BookingFormScreen(storeId: state.pathParameters['storeId']!)),
  GoRoute(
    path: '/booking-success/:orderNumber',
    builder: (_, state) {
      final extra = state.extra;
      if (extra is Map && extra['isGuest'] == true) {
        return GuestBookingSuccessScreen(
          orderNumber: state.pathParameters['orderNumber']!,
        );
      }
      return BookingSuccessScreen(
        orderNumber: state.pathParameters['orderNumber']!,
        isNewCustomer: extra is bool ? extra : (extra is Map ? (extra['isNewCustomer'] as bool? ?? false) : false),
      );
    },
  ),
  GoRoute(
    path: '/guest/track',
    builder: (_, __) => const GuestTrackingScreen(),
  ),
  GoRoute(
    path: '/guest/track/:orderNumber',
    builder: (_, state) => GuestTrackingScreen(
      initialOrderNumber: state.pathParameters['orderNumber'],
    ),
  ),
  GoRoute(path: '/orders', builder: (_, __) => const OrderListScreen()),
  GoRoute(
      path: '/orders/:id',
      builder: (_, state) =>
          OrderDetailScreen(orderId: state.pathParameters['id']!)),
  GoRoute(
      path: '/orders/:id/tracking',
      builder: (_, state) =>
          TrackingScreen(orderId: state.pathParameters['id']!)),
  GoRoute(
      path: '/orders/:id/payment',
      builder: (_, state) =>
          PaymentUploadScreen(orderId: state.pathParameters['id']!)),
  GoRoute(
      path: '/orders/:id/review',
      builder: (_, state) =>
          ReviewFormScreen(orderId: state.pathParameters['id']!)),
  GoRoute(
      path: '/orders/:id/warranty-claim',
      builder: (_, state) =>
          WarrantyClaimScreen(orderId: state.pathParameters['id']!)),
  GoRoute(
      path: '/review-success',
      builder: (_, state) =>
          ReviewSuccessScreen(result: state.extra as ReviewResult)),
  GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
  GoRoute(path: '/sessions', builder: (_, __) => const SessionsScreen()),
  GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  GoRoute(
      path: '/notifications', builder: (_, __) => const NotificationsScreen()),
  GoRoute(
      path: '/notifications/:id',
      builder: (_, state) => _NotificationDetail(
          notification: state.extra as NotificationItem)),
  GoRoute(path: '/coupons', builder: (_, __) => const CouponsScreen()),
  GoRoute(path: '/security', builder: (_, __) => const SecurityScreen()),
  GoRoute(path: '/notification-preferences', builder: (_, __) => const NotificationsScreen()),
];

class _NotificationDetail extends StatelessWidget {
  const _NotificationDetail({required this.notification});
  final NotificationItem notification;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(notification.title)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(notification.message),
            const SizedBox(height: 12),
            Text(notification.createdAt.toLocal().toString().substring(0, 16),
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
}
