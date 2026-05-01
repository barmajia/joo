import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:aurora/services/vault_service.dart';
import 'package:aurora/models/customers/customerbill.dart';

class BillVaultStorage {
  static BillVaultStorage? _instance;
  late final VaultStorage _vault;
  static bool _initialized = false;

  BillVaultStorage._();

  static Future<BillVaultStorage> getInstance() async {
    if (_instance == null || !_initialized) {
      _instance = BillVaultStorage._();
      _instance!._vault = await VaultStorage.getInstance();
      _initialized = true;
    }
    return _instance!;
  }

  Future<void> saveBill(String orderId, Order order) async {
    try {
      final orderJson = order.toMap();
      await _vault.saveMap('bill_$orderId', orderJson);
    } catch (e) {
      debugPrint('[BillVaultStorage.saveBill] Error: $e');
      rethrow;
    }
  }

  Order? getBill(String orderId) {
    try {
      final orderJson = _vault.getMap('bill_$orderId');
      if (orderJson == null) return null;
      return Order.fromMap(orderJson);
    } catch (e) {
      debugPrint('[BillVaultStorage.getBill] Error: $e');
      return null;
    }
  }

  Future<void> saveCustomerBills(String customerId, List<Order> orders) async {
    try {
      final ordersJson = orders.map((o) => o.toMap()).toList();
      await _vault.saveList('customer_bills_$customerId', ordersJson);
    } catch (e) {
      debugPrint('[BillVaultStorage.saveCustomerBills] Error: $e');
      rethrow;
    }
  }

  List<Order> getCustomerBills(String customerId) {
    try {
      final ordersJson = _vault.getList('customer_bills_$customerId');
      if (ordersJson == null) return [];

      return ordersJson
          .map((o) => Order.fromMap(o as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[BillVaultStorage.getCustomerBills] Error: $e');
      return [];
    }
  }

  Future<void> saveSellerBills(String sellerId, List<Order> orders) async {
    try {
      final ordersJson = orders.map((o) => o.toMap()).toList();
      await _vault.saveList('seller_bills_$sellerId', ordersJson);
    } catch (e) {
      debugPrint('[BillVaultStorage.saveSellerBills] Error: $e');
      rethrow;
    }
  }

  List<Order> getSellerBills(String sellerId) {
    try {
      final ordersJson = _vault.getList('seller_bills_$sellerId');
      if (ordersJson == null) return [];

      return ordersJson
          .map((o) => Order.fromMap(o as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[BillVaultStorage.getSellerBills] Error: $e');
      return [];
    }
  }

  List<Order> getBillsByStatus(String sellerId, String status) {
    try {
      final allBills = getSellerBills(sellerId);
      return allBills.where((o) => o.status.name == status).toList();
    } catch (e) {
      debugPrint('[BillVaultStorage.getBillsByStatus] Error: $e');
      return [];
    }
  }

  Future<void> updateBill(String orderId, Map<String, dynamic> updates) async {
    try {
      final existing = _vault.getMap('bill_$orderId');
      if (existing != null) {
        existing.addAll(updates);
        await _vault.saveMap('bill_$orderId', existing);
      }
    } catch (e) {
      debugPrint('[BillVaultStorage.updateBill] Error: $e');
      rethrow;
    }
  }

  Future<void> deleteBill(String orderId) async {
    try {
      await _vault.remove('bill_$orderId');
    } catch (e) {
      debugPrint('[BillVaultStorage.deleteBill] Error: $e');
      rethrow;
    }
  }

  Future<void> deleteSellerBills(String sellerId) async {
    try {
      await _vault.remove('seller_bills_$sellerId');
    } catch (e) {
      debugPrint('[BillVaultStorage.deleteSellerBills] Error: $e');
      rethrow;
    }
  }

  Future<void> deleteCustomerBills(String customerId) async {
    try {
      await _vault.remove('customer_bills_$customerId');
    } catch (e) {
      debugPrint('[BillVaultStorage.deleteCustomerBills] Error: $e');
      rethrow;
    }
  }

  Future<void> refreshSellerBills(String sellerId, List<Order> orders) async {
    try {
      await deleteSellerBills(sellerId);
      await saveSellerBills(sellerId, orders);

      for (final order in orders) {
        if (order.id.isNotEmpty) {
          await saveBill(order.id, order);
        }
      }

      final customerBillsMap = <String, List<Order>>{};
      for (final order in orders) {
        final userId = order.userId;
        if (userId.isNotEmpty) {
          customerBillsMap.putIfAbsent(userId, () => []);
          customerBillsMap[userId]!.add(order);
        }
      }

      for (final entry in customerBillsMap.entries) {
        await saveCustomerBills(entry.key, entry.value);
      }
    } catch (e) {
      debugPrint('[BillVaultStorage.refreshSellerBills] Error: $e');
      rethrow;
    }
  }

  Future<bool> hasBill(String orderId) async {
    try {
      return _vault.getMap('bill_$orderId') != null;
    } catch (e) {
      debugPrint('[BillVaultStorage.hasBill] Error: $e');
      return false;
    }
  }

  Future<List<String>> getAllCachedBillIds() async {
    try {
      final keys = await _vault.getAllKeys();
      return keys
          .where((k) => k.startsWith('bill_') && !k.startsWith('seller_bills_') && !k.startsWith('customer_bills_'))
          .map((k) => k.replaceFirst('bill_', ''))
          .toList();
    } catch (e) {
      debugPrint('[BillVaultStorage.getAllCachedBillIds] Error: $e');
      return [];
    }
  }

  Future<void> clearAllCachedBills() async {
    try {
      final keys = await _vault.getAllKeys();
      for (final key in keys) {
        if (key.startsWith('bill_') || key.startsWith('seller_bills_') || key.startsWith('customer_bills_')) {
          await _vault.remove(key);
        }
      }
    } catch (e) {
      debugPrint('[BillVaultStorage.clearAllCachedBills] Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getVaultStats() async {
    try {
      final keys = await _vault.getAllKeys();
      final billKeys = keys.where((k) => k.startsWith('bill_') && !k.startsWith('seller_bills_') && !k.startsWith('customer_bills_')).toList();
      final sellerKeys = keys.where((k) => k.startsWith('seller_bills_')).toList();
      final customerKeys = keys.where((k) => k.startsWith('customer_bills_')).toList();

      return {
        'total_bills': billKeys.length,
        'total_seller_caches': sellerKeys.length,
        'total_customer_caches': customerKeys.length,
        'bill_ids': billKeys.map((k) => k.replaceFirst('bill_', '')).toList(),
        'seller_ids': sellerKeys.map((k) => k.replaceFirst('seller_bills_', '')).toList(),
        'customer_ids': customerKeys.map((k) => k.replaceFirst('customer_bills_', '')).toList(),
      };
    } catch (e) {
      debugPrint('[BillVaultStorage.getVaultStats] Error: $e');
      return {};
    }
  }
}
