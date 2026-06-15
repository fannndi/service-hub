import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/customer_models.dart';
import '../screens/booking_form_screen.dart';

final customerRoutes = <RouteBase>[
  GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
  GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
  GoRoute(path: '/service', builder: (_, __) => const ServiceFlowScreen()),
  GoRoute(path: '/change-password', builder: (_, __) => const ChangePasswordScreen()),
  GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
  GoRoute(path: '/stores', builder: (_, __) => const StoreListScreen()),
  GoRoute(path: '/stores/:id', builder: (_, state) => StoreDetailScreen(storeId: state.pathParameters['id']!)),
  GoRoute(path: '/booking/:storeId', builder: (_, state) => BookingFormScreen(storeId: state.pathParameters['storeId']!)),
  GoRoute(
    path: '/booking-success/:orderNumber',
    builder: (_, state) => BookingSuccessScreen(
      orderNumber: state.pathParameters['orderNumber']!,
      isNewCustomer: state.extra as bool? ?? false,
    ),
  ),
  GoRoute(path: '/orders', builder: (_, __) => const OrderListScreen()),
  GoRoute(path: '/orders/:id', builder: (_, state) => OrderDetailScreen(orderId: state.pathParameters['id']!)),
  GoRoute(path: '/orders/:id/tracking', builder: (_, state) => TrackingScreen(orderId: state.pathParameters['id']!)),
  GoRoute(path: '/orders/:id/payment', builder: (_, state) => PaymentUploadScreen(orderId: state.pathParameters['id']!)),
  GoRoute(path: '/orders/:id/review', builder: (_, state) => ReviewFormScreen(orderId: state.pathParameters['id']!)),
  GoRoute(path: '/orders/:id/warranty-claim', builder: (_, state) => WarrantyClaimScreen(orderId: state.pathParameters['id']!)),
  GoRoute(path: '/review-success', builder: (_, state) => ReviewSuccessScreen(result: state.extra as ReviewResult)),
  GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
  GoRoute(path: '/sessions', builder: (_, __) => const SessionsScreen()),
  GoRoute(path: '/security', builder: (_, __) => const SecurityScreen()),
  GoRoute(path: '/coupons', builder: (_, __) => const CouponsScreen()),
  GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
  GoRoute(path: '/notifications/:id', builder: (_, state) => NotificationDetailScreen(item: state.extra as NotificationItem?)),
  GoRoute(path: '/notification-preferences', builder: (_, __) => const NotificationPreferencesScreen()),
];
