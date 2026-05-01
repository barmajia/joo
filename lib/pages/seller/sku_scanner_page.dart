import 'package:aurora/models/product/productModel.dart';
import 'package:aurora/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SkuScannerPage extends StatefulWidget {
  const SkuScannerPage({super.key});

  @override
  State<SkuScannerPage> createState() => _SkuScannerPageState();
}

class _SkuScannerPageState extends State<SkuScannerPage> {
  final ProductService _productService = ProductService();
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _manualController = TextEditingController();

  List<Product> _products = [];
  Product? _matchedProduct;
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _message = 'Please log in to scan products.';
      });
      return;
    }

    try {
      final products = await _productService.getSellerProducts(user.id);
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _message = 'Could not load products: $e';
      });
    }
  }

  void _handleCode(String rawCode) {
    final code = rawCode.trim();
    if (code.isEmpty) return;

    Product? match;
    for (final product in _products) {
      final sku = product.sku?.trim().toLowerCase();
      final asin = product.asin?.trim().toLowerCase();
      final normalized = code.toLowerCase();
      if (sku == normalized || asin == normalized) {
        match = product;
        break;
      }
    }

    setState(() {
      _matchedProduct = match;
      _message = match == null ? 'No product found for "$code".' : null;
    });
  }

  Future<void> _adjustStock(int change) async {
    final product = _matchedProduct;
    if (product == null || product.id == null) return;

    final newQuantity = product.quantity + change;
    if (newQuantity < 0) {
      setState(() => _message = 'Stock cannot go below zero.');
      return;
    }

    setState(() => _isUpdating = true);
    try {
      await _productService.updateProduct(product.id!, {
        'quantity': newQuantity,
        'updated_at': DateTime.now().toIso8601String(),
      });

      final updated = product.copyWith(quantity: newQuantity);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) _products[index] = updated;

      if (!mounted) return;
      setState(() {
        _matchedProduct = updated;
        _message = 'Stock updated to $newQuantity.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = 'Failed to update stock: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan SKU')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: MobileScanner(
                      controller: _scannerController,
                      onDetect: (capture) {
                        final value = capture.barcodes.isEmpty
                            ? null
                            : capture.barcodes.first.rawValue;
                        if (value != null) _handleCode(value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _manualController,
                  decoration: InputDecoration(
                    labelText: 'SKU or ASIN',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.qr_code_scanner),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _handleCode(_manualController.text),
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: _handleCode,
                ),
                const SizedBox(height: 16),
                if (_message != null)
                  Card(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_message!),
                    ),
                  ),
                if (_matchedProduct != null)
                  _buildProductPanel(_matchedProduct!),
              ],
            ),
    );
  }

  Widget _buildProductPanel(Product product) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('SKU: ${product.sku ?? 'N/A'}'),
            Text('ASIN: ${product.asin ?? 'N/A'}'),
            const Divider(height: 24),
            Text(
              'Current stock: ${product.quantity}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUpdating ? null : () => _adjustStock(-1),
                    icon: const Icon(Icons.remove),
                    label: const Text('Remove 1'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUpdating ? null : () => _adjustStock(1),
                    icon: const Icon(Icons.add),
                    label: const Text('Add 1'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
