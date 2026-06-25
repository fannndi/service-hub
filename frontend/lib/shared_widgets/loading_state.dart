import 'package:flutter/material.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message = 'Memuat data...', this.isSkeleton = false});

  final String message;
  final bool isSkeleton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isSkeleton) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 120, width: 120, decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(12))),
              const SizedBox(height: 16),
              Container(height: 16, width: 200, decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(4))),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(message),
          ],
        ),
      ),
    );
  }
}
