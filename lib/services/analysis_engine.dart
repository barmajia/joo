import 'package:aurora/models/customers/customerbill.dart';
import 'package:aurora/models/analysis/analytics.dart';
import 'package:aurora/models/analysis/enums.dart';
import 'package:aurora/models/product/productModel.dart';
import 'package:aurora/services/product_service.dart';
import 'package:aurora/storage/analysis/analytics_storage.dart';
import 'package:aurora/storage/order_storage.dart';
import 'package:aurora/storage/bill_vault_storage.dart';
import 'package:flutter/material.dart';

class AnalysisEngine {
  static final AnalysisEngine _instance = AnalysisEngine._internal();
  factory AnalysisEngine() => _instance;
  AnalysisEngine._internal();

  BillVaultStorage? _vault;
  final ProductService _productService = ProductService();

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
      List<Product> products = [];
      try {
        products = await _productService.getSellerProducts(sellerId);
      } catch (e) {
        debugPrint('[AnalysisEngine] Product lookup unavailable: $e');
      }

      final snapshot = _calculateMetrics(
        sellerId: sellerId,
        orders: filteredOrders,
        products: products,
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
    required List<Product> products,
    required PeriodType periodType,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    double totalRevenue = 0;
    double totalCost = 0;
    int totalOrders = orders.length;
    int totalItemsSold = 0;
    final customerSet = <String>{};
    final productSales = <String, Map<String, dynamic>>{};
    final categorySales = <String, Map<String, dynamic>>{};
    final dealStats = <String, Map<String, dynamic>>{};
    final dailyData = <Map<String, dynamic>>[];
    final dailyRevenue = <String, double>{};
    final productLookup = _buildProductLookup(products);

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
        final product =
            productLookup[item.productId] ??
            productLookup[item.asin] ??
            productLookup[item.productName.toLowerCase()];
        final itemRevenue = item.unitPrice * item.quantity;
        final itemCost = (_readCost(product) ?? 0) * item.quantity;
        totalCost += itemCost;
        final category = product?.category ?? 'Uncategorized';

        if (productSales.containsKey(productId)) {
          productSales[productId]!['quantity'] =
              (productSales[productId]!['quantity'] as int) + item.quantity;
          productSales[productId]!['revenue'] =
              (productSales[productId]!['revenue'] as double) + itemRevenue;
          productSales[productId]!['profit'] =
              (productSales[productId]!['profit'] as double) +
              (itemRevenue - itemCost);
        } else {
          productSales[productId] = {
            'product_id': productId,
            'title': item.productName,
            'category': category,
            'quantity': item.quantity,
            'revenue': itemRevenue,
            'profit': itemRevenue - itemCost,
          };
        }

        categorySales.putIfAbsent(category, () {
          return {
            'category': category,
            'quantity': 0,
            'revenue': 0.0,
            'profit': 0.0,
          };
        });
        categorySales[category]!['quantity'] =
            (categorySales[category]!['quantity'] as int) + item.quantity;
        categorySales[category]!['revenue'] =
            (categorySales[category]!['revenue'] as double) + itemRevenue;
        categorySales[category]!['profit'] =
            (categorySales[category]!['profit'] as double) +
            (itemRevenue - itemCost);
      }

      if (order.dealId?.isNotEmpty == true) {
        final dealId = order.dealId!;
        dealStats.putIfAbsent(dealId, () {
          return {
            'deal_id': dealId,
            'orders': 0,
            'revenue': 0.0,
            'discount': 0.0,
          };
        });
        dealStats[dealId]!['orders'] =
            (dealStats[dealId]!['orders'] as int) + 1;
        dealStats[dealId]!['revenue'] =
            (dealStats[dealId]!['revenue'] as double) + order.total;
        dealStats[dealId]!['discount'] =
            (dealStats[dealId]!['discount'] as double) + order.discount;
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
    final categories = categorySales.values.toList()
      ..sort(
        (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double),
      );
    final deals = dealStats.values.toList()
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

    final repeatCustomers = customerOrders.values
        .where((count) => count > 1)
        .length;
    final grossProfit = totalRevenue - totalCost;
    final profitMargin = totalRevenue > 0
        ? (grossProfit / totalRevenue) * 100
        : 0.0;
    final activeDays = dailyRevenue.isEmpty ? 1 : dailyRevenue.length;
    final averageDailyRevenue = totalRevenue / activeDays;
    final forecastedMonthlyRevenue = averageDailyRevenue * 30;

    final analyticsData = {
      'kpis': {
        'total_revenue': totalRevenue,
        'gross_profit': grossProfit,
        'profit_margin': profitMargin,
        'total_sales': totalOrders,
        'total_orders': totalOrders,
        'total_items_sold': totalItemsSold,
        'total_customers': customerSet.length,
        'unique_customers_in_period': customerSet.length,
        'repeat_customers': repeatCustomers,
        'customer_retention_rate': customerSet.isEmpty
            ? 0.0
            : (repeatCustomers / customerSet.length) * 100,
        'average_order_value': totalOrders > 0 ? totalRevenue / totalOrders : 0,
        'conversion_rate': 0.0,
        'forecasted_monthly_revenue': forecastedMonthlyRevenue,
      },
      'top_products': topProducts.take(10).toList(),
      'best_categories': categories.take(5).toList(),
      'worst_categories': categories.reversed.take(5).toList(),
      'top_customers': topCustomers.take(10).toList(),
      'deal_performance': deals.take(10).toList(),
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

  Map<String, Product> _buildProductLookup(List<Product> products) {
    final lookup = <String, Product>{};
    for (final product in products) {
      if (product.id?.isNotEmpty == true) lookup[product.id!] = product;
      if (product.asin?.isNotEmpty == true) lookup[product.asin!] = product;
      if (product.sku?.isNotEmpty == true) lookup[product.sku!] = product;
      lookup[product.title.toLowerCase()] = product;
    }
    return lookup;
  }

  double? _readCost(Product? product) {
    final value = product?.attributes?['cost'];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
