import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aurora/models/customers/customermodel.dart';
import 'package:aurora/models/customers/customerbill.dart';
import 'package:aurora/models/analysis/enums.dart';
import 'package:aurora/services/order_service.dart';
import 'package:aurora/storage/userStorage.dart';

class BillFormPage extends StatefulWidget {
  final Customer customer;

  const BillFormPage({super.key, required this.customer});

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
  bool _isSaving = false;

  @override
  void dispose() {
    _subtotalController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _shippingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _total {
    final subtotal = double.tryParse(_subtotalController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;
    final tax = double.tryParse(_taxController.text) ?? 0;
    final shipping = double.tryParse(_shippingController.text) ?? 0;
    return subtotal - discount + tax + shipping;
  }

  Future<void> _saveBill() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final userStorage = Provider.of<UserStorage>(context, listen: false);
      final sellerId = userStorage.currentUser?.id ?? '';

      final order = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: widget.customer.id,
        sellerId: sellerId,
        subtotal: double.tryParse(_subtotalController.text) ?? 0,
        discount: double.tryParse(_discountController.text) ?? 0,
        tax: double.tryParse(_taxController.text) ?? 0,
        shipping: double.tryParse(_shippingController.text) ?? 0,
        total: _total,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        items: [],
      );

      final created = await _orderService.createOrder(order);
      if (created == null) throw Exception('Failed to create order');

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill created successfully')),
        );
      }
    } catch (e) {
      debugPrint('[BillForm._saveBill] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Bill')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer: ${widget.customer.name}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _subtotalController,
                decoration: const InputDecoration(
                  labelText: 'Subtotal *',
                  border: OutlineInputBorder(),
                  prefixText: 'EGP ',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                validator: (value) => value == null || value.isEmpty
                    ? 'Subtotal is required'
                    : null,
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
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontSize: 16)),
                    Text(
                      'EGP ${_total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
}
