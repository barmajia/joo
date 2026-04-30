import 'package:aurora/models/customers/customerbill.dart';
import 'package:aurora/models/analysis/analytics.dart';
import 'package:aurora/models/analysis/enums.dart';
import 'package:aurora/storage/analysis/analytics_storage.dart';
import 'package:aurora/storage/order_storage.dart';
import 'package:aurora/storage/bill_vault_storage.dart';
import 'package:flutter/material.dart';

class AnalysisEngine {
  static final AnalysisEngine _instance = AnalysisEngine._internal();
  factory AnalysisEngine() => _instance;
  AnalysisEngine._internal();

  BillVaultStorage? _vault;

  Future<BillVaultStorage> _getVault() async {
    _vault ??= await BillVaultStorage.getInstance();
    return _vault!;
  }

  Future<AnalyticsSnapshot?> analyzeBills({
    required String sellerId,
    PeriodType periodType = PeriodType.daily,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? _getDefaultStart(periodType);
    final end = endDate ?? DateTime.now();

    try {
      final vault = await _getVault();
      List<Order> orders = vault.getSellerBills(sellerId);

      if (orders.isEmpty) {
        orders = await OrderStorage.getOrders();
      }

      final filteredOrders = orders.where((order) {
        return order.createdAt.isAfter(
              start.subtract(const Duration(days: 1)),
            ) &&
            order.createdAt.isBefore(end.add(const Duration(days: 1)));
      }).toList();

      final snapshot = _calculateMetrics(
        sellerId: sellerId,
        orders: filteredOrders,
        periodType: periodType,
        periodStart: start,
        periodEnd: end,
      );

      await _saveSnapshot(snapshot);
      await _saveDailyMetrics(snapshot, filteredOrders);

      return snapshot;
    } catch (e) {
      debugPrint('[AnalysisEngine.analyzeBills] Error: $e');
      return null;
    }
  }

  AnalyticsSnapshot _calculateMetrics({
    required String sellerId,
    required List<Order> orders,
    required PeriodType periodType,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    double totalRevenue = 0;
    int totalOrders = orders.length;
    int totalItemsSold = 0;
    final customerSet = <String>{};
    final productSales = <String, Map<String, dynamic>>{};
    final dailyData = <Map<String, dynamic>>[];
    final dailyRevenue = <String, double>{};

    for (final order in orders) {
      if (order.paymentStatus.value == 'completed') {
        totalRevenue += order.total;
      }

      if (order.userId.isNotEmpty) {
        customerSet.add(order.userId);
      }

      for (final item in order.items) {
        totalItemsSold += item.quantity;

        final productId = item.productId ?? item.asin;
        if (productSales.containsKey(productId)) {
          productSales[productId]!['quantity'] =
              (productSales[productId]!['quantity'] as int) + item.quantity;
          productSales[productId]!['revenue'] =
              (productSales[productId]!['revenue'] as double) +
              (item.unitPrice * item.quantity);
        } else {
          productSales[productId] = {
            'product_id': productId,
            'title': item.productName,
            'quantity': item.quantity,
            'revenue': item.unitPrice * item.quantity,
          };
        }
      }

      final day = order.createdAt.toIso8601String().split('T')[0];

      dailyRevenue[day] = (dailyRevenue[day] ?? 0) + order.total;
    }

    dailyRevenue.forEach((day, revenue) {
      dailyData.add({
        'date': day,
        'revenue': revenue,
        'orders': orders
            .where((o) => o.createdAt.toIso8601String().split('T')[0] == day)
            .length,
      });
    });

    final topProducts = productSales.values.toList()
      ..sort(
        (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double),
      );

    final customerOrders = <String, int>{};
    for (final order in orders) {
      if (order.userId.isNotEmpty) {
        customerOrders[order.userId] = (customerOrders[order.userId] ?? 0) + 1;
      }
    }

    final topCustomers =
        customerOrders.entries
            .map((e) => {'customer_id': e.key, 'order_count': e.value})
            .toList()
          ..sort(
            (a, b) =>
                (b['order_count'] as int).compareTo(a['order_count'] as int),
          );

    final analyticsData = {
      'kpis': {
        'total_revenue': totalRevenue,
        'total_sales': totalOrders,
        'total_orders': totalOrders,
        'total_items_sold': totalItemsSold,
        'total_customers': customerSet.length,
        'unique_customers_in_period': customerSet.length,
        'average_order_value': totalOrders > 0 ? totalRevenue / totalOrders : 0,
        'conversion_rate': 0.0,
      },
      'top_products': topProducts.take(10).toList(),
      'top_customers': topCustomers.take(10).toList(),
      'daily_breakdown': dailyData,
    };

    return AnalyticsSnapshot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sellerId: sellerId,
      periodType: periodType,
      periodStart: periodStart,
      periodEnd: periodEnd,
      analyticsData: analyticsData,
      isCurrent: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _saveSnapshot(AnalyticsSnapshot snapshot) async {
    await AnalyticsStorage.saveSnapshot(snapshot);
  }

  Future<void> _saveDailyMetrics(
    AnalyticsSnapshot snapshot,
    List<Order> orders,
  ) async {
    final dailyMetrics = <DailyAnalytics>[];

    for (final order in orders) {
      dailyMetrics.add(
        DailyAnalytics(
          id: '${order.id}_revenue',
          sellerId: snapshot.sellerId,
          metricType: MetricType.totalSales,
          metricValue: order.total,
          metricDate: order.createdAt,
          metadata: {'order_id': order.id},
        ),
      );
    }

    if (dailyMetrics.isNotEmpty) {
      await AnalyticsStorage.saveDailyAnalytics(dailyMetrics);
    }
  }

  Future<AnalyticsSnapshot?> getLatestSnapshot(String sellerId) async {
    return await AnalyticsStorage.getSnapshot();
  }

  DateTime _getDefaultStart(PeriodType periodType) {
    final now = DateTime.now();
    switch (periodType) {
      case PeriodType.daily:
        return DateTime(now.year, now.month, now.day);
      case PeriodType.weekly:
        return now.subtract(const Duration(days: 7));
      case PeriodType.monthly:
        return DateTime(now.year, now.month - 1, now.day);
      case PeriodType.yearly:
        return DateTime(now.year - 1, now.month, now.day);
      case PeriodType.custom:
        return DateTime(now.year, now.month, now.day);
    }
  }

  Future<void> runAnalysis(String sellerId) async {
    await analyzeBills(sellerId: sellerId);
  }
}
