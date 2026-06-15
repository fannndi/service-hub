import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders an AsyncValue with loading/error/data states.
class AsyncPage<T> extends StatelessWidget {
  const AsyncPage({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final Widget Function(Object error)? error;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => loading ?? const Center(child: CircularProgressIndicator()),
      error: (err, _) => error != null
          ? error!(err)
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Terjadi kesalahan: $err'),
              ),
            ),
      data: data,
    );
  }
}
