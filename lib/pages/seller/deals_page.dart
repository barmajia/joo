import 'package:aurora/models/product/productModel.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/models/product/product_deal.dart';
import 'package:aurora/models/product/categories.dart';
import 'package:aurora/services/product_service.dart';

class DealsPage extends StatefulWidget {
  const DealsPage({super.key});

  @override
  State<DealsPage> createState() => _DealsPageState();
}

class _DealsPageState extends State<DealsPage> {
  final ProductService _productService = ProductService();
  List<ProductDeal> _deals = [];
  bool _isLoading = true;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadDeals();
  }

  Future<void> _loadDeals() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final products = await _productService.getSellerProducts(user.id);
      final allDeals = <ProductDeal>[];

      for (final product in products) {
        if (product.id != null) {
          final deals = await _productService.getProductDeals(product.id!);
          allDeals.addAll(deals);
        }
      }

      setState(() {
        _deals = allDeals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  List<ProductDeal> get _filteredDeals {
    if (_selectedCategoryId == null) return _deals;
    return _deals.where((d) => d.categoryId == _selectedCategoryId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Deals'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDeals),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Filter by Category',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Categories'),
                ),
                ...ProductCategories.categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Text('${cat.icon} ${cat.name}'),
                  );
                }),
              ],
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDeals.isEmpty
                ? const Center(child: Text('No deals found'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredDeals.length,
                    itemBuilder: (context, index) =>
                        _buildDealCard(_filteredDeals[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddDealPage()),
          );
          _loadDeals();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDealCard(ProductDeal deal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: deal.isActiveNow ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
          child: Icon(
            deal.dealType == 'discount' ? Icons.percent : Icons.local_offer,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          deal.dealType.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (deal.discountPercent != null)
              Text('${deal.discountPercent}% off'),
            if (deal.fixedPrice != null)
              Text('Fixed: \$${deal.fixedPrice!.toStringAsFixed(2)}'),
            if (deal.categoryId != null)
              Text(
                ProductCategories.getCategoryById(deal.categoryId!)?.name ??
                    deal.categoryId!,
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
            Text(
              deal.isActiveNow ? 'Active' : 'Inactive',
              style: TextStyle(
                color: deal.isActiveNow ? Colors.green : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (value) {
            // Handle actions
          },
        ),
      ),
    );
  }
}

class AddDealPage extends StatefulWidget {
  const AddDealPage({super.key});

  @override
  State<AddDealPage> createState() => _AddDealPageState();
}

class _AddDealPageState extends State<AddDealPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  String? _selectedProductId;
  String? _selectedCategoryId;
  String? _selectedSubcategory;
  String _dealType = 'discount';
  final _discountController = TextEditingController();
  final _fixedPriceController = TextEditingController();
  final _minQtyController = TextEditingController(text: '1');
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _isSaving = false;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final service = ProductService();
      _products = await service.getSellerProducts(user.id);
      setState(() {});
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _saveDeal() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await _supabase.from('product_deals').insert({
        'seller_id': userId,
        'product_id': _selectedProductId,
        'category_id': _selectedCategoryId,
        'subcategory': _selectedSubcategory,
        'deal_type': _dealType,
        'discount_percent': double.tryParse(_discountController.text),
        'fixed_price': double.tryParse(_fixedPriceController.text),
        'min_quantity': int.tryParse(_minQtyController.text) ?? 1,
        'starts_at': _startsAt?.toIso8601String(),
        'ends_at': _endsAt?.toIso8601String(),
        'is_active': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deal created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
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
      appBar: AppBar(title: const Text('Add Deal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedProductId,
                decoration: const InputDecoration(labelText: 'Product'),
                items: _products.map((p) {
                  return DropdownMenuItem(
                    value: p.id,
                    child: Text(p.title ?? 'Untitled'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedProductId = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category (Optional)',
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...ProductCategories.categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat.id,
                      child: Text('${cat.icon} ${cat.name}'),
                    );
                  }),
                ],
                onChanged: (v) => setState(() {
                  _selectedCategoryId = v;
                  _selectedSubcategory = null;
                }),
              ),
              const SizedBox(height: 16),
              if (_selectedCategoryId != null)
                DropdownButtonFormField<String>(
                  value: _selectedSubcategory,
                  decoration: const InputDecoration(labelText: 'Subcategory'),
                  items:
                      ProductCategories.getSubcategories(_selectedCategoryId!)
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _selectedSubcategory = v),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _dealType,
                decoration: const InputDecoration(labelText: 'Deal Type'),
                items: const [
                  DropdownMenuItem(
                    value: 'discount',
                    child: Text('Discount (%)'),
                  ),
                  DropdownMenuItem(
                    value: 'bulk_price',
                    child: Text('Bulk Price'),
                  ),
                  DropdownMenuItem(
                    value: 'flash_sale',
                    child: Text('Flash Sale'),
                  ),
                ],
                onChanged: (v) => setState(() => _dealType = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(labelText: 'Discount %'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fixedPriceController,
                decoration: const InputDecoration(labelText: 'Fixed Price'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minQtyController,
                decoration: const InputDecoration(labelText: 'Min Quantity'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveDeal,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Deal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
