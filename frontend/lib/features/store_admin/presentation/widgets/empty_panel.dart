import 'package:flutter/material.dart';

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant))));
}
