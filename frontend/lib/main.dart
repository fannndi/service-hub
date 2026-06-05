import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/store_admin/presentation/routing/store_admin_router.dart';

void main() {
  runApp(const ProviderScope(child: ServisGadgetApp()));
}

class ServisGadgetApp extends ConsumerWidget {
  const ServisGadgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(storeAdminRouterProvider);
    return MaterialApp.router(
      title: 'ServisGadget Store Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: Colors.indigo, brightness: Brightness.dark, useMaterial3: true),
      routerConfig: router,
    );
  }
}
