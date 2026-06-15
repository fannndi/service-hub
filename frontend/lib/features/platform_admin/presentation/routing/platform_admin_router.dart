import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/platform_admin_screens.dart';

final adminRoutes = <RouteBase>[
  GoRoute(path: '/admin/login', builder: (_, __) => const AdminLoginScreen()),
  GoRoute(path: '/admin/dashboard', builder: (_, __) => const AdminDashboardScreen()),
];
