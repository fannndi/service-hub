import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/customer_providers.dart';

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
