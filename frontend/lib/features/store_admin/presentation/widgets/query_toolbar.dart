import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                  width: 320,
                  child: SearchBar(
                      hintText: hint,
                      leading: const Icon(Icons.search),
                      elevation: const WidgetStatePropertyAll(0),
                      onSubmitted: onSearch)),
              ...filters,
              OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Export')),
            ]),
      );
}
