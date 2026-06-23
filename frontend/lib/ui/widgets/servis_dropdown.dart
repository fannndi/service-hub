import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class ServisDropdown<T> extends StatelessWidget {
  const ServisDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hint,
    this.icon,
    this.prefixIcon,
    this.disabled = false,
  });

  final T? value;
  final List<(T, String)> items;
  final ValueChanged<T?> onChanged;
  final String? label;
  final String? hint;
  final IconData? icon;
  final Widget? prefixIcon;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: scheme.onSurfaceVariant,
        ),
      ),
      items: items.map(((T, String) item) {
        return DropdownMenuItem<T>(
          value: item.$1,
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(item.$2),
            ],
          ),
        );
      }).toList(),
      onChanged: disabled ? null : onChanged,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    );
  }
}
