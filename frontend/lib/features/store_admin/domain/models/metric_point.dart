import '../../../../core/json_helpers.dart';

class MetricPoint {
  const MetricPoint(this.label, this.value);
  final String label;
  final num value;
  factory MetricPoint.fromJson(Map<String, dynamic> json) => MetricPoint(
      jsonString(json['label'] ?? json['date']),
      jsonNum(json['value'] ?? json['total']));
}
