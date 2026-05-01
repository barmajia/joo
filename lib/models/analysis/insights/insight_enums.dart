enum InsightType {
  opportunity,
  warning,
  recommendation,
  alert,
  trend,
}

enum InsightPriority {
  low,
  medium,
  high,
  critical,
}

enum InsightCategory {
  sales,
  inventory,
  pricing,
  customer,
  marketing,
  performance,
  seasonal,
}

extension InsightTypeExtension on InsightType {
  String get name {
    switch (this) {
      case InsightType.opportunity:
        return 'opportunity';
      case InsightType.warning:
        return 'warning';
      case InsightType.recommendation:
        return 'recommendation';
      case InsightType.alert:
        return 'alert';
      case InsightType.trend:
        return 'trend';
    }
  }

  static InsightType fromString(String value) {
    switch (value) {
      case 'opportunity':
        return InsightType.opportunity;
      case 'warning':
        return InsightType.warning;
      case 'recommendation':
        return InsightType.recommendation;
      case 'alert':
        return InsightType.alert;
      case 'trend':
        return InsightType.trend;
      default:
        return InsightType.recommendation;
    }
  }
}

extension InsightPriorityExtension on InsightPriority {
  String get name {
    switch (this) {
      case InsightPriority.low:
        return 'low';
      case InsightPriority.medium:
        return 'medium';
      case InsightPriority.high:
        return 'high';
      case InsightPriority.critical:
        return 'critical';
    }
  }

  static InsightPriority fromString(String value) {
    switch (value) {
      case 'low':
        return InsightPriority.low;
      case 'medium':
        return InsightPriority.medium;
      case 'high':
        return InsightPriority.high;
      case 'critical':
        return InsightPriority.critical;
      default:
        return InsightPriority.medium;
    }
  }

  int get weight {
    switch (this) {
      case InsightPriority.low:
        return 1;
      case InsightPriority.medium:
        return 2;
      case InsightPriority.high:
        return 3;
      case InsightPriority.critical:
        return 4;
    }
  }
}

extension InsightCategoryExtension on InsightCategory {
  String get name {
    switch (this) {
      case InsightCategory.sales:
        return 'sales';
      case InsightCategory.inventory:
        return 'inventory';
      case InsightCategory.pricing:
        return 'pricing';
      case InsightCategory.customer:
        return 'customer';
      case InsightCategory.marketing:
        return 'marketing';
      case InsightCategory.performance:
        return 'performance';
      case InsightCategory.seasonal:
        return 'seasonal';
    }
  }

  static InsightCategory fromString(String value) {
    switch (value) {
      case 'sales':
        return InsightCategory.sales;
      case 'inventory':
        return InsightCategory.inventory;
      case 'pricing':
        return InsightCategory.pricing;
      case 'customer':
        return InsightCategory.customer;
      case 'marketing':
        return InsightCategory.marketing;
      case 'performance':
        return InsightCategory.performance;
      case 'seasonal':
        return InsightCategory.seasonal;
      default:
        return InsightCategory.performance;
    }
  }

  String get displayName {
    switch (this) {
      case InsightCategory.sales:
        return 'Sales';
      case InsightCategory.inventory:
        return 'Inventory';
      case InsightCategory.pricing:
        return 'Pricing';
      case InsightCategory.customer:
        return 'Customer';
      case InsightCategory.marketing:
        return 'Marketing';
      case InsightCategory.performance:
        return 'Performance';
      case InsightCategory.seasonal:
        return 'Seasonal';
    }
  }
}
