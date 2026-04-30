import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/models/customers/customerbill.dart';
import 'package:aurora/models/analysis/enums.dart';
import 'package:aurora/storage/order_storage.dart';
import 'package:aurora/storage/bill_vault_storage.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  BillVaultStorage? _vault;

  Future<BillVaultStorage> _getVault() async {
    _vault ??= await BillVaultStorage.getInstance();
    return _vault!;
  }

  Future<List<Order>> fetchOrdersBySeller(String sellerId) async {
    try {
      final response = await Supabase.instance.client
          .from('orders')
          .select('*, items:order_items(*)')
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      final orders = response.map((item) {
        final orderMap = Map<String, dynamic>.from(item);
        if (orderMap['items'] is List) {
          orderMap['items'] = (orderMap['items'] as List)
              .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
              .toList();
        }
        return Order.fromMap(orderMap);
      }).toList();

      await OrderStorage.saveOrders(orders);
      final vault = await _getVault();
      await vault.refreshSellerBills(sellerId, orders);
      return orders;
    } catch (e) {
      debugPrint('[OrderService.fetchOrdersBySeller] Error: $e');
      final vault = await _getVault();
      final cached = vault.getSellerBills(sellerId);
      if (cached.isNotEmpty) return cached;
      return await OrderStorage.getOrders();
    }
  }

  Future<List<Order>> fetchOrdersByCustomer(String customerId) async {
    try {
      final response = await Supabase.instance.client
          .from('orders')
          .select('*, items:order_items(*)')
          .eq('user_id', customerId)
          .order('created_at', ascending: false);

      final orders = response.map((item) {
        final orderMap = Map<String, dynamic>.from(item);
        if (orderMap['items'] is List) {
          orderMap['items'] = (orderMap['items'] as List)
              .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
              .toList();
        }
        return Order.fromMap(orderMap);
      }).toList();

      final vault = await _getVault();
      await vault.saveCustomerBills(customerId, orders);
      return orders;
    } catch (e) {
      debugPrint('[OrderService.fetchOrdersByCustomer] Error: $e');
      final vault = await _getVault();
      final cached = vault.getCustomerBills(customerId);
      if (cached.isNotEmpty) return cached;
      return await OrderStorage.getOrdersByCustomer(customerId);
    }
  }

  Future<Order?> fetchOrderById(String orderId) async {
    try {
      final response = await Supabase.instance.client
          .from('orders')
          .select('*, items:order_items(*)')
          .eq('id', orderId)
          .maybeSingle();

      if (response != null) {
        final orderMap = Map<String, dynamic>.from(response);
        if (orderMap['items'] is List) {
          orderMap['items'] = (orderMap['items'] as List)
              .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
              .toList();
        }
        return Order.fromMap(orderMap);
      }
    } catch (e) {
      debugPrint('[OrderService.fetchOrderById] Error: $e');
      return await OrderStorage.getOrderById(orderId);
    }
    return null;
  }

  Future<Order?> createOrder(Order order) async {
    try {
      final orderMap = order.toMap();
      final items = order.items;
      orderMap.remove('items');

      final response = await Supabase.instance.client
          .from('orders')
          .insert(orderMap)
          .select()
          .maybeSingle();

      if (response != null) {
        final created = Order.fromMap(response);

        if (items.isNotEmpty) {
          await _insertOrderItems(created.id, items);
        }

        await OrderStorage.addOrder(created);
        final vault = await _getVault();
        await vault.saveBill(created.id, created);
        return created;
      }
    } catch (e) {
      debugPrint('[OrderService.createOrder] Error: $e');
      rethrow;
    }
    return null;
  }

  Future<Order?> updateOrder(Order order) async {
    try {
      final orderMap = order.toMap();
      final items = order.items;
      orderMap.remove('items');

      final response = await Supabase.instance.client
          .from('orders')
          .update(orderMap)
          .eq('id', order.id)
          .select()
          .maybeSingle();

      if (response != null) {
        final updated = Order.fromMap(response);

        await _deleteOrderItems(updated.id);
        if (items.isNotEmpty) {
          await _insertOrderItems(updated.id, items);
        }

        await OrderStorage.updateOrder(updated);
        final vault = await _getVault();
        await vault.saveBill(updated.id, updated);
        return updated;
      }
    } catch (e) {
      debugPrint('[OrderService.updateOrder] Error: $e');
      await OrderStorage.updateOrder(order);
      final vault = await _getVault();
      await vault.saveBill(order.id, order);
    }
    return order;
  }

  Future<void> _insertOrderItems(String orderId, List<OrderItem> items) async {
    try {
      final itemsData = items
          .map((item) {
            final map = item.toMap();
            map['order_id'] = orderId;
            if (map['id'] == null || map['id'].toString().isEmpty) {
              map.remove('id');
            }
            return map;
          })
          .toList();

      await Supabase.instance.client
          .from('order_items')
          .insert(itemsData);
    } catch (e) {
      debugPrint('[OrderService._insertOrderItems] Error: $e');
      rethrow;
    }
  }

  Future<void> _deleteOrderItems(String orderId) async {
    try {
      await Supabase.instance.client
          .from('order_items')
          .delete()
          .eq('order_id', orderId);
    } catch (e) {
      debugPrint('[OrderService._deleteOrderItems] Error: $e');
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await _deleteOrderItems(orderId);
      await Supabase.instance.client
          .from('orders')
          .delete()
          .eq('id', orderId);
      await OrderStorage.deleteOrder(orderId);
      final vault = await _getVault();
      await vault.deleteBill(orderId);
    } catch (e) {
      debugPrint('[OrderService.deleteOrder] Error: $e');
      rethrow;
    }
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

  OrderStatus _parseStatus(String status) {
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
