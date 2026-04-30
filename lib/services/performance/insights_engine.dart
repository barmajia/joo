import 'package:aurora/models/analysis/analytics.dart';
import 'package:aurora/models/analysis/goals/seller_goal.dart';
import 'package:aurora/models/analysis/insights/actionable_insight.dart';
import 'package:aurora/storage/analysis/goals_storage.dart';
import 'package:aurora/storage/analysis/insights_storage.dart';
import 'package:flutter/material.dart';

class InsightsEngine {
  static final InsightsEngine _instance = InsightsEngine._internal();
  factory InsightsEngine() => _instance;
  InsightsEngine._internal();

  /// Generate actionable insights based on analytics data
  Future<List<ActionableInsight>> generateInsights({
    required String sellerId,
    AnalyticsSnapshot? snapshot,
  }) async {
    final insights = <ActionableInsight>[];
    final now = DateTime.now();

    // If no snapshot provided, try to get latest
    if (snapshot == null) {
      debugPrint('[InsightsEngine] No snapshot provided, skipping insight generation');
      return insights;
    }

    // Generate inventory insights
    insights.addAll(_generateInventoryInsights(sellerId, snapshot, now));

    // Generate sales insights
    insights.addAll(_generateSalesInsights(sellerId, snapshot, now));

    // Generate pricing insights
    insights.addAll(_generatePricingInsights(sellerId, snapshot, now));

    // Generate customer insights
    insights.addAll(_generateCustomerInsights(sellerId, snapshot, now));

    // Save insights to storage
    for (final insight in insights) {
      await InsightsStorage.saveInsight(insight);
    }

    return insights;
  }

  List<ActionableInsight> _generateInventoryInsights(
    String sellerId,
    AnalyticsSnapshot snapshot,
    DateTime now,
  ) {
    final insights = <ActionableInsight>[];
    
    // Check top products for potential stock issues (simulated)
    final topProducts = snapshot.topProducts;
    for (final product in topProducts.take(3)) {
      final quantity = product['quantity'] as int? ?? 0;
      if (quantity > 0 && quantity < 10) {
        insights.add(ActionableInsight(
          id: 'inv_${product['product_id']}_${now.millisecondsSinceEpoch}',
          sellerId: sellerId,
          type: InsightType.warning,
          priority: InsightPriority.high,
          category: InsightCategory.inventory,
          title: 'Low Stock Alert: ${product['title']}',
          description: 'Product "${product['title']}" has sold $quantity units and may be running low. Current sales velocity suggests restocking soon.',
          recommendedAction: 'Restock at least 20 units to maintain sales momentum and avoid stockouts.',
          potentialImpact: (product['revenue'] as num?)?.toDouble() ?? 0,
          impactMetric: 'potential_lost_revenue',
          createdAt: now,
          expiresAt: now.add(const Duration(days: 3)),
          metadata: {
            'product_id': product['product_id'],
            'units_sold': quantity,
          },
        ));
      }
    }

    return insights;
  }

  List<ActionableInsight> _generateSalesInsights(
    String sellerId,
    AnalyticsSnapshot snapshot,
    DateTime now,
  ) {
    final insights = <ActionableInsight>[];
    final totalRevenue = snapshot.totalRevenue;
    final totalOrders = snapshot.totalOrders;

    // Revenue milestone celebration
    if (totalRevenue >= 1000) {
      insights.add(ActionableInsight(
        id: 'sales_milestone_${now.millisecondsSinceEpoch}',
        sellerId: sellerId,
        type: InsightType.trend,
        priority: InsightPriority.medium,
        category: InsightCategory.sales,
        title: 'Revenue Milestone Achieved! 🎉',
        description: 'Congratulations! You\'ve reached \$${totalRevenue.toStringAsFixed(0)} in revenue this period.',
        recommendedAction: 'Consider reinvesting profits into marketing or expanding your product line.',
        potentialImpact: totalRevenue * 0.2,
        impactMetric: 'growth_potential',
        createdAt: now,
        metadata: {'revenue_amount': totalRevenue},
      ));
    }

    // Order volume insight
    if (totalOrders >= 50) {
      insights.add(ActionableInsight(
        id: 'order_volume_${now.millisecondsSinceEpoch}',
        sellerId: sellerId,
        type: InsightType.opportunity,
        priority: InsightPriority.medium,
        category: InsightCategory.sales,
        title: 'High Order Volume Detected',
        description: 'You\'ve received $totalOrders orders this period. This is a great opportunity to optimize fulfillment.',
        recommendedAction: 'Review your fulfillment process and consider batching shipments for efficiency.',
        potentialImpact: totalOrders * 5.0,
        impactMetric: 'cost_savings',
        createdAt: now,
        metadata: {'order_count': totalOrders},
      ));
    }

    return insights;
  }

  List<ActionableInsight> _generatePricingInsights(
    String sellerId,
    AnalyticsSnapshot snapshot,
    DateTime now,
  ) {
    final insights = <ActionableInsight>[];
    final avgOrderValue = snapshot.averageOrderValue;

    // AOV optimization suggestion
    if (avgOrderValue > 0 && avgOrderValue < 50) {
      insights.add(ActionableInsight(
        id: 'pricing_aov_${now.millisecondsSinceEpoch}',
        sellerId: sellerId,
        type: InsightType.recommendation,
        priority: InsightPriority.medium,
        category: InsightCategory.pricing,
        title: 'Increase Average Order Value',
        description: 'Your average order value is \$${avgOrderValue.toStringAsFixed(2)}. Consider bundling products or offering free shipping thresholds to increase AOV.',
        recommendedAction: 'Set up product bundles or offer free shipping on orders over \$${(avgOrderValue * 1.5).toStringAsFixed(0)}',
        potentialImpact: avgOrderValue * 0.3 * snapshot.totalOrders,
        impactMetric: 'additional_revenue',
        createdAt: now,
        metadata: {'current_aov': avgOrderValue, 'target_aov': avgOrderValue * 1.5},
      ));
    }

    return insights;
  }

  List<ActionableInsight> _generateCustomerInsights(
    String sellerId,
    AnalyticsSnapshot snapshot,
    DateTime now,
  ) {
    final insights = <ActionableInsight>[];
    final totalCustomers = snapshot.totalCustomers;
    final topCustomers = snapshot.topCustomers;

    // Customer retention opportunity
    if (totalCustomers >= 10) {
      final repeatCustomers = topCustomers.where((c) => (c['order_count'] as int) > 1).length;
      final retentionRate = (repeatCustomers / totalCustomers) * 100;

      if (retentionRate < 30) {
        insights.add(ActionableInsight(
          id: 'customer_retention_${now.millisecondsSinceEpoch}',
          sellerId: sellerId,
          type: InsightType.warning,
          priority: InsightPriority.high,
          category: InsightCategory.customer,
          title: 'Improve Customer Retention',
          description: 'Only ${retentionRate.toStringAsFixed(1)}% of customers are making repeat purchases. Focus on building customer loyalty.',
          recommendedAction: 'Implement a loyalty program, send personalized follow-up emails, or offer exclusive discounts to repeat customers.',
          potentialImpact: totalCustomers * 25.0,
          impactMetric: 'lifetime_value_increase',
          createdAt: now,
          metadata: {'retention_rate': retentionRate, 'repeat_customers': repeatCustomers},
        ));
      } else {
        insights.add(ActionableInsight(
          id: 'customer_loyalty_${now.millisecondsSinceEpoch}',
          sellerId: sellerId,
          type: InsightType.trend,
          priority: InsightPriority.low,
          category: InsightCategory.customer,
          title: 'Strong Customer Loyalty',
          description: 'Great job! ${retentionRate.toStringAsFixed(1)}% of your customers are returning buyers.',
          recommendedAction: 'Continue engaging with your loyal customers and consider launching a VIP rewards program.',
          potentialImpact: totalCustomers * 15.0,
          impactMetric: 'retained_revenue',
          createdAt: now,
          metadata: {'retention_rate': retentionRate, 'repeat_customers': repeatCustomers},
        ));
      }
    }

    return insights;
  }

  /// Check and update goals progress
  Future<void> updateGoalsProgress(String sellerId, AnalyticsSnapshot snapshot) async {
    final goals = await GoalsStorage.getGoals(sellerId);
    
    for (final goal in goals) {
      if (goal.status == GoalStatus.active) {
        double currentValue = 0;

        switch (goal.type) {
          case GoalType.revenue:
            currentValue = snapshot.totalRevenue;
            break;
          case GoalType.orders:
            currentValue = snapshot.totalOrders.toDouble();
            break;
          case GoalType.customers:
            currentValue = snapshot.totalCustomers.toDouble();
            break;
          case GoalType.itemsSold:
            currentValue = snapshot.totalItemsSold.toDouble();
            break;
          case GoalType.averageOrderValue:
            currentValue = snapshot.averageOrderValue;
            break;
          case GoalType.conversionRate:
          case GoalType.retentionRate:
            // These would need additional data sources
            break;
        }

        await GoalsStorage.updateGoalProgress(goal.id, currentValue);

        // Award achievement if goal achieved
        if (currentValue >= goal.targetValue) {
          await _checkAndAwardAchievements(sellerId, goal);
        }
      }
    }
  }

  Future<void> _checkAndAwardAchievements(String sellerId, SellerGoal achievedGoal) async {
    final now = DateTime.now();
    
    // First sale achievement
    if (achievedGoal.type == GoalType.orders && achievedGoal.targetValue >= 1) {
      await GoalsStorage.awardAchievement(Achievement(
        id: 'first_sale',
        sellerId: sellerId,
        title: 'First Sale',
        description: 'Congratulations on your first sale!',
        badgeIcon: '🎉',
        category: 'milestone',
        points: 10,
        earnedAt: now,
      ));
    }

    // Century Club achievement
    if (achievedGoal.type == GoalType.orders && achievedGoal.targetValue >= 100) {
      await GoalsStorage.awardAchievement(Achievement(
        id: 'hundred_sales',
        sellerId: sellerId,
        title: 'Century Club',
        description: 'Reached 100 sales',
        badgeIcon: '💯',
        category: 'milestone',
        points: 50,
        earnedAt: now,
      ));
    }

    // Revenue King achievement
    if (achievedGoal.type == GoalType.revenue && achievedGoal.targetValue >= 10000) {
      await GoalsStorage.awardAchievement(Achievement(
        id: 'revenue_king',
        sellerId: sellerId,
        title: 'Revenue King',
        description: 'Earned \$10,000 in total revenue',
        badgeIcon: '👑',
        category: 'revenue',
        points: 150,
        earnedAt: now,
      ));
    }
  }

  /// Get insight summary for dashboard
  Future<InsightSummary> getInsightSummary(String sellerId) async {
    final insights = await InsightsStorage.getInsights(sellerId);
    return InsightSummary.fromInsights(insights);
  }
}
