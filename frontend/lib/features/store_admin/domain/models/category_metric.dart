import '../../../../core/json_helpers.dart';

class CategoryMetric {
  const CategoryMetric(this.label, this.value);
  final String label;
  final num value;
  factory CategoryMetric.fromJson(Map<String, dynamic> json) => CategoryMetric(
      jsonString(json['label'] ?? json['name']),
      jsonNum(json['value'] ?? json['count']));
}
