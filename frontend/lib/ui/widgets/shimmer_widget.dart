import 'package:flutter/material.dart';

class ShimmerWidget extends StatefulWidget {
  const ShimmerWidget({super.key, this.width, this.height, this.borderRadius = 14, this.count = 1});

  final double? width;
  final double? height;
  final double borderRadius;
  final int count;

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final stops = [
          (_controller.value - 0.3).clamp(0.0, 1.0),
          _controller.value,
          (_controller.value + 0.3).clamp(0.0, 1.0),
        ];
        return Column(
          children: List.generate(widget.count, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: widget.width,
              height: widget.height ?? 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                gradient: LinearGradient(
                  colors: [
                    scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ],
                  stops: stops,
                ),
              ),
            ),
          )),
        );
      },
    );
  }
}

class ShimmerText extends StatelessWidget {
  const ShimmerText({super.key, this.width, this.height = 16});
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ShimmerWidget(width: width, height: height, borderRadius: 8);
  }
}
