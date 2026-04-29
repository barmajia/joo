import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aurora/models/customers/customerbill.dart';
import 'package:aurora/models/analysis/enums.dart';

class OrderStorage {
  static late final SharedPreferences _prefs;
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  static Future<void> _saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  static Future<String?> _getString(String key) async {
    try {
      return _prefs.getString(key);
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveOrders(List<Order> orders) async {
    final list = orders.map((o) => o.toMap()).toList();
    await _saveString('orders_list', jsonEncode(list));
  }

  static Future<List<Order>> getOrders() async {
    final value = await _getString('orders_list');
    if (value == null || value.isEmpty) return [];
    try {
      final list = jsonDecode(value) as List;
      return list
          .map((item) => Order.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Order>> getOrdersByCustomer(String customerId) async {
    final orders = await getOrders();
    return orders.where((o) => o.userId == customerId).toList();
  }

  static Future<List<Order>> getOrdersBySeller(String sellerId) async {
    final orders = await getOrders();
    return orders.where((o) => o.sellerId == sellerId).toList();
  }

  static Future<Order?> getOrderById(String id) async {
    final orders = await getOrders();
    try {
      return orders.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }

  static Future<void> addOrder(Order order) async {
    final orders = await getOrders();
    orders.insert(0, order);
    await saveOrders(orders);
  }

  static Future<void> updateOrder(Order order) async {
    final orders = await getOrders();
    final index = orders.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      orders[index] = order;
      await saveOrders(orders);
    }
  }

  static Future<void> deleteOrder(String id) async {
    final orders = await getOrders();
    orders.removeWhere((o) => o.id == id);
    await saveOrders(orders);
  }

  static Future<void> clearOrders() async {
    await _prefs.remove('orders_list');
  }

  static Future<double> getTotalRevenue() async {
    final orders = await getOrders();
    double total = 0;
    for (final order in orders) {
      if (order.paymentStatus.value == 'completed') {
        total += order.total;
      }
    }
    return total;
  }

  static Future<int> getTotalOrdersCount() async {
    final orders = await getOrders();
    return orders.length;
  }

  static Future<Map<String, double>> getRevenueByStatus() async {
    final orders = await getOrders();
    final Map<String, double> revenue = {};
    for (final order in orders) {
      final status = order.status.value;
      revenue[status] = (revenue[status] ?? 0) + order.total;
    }
    return revenue;
  }
}