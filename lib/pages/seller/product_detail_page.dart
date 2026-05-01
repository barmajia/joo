import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aurora/models/product/productModel.dart';
import 'package:aurora/models/product/categories.dart';
import 'package:aurora/pages/seller/add_product_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  String? _getImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) return null;
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    try {
      return Supabase.instance.client.storage
          .from('products')
          .getPublicUrl(imageUrl);
    } catch (e) {
      return null;
    }
  }

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

  String _formatPrice(num? price, String currency) {
    if (price == null) return '—';
    final symbols = {'USD': '\$', 'EUR': '€', 'GBP': '£', 'JPY': '¥'};
    final symbol = symbols[currency] ?? currency;
    return '$symbol${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = widget.product;
    final imageUrl = _getImageUrl(product.mainImage);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _showShareOptions(context),
                tooltip: 'Share Product',
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editProduct(context),
                tooltip: 'Edit Product',
              ),
            ],
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sell, color: Colors.white),
              ),
              onPressed: () => _showSellOptions(context),
              tooltip: 'Sell Product',
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, size: 64),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, size: 64),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(product.status).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              product.status == 'active' ? Icons.check_circle : Icons.edit,
                              size: 14,
                              color: _getStatusColor(product.status),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(product.status),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (product.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ProductCategories.getCategoryByName(product.category!)?.icon ?? '',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                product.category!,
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product.title,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (product.brand.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.business, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(product.brand, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildInfoSection(theme, 'Pricing & Inventory', Icons.inventory_2, [
                    _buildInfoRow('Price', _formatPrice(product.price, product.currency)),
                    _buildInfoRow('Quantity', '${product.quantity}'),
                    _buildInfoRow('Currency', product.currency ?? 'USD'),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoSection(theme, 'Product Identifiers', Icons.qr_code, [
                    if (product.asin != null && product.asin!.isNotEmpty)
                      _buildInfoRow('ASIN', product.asin!),
                    if (product.sku != null && product.sku!.isNotEmpty)
                      _buildInfoRow('SKU', product.sku!),
                    _buildInfoRow('Product ID', product.id ?? 'N/A'),
                  ]),
                  if (product.description.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    _buildInfoSection(theme, 'Description', Icons.description, [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(product.description, style: const TextStyle(fontSize: 14)),
                      ),
                    ]),
                  ],
                  if (product.attributes != null && product.attributes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoSection(theme, 'Attributes', Icons.settings,
                      product.attributes!.entries.map((e) => _buildInfoRow(e.key, e.value.toString())).toList(),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showSellOptions(context),
                          icon: const Icon(Icons.sell),
                          label: const Text('Sell'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showShareOptions(context),
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme, String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  void _editProduct(BuildContext context) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddProductPage(product: widget.product)));
    if (result == true && mounted) {
      Navigator.pop(context);
    }
  }

  void _showSellOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _SellProductSheet(product: widget.product),
    );
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _ShareProductSheet(product: widget.product),
    );
  }
}

class _SellProductSheet extends StatefulWidget {
  final Product product;
  const _SellProductSheet({required this.product});
  @override
  State<_SellProductSheet> createState() => _SellProductSheetState();
}

class _SellProductSheetState extends State<_SellProductSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.sell, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('Sell Product', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildSellOption(Icons.person, 'Sell to Customer', 'Select from your customer list', () {}),
                  _buildSellOption(Icons.factory, 'Import from Factory', 'Receive products from connected factories', () {}),
                  _buildSellOption(Icons.qr_code, 'Quick Sell (QR)', 'Generate QR code for quick sale', () {}),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSellOption(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.green),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _ShareProductSheet extends StatefulWidget {
  final Product product;
  const _ShareProductSheet({required this.product});
  @override
  State<_ShareProductSheet> createState() => _ShareProductSheetState();
}

class _ShareProductSheetState extends State<_ShareProductSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.share, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text('Share Product', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildShareSection('Share to Customer', Icons.person, Colors.blue, [
                    _ShareOption(Icons.list, 'Select Customer', 'Choose from customer list', () {}),
                    _ShareOption(Icons.qr_code, 'Share via QR Code', 'Customer scans to receive', () {}),
                  ]),
                  const SizedBox(height: 16),
                  _buildShareSection('Import from Factory', Icons.factory, Colors.orange, [
                    _ShareOption(Icons.wifi, 'Nearby Factories', 'Find factories within distance', () {}),
                    _ShareOption(Icons.handshake, 'Connected Factories', 'Import from connected factories', () {}),
                    _ShareOption(Icons.lock, 'Secure Box', 'Share via secure token', () {}),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.security, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text('Secure Box', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Products are shared in an encrypted secure box. The access key is your profile token - share it securely with your customer or factory.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShareSection(String title, IconData icon, Color color, List<_ShareOption> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        ...options.map((option) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(option.icon, color: color, size: 20),
            ),
            title: Text(option.title),
            subtitle: Text(option.subtitle, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: option.onTap,
          ),
        )),
      ],
    );
  }
}

class _ShareOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  _ShareOption(this.icon, this.title, this.subtitle, this.onTap);
}