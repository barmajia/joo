import 'package:aurora/models/analysis/enums.dart';

enum GoalType {
  revenue,
  orders,
  customers,
  itemsSold,
  averageOrderValue,
  conversionRate,
  retentionRate,
}

enum GoalPeriod {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
}

enum GoalStatus {
  active,
  achieved,
  failed,
  cancelled,
}

extension GoalTypeExtension on GoalType {
  String get name {
    switch (this) {
      case GoalType.revenue:
        return 'revenue';
      case GoalType.orders:
        return 'orders';
      case GoalType.customers:
        return 'customers';
      case GoalType.itemsSold:
        return 'items_sold';
      case GoalType.averageOrderValue:
        return 'average_order_value';
      case GoalType.conversionRate:
        return 'conversion_rate';
      case GoalType.retentionRate:
        return 'retention_rate';
    }
  }

  static GoalType fromString(String value) {
    switch (value) {
      case 'revenue':
        return GoalType.revenue;
      case 'orders':
        return GoalType.orders;
      case 'customers':
        return GoalType.customers;
      case 'items_sold':
        return GoalType.itemsSold;
      case 'average_order_value':
        return GoalType.averageOrderValue;
      case 'conversion_rate':
        return GoalType.conversionRate;
      case 'retention_rate':
        return GoalType.retentionRate;
      default:
        return GoalType.revenue;
    }
  }

  String get displayName {
    switch (this) {
      case GoalType.revenue:
        return 'Revenue Goal';
      case GoalType.orders:
        return 'Orders Goal';
      case GoalType.customers:
        return 'Customer Acquisition';
      case GoalType.itemsSold:
        return 'Items Sold';
      case GoalType.averageOrderValue:
        return 'Average Order Value';
      case GoalType.conversionRate:
        return 'Conversion Rate';
      case GoalType.retentionRate:
        return 'Retention Rate';
    }
  }
}

extension GoalPeriodExtension on GoalPeriod {
  String get name {
    switch (this) {
      case GoalPeriod.daily:
        return 'daily';
      case GoalPeriod.weekly:
        return 'weekly';
      case GoalPeriod.monthly:
        return 'monthly';
      case GoalPeriod.quarterly:
        return 'quarterly';
      case GoalPeriod.yearly:
        return 'yearly';
    }
  }

  static GoalPeriod fromString(String value) {
    switch (value) {
      case 'daily':
        return GoalPeriod.daily;
      case 'weekly':
        return GoalPeriod.weekly;
      case 'monthly':
        return GoalPeriod.monthly;
      case 'quarterly':
        return GoalPeriod.quarterly;
      case 'yearly':
        return GoalPeriod.yearly;
      default:
        return GoalPeriod.monthly;
    }
  }

  int get daysCount {
    switch (this) {
      case GoalPeriod.daily:
        return 1;
      case GoalPeriod.weekly:
        return 7;
      case GoalPeriod.monthly:
        return 30;
      case GoalPeriod.quarterly:
        return 90;
      case GoalPeriod.yearly:
        return 365;
    }
  }
}

extension GoalStatusExtension on GoalStatus {
  String get name {
    switch (this) {
      case GoalStatus.active:
        return 'active';
      case GoalStatus.achieved:
        return 'achieved';
      case GoalStatus.failed:
        return 'failed';
      case GoalStatus.cancelled:
        return 'cancelled';
    }
  }

  static GoalStatus fromString(String value) {
    switch (value) {
      case 'active':
        return GoalStatus.active;
      case 'achieved':
        return GoalStatus.achieved;
      case 'failed':
        return GoalStatus.failed;
      case 'cancelled':
        return GoalStatus.cancelled;
      default:
        return GoalStatus.active;
    }
  }
}
