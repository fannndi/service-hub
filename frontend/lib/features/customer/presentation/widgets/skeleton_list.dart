import 'package:flutter/material.dart';

import '../../../../ui/theme/app_spacing.dart';
import '../../../../ui/widgets/shimmer_widget.dart';

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4});
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        child: ShimmerWidget(count: count),
      );
}
