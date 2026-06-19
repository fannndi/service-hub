import '../../../core/json_helpers.dart';
import 'store_admin_session.dart';
import 'store_admin_order_models.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.adminName,
    required this.storeName,
    required this.ratingAvg,
    required this.todayOrders,
    required this.activeOrders,
    required this.pendingOrders,
    required this.customers,
    required this.pendingPayments,
    required this.waitingApproval,
    required this.activeDisputes,
    required this.revenueToday,
    required this.revenueMonth,
    required this.completionRate,
    required this.statusBreakdown,
    required this.revenueTrend,
    required this.ordersTrend,
    required this.serviceCategories,
    required this.sparepartConsumption,
    required this.recentOrders,
  });

  final String adminName;
  final String storeName;
  final double ratingAvg;
  final int todayOrders;
  final int activeOrders;
  final int pendingOrders;
  final int customers;
  final int pendingPayments;
  final int waitingApproval;
  final int activeDisputes;
  final num revenueToday;
  final num revenueMonth;
  final double completionRate;
  final Map<String, int> statusBreakdown;
  final List<MetricPoint> revenueTrend;
  final List<MetricPoint> ordersTrend;
  final List<CategoryMetric> serviceCategories;
  final List<CategoryMetric> sparepartConsumption;
  final List<StoreOrder> recentOrders;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        adminName: jsonString(json['adminName'] ?? json['admin_name'],
            fallback: 'Admin Toko'),
        storeName: jsonString(json['storeName'] ?? json['store_name'],
            fallback: 'Toko Servis'),
        ratingAvg: jsonDouble(json['ratingAvg'] ?? json['rating_avg']),
        todayOrders: jsonInt(json['todayOrders'] ?? json['today_orders']),
        activeOrders: jsonInt(
            json['activeOrders'] ?? json['active_orders'] ?? json['active']),
        pendingOrders: jsonInt(
            json['pendingOrders'] ?? json['pending_orders'] ?? json['pending']),
        customers: jsonInt(json['customers'] ?? json['customer_count']),
        pendingPayments:
            jsonInt(json['pendingPayments'] ?? json['pending_payments']),
        waitingApproval:
            jsonInt(json['waitingApproval'] ?? json['waiting_approval']),
        activeDisputes: jsonInt(json['activeDisputes'] ??
            json['active_disputes'] ??
            json['disputes']),
        revenueToday: jsonNum(json['revenueToday'] ?? json['revenue_today']),
        revenueMonth: jsonNum(json['revenueMonth'] ?? json['revenue_month']),
        completionRate:
            jsonDouble(json['completionRate'] ?? json['completion_rate']),
        statusBreakdown:
            jsonIntMap(json['statusBreakdown'] ?? json['status_breakdown']),
        revenueTrend: jsonList(json['revenueTrend'] ?? json['revenue_trend'])
            .map(MetricPoint.fromJson)
            .toList(),
        ordersTrend: jsonList(json['ordersTrend'] ?? json['orders_trend'])
            .map(MetricPoint.fromJson)
            .toList(),
        serviceCategories:
            jsonList(json['serviceCategories'] ?? json['service_categories'])
                .map(CategoryMetric.fromJson)
                .toList(),
        sparepartConsumption: jsonList(
                json['sparepartConsumption'] ?? json['sparepart_consumption'])
            .map(CategoryMetric.fromJson)
            .toList(),
        recentOrders: jsonList(json['recentOrders'] ?? json['recent_orders'])
            .map(StoreOrder.fromJson)
            .toList(),
      );

  factory DashboardSummary.empty(StoreAdminSession? session) =>
      DashboardSummary(
        adminName: session?.adminName ?? 'Admin Toko',
        storeName: session?.storeName ?? 'Toko Servis',
        ratingAvg: 0,
        todayOrders: 0,
        activeOrders: 0,
        pendingOrders: 0,
        customers: 0,
        pendingPayments: 0,
        waitingApproval: 0,
        activeDisputes: 0,
        revenueToday: 0,
        revenueMonth: 0,
        completionRate: 0,
        statusBreakdown: const {},
        revenueTrend: const [],
        ordersTrend: const [],
        serviceCategories: const [],
        sparepartConsumption: const [],
        recentOrders: const [],
      );
}

class MetricPoint {
  const MetricPoint(this.label, this.value);
  final String label;
  final num value;
  factory MetricPoint.fromJson(Map<String, dynamic> json) => MetricPoint(
      jsonString(json['label'] ?? json['date']),
      jsonNum(json['value'] ?? json['total']));
}

class CategoryMetric {
  const CategoryMetric(this.label, this.value);
  final String label;
  final num value;
  factory CategoryMetric.fromJson(Map<String, dynamic> json) => CategoryMetric(
      jsonString(json['label'] ?? json['name']),
      jsonNum(json['value'] ?? json['count']));
}
