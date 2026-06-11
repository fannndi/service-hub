import 'package:flutter/material.dart';

class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    required this.hintText,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
    this.onSearch,
    this.searchController,
  });

  final String hintText;
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;
  final ValueChanged<String>? onSearch;
  final TextEditingController? searchController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: hintText,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: onSearch,
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((filter) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter),
                  selected: filter == selectedFilter,
                  onSelected: (_) => onFilterSelected(filter),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
