import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../ui/theme/app_spacing.dart';

class QueryToolbar extends StatelessWidget {
  const QueryToolbar(
      {super.key,
      required this.hint,
      required this.onSearch,
      this.filters = const []});
  final String hint;
  final ValueChanged<String> onSearch;
  final List<Widget> filters;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      decoration: BoxDecoration(color: scheme.surface),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(Icons.search, size: 20),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
          onSubmitted: onSearch,
        ),
        if (filters.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: filters,
            ),
          ),
        ],
      ]),
    );
  }
}
