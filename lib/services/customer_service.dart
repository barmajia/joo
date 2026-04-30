import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/models/customers/customermodel.dart';
import 'package:aurora/storage/customer_storage.dart';
import 'package:aurora/storage/customer_vault_storage.dart';

class CustomerService {
  static final CustomerService _instance = CustomerService._internal();
  factory CustomerService() => _instance;
  CustomerService._internal();

  CustomerVaultStorage? _vault;

  Future<CustomerVaultStorage> _getVault() async {
    _vault ??= await CustomerVaultStorage.getInstance();
    return _vault!;
  }

  Future<List<Customer>> fetchCustomers(String sellerId) async {
    try {
      final response = await Supabase.instance.client
          .from('customers')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      final customers = response.map((item) => Customer.fromMap(item)).toList();

      final vault = await _getVault();

      if (customers.isNotEmpty) {
        await CustomerStorage.saveCustomers(customers);
        await vault.refreshSellerCustomers(sellerId, customers);
        return customers;
      }

      // Supabase returned empty, try vault cache
      final cached = vault.getSellerCustomers(sellerId);
      if (cached.isNotEmpty) return cached;

      // Fall back to shared preferences
      return await CustomerStorage.getCustomers();
    } catch (e) {
      debugPrint('[CustomerService.fetchCustomers] Error: $e');
      final vault = await _getVault();
      final cached = vault.getSellerCustomers(sellerId);
      if (cached.isNotEmpty) return cached;
      return await CustomerStorage.getCustomers();
    }
  }

  Future<Customer?> fetchCustomerById(String customerId) async {
    try {
      final response = await Supabase.instance.client
          .from('customers')
          .select()
          .eq('id', customerId)
          .maybeSingle();

      if (response != null) {
        return Customer.fromMap(response);
      }
    } catch (e) {
      debugPrint('[CustomerService.fetchCustomerById] Error: $e');
      // fallback to cache
    }
    return null;
  }

  Future<Customer?> createCustomer(Customer customer) async {
    try {
      final response = await Supabase.instance.client
          .from('customers')
          .insert(customer.toMap())
          .select()
          .maybeSingle();

      final savedCustomer = response != null
          ? Customer.fromMap(response)
          : customer;

      await CustomerStorage.addCustomer(savedCustomer);
      final vault = await _getVault();
      await vault.saveCustomer(savedCustomer.id, savedCustomer);

      // Update seller index
      final sellerId = savedCustomer.sellerId;
      if (sellerId.isNotEmpty) {
        final existing = vault.getSellerCustomers(sellerId);
        if (!existing.any((c) => c.id == savedCustomer.id)) {
          final updated = [savedCustomer, ...existing];
          await vault.saveSellerCustomers(sellerId, updated);
        }
      }

      return savedCustomer;
    } catch (e) {
      debugPrint('[CustomerService.createCustomer] Error: $e');
      await CustomerStorage.addCustomer(customer);
      final vault = await _getVault();
      await vault.saveCustomer(customer.id, customer);

      final sellerId = customer.sellerId;
      if (sellerId.isNotEmpty) {
        final existing = vault.getSellerCustomers(sellerId);
        if (!existing.any((c) => c.id == customer.id)) {
          final updated = [customer, ...existing];
          await vault.saveSellerCustomers(sellerId, updated);
        }
      }

      return customer;
    }
  }

  Future<Customer?> updateCustomer(Customer customer) async {
    try {
      final response = await Supabase.instance.client
          .from('customers')
          .update(customer.toMap())
          .eq('id', customer.id)
          .select()
          .maybeSingle();

      final updated = response != null ? Customer.fromMap(response) : customer;

      await CustomerStorage.updateCustomer(updated);
      final vault = await _getVault();
      await vault.saveCustomer(updated.id, updated);

      // Update seller index
      final sellerId = updated.sellerId;
      if (sellerId.isNotEmpty) {
        final existing = vault.getSellerCustomers(sellerId);
        final index = existing.indexWhere((c) => c.id == updated.id);
        if (index != -1) {
          existing[index] = updated;
          await vault.saveSellerCustomers(sellerId, existing);
        }
      }

      return updated;
    } catch (e) {
      debugPrint('[CustomerService.updateCustomer] Error: $e');
      await CustomerStorage.updateCustomer(customer);
      final vault = await _getVault();
      await vault.saveCustomer(customer.id, customer);

      final sellerId = customer.sellerId;
      if (sellerId.isNotEmpty) {
        final existing = vault.getSellerCustomers(sellerId);
        final index = existing.indexWhere((c) => c.id == customer.id);
        if (index != -1) {
          existing[index] = customer;
          await vault.saveSellerCustomers(sellerId, existing);
        }
      }

      return customer;
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      await Supabase.instance.client
          .from('customers')
          .delete()
          .eq('id', customerId);
      await CustomerStorage.deleteCustomer(customerId);
      final vault = await _getVault();
      await vault.deleteCustomer(customerId);
    } catch (e) {
      debugPrint('[CustomerService.deleteCustomer] Error: $e');
      rethrow;
    }
  }

  Future<List<Customer>> searchCustomers(String sellerId, String query) async {
    final customers = await fetchCustomers(sellerId);
    final lowerQuery = query.toLowerCase();
    return customers
        .where(
          (c) =>
              c.name.toLowerCase().contains(lowerQuery) ||
              c.phone.contains(lowerQuery) ||
              (c.email?.toLowerCase().contains(lowerQuery) ?? false),
        )
        .toList();
  }
}
