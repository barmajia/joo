import 'package:flutter/material.dart';
import 'package:aurora/models/analysis/insights/actionable_insight.dart';
import 'package:aurora/storage/analysis/insights_storage.dart';

class InsightsPanel extends StatefulWidget {
  final String sellerId;
  final VoidCallback? onDismissInsight;

  const InsightsPanel({
    super.key,
    required this.sellerId,
    this.onDismissInsight,
  });

  @override
  State<InsightsPanel> createState() => _InsightsPanelState();
}

class _InsightsPanelState extends State<InsightsPanel> {
  List<ActionableInsight> _insights = [];
  bool _isLoading = true;
  InsightSummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);
    
    try {
      final insights = await InsightsStorage.getInsights(widget.sellerId);
      final summary = InsightSummary.fromInsights(insights);
      
      setState(() {
        _insights = insights;
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('[InsightsPanel] Error loading insights: $e');
    }
  }

  Future<void> _dismissInsight(String insightId) async {
    await InsightsStorage.dismissInsight(insightId);
    await _loadInsights();
    widget.onDismissInsight?.call();
  }

  Future<void> _markAsRead(String insightId) async {
    await InsightsStorage.markAsRead(insightId);
    await _loadInsights();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_insights.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_summary != null) _buildSummaryHeader(),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: _insights.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _buildInsightCard(_insights[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Insights Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when we find opportunities\nto improve your sales performance',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Total',
            '${_summary!.totalInsights}',
            Icons.lightbulb,
            Colors.blue,
          ),
          _buildSummaryItem(
            'Unread',
            '${_summary!.unreadCount}',
            Icons.mail_outline,
            Colors.orange,
          ),
          _buildSummaryItem(
            'Critical',
            '${_summary!.criticalCount}',
            Icons.warning,
            Colors.red,
          ),
          _buildSummaryItem(
            'High',
            '${_summary!.highPriorityCount}',
            Icons.priority_high,
            Colors.deepOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(ActionableInsight insight) {
    final isRead = insight.isRead;
    final isExpired = insight.isExpired;

    return Dismissible(
      key: Key(insight.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _dismissInsight(insight.id),
      child: Card(
        elevation: isRead ? 0 : 2,
        color: isExpired ? Colors.grey[100] : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _getPriorityColor(insight.priority).withValues(alpha: 0.3),
            width: isRead ? 1 : 2,
          ),
        ),
        child: InkWell(
          onTap: () => _markAsRead(insight.id),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildPriorityIndicator(insight.priority),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  insight.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                    color: isRead ? Colors.grey[600] : null,
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            insight.category.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showOptionsDialog(insight),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  insight.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isRead ? Colors.grey[500] : Colors.grey[700],
                  ),
                ),
                if (insight.recommendedAction.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(insight.priority).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb,
                          size: 18,
                          color: _getPriorityColor(insight.priority),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            insight.recommendedAction,
                            style: TextStyle(
                              fontSize: 13,
                              color: _getPriorityColor(insight.priority),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (insight.potentialImpact != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 16,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Potential Impact: ${_formatImpact(insight)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                if (isExpired) ...[
                  const SizedBox(height: 8),
                  Text(
                    'This insight has expired',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(InsightPriority priority) {
    Color color;
    String label;

    switch (priority) {
      case InsightPriority.critical:
        color = Colors.red;
        label = 'CRITICAL';
        break;
      case InsightPriority.high:
        color = Colors.orange;
        label = 'HIGH';
        break;
      case InsightPriority.medium:
        color = Colors.amber;
        label = 'MEDIUM';
        break;
      case InsightPriority.low:
        color = Colors.blue;
        label = 'LOW';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getPriorityColor(InsightPriority priority) {
    switch (priority) {
      case InsightPriority.critical:
        return Colors.red;
      case InsightPriority.high:
        return Colors.orange;
      case InsightPriority.medium:
        return Colors.amber;
      case InsightPriority.low:
        return Colors.blue;
    }
  }

  String _formatImpact(ActionableInsight insight) {
    final impact = insight.potentialImpact ?? 0;
    final metric = insight.impactMetric ?? 'value';
    
    if (metric.contains('revenue') || metric.contains('value')) {
      return '\$${impact.toStringAsFixed(2)}';
    } else if (metric.contains('rate') || metric.contains('percentage')) {
      return '${impact.toStringAsFixed(1)}%';
    } else {
      return '$impact ${metric.replaceAll('_', ' ')}';
    }
  }

  void _showOptionsDialog(ActionableInsight insight) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mark_email_read),
              title: const Text('Mark as Read'),
              onTap: () {
                Navigator.pop(context);
                _markAsRead(insight.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dismiss),
              title: const Text('Dismiss'),
              onTap: () {
                Navigator.pop(context);
                _dismissInsight(insight.id);
              },
            ),
            if (insight.metadata != null)
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  _showDetailsDialog(insight);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(ActionableInsight insight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insight Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type', insight.type.name),
              _buildDetailRow('Priority', insight.priority.name),
              _buildDetailRow('Category', insight.category.displayName),
              _buildDetailRow('Created', _formatDate(insight.createdAt)),
              if (insight.expiresAt != null)
                _buildDetailRow('Expires', _formatDate(insight.expiresAt!)),
              if (insight.potentialImpact != null)
                _buildDetailRow('Impact', _formatImpact(insight)),
              if (insight.metadata != null && insight.metadata!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Metadata:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  insight.metadata.toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
