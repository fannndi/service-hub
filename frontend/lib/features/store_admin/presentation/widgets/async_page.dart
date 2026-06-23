import 'package:flutter/material.dart';

import 'empty_panel.dart';
import 'error_panel.dart';

class AsyncPage<T> extends StatelessWidget {
  const AsyncPage({super.key, required this.value, required this.builder});
  final AsyncSnapshot<T> value;
  final Widget Function(T data) builder;
  @override
  Widget build(BuildContext context) {
    if (value.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (value.hasError) return ErrorPanel(message: value.error.toString());
    final data = value.data;
    return data == null
        ? const EmptyPanel(message: 'Data belum tersedia')
        : builder(data);
  }
}
