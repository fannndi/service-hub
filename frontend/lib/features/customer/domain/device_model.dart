class DeviceModelGroup {
  const DeviceModelGroup({required this.brand, required this.models});

  final String brand;
  final List<String> models;

  factory DeviceModelGroup.fromJson(Map<String, dynamic> json) => DeviceModelGroup(
        brand: json['brand'] as String,
        models: (json['models'] as List).cast<String>(),
      );
}
