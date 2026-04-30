import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:aurora/models/customers/customermodel.dart';
import 'package:aurora/models/customers/customerbill.dart';
import 'package:aurora/models/analysis/enums.dart';
import 'package:aurora/services/order_service.dart';
import 'package:aurora/services/customer_service.dart';
import 'package:aurora/storage/userStorage.dart';

class BillFormPage extends StatefulWidget {
  final Customer? customer;

  const BillFormPage({super.key, this.customer});

  @override
  State<BillFormPage> createState() => _BillFormPageState();
}

class _BillFormPageState extends State<BillFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _subtotalController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '0');
  final _shippingController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final OrderService _orderService = OrderService();
  final CustomerService _customerService = CustomerService();
  bool _isSaving = false;
  Customer? _selectedCustomer;
  List<Customer> _availableCustomers = [];
  final List<OrderItem> _items = [];

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.customer;
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final userStorage = Provider.of<UserStorage>(context, listen: false);
      final sellerId = userStorage.currentUser?.id;
      if (sellerId != null) {
        final customers = await _customerService.fetchCustomers(sellerId);
        setState(() => _availableCustomers = customers);
      }
    } catch (e) {
      debugPrint('[BillFormPage._loadCustomers] Error: $e');
    }
  }

  @override
  void dispose() {
    _subtotalController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _shippingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return _items.isEmpty
        ? (double.tryParse(_subtotalController.text) ?? 0)
        : _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get _total {
    final subtotal = _subtotal;
    final discount = double.tryParse(_discountController.text) ?? 0;
    final tax = double.tryParse(_taxController.text) ?? 0;
    final shipping = double.tryParse(_shippingController.text) ?? 0;
    return subtotal - discount + tax + shipping;
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        onAdd: (name, quantity, price) {
          setState(() {
            _items.add(OrderItem(
              id: const Uuid().v4(),
              orderId: '',
              asin: '',
              productName: name,
              quantity: quantity,
              unitPrice: price,
              totalPrice: quantity * price,
            ));
          });
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _saveBill() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final userStorage = Provider.of<UserStorage>(context, listen: false);
      final sellerId = userStorage.currentUser?.id ?? '';

      final order = Order(
        id: const Uuid().v4(),
        userId: _selectedCustomer!.id,
        sellerId: sellerId,
        subtotal: _subtotal,
        discount: double.tryParse(_discountController.text) ?? 0,
        tax: double.tryParse(_taxController.text) ?? 0,
        shipping: double.tryParse(_shippingController.text) ?? 0,
        total: _total,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        items: _items,
      );

      final created = await _orderService.createOrder(order);
      if (created == null) throw Exception('Failed to create order');

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill created successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('[BillForm._saveBill] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer != null ? 'Create Bill' : 'New Bill'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.customer == null) ...[
                _buildCustomerSelector(),
                const SizedBox(height: 16),
              ] else ...[
                _buildCustomerCard(),
                const SizedBox(height: 16),
              ],
              const Text('Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                    ),
                  ),
                )
              else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        title: Text(item.productName),
                        subtitle: Text('${item.quantity} x EGP ${item.unitPrice.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'EGP ${item.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () => _removeItem(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Another Item'),
                ),
              ],
              const SizedBox(height: 16),
              if (_items.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:', style: TextStyle(fontSize: 14)),
                      Text(
                        'EGP ${_subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _items.isEmpty ? _subtotalController : null,
                decoration: const InputDecoration(
                  labelText: 'Subtotal *',
                  border: OutlineInputBorder(),
                  prefixText: 'EGP ',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                validator: _items.isEmpty
                    ? (value) => value == null || value.isEmpty
                        ? 'Subtotal is required'
                        : null
                    : null,
                enabled: _items.isEmpty,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(
                  labelText: 'Discount',
                  border: OutlineInputBorder(),
                  prefixText: 'EGP ',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _taxController,
                decoration: const InputDecoration(
                  labelText: 'Tax',
                  border: OutlineInputBorder(),
                  prefixText: 'EGP ',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shippingController,
                decoration: const InputDecoration(
                  labelText: 'Shipping',
                  border: OutlineInputBorder(),
                  prefixText: 'EGP ',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
                    Text(
                      'EGP ${_total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentMethod>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: PaymentMethod.values.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(method.value),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _paymentMethod = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveBill,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Bill'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSelector() {
    return DropdownButtonFormField<Customer>(
      value: _selectedCustomer,
      decoration: const InputDecoration(
        labelText: 'Select Customer *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person_outline),
      ),
      items: _availableCustomers.map((customer) {
        return DropdownMenuItem(
          value: customer,
          child: Text('${customer.name} (${customer.phone})'),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCustomer = value),
      validator: (value) => value == null ? 'Please select a customer' : null,
    );
  }

  Widget _buildCustomerCard() {
    final customer = _selectedCustomer ?? widget.customer;
    if (customer == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              customer.initials,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(customer.phone, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddItemDialog extends StatefulWidget {
  final Function(String name, int quantity, double price) onAdd;

  const _AddItemDialog({required this.onAdd});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quantityController,
            decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: 'Unit Price', border: OutlineInputBorder(), prefixText: 'EGP '),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final quantity = int.tryParse(_quantityController.text) ?? 1;
            final price = double.tryParse(_priceController.text) ?? 0;
            if (name.isEmpty || price <= 0) return;
            widget.onAdd(name, quantity, price);
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
