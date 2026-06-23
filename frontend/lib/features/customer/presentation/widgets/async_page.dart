import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/shimmer_widget.dart';

class AsyncPage<T> extends StatelessWidget {
  const AsyncPage({super.key, required this.value, required this.builder});
  final AsyncValue<T> value;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) => value.when(
        data: builder,
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ShimmerWidget(count: 3),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Gagal memuat data',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(error.toString(), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
}
