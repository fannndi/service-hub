class Province {
  final String id;
  final String name;

  const Province({required this.id, required this.name});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class City {
  final String id;
  final String provinceId;
  final String name;

  const City({required this.id, required this.provinceId, required this.name});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as String,
      provinceId: json['province_id'] as String,
      name: json['name'] as String,
    );
  }
}

class District {
  final String id;
  final String regencyId;
  final String name;

  const District(
      {required this.id, required this.regencyId, required this.name});

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] as String,
      regencyId: json['regency_id'] as String,
      name: json['name'] as String,
    );
  }
}

class Village {
  final String id;
  final String districtId;
  final String name;

  const Village(
      {required this.id, required this.districtId, required this.name});

  factory Village.fromJson(Map<String, dynamic> json) {
    return Village(
      id: json['id'] as String,
      districtId: json['district_id'] as String,
      name: json['name'] as String,
    );
  }
}
