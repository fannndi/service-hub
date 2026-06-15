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

