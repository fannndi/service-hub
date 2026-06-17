import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'address_models.dart';

class AddressRepository {
  static const _provinceIdJateng = '33';

  static List<Province> _provinces = [];
  static List<City> _cities = [];
  static List<District> _districts = [];
  static List<Village> _villages = [];
  static bool _loaded = false;

  static Future<void> init() async {
    if (_loaded) return;

    _provinces = _parseList(
      await rootBundle.loadString('assets/data/provinces.json'),
      Province.fromJson,
    );

    _cities = _parseList(
      await rootBundle.loadString('assets/data/jateng_cities.json'),
      City.fromJson,
    );

    _districts = _parseList(
      await rootBundle.loadString('assets/data/jateng_districts.json'),
      District.fromJson,
    );

    _villages = _parseList(
      await rootBundle.loadString('assets/data/jateng_villages.json'),
      Village.fromJson,
    );

    _loaded = true;
  }

  static List<T> _parseList<T>(String json, T Function(Map<String, dynamic>) fromJson) {
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  static List<Province> get provinces => _provinces;
  static List<City> get cities => _cities;
  static List<District> get districts => _districts;
  static List<Village> get villages => _villages;

  static List<City> citiesByProvince(String provinceId) {
    return _cities.where((c) => c.provinceId == provinceId).toList();
  }

  static List<District> districtsByCity(String cityId) {
    return _districts.where((d) => d.regencyId == cityId).toList();
  }

  static List<Village> villagesByDistrict(String districtId) {
    return _villages.where((v) => v.districtId == districtId).toList();
  }

  static String formatAddress({
    required String detail,
    required String villageName,
    required String districtName,
    required String cityName,
    required String provinceName,
  }) {
    final parts = <String>[];
    if (detail.isNotEmpty) parts.add(detail);
    parts.add(villageName);
    parts.add('Kec. $districtName');
    parts.add(cityName);
    parts.add(provinceName);
    return parts.join(', ');
  }
}
