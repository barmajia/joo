import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/services/product_service.dart';
import 'package:aurora/services/order_service.dart';
import 'package:aurora/models/analysis/enums.dart';
import 'package:intl/intl.dart';

class FactoryDashboard extends StatefulWidget {
  const FactoryDashboard({super.key});

  @override
  State<FactoryDashboard> createState() => _FactoryDashboardState();
}

class _FactoryDashboardState extends State<FactoryDashboard> {
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();

  bool _isLoading = true;
  String? _errorMessage;

  // Dashboard metrics
  int _totalProducts = 0;
  int _activeProductionJobs = 0;
  int _pendingQuotes = 0;
  int _completedThisMonth = 0;
  double _monthlyRevenue = 0.0;
  double _totalCapacity = 0.0;
  double _utilizedCapacity = 0.0;
  List<Map<String, dynamic>> _productionQueue = [];
  List<Map<String, dynamic>> _recentQuotes = [];
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
        _loadProductionStats(),
        _loadQuotes(),
        _loadRevenue(),
        _loadCapacity(),
      ]);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[FactoryDashboard._loadDashboardData] Error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProductionStats() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Get factory products and orders
      final products = await _productService.getSellerProducts(user.id);
      final orders = await _orderService.fetchOrdersBySeller(user.id);

      if (!mounted) return;
      setState(() {
        _totalProducts = products.length;
        _activeProductionJobs = orders.where((o) => 
          ['pending', 'processing', 'in_production'].contains(o.status)
        ).length;
        _completedThisMonth = orders.where((o) => 
          o.status == OrderStatus.delivered && 
          _isCurrentMonth(o.createdAt)
        ).length;

        // Get active production queue
        _productionQueue = orders
            .where((o) => ['pending', 'processing', 'in_production'].contains(o.status))
            .take(5)
            .map((o) => {
                  'id': o.id,
                  'productName': o.items.isNotEmpty ? o.items.first.productName ?? 'Unknown' : 'Unknown',
                  'quantity': o.items.isNotEmpty ? o.items.first.quantity : 0,
                  'status': o.status.name,
                  'dueDate': o.deliveredAt,
                })
            .toList();
      });
    } catch (e) {
      debugPrint('[FactoryDashboard._loadProductionStats] Error: $e');
    }
  }

  bool _isCurrentMonth(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  Future<void> _loadQuotes() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // TODO: Implement quote service when created
      // For now, mock data
      if (!mounted) return;
      setState(() {
        _pendingQuotes = 3; // Mock data
        _recentQuotes = [
          {'customer': 'ABC Trading', 'amount': 5000.0, 'status': 'pending'},
          {'customer': 'XYZ Corp', 'amount': 12000.0, 'status': 'pending'},
        ];
      });
    } catch (e) {
      debugPrint('[FactoryDashboard._loadQuotes] Error: $e');
    }
  }

  Future<void> _loadRevenue() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final orders = await _orderService.fetchOrdersBySeller(user.id);
      
      double monthly = 0.0;
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);

      for (var order in orders) {
        final amount = order.total;
        
        if (order.createdAt != null && 
            order.createdAt!.isAfter(firstDayOfMonth) &&
            order.status == OrderStatus.delivered) {
          monthly += amount;
        }
      }

      if (!mounted) return;
      setState(() {
        _monthlyRevenue = monthly;
      });
    } catch (e) {
      debugPrint('[FactoryDashboard._loadRevenue] Error: $e');
    }
  }

  Future<void> _loadCapacity() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // TODO: Get actual capacity from factory profile
      // For now, mock data
      if (!mounted) return;
      setState(() {
        _totalCapacity = 1000.0; // Units per month
        _utilizedCapacity = 650.0; // Units currently in production
      });
    } catch (e) {
      debugPrint('[FactoryDashboard._loadCapacity] Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Factory Dashboard'),
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
          _buildCapacityGauge(),
          const SizedBox(height: 24),
          _buildRevenueCard(),
          const SizedBox(height: 24),
          _buildProductionQueue(),
          const SizedBox(height: 24),
          _buildQuoteRequests(),
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
            colors: [Colors.indigo.shade700, Colors.indigo.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: const Icon(
                Icons.factory,
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
                    user?.email?.split('@').first ?? 'Factory',
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
          'Active Jobs',
          '$_activeProductionJobs',
          Icons.precision_manufacturing,
          Colors.blue,
        ),
        _buildStatCard(
          'Pending Quotes',
          '$_pendingQuotes',
          Icons.request_quote,
          Colors.orange,
        ),
        _buildStatCard(
          'Completed (Month)',
          '$_completedThisMonth',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Total Products',
          '$_totalProducts',
          Icons.inventory_2,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
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
                  'New Quote',
                  Icons.add_business,
                  Colors.blue,
                  () => _showComingSoon('Create Quote'),
                ),
                _buildActionButton(
                  'Production Queue',
                  Icons.view_list,
                  Colors.green,
                  () => _showComingSoon('Production Queue'),
                ),
                _buildActionButton(
                  'Manage Capacity',
                  Icons.calendar_today,
                  Colors.orange,
                  () => _showComingSoon('Capacity Planning'),
                ),
                _buildActionButton(
                  'Quality Checks',
                  Icons.verified_user,
                  Colors.purple,
                  () => _showComingSoon('Quality Control'),
                ),
                _buildActionButton(
                  'Analytics',
                  Icons.analytics,
                  Colors.teal,
                  () => _navigateToAnalytics(),
                ),
                _buildActionButton(
                  'Settings',
                  Icons.settings,
                  Colors.grey,
                  () => _showComingSoon('Settings'),
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
            color: color.withValues(alpha: 0.1),
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

  Widget _buildCapacityGauge() {
    final utilization = _totalCapacity > 0 
        ? (_utilizedCapacity / _totalCapacity * 100).clamp(0, 100)
        : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.speed,
                  color: _getColorForUtilization(utilization.toDouble()),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Capacity Utilization',
                  style: TextStyle(
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
                      Text(
                        '${utilization.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _getColorForUtilization(utilization.toDouble()),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'of total capacity utilized',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                           value: utilization.toDouble() / 100,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                             _getColorForUtilization(utilization.toDouble()),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_utilizedCapacity.toInt()}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '/ ${_totalCapacity.toInt()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const Text(
                            'units',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
             LinearProgressIndicator(
               value: utilization.toDouble() / 100,
               backgroundColor: Colors.grey.shade200,
               valueColor: AlwaysStoppedAnimation<Color>(
                 _getColorForUtilization(utilization.toDouble()),
               ),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available: ${(_totalCapacity - _utilizedCapacity).toInt()} units',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                if (utilization > 85)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'High Demand',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForUtilization(double utilization) {
    if (utilization < 50) return Colors.green;
    if (utilization < 75) return Colors.orange;
    if (utilization < 90) return Colors.deepOrange;
    return Colors.red;
  }

  Widget _buildRevenueCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade600, Colors.teal.shade800],
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
                  Icons.monetization_on,
                  color: Colors.white70,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Monthly Revenue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '\$${_monthlyRevenue.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completed orders this month',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductionQueue() {
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
                  'Production Queue',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => _showComingSoon('Production Queue'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_productionQueue.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No active production jobs',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._productionQueue.map((job) => _buildProductionJobTile(job)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductionJobTile(Map<String, dynamic> job) {
    Color statusColor;
    String statusText;
    
    switch (job['status']) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'PENDING';
        break;
      case 'processing':
        statusColor = Colors.blue;
        statusText = 'PROCESSING';
        break;
      case 'in_production':
        statusColor = Colors.purple;
        statusText = 'IN PRODUCTION';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'UNKNOWN';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.1),
        child: Icon(Icons.precision_manufacturing, color: statusColor, size: 20),
      ),
      title: Text(
        job['productName'] ?? 'Unknown Product',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'Qty: ${job['quantity']} | Due: ${job['dueDate'] != null ? DateFormat('MMM dd').format(job['dueDate']) : 'TBD'}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: () {
        // TODO: Navigate to job details
      },
    );
  }

  Widget _buildQuoteRequests() {
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
                  'Recent Quote Requests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => _showComingSoon('Quotes'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_recentQuotes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No pending quotes',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._recentQuotes.map((quote) => _buildQuoteTile(quote)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteTile(Map<String, dynamic> quote) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: const CircleAvatar(
        backgroundColor: Colors.orange,
        child: Icon(Icons.request_quote, color: Colors.white, size: 20),
      ),
      title: Text(
        quote['customer'] ?? 'Unknown Customer',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: const Text('Quote request pending review'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${(quote['amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'PENDING',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      onTap: () {
        // TODO: Navigate to quote details
      },
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
              'On-Time Delivery',
              '92%',
              Icons.schedule,
              Colors.green,
            ),
            const Divider(),
            _buildMetricRow(
              'Quality Pass Rate',
              '98%',
              Icons.verified,
              Colors.blue,
            ),
            const Divider(),
            _buildMetricRow(
              'Avg Production Time',
              '5.2 days',
              Icons.timer,
              Colors.orange,
            ),
            const Divider(),
            _buildMetricRow(
              'Customer Rating',
              '4.7/5.0',
              Icons.star,
              Colors.amber,
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

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon')),
    );
  }

  void _navigateToAnalytics() {
    Navigator.pushNamed(context, '/analysis');
  }
}
