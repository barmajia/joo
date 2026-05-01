import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:aurora/services/vault_service.dart';
import 'package:aurora/models/customers/customermodel.dart';

class CustomerVaultStorage {
  static CustomerVaultStorage? _instance;
  late final VaultStorage _vault;
  static bool _initialized = false;

  CustomerVaultStorage._();

  static Future<CustomerVaultStorage> getInstance() async {
    if (_instance == null || !_initialized) {
      _instance = CustomerVaultStorage._();
      _instance!._vault = await VaultStorage.getInstance();
      _initialized = true;
    }
    return _instance!;
  }

  Future<void> saveCustomer(String customerId, Customer customer) async {
    try {
      final customerJson = customer.toMap();
      await _vault.saveMap('customer_$customerId', customerJson);
    } catch (e) {
      debugPrint('[CustomerVaultStorage.saveCustomer] Error: $e');
      rethrow;
    }
  }

  Customer? getCustomer(String customerId) {
    try {
      final customerJson = _vault.getMap('customer_$customerId');
      if (customerJson == null) return null;
      return Customer.fromMap(customerJson);
    } catch (e) {
      debugPrint('[CustomerVaultStorage.getCustomer] Error: $e');
      return null;
    }
  }

  Future<void> saveSellerCustomers(String sellerId, List<Customer> customers) async {
    try {
      final customersJson = customers.map((c) => c.toMap()).toList();
      await _vault.saveList('seller_customers_$sellerId', customersJson);
    } catch (e) {
      debugPrint('[CustomerVaultStorage.saveSellerCustomers] Error: $e');
      rethrow;
    }
  }

  List<Customer> getSellerCustomers(String sellerId) {
    try {
      final customersJson = _vault.getList('seller_customers_$sellerId');
      if (customersJson == null) return [];

      return customersJson
          .map((c) => Customer.fromMap(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[CustomerVaultStorage.getSellerCustomers] Error: $e');
      return [];
    }
  }

  Future<void> updateCustomer(String customerId, Map<String, dynamic> updates) async {
    try {
      final existing = _vault.getMap('customer_$customerId');
      if (existing != null) {
        existing.addAll(updates);
        await _vault.saveMap('customer_$customerId', existing);
      }
    } catch (e) {
      debugPrint('[CustomerVaultStorage.updateCustomer] Error: $e');
      rethrow;
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      await _vault.remove('customer_$customerId');
    } catch (e) {
      debugPrint('[CustomerVaultStorage.deleteCustomer] Error: $e');
      rethrow;
    }
  }

  Future<void> deleteSellerCustomers(String sellerId) async {
    try {
      await _vault.remove('seller_customers_$sellerId');
    } catch (e) {
      debugPrint('[CustomerVaultStorage.deleteSellerCustomers] Error: $e');
      rethrow;
    }
  }

  Future<void> refreshSellerCustomers(String sellerId, List<Customer> customers) async {
    try {
      await deleteSellerCustomers(sellerId);
      await saveSellerCustomers(sellerId, customers);

      for (final customer in customers) {
        await saveCustomer(customer.id, customer);
      }
    } catch (e) {
      debugPrint('[CustomerVaultStorage.refreshSellerCustomers] Error: $e');
      rethrow;
    }
  }

  Future<bool> hasCustomer(String customerId) async {
    try {
      return _vault.getMap('customer_$customerId') != null;
    } catch (e) {
      debugPrint('[CustomerVaultStorage.hasCustomer] Error: $e');
      return false;
    }
  }

  Future<List<String>> getAllCachedCustomerIds() async {
    try {
      final keys = await _vault.getAllKeys();
      return keys
          .where((k) => k.startsWith('customer_') && !k.startsWith('seller_customers_'))
          .map((k) => k.replaceFirst('customer_', ''))
          .toList();
    } catch (e) {
      debugPrint('[CustomerVaultStorage.getAllCachedCustomerIds] Error: $e');
      return [];
    }
  }

  Future<void> clearAllCachedCustomers() async {
    try {
      final keys = await _vault.getAllKeys();
      for (final key in keys) {
        if (key.startsWith('customer_') || key.startsWith('seller_customers_')) {
          await _vault.remove(key);
        }
      }
    } catch (e) {
      debugPrint('[CustomerVaultStorage.clearAllCachedCustomers] Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getVaultStats() async {
    try {
      final keys = await _vault.getAllKeys();
      final customerKeys = keys.where((k) => k.startsWith('customer_')).toList();
      final sellerKeys = keys.where((k) => k.startsWith('seller_customers_')).toList();

      return {
        'total_customers': customerKeys.length,
        'total_seller_caches': sellerKeys.length,
        'customer_ids': customerKeys.map((k) => k.replaceFirst('customer_', '')).toList(),
        'seller_ids': sellerKeys.map((k) => k.replaceFirst('seller_customers_', '')).toList(),
      };
    } catch (e) {
      debugPrint('[CustomerVaultStorage.getVaultStats] Error: $e');
      return {};
    }
  }
}
