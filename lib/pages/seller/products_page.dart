// lib/pages/seller/seller_products_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aurora/models/product/productModel.dart';
import 'package:aurora/models/product/categories.dart';
import 'package:aurora/services/product_service.dart';
import 'package:aurora/pages/seller/add_product_page.dart';

class SellerProductsPage extends StatefulWidget {
  const SellerProductsPage({super.key});

  @override
  State<SellerProductsPage> createState() => _SellerProductsPageState();
}

class _SellerProductsPageState extends State<SellerProductsPage> {
  final _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedCategory;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Please log in to view your products';
          _isLoading = false;
        });
        return;
      }

      final products = await _productService.getSellerProducts(user.id);

      if (!mounted) return;

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e, stack) {
      debugPrint('[SellerProductsPage._loadProducts] Error: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load products: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _forceSyncFromCloud() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Please log in to sync';
          _isLoading = false;
        });
        return;
      }

      await _productService.refreshVault(user.id);
      final products = await _productService.getSellerProducts(user.id);

      if (!mounted) return;

      setState(() {
        _products = products;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synced from cloud'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('[SellerProductsPage._forceSyncFromCloud] Error: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Sync failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Filter products by category AND search query
  List<Product> get _filteredProducts {
    var results = _products;

    // Filter by category
    if (_selectedCategory != null) {
      results = results.where((p) {
        final cat = ProductCategories.getCategoryByName(p.category ?? '');
        return cat?.id == _selectedCategory;
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      results = results.where((p) {
        final title = p.title.toLowerCase();
        final brand = p.brand.toLowerCase();
        final sku = p.sku?.toLowerCase() ?? '';
        return title.contains(query) ||
            brand.contains(query) ||
            sku.contains(query);
      }).toList();
    }

    return results;
  }

  /// Safe image URL getter - handles null, empty, and relative paths
  String? _getImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) return null;

    // Already a full URL
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // Relative path - get public URL from Supabase Storage
    try {
      return Supabase.instance.client.storage
          .from('products')
          .getPublicUrl(imageUrl);
    } catch (e) {
      debugPrint('[_getImageUrl] Error: $e');
      return null;
    }
  }

  /// Get color for status badge
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      case 'inactive':
        return Colors.grey;
      case 'archived':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  /// Format price with currency
  String _formatPrice(num? price, String currency) {
    if (price == null) return '—';
    final symbols = {'USD': '\$', 'EUR': '€', 'GBP': '£', 'JPY': '¥'};
    final symbol = symbols[currency] ?? currency;
    return '$symbol${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download),
            onPressed: _isLoading ? null : _forceSyncFromCloud,
            tooltip: 'Sync from Cloud',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search products',
                hintText: 'Title, brand, or SKU',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
          ),

          // Category Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
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
              onChanged: (value) => setState(() => _selectedCategory = value),
              isExpanded: true,
            ),
          ),

          const SizedBox(height: 8),

          // Results count
          if (!_isLoading && _errorMessage == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_filteredProducts.length} product(s) found',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),

          const SizedBox(height: 8),

          // Product List
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductPage()),
          );
          if (result == true && mounted) {
            _loadProducts();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Product',
      ),
    );
  }

  Widget _buildBody() {
    // Loading state
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (_filteredProducts.isEmpty) {
      final hasFilters = _selectedCategory != null || _searchQuery.isNotEmpty;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.search_off : Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No matching products' : 'No products yet',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting your filters'
                  : 'Tap + to create your first product',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      );
    }

    // Product list with pull-to-refresh
    return RefreshIndicator(
      onRefresh: _forceSyncFromCloud,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final imageUrl = _getImageUrl(product.mainImage);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 1,
      child: InkWell(
        onTap: () => _navigateToProductDetail(product),
        onLongPress: () => _showProductOptions(product),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Thumbnail Image
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: _buildProductImage(imageUrl),
                ),
              ),
              const SizedBox(width: 12),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              product.status,
                            ).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.status.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(product.status),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (product.brand.isNotEmpty == true)
                      Text(
                        product.brand,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatPrice(product.price, product.currency),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 13,
                          color: (product.quantity) > 0
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${product.quantity}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Menu Button
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit, size: 20),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, size: 20, color: Colors.red),
                      title: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') _editProduct(product);
                  if (value == 'delete') _deleteProduct(product);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: Center(
          child: Icon(
            Icons.image_not_supported,
            size: 24,
            color: Colors.grey.shade400,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey.shade200,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey.shade200,
        child: Center(
          child: Icon(
            Icons.error_outline,
            size: 24,
            color: Colors.red.shade400,
          ),
        ),
      ),
    );
  }

  void _navigateToProductDetail(Product product) {
    // Navigate to detail page or edit page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddProductPage(product: product)),
    );
  }

  void _showProductOptions(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Product'),
              onTap: () {
                Navigator.pop(context);
                _editProduct(product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _navigateToProductDetail(product);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Product',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteProduct(product);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editProduct(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddProductPage(product: product)),
    );
    if (result == true && mounted) {
      _loadProducts();
    }
  }

  Future<void> _deleteProduct(Product product) async {
    // Confirm deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${product.title}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Optimistic update: remove from UI immediately
    setState(() {
      _products.removeWhere((p) => p.id == product.id);
    });

    try {
      // ✅ Use product.id (primary key), NOT asin
      final success = await _productService.deleteProduct(product.id ?? '');

      if (!success) {
        // Revert if delete failed
        await _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete product'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('[SellerProductsPage._deleteProduct] Error: $e\n$stack');

      // Revert on error
      await _loadProducts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
