import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'cache_config.dart';

class CacheManager {
  static final CacheManager _instance = CacheManager._();
  CacheManager._();

  static CacheManager get instance => _instance;

  final _memoryCache = <String, _MemoryEntry>{};

  Future<void> set<T>(String key, T data, {Duration? ttl}) async {
    _memoryCache[key] = _MemoryEntry(data: data, cachedAt: DateTime.now());

    try {
      final prefs = await SharedPreferences.getInstance();
      final entry = {
        'data': jsonEncode(data is String ? data : _toJsonSafe(data)),
        'cachedAt': DateTime.now().toIso8601String(),
        'ttlSeconds': (ttl ?? CacheConfig.stores).inSeconds,
      };
      await prefs.setString('cache_$key', jsonEncode(entry));
    } catch (_) {}
  }

  T? get<T>(String key) {
    final mem = _memoryCache[key];
    if (mem != null && !mem.isExpired(CacheConfig.stores)) return mem.data as T;

    return null;
  }

  Future<T?> getAsync<T>(String key, {Duration? ttl}) async {
    final mem = _memoryCache[key];
    if (mem != null && !mem.isExpired(ttl ?? CacheConfig.stores)) {
      return mem.data as T;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cache_$key');
      if (raw == null) return null;

      final entry = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(entry['cachedAt'] as String);
      final entryTtl = Duration(seconds: entry['ttlSeconds'] as int);
      final effectiveTtl = ttl ?? entryTtl;

      if (DateTime.now().difference(cachedAt) > effectiveTtl) return null;

      final decoded = jsonDecode(entry['data'] as String);
      _memoryCache[key] = _MemoryEntry(data: decoded, cachedAt: cachedAt);
      return decoded as T;
    } catch (_) {
      return null;
    }
  }

  Future<void> invalidate(String key) async {
    _memoryCache.remove(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cache_$key');
    } catch (_) {}
  }

  Future<void> clear() async {
    _memoryCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('cache_'));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }

  dynamic _toJsonSafe(dynamic value) {
    if (value == null) return null;
    if (value is String || value is num || value is bool) return value;
    if (value is List) return value.map(_toJsonSafe).toList();
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _toJsonSafe(v)));
    }
    return value.toString();
  }
}

class _MemoryEntry {
  final dynamic data;
  final DateTime cachedAt;

  _MemoryEntry({required this.data, required this.cachedAt});

  bool isExpired(Duration ttl) => DateTime.now().difference(cachedAt) > ttl;
}
