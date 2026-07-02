import 'dart:convert';

class CacheEntry<T> {
  final T data;
  final DateTime cachedAt;
  final Duration ttl;

  CacheEntry({required this.data, required this.cachedAt, required this.ttl});

  bool get isExpired => DateTime.now().difference(cachedAt) > ttl;

  Map<String, dynamic> toJson(T Function(dynamic) toJson) => {
    'data': jsonEncode(toJson(data)),
    'cachedAt': cachedAt.toIso8601String(),
    'ttlSeconds': ttl.inSeconds,
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJson) {
    return CacheEntry(
      data: fromJson(json['data']),
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      ttl: Duration(seconds: json['ttlSeconds'] as int),
    );
  }
}

class CacheConfig {
  static const Duration deviceModels = Duration(hours: 24);
  static const Duration stores = Duration(hours: 1);
  static const Duration spareparts = Duration(minutes: 30);
  static const Duration brands = Duration(hours: 1);
  static const Duration homeSummary = Duration(seconds: 30);
  static const Duration dashboard = Duration(seconds: 30);
  static const Duration userProfile = Duration(hours: 1);
  static const Duration storeProfile = Duration(hours: 1);
  static const Duration notifications = Duration(seconds: 15);
}
