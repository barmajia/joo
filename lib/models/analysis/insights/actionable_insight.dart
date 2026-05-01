import 'package:aurora/models/analysis/insights/insight_enums.dart';

class ActionableInsight {
  final String id;
  final String sellerId;
  final InsightType type;
  final InsightPriority priority;
  final InsightCategory category;
  final String title;
  final String description;
  final String recommendedAction;
  final double? potentialImpact;
  final String? impactMetric;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final bool isDismissed;
  final DateTime createdAt;
  final DateTime? expiresAt;

  ActionableInsight({
    required this.id,
    required this.sellerId,
    required this.type,
    required this.priority,
    required this.category,
    required this.title,
    required this.description,
    required this.recommendedAction,
    this.potentialImpact,
    this.impactMetric,
    this.metadata,
    this.isRead = false,
    this.isDismissed = false,
    required this.createdAt,
    this.expiresAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isUrgent {
    return priority == InsightPriority.critical ||
        priority == InsightPriority.high;
  }

  factory ActionableInsight.fromMap(Map<String, dynamic> map) {
    return ActionableInsight(
      id: map['id'] as String? ?? '',
      sellerId: map['seller_id'] as String? ?? '',
      type: InsightTypeExtension.fromString(map['type'] as String? ?? 'recommendation'),
      priority: InsightPriorityExtension.fromString(map['priority'] as String? ?? 'medium'),
      category: InsightCategoryExtension.fromString(map['category'] as String? ?? 'performance'),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      recommendedAction: map['recommended_action'] as String? ?? '',
      potentialImpact: _parseNumeric(map['potential_impact']),
      impactMetric: map['impact_metric'] as String?,
      metadata: map['metadata'] is Map<String, dynamic>
          ? map['metadata'] as Map<String, dynamic>
          : null,
      isRead: map['is_read'] as bool? ?? false,
      isDismissed: map['is_dismissed'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      expiresAt: map['expires_at'] != null
          ? DateTime.tryParse(map['expires_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seller_id': sellerId,
      'type': type.name,
      'priority': priority.name,
      'category': category.name,
      'title': title,
      'description': description,
      'recommended_action': recommendedAction,
      'potential_impact': potentialImpact,
      'impact_metric': impactMetric,
      'metadata': metadata,
      'is_read': isRead,
      'is_dismissed': isDismissed,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  ActionableInsight copyWith({
    String? id,
    String? sellerId,
    InsightType? type,
    InsightPriority? priority,
    InsightCategory? category,
    String? title,
    String? description,
    String? recommendedAction,
    double? potentialImpact,
    String? impactMetric,
    Map<String, dynamic>? metadata,
    bool? isRead,
    bool? isDismissed,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return ActionableInsight(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      potentialImpact: potentialImpact ?? this.potentialImpact,
      impactMetric: impactMetric ?? this.impactMetric,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  static double _parseNumeric(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static List<ActionableInsight> generateSampleInsights(String sellerId) {
    final now = DateTime.now();
    return [
      ActionableInsight(
        id: 'insight_1',
        sellerId: sellerId,
        type: InsightType.opportunity,
        priority: InsightPriority.high,
        category: InsightCategory.inventory,
        title: 'Low Stock Alert',
        description: 'Product "Wireless Headphones" is running low on stock (5 units remaining). Based on current sales velocity, you may run out in 3 days.',
        recommendedAction: 'Restock at least 20 units to maintain sales momentum.',
        potentialImpact: 500.0,
        impactMetric: 'revenue',
        createdAt: now.subtract(const Duration(hours: 2)),
        expiresAt: now.add(const Duration(days: 2)),
        metadata: {'product_id': 'prod_123', 'current_stock': 5},
      ),
      ActionableInsight(
        id: 'insight_2',
        sellerId: sellerId,
        type: InsightType.recommendation,
        priority: InsightPriority.medium,
        category: InsightCategory.pricing,
        title: 'Price Optimization Opportunity',
        description: 'Your product "Smart Watch" is priced 15% below market average. Consider increasing price by 10% to improve margins.',
        recommendedAction: 'Increase price from \$49.99 to \$54.99',
        potentialImpact: 250.0,
        impactMetric: 'monthly_revenue',
        createdAt: now.subtract(const Duration(days: 1)),
        metadata: {'product_id': 'prod_456', 'current_price': 49.99, 'suggested_price': 54.99},
      ),
      ActionableInsight(
        id: 'insight_3',
        sellerId: sellerId,
        type: InsightType.trend,
        priority: InsightPriority.medium,
        category: InsightCategory.sales,
        title: 'Sales Trend Alert',
        description: 'Your sales have increased by 25% in the last 7 days compared to the previous week.',
        recommendedAction: 'Consider running a promotional campaign to capitalize on this momentum.',
        potentialImpact: 1000.0,
        impactMetric: 'weekly_revenue',
        createdAt: now.subtract(const Duration(hours: 6)),
        metadata: {'growth_percentage': 25, 'period': '7_days'},
      ),
      ActionableInsight(
        id: 'insight_4',
        sellerId: sellerId,
        type: InsightType.warning,
        priority: InsightPriority.high,
        category: InsightCategory.customer,
        title: 'Customer Retention Warning',
        description: 'Customer retention rate has dropped by 10% this month. Review recent customer feedback for issues.',
        recommendedAction: 'Reach out to recent customers with satisfaction surveys and offer incentives for repeat purchases.',
        potentialImpact: 800.0,
        impactMetric: 'customer_lifetime_value',
        createdAt: now.subtract(const Duration(days: 2)),
        metadata: {'retention_drop': 10, 'period': 'monthly'},
      ),
      ActionableInsight(
        id: 'insight_5',
        sellerId: sellerId,
        type: InsightType.opportunity,
        priority: InsightPriority.low,
        category: InsightCategory.marketing,
        title: 'Peak Hours Identified',
        description: 'Your sales peak between 7 PM - 9 PM. Consider scheduling social media posts during this time.',
        recommendedAction: 'Schedule marketing campaigns and flash sales during peak hours.',
        potentialImpact: 300.0,
        impactMetric: 'conversion_rate',
        createdAt: now.subtract(const Duration(days: 3)),
        metadata: {'peak_start': '19:00', 'peak_end': '21:00'},
      ),
    ];
  }
}

class InsightSummary {
  final int totalInsights;
  final int unreadCount;
  final int criticalCount;
  final int highPriorityCount;
  final Map<InsightCategory, int> insightsByCategory;
  final Map<InsightType, int> insightsByType;
  final List<ActionableInsight> topInsights;

  InsightSummary({
    required this.totalInsights,
    required this.unreadCount,
    required this.criticalCount,
    required this.highPriorityCount,
    required this.insightsByCategory,
    required this.insightsByType,
    required this.topInsights,
  });

  factory InsightSummary.fromInsights(List<ActionableInsight> insights) {
    final unreadCount = insights.where((i) => !i.isRead && !i.isDismissed && !i.isExpired).length;
    final criticalCount = insights.where((i) => i.priority == InsightPriority.critical && !i.isDismissed).length;
    final highPriorityCount = insights.where((i) => i.priority == InsightPriority.high && !i.isDismissed).length;

    final insightsByCategory = <InsightCategory, int>{};
    final insightsByType = <InsightType, int>{};

    for (final insight in insights) {
      if (!insight.isDismissed && !insight.isExpired) {
        insightsByCategory[insight.category] = (insightsByCategory[insight.category] ?? 0) + 1;
        insightsByType[insight.type] = (insightsByType[insight.type] ?? 0) + 1;
      }
    }

    final topInsights = insights
        .where((i) => !i.isDismissed && !i.isExpired)
        .toList()
      ..sort((a, b) => b.priority.weight.compareTo(a.priority.weight));

    return InsightSummary(
      totalInsights: insights.length,
      unreadCount: unreadCount,
      criticalCount: criticalCount,
      highPriorityCount: highPriorityCount,
      insightsByCategory: insightsByCategory,
      insightsByType: insightsByType,
      topInsights: topInsights.take(5).toList(),
    );
  }
}
