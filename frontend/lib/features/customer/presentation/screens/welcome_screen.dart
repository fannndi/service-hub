import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../application/customer_providers.dart';
import '../../data/customer_repositories.dart';
import '../../domain/customer_models.dart';
import '../widgets/customer_widgets.dart';

class WelcomeScreen extends StatelessWidget {

}
      );
        ),
          ]),
            CircularProgressIndicator(),
            SizedBox(height: 24),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text('ServisGadget',
            SizedBox(height: 16),
            Icon(Icons.handyman, size: 64),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        body: Center(
  Widget build(BuildContext context) => const Scaffold(
  @override

  }
    }
      if (mounted) context.go('/login');
      await ref.read(customerSessionProvider).clearAll();
    } catch (_) {
      context.go(user.isFirstLogin ? '/change-password' : '/home');
      if (!mounted) return;
          await ref.read(customerAuthProvider.notifier).restoreSession();
      final user =
    try {
    }
      return;
      context.go('/login');
    if (token == null) {
    if (!mounted) return;
    final token = await ref.read(customerSessionProvider).readAccessToken();
    await Future<void>.delayed(const Duration(milliseconds: 600));
  Future<void> _checkAuth() async {

  }
    Future.microtask(_checkAuth);
    super.initState();
  void initState() {
  @override
class _SplashScreenState extends ConsumerState<SplashScreen> {

}
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
  @override

  const SplashScreen({super.key});
class SplashScreen extends ConsumerStatefulWidget {

import '../widgets/customer_widgets.dart';
import '../../domain/customer_models.dart';
import '../../data/customer_repositories.dart';
import '../../application/customer_providers.dart';

import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
}

}
  }
    );
      ),
        ),
          ),
            ),
              ),
                ],
                  const SizedBox(height: 32),
                  ),
                    ),
                      label: const Text('Admin'),
                      icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
                      onPressed: () => context.push('/admin/login'),
                    child: OutlinedButton.icon(
                    width: double.infinity,
                  SizedBox(
                  const SizedBox(height: 12),
                  ),
                    ],
                      ),
                        ),
                          label: const Text('Toko'),
                          icon: const Icon(Icons.store_outlined, size: 20),
                          onPressed: () => context.push('/store-login'),
                        child: OutlinedButton.icon(
                      Expanded(
                      const SizedBox(width: 12),
                      ),
                        ),
                          label: const Text('Pelanggan'),
                          icon: const Icon(Icons.person_outline, size: 20),
                          onPressed: () => context.push('/login'),
                        child: OutlinedButton.icon(
                      Expanded(
                    children: [
                  Row(
                  const SizedBox(height: 14),
                  ),
                    ),
                          style: TextStyle(fontSize: 16)),
                      label: const Text('Service Now',
                      icon: const Icon(Icons.build, size: 22),
                      onPressed: () => context.go('/service'),
                    child: FilledButton.icon(
                    height: 52,
                    width: double.infinity,
                  SizedBox(
                  const SizedBox(height: 48),
                  ),
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    style: theme.textTheme.bodyLarge
                    'Servis smartphone cepat & terpercaya',
                  Text(
                  const SizedBox(height: 8),
                  ),
                        ?.copyWith(fontWeight: FontWeight.w800),
                    style: theme.textTheme.headlineLarge
                    'ServisGadget',
                  Text(
                  const SizedBox(height: 16),
                  Icon(Icons.build, size: 80, color: theme.colorScheme.primary),
                children: [
                mainAxisSize: MainAxisSize.min,
              child: Column(
              padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Padding(
            constraints: const BoxConstraints(maxWidth: 420),
          child: ConstrainedBox(
        child: Center(
      body: SafeArea(
    return Scaffold(
    final theme = Theme.of(context);
  Widget build(BuildContext context) {
  @override

  const WelcomeScreen({super.key});
class WelcomeScreen extends StatelessWidget {

}
      );
        ),
          ]),
            CircularProgressIndicator(),
            SizedBox(height: 24),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text('ServisGadget',
            SizedBox(height: 16),
            Icon(Icons.handyman, size: 64),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        body: Center(
  Widget build(BuildContext context) => const Scaffold(
  @override

  }
    }
      if (mounted) context.go('/login');
      await ref.read(customerSessionProvider).clearAll();
    } catch (_) {
      context.go(user.isFirstLogin ? '/change-password' : '/home');
      if (!mounted) return;
          await ref.read(customerAuthProvider.notifier).restoreSession();
      final user =
    try {
    }
      return;
      context.go('/login');
    if (token == null) {
    if (!mounted) return;
    final token = await ref.read(customerSessionProvider).readAccessToken();
    await Future<void>.delayed(const Duration(milliseconds: 600));
  Future<void> _checkAuth() async {

  }
    Future.microtask(_checkAuth);
    super.initState();
  void initState() {
  @override
class _SplashScreenState extends ConsumerState<SplashScreen> {

}
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
  @override

  const SplashScreen({super.key});
class SplashScreen extends ConsumerStatefulWidget {

import '../widgets/customer_widgets.dart';
import '../../domain/customer_models.dart';
import '../../data/customer_repositories.dart';
import '../../application/customer_providers.dart';

import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
}

