import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/models/analysis/analytics.dart';
import 'package:aurora/models/analysis/enums.dart';
import 'package:aurora/services/analysis_engine.dart';
import 'package:aurora/widgets/analytics/goal_widgets.dart';
import 'package:aurora/widgets/analytics/insights_panel.dart';
import 'package:aurora/storage/analysis/goals_storage.dart';
import 'package:aurora/storage/analysis/insights_storage.dart';
import 'package:aurora/models/analysis/goals/seller_goal.dart';
import 'package:aurora/services/performance/insights_engine.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> with SingleTickerProviderStateMixin {
  final AnalysisEngine _analysisEngine = AnalysisEngine();
  final InsightsEngine _insightsEngine = InsightsEngine();
  AnalyticsSnapshot? _snapshot;
  bool _isLoading = true;
  bool _isAnalyzing = false;
  String? _errorMessage;
  PeriodType _selectedPeriod = PeriodType.monthly;
  int _selectedTabIndex = 0;
  List<SellerGoal> _goals = [];
  bool _showGoalsTab = false;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadAnalysis();
    _loadGoals();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {
      _selectedTabIndex = _tabController.index;
    });
  }

  Future<void> _loadGoals() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final goals = await GoalsStorage.getGoals(user.id);
      setState(() {
        _goals = goals;
      });
    } catch (e) {
      debugPrint('[AnalysisPage._loadGoals] Error: $e');
    }
  }

  Future<void> _generateInsights() async {
    if (_snapshot == null) return;
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      await _insightsEngine.generateInsights(
        sellerId: user.id,
        analyticsSnapshot: _snapshot!,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New insights generated')),
        );
      }
    } catch (e) {
      debugPrint('[AnalysisPage._generateInsights] Error: $e');
    }
  }

  Future<void> _loadAnalysis() async {
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

      var snapshot = await _analysisEngine.getLatestSnapshot(user.id);

      if (snapshot == null) {
        snapshot = await _analysisEngine.analyzeBills(
          sellerId: user.id,
          periodType: _selectedPeriod,
        );
      }

      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[AnalysisPage._loadAnalysis] Error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _runNewAnalysis() async {
    setState(() => _isAnalyzing = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final snapshot = await _analysisEngine.analyzeBills(
        sellerId: user.id,
        periodType: _selectedPeriod,
      );

      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _isAnalyzing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analysis complete')),
        );
      }
    } catch (e) {
      debugPrint('[AnalysisPage._runNewAnalysis] Error: $e');
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Analysis'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(
              icon: Icon(Icons.analytics),
              text: 'Analytics',
            ),
            const Tab(
              icon: Icon(Icons.lightbulb_outline),
              text: 'Insights',
            ),
            Tab(
              icon: const Icon(Icons.flag),
              text: 'Goals',
            ),
          ],
        ),
        actions: [
          if (_selectedTabIndex == 0) ...[
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              onPressed: _snapshot != null ? _generateInsights : null,
              tooltip: 'Generate Insights',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isAnalyzing ? null : _runNewAnalysis,
              tooltip: 'Refresh Analysis',
            ),
          ],
          if (_selectedTabIndex == 2)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateGoalDialog(),
              tooltip: 'Create Goal',
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnalyticsTab(),
          _buildInsightsTab(),
          _buildGoalsTab(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnalysis,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_snapshot == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No analysis data available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _runNewAnalysis,
              child: const Text('Run Analysis'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _runNewAnalysis,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 16),
          _buildKPIs(),
          const SizedBox(height: 16),
          _buildTopProducts(),
          const SizedBox(height: 16),
          _buildTopCustomers(),
          const SizedBox(height: 16),
          _buildDailyBreakdown(),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Please log in to view insights'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Actionable Insights',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _generateInsights,
                tooltip: 'Refresh Insights',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: InsightsPanel(
              sellerId: user.id,
              onDismissInsight: _loadAnalysis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Goals',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your progress and achieve your business targets',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          if (_goals.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No goals yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first goal to start tracking\nyour performance',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateGoalDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Goal'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _goals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return GoalProgressCard(
                    goal: _goals[index],
                    onTap: () => _showGoalDetails(_goals[index]),
                    onEdit: () => _showEditGoalDialog(_goals[index]),
                    onDelete: () => _deleteGoal(_goals[index]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showCreateGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateGoalDialog(
        onSave: _saveGoal,
      ),
    );
  }

  Future<void> _saveGoal(SellerGoal goal) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      // Update seller ID
      final updatedGoal = goal.copyWith(sellerId: user.id);
      await GoalsStorage.saveGoal(updatedGoal);
      await _loadGoals();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal created successfully')),
        );
      }
    } catch (e) {
      debugPrint('[AnalysisPage._saveGoal] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create goal')),
        );
      }
    }
  }

  void _showEditGoalDialog(SellerGoal goal) {
    showDialog(
      context: context,
      builder: (context) => CreateGoalDialog(
        onSave: (updatedGoal) => _updateGoal(goal, updatedGoal),
      ),
    );
  }

  Future<void> _updateGoal(SellerGoal oldGoal, SellerGoal newGoal) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final updatedGoal = newGoal.copyWith(
        id: oldGoal.id,
        sellerId: user.id,
        currentValue: oldGoal.currentValue,
      );
      await GoalsStorage.saveGoal(updatedGoal);
      await _loadGoals();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal updated successfully')),
        );
      }
    } catch (e) {
      debugPrint('[AnalysisPage._updateGoal] Error: $e');
    }
  }

  Future<void> _deleteGoal(SellerGoal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.type.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await GoalsStorage.deleteGoal(goal.id);
        await _loadGoals();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Goal deleted')),
          );
        }
      } catch (e) {
        debugPrint('[AnalysisPage._deleteGoal] Error: $e');
      }
    }
  }

  void _showGoalDetails(SellerGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(goal.type.displayName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (goal.description != null) ...[
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(goal.description!),
                const SizedBox(height: 16),
              ],
              _buildDetailRow('Target', _formatGoalValue(goal.targetValue, goal.type)),
              _buildDetailRow('Current', _formatGoalValue(goal.currentValue, goal.type)),
              _buildDetailRow('Progress', '${goal.progressPercentage.toStringAsFixed(1)}%'),
              _buildDetailRow('Daily Need', _formatGoalValue(goal.dailyTargetNeeded, goal.type)),
              _buildDetailRow('Start Date', _formatDate(goal.startDate)),
              _buildDetailRow('End Date', _formatDate(goal.endDate)),
              _buildDetailRow('Days Remaining', '${goal.daysRemaining} days'),
              if (goal.isAchieved) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.amber),
                      const SizedBox(width: 8),
                      const Text(
                        'Goal Achieved!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatGoalValue(double value, GoalType type) {
    switch (type) {
      case GoalType.revenue:
      case GoalType.averageOrderValue:
        return '\$${value.toStringAsFixed(2)}';
      case GoalType.conversionRate:
      case GoalType.retentionRate:
        return '${value.toStringAsFixed(1)}%';
      default:
        return value.toStringAsFixed(0);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Text('Period:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<PeriodType>(
                value: _selectedPeriod,
                isExpanded: true,
                items: PeriodType.values.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(period.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPeriod = value);
                    _loadAnalysis();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIs() {
    final kpis = _snapshot!.analyticsData['kpis'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Key Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Revenue',
                    '\$${(kpis['total_revenue'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'Orders',
                    '${kpis['total_orders'] ?? 0}',
                    Icons.shopping_cart,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Items Sold',
                    '${kpis['total_items_sold'] ?? 0}',
                    Icons.inventory,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    'Avg Order',
                    '\$${(kpis['average_order_value'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    final products = _snapshot!.topProducts;

    if (products.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No product data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...products.take(5).map((product) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text('${products.indexOf(product) + 1}'),
                ),
                title: Text(product['title'] ?? 'Unknown'),
                subtitle: Text('Qty: ${product['quantity'] ?? 0}'),
                trailing: Text(
                  '\$${(product['revenue'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCustomers() {
    final customers = _snapshot!.topCustomers;

    if (customers.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No customer data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Customers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...customers.take(5).map((customer) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text('Customer ${customer['customer_id']}'),
                trailing: Text(
                  '${customer['order_count']} orders',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyBreakdown() {
    final daily = _snapshot!.dailyBreakdown;

    if (daily.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No daily breakdown available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...daily.map((day) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(day['date'] ?? ''),
                    Text(
                      '\$${(day['revenue'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('${day['orders'] ?? 0} orders'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
