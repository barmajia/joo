import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aurora/models/product/productModel.dart';
import 'package:aurora/providers/cart_provider.dart';
import 'package:aurora/services/app_logger.dart';
import 'package:aurora/services/customer_product_service.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final _productService = CustomerProductService();
  final _scrollController = ScrollController();

  List<Product> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedCategory;
  final _searchController = TextEditingController();

  static const int _pageSize = 20;
  int _offset = 0;
  bool _hasMore = true;

  final List<String> _categories = [
    'All',
    'Electronics',
    'Clothing',
    'Home & Garden',
    'Sports',
    'Beauty',
    'Toys',
    'Books',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    AppLogger.logPageView('Marketplace');
    _loadProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreProducts();
      }
    }
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _offset = 0;
      _hasMore = true;
    });

    try {
      AppLogger.info('Loading marketplace products', context: 'Marketplace');

      final products = await _productService.getAllProducts(
        limit: _pageSize,
        offset: 0,
      );

      if (!mounted) return;

      setState(() {
        _products = products;
        _isLoading = false;
        _hasMore = products.length >= _pageSize;
      });

      AppLogger.info(
        'Loaded ${products.length} products for marketplace',
        context: 'Marketplace',
      );
    } catch (e, stack) {
      AppLogger.error(
        'Failed to load marketplace products: $e',
        context: 'Marketplace',
        error: e,
        stackTrace: stack,
      );

      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Failed to load products.\n\nError: ${e.toString()}\n\nPlease check your Supabase connection and ensure the products table has data.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (!mounted || _isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _offset += _pageSize;
    });

    try {
      AppLogger.info(
        'Loading more products (offset: $_offset)',
        context: 'Marketplace',
      );

      final moreProducts = await _productService.getAllProducts(
        limit: _pageSize,
        offset: _offset,
      );

      if (!mounted) return;

      setState(() {
        _products.addAll(moreProducts);
        _isLoadingMore = false;
        _hasMore = moreProducts.length >= _pageSize;
      });

      AppLogger.info(
        'Loaded ${moreProducts.length} more products',
        context: 'Marketplace',
      );
    } catch (e, stack) {
      AppLogger.error(
        'Failed to load more products: $e',
        context: 'Marketplace',
        error: e,
        stackTrace: stack,
      );

      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  List<Product> get _filteredProducts {
    var filtered = _products;

    if (_selectedCategory != null && _selectedCategory != 'All') {
      filtered = filtered
          .where((p) => p.category == _selectedCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return (p.title.toLowerCase().contains(query)) ||
            (p.sku?.toLowerCase().contains(query) ?? false) ||
            (p.brand.toLowerCase().contains(query));
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        centerTitle: true,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => Navigator.pushNamed(context, '/cart'),
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
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
                              _loadProducts();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                  onSubmitted: (_) => _loadProducts(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected =
                          _selectedCategory == category ||
                          (_selectedCategory == null && category == 'All');
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category == 'All'
                                  ? null
                                  : category;
                            });
                            _loadProducts();
                          },
                          selectedColor: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          checkmarkColor: theme.colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadProducts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No products found for "$_searchQuery"'
                              : 'No products available',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.7,
                          ),
                      itemCount: _filteredProducts.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _filteredProducts.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final product = _filteredProducts[index];
                        return _ProductCard(product: product);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = Provider.of<CartProvider>(context);
    final inCart = cart.hasProduct(product.id ?? '');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showProductDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: product.images != null && product.images!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.images!.first.url ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, size: 40),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (!product.brand.isEmpty)
                      Text(
                        product.brand,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${product.price?.toStringAsFixed(2) ?? '0.00'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            cart.addItem(product);
                            AppLogger.logCartAction(
                              'Added from marketplace',
                              productId: product.id,
                              quantity: 1,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.title} added to cart'),
                                duration: const Duration(seconds: 1),
                                action: SnackBarAction(
                                  label: 'View Cart',
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/cart'),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: inCart
                                  ? Colors.green
                                  : theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              inCart ? Icons.check : Icons.add_shopping_cart,
                              size: 18,
                              color: Colors.white,
                            ),
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
      ),
    );
  }

  void _showProductDetails(BuildContext context) {
    final theme = Theme.of(context);
    final cart = Provider.of<CartProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.images != null && product.images!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: product.images!.first.url ?? '',
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 60),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!product.brand.isEmpty)
                      Chip(label: Text(product.brand)),
                    const SizedBox(height: 12),
                    Text(
                      '\$${product.price?.toStringAsFixed(2) ?? '0.00'}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'In Stock: ${product.quantity}',
                      style: TextStyle(
                        color: product.quantity > 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (product.sku != null) ...[
                      Row(
                        children: [
                          Text(
                            'SKU: ',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            product.sku!,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      product.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              cart.addItem(product);
                              AppLogger.logCartAction(
                                'Added to cart',
                                productId: product.id,
                                quantity: 1,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${product.title} added to cart',
                                  ),
                                  action: SnackBarAction(
                                    label: 'View Cart',
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pushNamed(context, '/cart');
                                    },
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('Add to Cart'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              cart.addItem(product);
                              AppLogger.logCartAction(
                                'Buy now clicked',
                                productId: product.id,
                                quantity: 1,
                              );
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/cart');
                            },
                            icon: const Icon(Icons.shopping_bag),
                            label: const Text('Buy Now'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
