import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/models/customers/customermodel.dart';
import 'package:aurora/storage/customer_storage.dart';

class CustomerService {
  static final CustomerService _instance = CustomerService._internal();
  factory CustomerService() => _instance;
  CustomerService._internal();

  Future<List<Customer>> fetchCustomers(String sellerId) async {
    try {
      final response = await Supabase.instance.client
          .from('customers')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      final customers = response
          .map((item) => Customer.fromMap(item as Map<String, dynamic>))
          .toList();

      await CustomerStorage.saveCustomers(customers);
      return customers;
    } catch (e) {
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

      if (response != null) {
        final newCustomer = Customer.fromMap(response);
        await CustomerStorage.addCustomer(newCustomer);
        return newCustomer;
      }
    } catch (e) {
      // fallback to local
      await CustomerStorage.addCustomer(customer);
    }
    return customer;
  }

  Future<Customer?> updateCustomer(Customer customer) async {
    try {
      final response = await Supabase.instance.client
          .from('customers')
          .update(customer.toMap())
          .eq('id', customer.id)
          .select()
          .maybeSingle();

      if (response != null) {
        final updated = Customer.fromMap(response);
        await CustomerStorage.updateCustomer(updated);
        return updated;
      }
    } catch (e) {
      await CustomerStorage.updateCustomer(customer);
    }
    return customer;
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      await Supabase.instance.client
          .from('customers')
          .delete()
          .eq('id', customerId);
    } catch (e) {
      // continue with local delete
    }
    await CustomerStorage.deleteCustomer(customerId);
  }

  Future<List<Customer>> searchCustomers(String sellerId, String query) async {
    final customers = await fetchCustomers(sellerId);
    final lowerQuery = query.toLowerCase();
    return customers.where((c) =>
        c.name.toLowerCase().contains(lowerQuery) ||
        c.phone.contains(lowerQuery) ||
        (c.email?.toLowerCase().contains(lowerQuery) ?? false)).toList();
  }
}