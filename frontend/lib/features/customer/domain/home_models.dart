class HomeSummary {
  const HomeSummary({this.activeOrders = 0, this.activeCoupons = 0, this.activeWarranties = 0});
  final int activeOrders;
  final int activeCoupons;
  final int activeWarranties;
  factory HomeSummary.fromJson(Map<String, dynamic> json) => HomeSummary(
        activeOrders: json['active_orders'] as int? ?? json['activeOrders'] as int? ?? 0,
        activeCoupons: json['active_coupons'] as int? ?? json['activeCoupons'] as int? ?? 0,
        activeWarranties: json['active_warranties'] as int? ?? json['activeWarranties'] as int? ?? 0,
      );
}
