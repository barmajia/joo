import 'package:aurora/models/analysis/enums.dart';

class DailyAnalytics {
  final String id;
  final String? sellerId;
  final MetricType metricType;
  final double metricValue;
  final DateTime metricDate;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  DailyAnalytics({
    required this.id,
    this.sellerId,
    required this.metricType,
    required this.metricValue,
    required this.metricDate,
    this.metadata,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory DailyAnalytics.fromMap(Map<String, dynamic> map) {
    return DailyAnalytics(
      id: map['id'] as String? ?? '',
      sellerId: map['seller_id'] as String?,
      metricType:
          MetricTypeExtension.fromString(map['metric_type'] as String? ?? 'total_sales'),
      metricValue: _parseNumeric(map['metric_value']),
      metricDate: DateTime.tryParse(map['metric_date']?.toString() ?? '') ?? DateTime.now(),
      metadata: map['metadata'] is Map<String, dynamic>
          ? map['metadata'] as Map<String, dynamic>
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seller_id': sellerId,
      'metric_type': metricType.name,
      'metric_value': metricValue,
      'metric_date': metricDate.toIso8601String().split('T')[0],
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static double _parseNumeric(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class AnalyticsSnapshot {
  final String id;
  final String sellerId;
  final PeriodType periodType;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, dynamic> analyticsData;
  final bool isCurrent;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnalyticsSnapshot({
    required this.id,
    required this.sellerId,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    required this.analyticsData,
    this.isCurrent = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get totalRevenue =>
      (analyticsData['kpis']?['total_revenue'] as num?)?.toDouble() ?? 0;

  int get totalSales => analyticsData['kpis']?['total_sales'] as int? ?? 0;

  int get totalOrders => analyticsData['kpis']?['total_orders'] as int? ?? 0;

  int get totalItemsSold =>
      analyticsData['kpis']?['total_items_sold'] as int? ?? 0;

  int get totalCustomers => analyticsData['kpis']?['total_customers'] as int? ?? 0;

  int get uniqueCustomersInPeriod =>
      analyticsData['kpis']?['unique_customers_in_period'] as int? ?? 0;

  double get averageOrderValue =>
      (analyticsData['kpis']?['average_order_value'] as num?)?.toDouble() ?? 0;

  double get conversionRate =>
      (analyticsData['kpis']?['conversion_rate'] as num?)?.toDouble() ?? 0;

  List<Map<String, dynamic>> get topProducts {
    final products = analyticsData['top_products'];
    if (products is List) {
      return products.cast<Map<String, dynamic>>();
    }
    return [];
  }

  List<Map<String, dynamic>> get topCustomers {
    final customers = analyticsData['top_customers'];
    if (customers is List) {
      return customers.cast<Map<String, dynamic>>();
    }
    return [];
  }

  List<Map<String, dynamic>> get dailyBreakdown {
    final daily = analyticsData['daily_breakdown'];
    if (daily is List) {
      return daily.cast<Map<String, dynamic>>();
    }
    return [];
  }

  factory AnalyticsSnapshot.fromMap(Map<String, dynamic> map) {
    return AnalyticsSnapshot(
      id: map['id'] as String? ?? '',
      sellerId: map['seller_id'] as String? ?? '',
      periodType:
          PeriodTypeExtension.fromString(map['period_type'] as String? ?? 'daily'),
      periodStart: DateTime.tryParse(map['period_start']?.toString() ?? '') ?? DateTime.now(),
      periodEnd: DateTime.tryParse(map['period_end']?.toString() ?? '') ?? DateTime.now(),
      analyticsData: map['analytics_data'] is Map<String, dynamic>
          ? map['analytics_data'] as Map<String, dynamic>
          : {},
      isCurrent: map['is_current'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seller_id': sellerId,
      'period_type': periodType.value,
      'period_start': periodStart.toIso8601String().split('T')[0],
      'period_end': periodEnd.toIso8601String().split('T')[0],
      'analytics_data': analyticsData,
      'is_current': isCurrent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AnalyticsSnapshot copyWith({
    String? id,
    String? sellerId,
    PeriodType? periodType,
    DateTime? periodStart,
    DateTime? periodEnd,
    Map<String, dynamic>? analyticsData,
    bool? isCurrent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnalyticsSnapshot(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      periodType: periodType ?? this.periodType,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      analyticsData: analyticsData ?? this.analyticsData,
      isCurrent: isCurrent ?? this.isCurrent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}