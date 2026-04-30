import 'package:flutter/material.dart';
import 'package:aurora/gen_l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/models/analysis/analytics.dart';
import 'package:aurora/models/analysis/enums.dart';
import 'package:aurora/models/analysis/goals/goal_enums.dart';
import 'package:aurora/models/analysis/goals/seller_goal.dart';
import 'package:aurora/services/analysis_engine.dart';
import 'package:aurora/services/performance/insights_engine.dart';
import 'package:aurora/widgets/analytics/goal_widgets.dart';
import 'package:aurora/widgets/analytics/insights_panel.dart';
import 'package:aurora/storage/analysis/goals_storage.dart';
import 'package:aurora/storage/analysis/insights_storage.dart';
import 'package:intl/intl.dart';

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
        snapshot: _snapshot!,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.newInsightsGenerated)),
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
          _errorMessage = AppLocalizations.of(context)!.userNotAuthenticated;
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
          SnackBar(content: Text(AppLocalizations.of(context)!.analysisComplete)),
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
        title: Text(AppLocalizations.of(context)!.salesAnalysis),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.analytics),
              text: AppLocalizations.of(context)!.analytics,
            ),
            Tab(
              icon: const Icon(Icons.lightbulb_outline),
              text: AppLocalizations.of(context)!.insights,
            ),
            Tab(
              icon: const Icon(Icons.flag),
              text: AppLocalizations.of(context)!.goals,
            ),
          ],
        ),
        actions: [
          if (_selectedTabIndex == 0) ...[
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              onPressed: _snapshot != null ? _generateInsights : null,
              tooltip: AppLocalizations.of(context)!.generateInsights,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isAnalyzing ? null : _runNewAnalysis,
              tooltip: AppLocalizations.of(context)!.refreshAnalysis,
            ),
          ],
          if (_selectedTabIndex == 2)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateGoalDialog(),
              tooltip: AppLocalizations.of(context)!.createGoal,
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
              child: Text(AppLocalizations.of(context)!.retry),
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
            Text(
              AppLocalizations.of(context)!.noAnalysisData,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _runNewAnalysis,
              child: Text(AppLocalizations.of(context)!.runAnalysis),
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
      return Center(
        child: Text(AppLocalizations.of(context)!.pleaseLogin),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.actionableInsights,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _generateInsights,
                tooltip: AppLocalizations.of(context)!.refreshAnalysis,
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
          Text(
            AppLocalizations.of(context)!.yourGoals,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.trackGoals,
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
                      AppLocalizations.of(context)!.noGoalsYet,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.createFirstGoal,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateGoalDialog(),
                      icon: const Icon(Icons.add),
                      label: Text(AppLocalizations.of(context)!.createGoalBtn),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.goalCreated)),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.goalUpdated)),
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
        title: Text(AppLocalizations.of(context)!.deleteGoal),
        content: Text('${AppLocalizations.of(context)!.deleteGoalConfirm} "${goal.type.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
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
            SnackBar(content: Text(AppLocalizations.of(context)!.goalDeleted)),
          );
        }
      } catch (e) {
        debugPrint('[AnalysisPage._deleteGoal] Error: $e');
      }
    }
  }

  void _showGoalDetails(SellerGoal goal) {
    final l10n = AppLocalizations.of(context)!;
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
                Text(
                  '${l10n.description}:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(goal.description!),
                const SizedBox(height: 16),
              ],
              _buildDetailRow(l10n.target, _formatGoalValue(goal.targetValue, goal.type)),
              _buildDetailRow(l10n.current, _formatGoalValue(goal.currentValue, goal.type)),
              _buildDetailRow(l10n.progress, '${goal.progressPercentage.toStringAsFixed(1)}%'),
              _buildDetailRow(l10n.dailyNeed, _formatGoalValue(goal.dailyTargetNeeded, goal.type)),
              _buildDetailRow(l10n.startDate, _formatDate(goal.startDate)),
              _buildDetailRow(l10n.endDate, _formatDate(goal.endDate)),
              _buildDetailRow('${goal.daysRemaining} ${l10n.daysRemaining}', ''),
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
                      Text(
                        l10n.goalAchieved,
                        style: const TextStyle(
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
            child: Text(l10n.close),
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
        return 'EGP ${value.toStringAsFixed(2)}';
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
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text('Period:', style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final l10n = AppLocalizations.of(context)!;
    final kpis = _snapshot!.analyticsData['kpis'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.keyMetrics,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    l10n.revenue,
                    'EGP ${(kpis['total_revenue'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    l10n.orders,
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
                    l10n.itemsSold,
                    '${kpis['total_items_sold'] ?? 0}',
                    Icons.inventory,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    l10n.avgOrder,
                    'EGP ${(kpis['average_order_value'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
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
    final l10n = AppLocalizations.of(context)!;
    final products = _snapshot!.topProducts;

    if (products.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.noProductData),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.topProducts,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...products.take(5).map((product) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text('${products.indexOf(product) + 1}'),
                ),
                title: Text(product['title'] ?? l10n.unknown),
                subtitle: Text('${l10n.quantity}: ${product['quantity'] ?? 0}'),
                trailing: Text(
                  'EGP ${(product['revenue'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
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
    final l10n = AppLocalizations.of(context)!;
    final customers = _snapshot!.topCustomers;

    if (customers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.noCustomerData),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.topCustomers,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...customers.take(5).map((customer) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text('${l10n.customer} ${customer['customer_id']}'),
                trailing: Text(
                  '${customer['order_count']} ${l10n.orders}',
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
    final l10n = AppLocalizations.of(context)!;
    final daily = _snapshot!.dailyBreakdown;

    if (daily.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.noDailyBreakdown),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dailyBreakdown,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      'EGP ${(day['revenue'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('${day['orders'] ?? 0} ${l10n.orders}'),
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
