import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/customer/presentation/routing/customer_router.dart';

void main() {
  runApp(const ProviderScope(child: ServisGadgetApp()));
}

class ServisGadgetApp extends ConsumerWidget {
  const ServisGadgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(customerRouterProvider);
    return MaterialApp.router(
      title: 'ServisGadget',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.dark, useMaterial3: true),
      routerConfig: router,
    );
  }
}
