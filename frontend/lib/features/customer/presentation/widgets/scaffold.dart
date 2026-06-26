import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomerScaffold extends StatelessWidget {
  const CustomerScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = true,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...?actions,
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
        leading: showBackButton
            ? Builder(
                builder: (ctx) {
                  if (Navigator.of(ctx).canPop()) {
                    return IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              )
            : null,
        leadingWidth: showBackButton ? 56 : null,
      ),
      body: child,
      floatingActionButton: floatingActionButton,
    );
  }
}
