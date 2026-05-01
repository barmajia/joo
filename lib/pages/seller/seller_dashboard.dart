import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/services/product_service.dart';
import 'package:aurora/services/order_service.dart';
import 'package:aurora/services/customer_service.dart';
import 'package:aurora/models/product/productModel.dart';
import 'package:aurora/pages/seller/products_page.dart';
import 'package:aurora/pages/seller/deals_page.dart';
import 'package:aurora/pages/analysis/analysis_page.dart';
import 'package:intl/intl.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();
  final CustomerService _customerService = CustomerService();

  bool _isLoading = true;
  String? _errorMessage;

  // Dashboard metrics
  int _totalProducts = 0;
  int _activeProducts = 0;
  int _lowStockProducts = 0;
  int _pendingOrders = 0;
  int _processingOrders = 0;
  double _totalRevenue = 0.0;
  double _monthlyRevenue = 0.0;
  int _totalCustomers = 0;
  List<Map<String, dynamic>> _recentOrders = [];
  List<Map<String, dynamic>> _lowStockItems = [];
  Map<String, dynamic>? _performanceMetrics;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
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
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Load all data in parallel
      await Future.wait([
        _loadProducts(),
        _loadOrders(),
        _loadCustomers(),
        _loadRevenue(),
      ]);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[SellerDashboard._loadDashboardData] Error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final products = await _productService.getSellerProducts(user.id);
    
    if (!mounted) return;
    setState(() {
      _totalProducts = products.length;
      _activeProducts = products.where((p) => p.isActive).length;
      _lowStockProducts = products.where((p) => (p.quantity ?? 0) < 10).length;
      
      // Get low stock items for display
      _lowStockItems = products
          .where((p) => (p.quantity ?? 0) < 10)
          .take(5)
          .map((p) => {
                'title': p.title,
                'quantity': p.quantity,
                'asin': p.asin,
              })
          .toList();
    });
  }

  Future<void> _loadOrders() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Get recent orders
      final orders = await _orderService.getSellerOrders(user.id);
      
      if (!mounted) return;
      setState(() {
        _pendingOrders = orders.where((o) => o.status == 'pending').length;
        _processingOrders = orders.where((o) => o.status == 'processing').length;
        
        // Format recent orders for display
        _recentOrders = orders
            .take(5)
            .map((o) => {
                  'id': o.id,
                  'customerName': o.customerName ?? 'Unknown',
                  'total': o.totalAmount ?? 0.0,
                  'status': o.status,
                  'createdAt': o.createdAt,
                })
            .toList();
      });
    } catch (e) {
      debugPrint('[SellerDashboard._loadOrders] Error: $e');
    }
  }

  Future<void> _loadCustomers() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final customers = await _customerService.getCustomers(user.id);
      
      if (!mounted) return;
      setState(() {
        _totalCustomers = customers.length;
      });
    } catch (e) {
      debugPrint('[SellerDashboard._loadCustomers] Error: $e');
    }
  }

  Future<void> _loadRevenue() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Calculate total and monthly revenue from orders
      final orders = await _orderService.getSellerOrders(user.id);
      
      double total = 0.0;
      double monthly = 0.0;
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);

      for (var order in orders) {
        final amount = order.totalAmount ?? 0.0;
        total += amount;
        
        if (order.createdAt != null && 
            order.createdAt!.isAfter(firstDayOfMonth)) {
          monthly += amount;
        }
      }

      if (!mounted) return;
      setState(() {
        _totalRevenue = total;
        _monthlyRevenue = monthly;
      });
    } catch (e) {
      debugPrint('[SellerDashboard._loadRevenue] Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadDashboardData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 24),
          _buildQuickStats(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildRevenueCard(),
          const SizedBox(height: 24),
          _buildOrdersSection(),
          const SizedBox(height: 24),
          _buildLowStockAlerts(),
          const SizedBox(height: 24),
          _buildPerformanceMetrics(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final user = Supabase.instance.client.auth.currentUser;
    final greeting = _getGreeting();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(
                    Icons.storefront,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email?.split('@').first ?? 'Seller',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {
                    // TODO: Navigate to notifications
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildQuickStats() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Products',
          '$_totalProducts',
          Icons.inventory_2,
          Colors.blue,
          onTap: () => _navigateToProducts(),
        ),
        _buildStatCard(
          'Active Listings',
          '$_activeProducts',
          Icons.check_circle,
          Colors.green,
          onTap: () => _navigateToProducts(),
        ),
        _buildStatCard(
          'Pending Orders',
          '$_pendingOrders',
          Icons.pending_actions,
          Colors.orange,
          onTap: () => _navigateToOrders(),
        ),
        _buildStatCard(
          'Total Customers',
          '$_totalCustomers',
          Icons.people,
          Colors.purple,
          onTap: () => _navigateToCustomers(),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 28),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton(
                  'Add Product',
                  Icons.add_box,
                  Colors.blue,
                  () => _navigateToAddProduct(),
                ),
                _buildActionButton(
                  'View Orders',
                  Icons.shopping_bag,
                  Colors.green,
                  () => _navigateToOrders(),
                ),
                _buildActionButton(
                  'Manage Deals',
                  Icons.local_offer,
                  Colors.orange,
                  () => _navigateToDeals(),
                ),
                _buildActionButton(
                  'Analytics',
                  Icons.analytics,
                  Colors.purple,
                  () => _navigateToAnalytics(),
                ),
                _buildActionButton(
                  'Customers',
                  Icons.people_outline,
                  Colors.teal,
                  () => _navigateToCustomers(),
                ),
                _buildActionButton(
                  'Settings',
                  Icons.settings,
                  Colors.grey,
                  () => _navigateToSettings(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade600, Colors.green.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.attach_money,
                  color: Colors.white70,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Revenue Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'This Month',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${_monthlyRevenue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Revenue',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${_totalRevenue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildOrdersSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Orders',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _navigateToOrders,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_recentOrders.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No orders yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._recentOrders.map((order) => _buildOrderTile(order)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTile(Map<String, dynamic> order) {
    Color statusColor;
    switch (order['status']) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'processing':
        statusColor = Colors.blue;
        break;
      case 'shipped':
        statusColor = Colors.purple;
        break;
      case 'delivered':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(0.1),
        child: Icon(Icons.receipt_long, color: statusColor, size: 20),
      ),
      title: Text(
        order['customerName'] ?? 'Unknown Customer',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        order['createdAt'] != null
            ? DateFormat('MMM dd, yyyy • hh:mm a').format(order['createdAt'])
            : 'Unknown date',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${(order['total'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              (order['status'] as String?)?.toUpperCase() ?? 'UNKNOWN',
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      onTap: () {
        // TODO: Navigate to order details
      },
    );
  }

  Widget _buildLowStockAlerts() {
    if (_lowStockItems.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade400,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Low Stock Alerts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$_lowStockProducts items',
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._lowStockItems.map((item) => ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.red.shade400,
                ),
              ),
              title: Text(
                item['title'] ?? 'Unknown Product',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Qty: ${item['quantity']}',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              onTap: () {
                // TODO: Navigate to product edit
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Fulfillment Rate',
              '95%',
              Icons.speed,
              Colors.green,
            ),
            const Divider(),
            _buildMetricRow(
              'Response Time',
              '< 2 hours',
              Icons.timer,
              Colors.blue,
            ),
            const Divider(),
            _buildMetricRow(
              'Customer Satisfaction',
              '4.8/5.0',
              Icons.star,
              Colors.orange,
            ),
            const Divider(),
            _buildMetricRow(
              'Return Rate',
              '2.3%',
              Icons.return_item,
              Colors.red,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _navigateToAnalytics,
                child: const Text('View Detailed Analytics'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToProducts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SellerProductsPage()),
    );
  }

  void _navigateToAddProduct() {
    // Import here to avoid circular dependency
    Navigator.pushNamed(context, '/add-product');
  }

  void _navigateToOrders() {
    // TODO: Navigate to orders page when created
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Orders page coming soon')),
    );
  }

  void _navigateToDeals() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DealsPage()),
    );
  }

  void _navigateToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnalysisPage()),
    );
  }

  void _navigateToCustomers() {
    // TODO: Navigate to customers page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customers page coming soon')),
    );
  }

  void _navigateToSettings() {
    // TODO: Navigate to settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings page coming soon')),
    );
  }
}
