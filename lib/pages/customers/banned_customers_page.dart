import 'package:flutter/material.dart';
import 'package:aurora/services/customer_service.dart';
import 'package:aurora/storage/banned_customer_storage.dart';
import 'package:aurora/models/customers/customermodel.dart';
import 'package:aurora/models/customers/customerbill.dart';

class BannedCustomersPage extends StatefulWidget {
  const BannedCustomersPage({super.key});

  @override
  State<BannedCustomersPage> createState() => _BannedCustomersPageState();
}

class _BannedCustomersPageState extends State<BannedCustomersPage> {
  final _customerService = CustomerService();
  final _bannedStorage = BannedCustomerStorage.getInstance();
  List<Customer> _bannedCustomers = [];
  Map<String, List<Order>> _customerBills = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBannedCustomers();
  }

  Future<void> _loadBannedCustomers() async {
    setState(() => _isLoading = true);
    try {
      final customers = await _customerService.getBannedCustomers();
      setState(() => _bannedCustomers = customers);

      final storage = await _bannedStorage;
      for (final customer in customers) {
        final bills = storage.getBannedCustomerBills(customer.id);
        _customerBills[customer.id] = bills;
      }
    } catch (e) {
      debugPrint('[BannedCustomersPage] Error loading banned customers: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _unbanCustomer(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unban Customer'),
        content: Text('Are you sure you want to unban "${customer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unban'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _customerService.unbanCustomer(customer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${customer.name} has been unbanned'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBannedCustomers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error unbanning customer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banned Customers'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bannedCustomers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No banned customers',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _bannedCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = _bannedCustomers[index];
                    final bills = _customerBills[customer.id] ?? [];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ExpansionTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Icon(Icons.block, color: Colors.white),
                        ),
                        title: Text(customer.name),
                        subtitle: Text(
                          '${customer.phone.isNotEmpty ? customer.phone : 'No phone'} • ${bills.length} bill(s)',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.undo, color: Colors.green),
                          onPressed: () => _unbanCustomer(customer),
                          tooltip: 'Unban customer',
                        ),
                        children: bills.isEmpty
                            ? [
                                const ListTile(
                                  title: Text('No bills found'),
                                ),
                              ]
                            : bills.map((bill) {
                                return ListTile(
                                  contentPadding: const EdgeInsets.only(
                                    left: 32,
                                    right: 16,
                                  ),
                                  title: Text(
                                    'Bill #${bill.id.substring(0, 8)}',
                                  ),
                                  subtitle: Text(
                                    '${bill.items.length} item(s) • ${bill.status.name}',
                                  ),
                                  trailing: Text(
                                    '\$${bill.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                      ),
                    );
                  },
                ),
    );
  }
}
