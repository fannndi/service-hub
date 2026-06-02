import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/demo_account.dart';
import 'auth/demo_auth_controller.dart';
import 'screens/customer_shell_screen.dart';
import 'screens/demo_login_screen.dart';
import 'screens/store_admin_shell_screen.dart';

void main() {
  runApp(const ProviderScope(child: ServisGadgetApp()));
}

class ServisGadgetApp extends ConsumerWidget {
  const ServisGadgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(demoAuthProvider);
    return MaterialApp(
      title: 'ServisGadget',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: switch (auth.account?.role) {
        DemoRole.customer => const CustomerShellScreen(),
        DemoRole.storeAdmin => const StoreAdminShellScreen(),
        null => const DemoLoginScreen(),
      },
    );
  }
}
