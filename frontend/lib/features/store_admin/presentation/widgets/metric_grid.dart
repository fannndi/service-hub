import 'package:flutter/material.dart';

class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.cards});
  final List<Widget> cards;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final columns = c.maxWidth >= 1100
            ? 4
            : c.maxWidth >= 700
                ? 2
                : 1;
        return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: cards);
      });
}
