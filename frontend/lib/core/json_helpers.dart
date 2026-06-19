/// Unified JSON deserialization helpers.
/// Consolidates duplicated helpers from customer_models, store_admin_models, platform_admin_models.
library;

double moneyFromJson(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

DateTime? dateFromJson(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

String readString(Map<String, dynamic> json, String snake, [String? camel]) =>
    (json[snake] ?? (camel == null ? null : json[camel]) ?? '').toString();

Map<String, dynamic>? jsonMap(Object? value) =>
    value is Map ? value.cast<String, dynamic>() : null;

List<Map<String, dynamic>> jsonList(Object? value) => value is List
    ? value
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList()
    : const [];

String jsonString(Object? value, {String fallback = ''}) =>
    value?.toString() ?? fallback;

int jsonInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

num jsonNum(Object? value) =>
    value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;

double jsonDouble(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;

bool jsonBool(Object? value) => value == true || value?.toString() == 'true';

DateTime jsonDate(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '') ??
    DateTime.fromMillisecondsSinceEpoch(0);

DateTime? jsonDateOrNull(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());

List<String> jsonStringList(Object? value) =>
    value is List ? value.map((item) => item.toString()).toList() : const [];

Map<String, int> jsonIntMap(Object? value) => value is Map
    ? value.map((key, item) => MapEntry(key.toString(), jsonInt(item)))
    : const {};
