import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/models/customers/customerbill.dart';
import 'package:aurora/models/analysis/enums.dart';
import 'package:aurora/storage/order_storage.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  Future<List<Order>> fetchOrdersBySeller(String sellerId) async {
    try {
      final response = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      final orders = response
          .map((item) => Order.fromMap(item as Map<String, dynamic>))
          .toList();

      await OrderStorage.saveOrders(orders);
      return orders;
    } catch (e) {
      return await OrderStorage.getOrders();
    }
  }

  Future<List<Order>> fetchOrdersByCustomer(String customerId) async {
    try {
      final response = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('user_id', customerId)
          .order('created_at', ascending: false);

      final orders = response
          .map((item) => Order.fromMap(item as Map<String, dynamic>))
          .toList();

      return orders;
    } catch (e) {
      return await OrderStorage.getOrdersByCustomer(customerId);
    }
  }

  Future<Order?> fetchOrderById(String orderId) async {
    try {
      final response = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('id', orderId)
          .maybeSingle();

      if (response != null) {
        return Order.fromMap(response);
      }
    } catch (e) {
      // fallback
    }
    return null;
  }

  Future<Order?> createOrder(Order order) async {
    try {
      final response = await Supabase.instance.client
          .from('orders')
          .insert(order.toMap())
          .select()
          .maybeSingle();

      if (response != null) {
        final newOrder = Order.fromMap(response);
        await OrderStorage.addOrder(newOrder);
        return newOrder;
      }
    } catch (e) {
      await OrderStorage.addOrder(order);
    }
    return order;
  }

  Future<Order?> updateOrder(Order order) async {
    try {
      final response = await Supabase.instance.client
          .from('orders')
          .update(order.toMap())
          .eq('id', order.id)
          .select()
          .maybeSingle();

      if (response != null) {
        final updated = Order.fromMap(response);
        await OrderStorage.updateOrder(updated);
        return updated;
      }
    } catch (e) {
      await OrderStorage.updateOrder(order);
    }
    return order;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final order = await fetchOrderById(orderId);
    if (order != null) {
      final updated = order.copyWith(status: _parseStatus(status));
      await updateOrder(updated);
    }
  }

  Future<List<Order>> getPendingOrders(String sellerId) async {
    final orders = await fetchOrdersBySeller(sellerId);
    return orders.where((o) => o.isPending).toList();
  }

  Future<List<Order>> getCompletedOrders(String sellerId) async {
    final orders = await fetchOrdersBySeller(sellerId);
    return orders.where((o) => o.isDelivered).toList();
  }

  Future<double> getTotalRevenue(String sellerId) async {
    final orders = await fetchOrdersBySeller(sellerId);
    double total = 0;
    for (final order in orders) {
      if (order.paymentStatus.value == 'completed') {
        total += order.total;
      }
    }
    return total;
  }

  Future<Map<String, dynamic>> getDashboardStats(String sellerId) async {
    final orders = await fetchOrdersBySeller(sellerId);
    
    int totalOrders = orders.length;
    double totalRevenue = 0;
    int pendingOrders = 0;
    int completedOrders = 0;
    
    for (final order in orders) {
      if (order.paymentStatus.value == 'completed') {
        totalRevenue += order.total;
      }
      if (order.isPending) pendingOrders++;
      if (order.isDelivered) completedOrders++;
    }

    return {
      'total_orders': totalOrders,
      'total_revenue': totalRevenue,
      'pending_orders': pendingOrders,
      'completed_orders': completedOrders,
    };
  }

  _parseStatus(String status) {
    switch (status) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'refunded':
        return OrderStatus.refunded;
      default:
        return OrderStatus.pending;
    }
  }
}