class InventoryQuery {
  const InventoryQuery(
      {this.search,
      this.brand,
      this.deviceModel,
      this.partType,
      this.page = 1});
  final String? search;
  final String? brand;
  final String? deviceModel;
  final String? partType;
  final int page;

  InventoryQuery copyWith(
          {String? search,
          String? brand,
          String? deviceModel,
          String? partType,
          int? page}) =>
      InventoryQuery(
        search: search ?? this.search,
        brand: brand ?? this.brand,
        deviceModel: deviceModel ?? this.deviceModel,
        partType: partType ?? this.partType,
        page: page ?? this.page,
      );
}
