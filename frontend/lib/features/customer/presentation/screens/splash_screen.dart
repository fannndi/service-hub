import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../../domain/customer_models.dart';
import '../../domain/user_session.dart';
import '../../../../shared_widgets/error_state.dart';
import '../../../../shared_widgets/status_badge.dart';
import '../../../../shared_widgets/empty_state.dart';
import '../../../../shared_widgets/formatters.dart';
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
