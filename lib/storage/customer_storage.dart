import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aurora/models/customers/customermodel.dart';

class CustomerStorage {
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

  static Future<void> saveCustomers(List<Customer> customers) async {
    final list = customers.map((c) => c.toMap()).toList();
    await _saveString('customers_list', jsonEncode(list));
  }

  static Future<List<Customer>> getCustomers() async {
    final value = await _getString('customers_list');
    if (value == null || value.isEmpty) return [];
    try {
      final list = jsonDecode(value) as List;
      return list
          .map((item) => Customer.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Customer?> getCustomerById(String id) async {
    final customers = await getCustomers();
    try {
      return customers.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  static Future<void> addCustomer(Customer customer) async {
    final customers = await getCustomers();
    customers.insert(0, customer);
    await saveCustomers(customers);
  }

  static Future<void> updateCustomer(Customer customer) async {
    final customers = await getCustomers();
    final index = customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      customers[index] = customer;
      await saveCustomers(customers);
    }
  }

  static Future<void> deleteCustomer(String id) async {
    final customers = await getCustomers();
    customers.removeWhere((c) => c.id == id);
    await saveCustomers(customers);
  }

  static Future<void> clearCustomers() async {
    await _prefs.remove('customers_list');
  }
}