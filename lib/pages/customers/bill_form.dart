import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:aurora/models/customers/customermodel.dart';
import 'package:aurora/models/customers/customerbill.dart';
import 'package:aurora/models/analysis/enums.dart';
import 'package:aurora/models/product/productModel.dart';
import 'package:aurora/services/order_service.dart';
import 'package:aurora/services/customer_service.dart';
import 'package:aurora/services/product_service.dart';
import 'package:aurora/storage/userStorage.dart';

class _BillLineItem {
  final String id;
  final Product product;
  int quantity;
  final double unitPrice;

  _BillLineItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => quantity * unitPrice;
}

class BillFormPage extends StatefulWidget {
  final Customer? customer;

  const BillFormPage({super.key, this.customer});

  @override
  State<BillFormPage> createState() => _BillFormPageState();
}

class _BillFormPageState extends State<BillFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '0');
  final _shippingController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final OrderService _orderService = OrderService();
  final CustomerService _customerService = CustomerService();
  final ProductService _productService = ProductService();
  bool _isSaving = false;
  bool _isLoadingProducts = true;
  Customer? _selectedCustomer;
  List<Customer> _availableCustomers = [];
  List<Product> _availableProducts = [];
  final List<_BillLineItem> _lineItems = [];
  String _productSearch = '';

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.customer;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userStorage = Provider.of<UserStorage>(context, listen: false);
      final sellerId = userStorage.currentUser?.id;
      if (sellerId != null) {
        final customers = await _customerService.fetchCustomers(sellerId);
        final products = await _productService.getSellerProducts(sellerId);
        setState(() {
          _availableCustomers = customers;
          _availableProducts = products.where((p) => p.isInStock && !p.isDeleted).toList();
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('[BillFormPage._loadData] Error: $e');
      setState(() => _isLoadingProducts = false);
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    _taxController.dispose();
    _shippingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return _lineItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get _total {
    final discount = double.tryParse(_discountController.text) ?? 0;
    final tax = double.tryParse(_taxController.text) ?? 0;
    final shipping = double.tryParse(_shippingController.text) ?? 0;
    return _subtotal - discount + tax + shipping;
  }

  Future<void> _selectProduct(Product product) async {
    final existingIndex = _lineItems.indexWhere((item) => item.product.id == product.id);
    if (existingIndex != -1) {
      final existing = _lineItems[existingIndex];
      final maxQty = product.quantity - existing.quantity;
      if (maxQty <= 0) return;

      final result = await showDialog<int>(
        context: context,
        builder: (context) => _QuantityDialog(
          maxQuantity: maxQty,
          currentQuantity: existing.quantity,
        ),
      );

      if (result != null && result > 0) {
        setState(() {
          _lineItems[existingIndex] = _BillLineItem(
            id: existing.id,
            product: product,
            quantity: result,
            unitPrice: existing.unitPrice,
          );
        });
      }
    } else {
      final result = await showDialog<int>(
        context: context,
        builder: (context) => _QuantityDialog(
          maxQuantity: product.quantity,
          currentQuantity: 1,
        ),
      );

      if (result != null && result > 0) {
        setState(() {
          _lineItems.add(_BillLineItem(
            id: const Uuid().v4(),
            product: product,
            quantity: result,
            unitPrice: product.price ?? 0,
          ));
        });
      }
    }
  }

  void _removeItem(int index) {
    setState(() => _lineItems.removeAt(index));
  }

  void _showProductPicker() {
    showDialog(
      context: context,
      builder: (context) => _ProductPickerDialog(
        products: _availableProducts,
        selectedIds: _lineItems.map((item) => item.product.id).toSet(),
        onSelect: _selectProduct,
      ),
    );
  }

  Future<void> _saveBill() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }
    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final userStorage = Provider.of<UserStorage>(context, listen: false);
      final sellerId = userStorage.currentUser?.id ?? '';

      final orderItems = _lineItems.map((item) {
        return OrderItem(
          id: const Uuid().v4(),
          orderId: '',
          asin: item.product.asin ?? '',
          productId: item.product.id,
          productName: item.product.title,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          totalPrice: item.totalPrice,
        );
      }).toList();

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
        items: orderItems,
      );

      final created = await _orderService.createOrder(order);
      if (created == null) throw Exception('Failed to create order');

      for (final item in _lineItems) {
        try {
          await _productService.deductQuantity(
            item.product.id!,
            item.quantity,
            sellerId,
          );
        } catch (e) {
          debugPrint('[BillForm._saveBill] Failed to deduct ${item.product.title}: $e');
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
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
    if (_isLoadingProducts) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
              const Text('Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_lineItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: _availableProducts.isEmpty
                        ? Column(
                            children: [
                              const Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(
                                'No products in stock',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          )
                        : TextButton.icon(
                            onPressed: _showProductPicker,
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('Select Product'),
                          ),
                  ),
                )
              else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _lineItems.length,
                  itemBuilder: (context, index) {
                    final item = _lineItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          child: const Icon(Icons.inventory_2, size: 20),
                        ),
                        title: Text(item.product.title),
                        subtitle: Text(
                          '${item.quantity} x EGP ${item.unitPrice.toStringAsFixed(2)} • Stock: ${item.product.quantity}',
                        ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: _showProductPicker,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Product'),
                    ),
                    Text(
                      '${_lineItems.length} item(s)',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (_lineItems.isNotEmpty) ...[
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
                  onPressed: _isSaving || _lineItems.isEmpty ? null : _saveBill,
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

class _ProductPickerDialog extends StatefulWidget {
  final List<Product> products;
  final Set<String?> selectedIds;
  final Function(Product) onSelect;

  const _ProductPickerDialog({
    required this.products,
    required this.selectedIds,
    required this.onSelect,
  });

  @override
  State<_ProductPickerDialog> createState() => _ProductPickerDialogState();
}

class _ProductPickerDialogState extends State<_ProductPickerDialog> {
  String _searchQuery = '';

  List<Product> get _filtered {
    if (_searchQuery.isEmpty) return widget.products;
    final query = _searchQuery.toLowerCase();
    return widget.products.where((p) =>
        p.title.toLowerCase().contains(query) ||
        (p.sku?.toLowerCase().contains(query) ?? false) ||
        (p.brand.toLowerCase().contains(query))).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Product'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
            ),
            const SizedBox(height: 12),
            if (_filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No products found'),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final product = _filtered[index];
                    final isSelected = widget.selectedIds.contains(product.id);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.grey[200],
                        child: Icon(
                          isSelected ? Icons.check : Icons.inventory_2,
                          color: isSelected ? Colors.green : Colors.grey[600],
                        ),
                      ),
                      title: Text(product.title),
                      subtitle: Text(
                        'EGP ${product.price?.toStringAsFixed(2) ?? '0.00'} • ${product.quantity} in stock',
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSelect(product);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _QuantityDialog extends StatefulWidget {
  final int maxQuantity;
  final int currentQuantity;

  const _QuantityDialog({
    required this.maxQuantity,
    required this.currentQuantity,
  });

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  late int _quantity;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _quantity = widget.currentQuantity;
    _controller = TextEditingController(text: widget.currentQuantity.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Quantity (max: ${widget.maxQuantity})'),
      content: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: _quantity > 1
                ? () => setState(() {
                    _quantity--;
                    _controller.text = _quantity.toString();
                  })
                : null,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (value) {
                final parsed = int.tryParse(value);
                if (parsed != null && parsed > 0) {
                  setState(() => _quantity = parsed.clamp(1, widget.maxQuantity));
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _quantity < widget.maxQuantity
                ? () => setState(() {
                    _quantity++;
                    _controller.text = _quantity.toString();
                  })
                : null,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _quantity),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
