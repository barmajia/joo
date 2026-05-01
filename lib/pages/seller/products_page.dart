// lib/pages/seller/seller_products_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aurora/models/product/productModel.dart';
import 'package:aurora/models/product/categories.dart';
import 'package:aurora/pages/seller/sku_scanner_page.dart';
import 'package:aurora/services/product_import_export_service.dart';
import 'package:aurora/services/product_service.dart';
import 'package:aurora/pages/seller/add_product_page.dart';
import 'package:aurora/pages/seller/product_detail_page.dart';

class SellerProductsPage extends StatefulWidget {
  const SellerProductsPage({super.key});

  @override
  State<SellerProductsPage> createState() => _SellerProductsPageState();
}

class _SellerProductsPageState extends State<SellerProductsPage> {
  final _productService = ProductService();
  final _importExportService = ProductImportExportService();
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

  bool _isGridView = true;
  final Set<String> _selectedProducts = {};
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: _isSelectionMode
                ? Text('${_selectedProducts.length} selected')
                : const Text('My Products'),
            leading: _isSelectionMode
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedProducts.clear();
                        _isSelectionMode = false;
                      });
                    },
                  )
                : null,
            actions: _isSelectionMode
                ? [
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: _selectedProducts.isEmpty
                          ? null
                          : () => _deleteSelectedProducts(),
                      tooltip: 'Delete selected',
                    ),
                    IconButton(
                      icon: const Icon(Icons.select_all),
                      onPressed: () {
                        setState(() {
                          _selectedProducts.clear();
                          _selectedProducts.addAll(
                            _filteredProducts
                                .map((p) => p.id ?? '')
                                .where((id) => id.isNotEmpty),
                          );
                        });
                      },
                      tooltip: 'Select all',
                    ),
                  ]
                : [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: _isLoading ? null : _openSkuScanner,
                tooltip: 'Scan SKU',
              ),
              IconButton(
                icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                onPressed: () => setState(() => _isGridView = !_isGridView),
                tooltip: _isGridView ? 'List view' : 'Grid view',
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'import') _importProducts();
                  if (value == 'export') _exportProducts();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'import',
                    child: ListTile(
                      leading: Icon(Icons.upload_file),
                      title: Text('Import CSV'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export',
                    child: ListTile(
                      leading: Icon(Icons.download),
                      title: Text('Export inventory'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.cloud_download),
                onPressed: _isLoading ? null : _forceSyncFromCloud,
                tooltip: 'Sync from Cloud',
              ),
            ],
            pinned: true,
            floating: true,
            snap: true,
          ),
        ],
        body: Column(
          children: [
            // Stats Header
            if (!_isLoading && _errorMessage == null)
              _buildStatsHeader(),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
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

            // Category Chips
            _buildCategoryChips(),

            // Results count
            if (!_isLoading && _errorMessage == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${_filteredProducts.length} product(s) found',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    if (_selectedCategory != null || _searchQuery.isNotEmpty)
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
                ),
              ),

            // Product List/Grid
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductPage()),
          );
          if (result == true && mounted) {
            _loadProducts();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _buildStatsHeader() {
    final activeCount = _products.where((p) => p.status == 'active').length;
    final draftCount = _products.where((p) => p.status == 'draft').length;
    final outOfStock = _products.where((p) => p.quantity == 0).length;
    // ignore: unused_local_variable
    final theme = Theme.of(context); // Reserved for future styling

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildStatCard('Total', _products.length.toString(), Icons.inventory_2, Colors.blue),
          const SizedBox(width: 8),
          _buildStatCard('Active', activeCount.toString(), Icons.check_circle, Colors.green),
          const SizedBox(width: 8),
          _buildStatCard('Draft', draftCount.toString(), Icons.edit, Colors.orange),
          const SizedBox(width: 8),
          _buildStatCard('Out of Stock', outOfStock.toString(), Icons.warning, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: _selectedCategory == null,
              onSelected: (_) => setState(() => _selectedCategory = null),
              avatar: const Icon(Icons.apps, size: 16),
            ),
          ),
          ...ProductCategories.categories.map((cat) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: FilterChip(
                label: Text('${cat.icon} ${cat.name}'),
                selected: _selectedCategory == cat.id,
                onSelected: (_) => setState(() => _selectedCategory = cat.id),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _openSkuScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SkuScannerPage()),
    );
    if (mounted) _loadProducts();
  }

  Future<void> _exportProducts() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await _importExportService.exportInventory(
        sellerId: user.id,
        products: _products,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _importProducts() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final result = await _importExportService.importInventory(
        sellerId: user.id,
      );
      await _productService.refreshVault(user.id);
      await _loadProducts();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${result.imported} product(s), skipped ${result.skipped}.',
          ),
          action: result.errors.isEmpty
              ? null
              : SnackBarAction(
                  label: 'Details',
                  onPressed: () => _showImportErrors(result.errors),
                ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  void _showImportErrors(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import details'),
        content: SingleChildScrollView(child: Text(errors.join('\n'))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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
      child: _isGridView
          ? _buildGridView()
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return _buildProductCard(product);
              },
            ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductGridCard(product);
      },
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
                            ).withValues(alpha: 0.15),
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

  Widget _buildProductGridCard(Product product) {
    final imageUrl = _getImageUrl(product.mainImage);
    final theme = Theme.of(context);
    final isSelected = _selectedProducts.contains(product.id);
    final isOutOfStock = product.quantity == 0;

    return GestureDetector(
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          _selectedProducts.add(product.id ?? '');
        });
      },
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedProducts.remove(product.id);
              if (_selectedProducts.isEmpty) {
                _isSelectionMode = false;
              }
            } else {
              _selectedProducts.add(product.id ?? '');
            }
          });
        } else {
          _navigateToProductDetail(product);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Expanded(
                    flex: 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildProductImage(imageUrl),
                        if (isOutOfStock)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Out of Stock',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(product.status).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Product Info
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          if (product.brand.isNotEmpty == true)
                            Text(
                              product.brand,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatPrice(product.price, product.currency),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  fontSize: 13,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isOutOfStock
                                      ? Colors.red.withValues(alpha: 0.1)
                                      : Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.inventory_2,
                                      size: 10,
                                      color: isOutOfStock ? Colors.red : Colors.green,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${product.quantity}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isOutOfStock ? Colors.red : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Selection overlay
              if (isSelected)
                Positioned.fill(
                  child: Container(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToProductDetail(Product product) {
    // Navigate to read-only detail page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductDetailPage(product: product)),
    ).then((_) {
      // Refresh after returning from detail page
      _loadProducts();
    });
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

  Future<void> _deleteSelectedProducts() async {
    if (_selectedProducts.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Products'),
        content: Text(
          'Are you sure you want to delete ${_selectedProducts.length} product(s)?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete ${_selectedProducts.length}'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);

    int successCount = 0;
    int failedCount = 0;

    for (final productId in _selectedProducts) {
      try {
        final success = await _productService.deleteProduct(productId);
        if (success) {
          successCount++;
          _products.removeWhere((p) => p.id == productId);
        } else {
          failedCount++;
        }
      } catch (e) {
        failedCount++;
        debugPrint('[SellerProductsPage._deleteSelectedProducts] Error deleting $productId: $e');
      }
    }

    if (mounted) {
      setState(() {
        _selectedProducts.clear();
        _isSelectionMode = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failedCount == 0
                ? '$successCount product(s) deleted successfully'
                : '$successCount deleted, $failedCount failed',
          ),
          backgroundColor: failedCount == 0 ? Colors.green : Colors.orange,
        ),
      );
    }
  }
}
