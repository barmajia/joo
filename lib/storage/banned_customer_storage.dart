import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:aurora/services/vault_service.dart';
import 'package:aurora/models/customers/customermodel.dart';
import 'package:aurora/models/customers/customerbill.dart';

class BannedCustomerStorage {
  static BannedCustomerStorage? _instance;
  late final VaultStorage _vault;
  static bool _initialized = false;

  BannedCustomerStorage._();

  static Future<BannedCustomerStorage> getInstance() async {
    if (_instance == null || !_initialized) {
      _instance = BannedCustomerStorage._();
      _instance!._vault = await VaultStorage.getInstance();
      _initialized = true;
    }
    return _instance!;
  }

  Future<void> banCustomer(String customerId, Customer customer, List<Order> bills) async {
    try {
      final customerJson = customer.toMap();
      customerJson['banned_at'] = DateTime.now().toIso8601String();
      customerJson['bills_count'] = bills.length;
      await _vault.saveMap('banned_customer_$customerId', customerJson);

      for (final bill in bills) {
        await _vault.saveMap('banned_bill_${bill.id}', bill.toMap());
      }

      final bannedList = await getBannedCustomerIds();
      if (!bannedList.contains(customerId)) {
        bannedList.add(customerId);
        await _vault.saveList('banned_customers_list', bannedList);
      }

      debugPrint('[BannedCustomerStorage.banCustomer] Banned customer $customerId with ${bills.length} bills');
    } catch (e) {
      debugPrint('[BannedCustomerStorage.banCustomer] Error: $e');
      rethrow;
    }
  }

  Future<bool> isCustomerBanned(String customerId) async {
    try {
      return _vault.getMap('banned_customer_$customerId') != null;
    } catch (e) {
      debugPrint('[BannedCustomerStorage.isCustomerBanned] Error: $e');
      return false;
    }
  }

  Customer? getBannedCustomer(String customerId) {
    try {
      final customerJson = _vault.getMap('banned_customer_$customerId');
      if (customerJson == null) return null;
      return Customer.fromMap(customerJson);
    } catch (e) {
      debugPrint('[BannedCustomerStorage.getBannedCustomer] Error: $e');
      return null;
    }
  }

  Future<List<String>> getBannedCustomerIds() async {
    try {
      final list = _vault.getList('banned_customers_list');
      return list?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      debugPrint('[BannedCustomerStorage.getBannedCustomerIds] Error: $e');
      return [];
    }
  }

  List<Order> getBannedCustomerBills(String customerId) {
    try {
      final billsJson = _vault.getList('banned_customer_bills_$customerId');
      if (billsJson == null) return [];
      return billsJson
          .map((e) => Order.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[BannedCustomerStorage.getBannedCustomerBills] Error: $e');
      return [];
    }
  }

  Future<void> saveBannedCustomerBills(String customerId, List<Order> bills) async {
    try {
      final billsJson = bills.map((b) => b.toMap()).toList();
      await _vault.saveList('banned_customer_bills_$customerId', billsJson);
    } catch (e) {
      debugPrint('[BannedCustomerStorage.saveBannedCustomerBills] Error: $e');
      rethrow;
    }
  }

  Future<void> deleteBannedBill(String billId, String customerId) async {
    try {
      await _vault.remove('banned_bill_$billId');

      final bills = getBannedCustomerBills(customerId);
      bills.removeWhere((b) => b.id == billId);
      await saveBannedCustomerBills(customerId, bills);
    } catch (e) {
      debugPrint('[BannedCustomerStorage.deleteBannedBill] Error: $e');
      rethrow;
    }
  }

  Future<List<Customer>> getAllBannedCustomers() async {
    try {
      final ids = await getBannedCustomerIds();
      final customers = <Customer>[];
      for (final id in ids) {
        final customer = getBannedCustomer(id);
        if (customer != null) {
          customers.add(customer);
        }
      }
      return customers;
    } catch (e) {
      debugPrint('[BannedCustomerStorage.getAllBannedCustomers] Error: $e');
      return [];
    }
  }

  Future<void> unbanCustomer(String customerId) async {
    try {
      await _vault.remove('banned_customer_$customerId');

      final bannedList = await getBannedCustomerIds();
      bannedList.remove(customerId);
      await _vault.saveList('banned_customers_list', bannedList);

      final bills = getBannedCustomerBills(customerId);
      for (final bill in bills) {
        await _vault.remove('banned_bill_${bill.id}');
      }
      await _vault.remove('banned_customer_bills_$customerId');

      debugPrint('[BannedCustomerStorage.unbanCustomer] Unbanned customer $customerId');
    } catch (e) {
      debugPrint('[BannedCustomerStorage.unbanCustomer] Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getBannedStats() async {
    try {
      final ids = await getBannedCustomerIds();
      int totalBills = 0;
      for (final id in ids) {
        totalBills += getBannedCustomerBills(id).length;
      }
      return {
        'total_banned_customers': ids.length,
        'total_banned_bills': totalBills,
      };
    } catch (e) {
      debugPrint('[BannedCustomerStorage.getBannedStats] Error: $e');
      return {};
    }
  }
}
