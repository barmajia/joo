enum MetricType {
  totalSales,
  totalRevenue,
  totalOrders,
  averageOrderValue,
  uniqueCustomers,
  conversionRate,
  productViews,
  cartAdditions,
  wishlistAdds,
  refunds,
  returns,
}

enum PeriodType {
  daily,
  weekly,
  monthly,
  yearly,
  custom,
}

enum TransactionType {
  credit,
  debit,
  refund,
  withdrawal,
  deposit,
  commission,
  sale,
  purchase,
}

enum CommissionStatus {
  pending,
  paid,
  withdrawn,
  cancelled,
}

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
  refunded,
}

enum PaymentMethod {
  cash,
  card,
  bankTransfer,
  digitalWallet,
  cod,
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded,
}

enum DeliveryStatus {
  pending,
  assigned,
  pickedUp,
  inTransit,
  delivered,
  failed,
}

enum ProductionStatus {
  pending,
  inProduction,
  qualityCheck,
  readyToShip,
  shipped,
  delivered,
  cancelled,
}

enum CodCollectionStatus {
  pending,
  collected,
  failed,
  refunded,
}

enum AgeRange {
  teens,
  twenties,
  thirties,
  forties,
  fifties,
  sixties,
  seventiesPlus,
}

extension MetricTypeExtension on MetricType {
  String get name {
    switch (this) {
      case MetricType.totalSales:
        return 'total_sales';
      case MetricType.totalRevenue:
        return 'total_revenue';
      case MetricType.totalOrders:
        return 'total_orders';
      case MetricType.averageOrderValue:
        return 'average_order_value';
      case MetricType.uniqueCustomers:
        return 'unique_customers';
      case MetricType.conversionRate:
        return 'conversion_rate';
      case MetricType.productViews:
        return 'product_views';
      case MetricType.cartAdditions:
        return 'cart_additions';
      case MetricType.wishlistAdds:
        return 'wishlist_adds';
      case MetricType.refunds:
        return 'refunds';
      case MetricType.returns:
        return 'returns';
    }
  }

  static MetricType fromString(String value) {
    switch (value) {
      case 'total_sales':
        return MetricType.totalSales;
      case 'total_revenue':
        return MetricType.totalRevenue;
      case 'total_orders':
        return MetricType.totalOrders;
      case 'average_order_value':
        return MetricType.averageOrderValue;
      case 'unique_customers':
        return MetricType.uniqueCustomers;
      case 'conversion_rate':
        return MetricType.conversionRate;
      case 'product_views':
        return MetricType.productViews;
      case 'cart_additions':
        return MetricType.cartAdditions;
      case 'wishlist_adds':
        return MetricType.wishlistAdds;
      case 'refunds':
        return MetricType.refunds;
      case 'returns':
        return MetricType.returns;
      default:
        return MetricType.totalSales;
    }
  }
}

extension PeriodTypeExtension on PeriodType {
  String get value {
    switch (this) {
      case PeriodType.daily:
        return 'daily';
      case PeriodType.weekly:
        return 'weekly';
      case PeriodType.monthly:
        return 'monthly';
      case PeriodType.yearly:
        return 'yearly';
      case PeriodType.custom:
        return 'custom';
    }
  }

  static PeriodType fromString(String value) {
    switch (value) {
      case 'daily':
        return PeriodType.daily;
      case 'weekly':
        return PeriodType.weekly;
      case 'monthly':
        return PeriodType.monthly;
      case 'yearly':
        return PeriodType.yearly;
      case 'custom':
        return PeriodType.custom;
      default:
        return PeriodType.daily;
    }
  }
}

extension TransactionTypeExtension on TransactionType {
  String get value {
    switch (this) {
      case TransactionType.credit:
        return 'credit';
      case TransactionType.debit:
        return 'debit';
      case TransactionType.refund:
        return 'refund';
      case TransactionType.withdrawal:
        return 'withdrawal';
      case TransactionType.deposit:
        return 'deposit';
      case TransactionType.commission:
        return 'commission';
      case TransactionType.sale:
        return 'sale';
      case TransactionType.purchase:
        return 'purchase';
    }
  }

  static TransactionType fromString(String value) {
    switch (value) {
      case 'credit':
        return TransactionType.credit;
      case 'debit':
        return TransactionType.debit;
      case 'refund':
        return TransactionType.refund;
      case 'withdrawal':
        return TransactionType.withdrawal;
      case 'deposit':
        return TransactionType.deposit;
      case 'commission':
        return TransactionType.commission;
      case 'sale':
        return TransactionType.sale;
      case 'purchase':
        return TransactionType.purchase;
      default:
        return TransactionType.credit;
    }
  }
}

extension CommissionStatusExtension on CommissionStatus {
  String get value {
    switch (this) {
      case CommissionStatus.pending:
        return 'pending';
      case CommissionStatus.paid:
        return 'paid';
      case CommissionStatus.withdrawn:
        return 'withdrawn';
      case CommissionStatus.cancelled:
        return 'cancelled';
    }
  }

  static CommissionStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return CommissionStatus.pending;
      case 'paid':
        return CommissionStatus.paid;
      case 'withdrawn':
        return CommissionStatus.withdrawn;
      case 'cancelled':
        return CommissionStatus.cancelled;
      default:
        return CommissionStatus.pending;
    }
  }
}

extension OrderStatusExtension on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.processing:
        return 'processing';
      case OrderStatus.shipped:
        return 'shipped';
      case OrderStatus.outForDelivery:
        return 'out_for_delivery';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
      case OrderStatus.refunded:
        return 'refunded';
    }
  }

  static OrderStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'refunded':
        return OrderStatus.refunded;
      default:
        return OrderStatus.pending;
    }
  }
}

extension PaymentMethodExtension on PaymentMethod {
  String get value {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.digitalWallet:
        return 'digital_wallet';
      case PaymentMethod.cod:
        return 'cod';
    }
  }

  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'cash':
        return PaymentMethod.cash;
      case 'card':
        return PaymentMethod.card;
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      case 'digital_wallet':
        return PaymentMethod.digitalWallet;
      case 'cod':
        return PaymentMethod.cod;
      default:
        return PaymentMethod.cash;
    }
  }
}

extension PaymentStatusExtension on PaymentStatus {
  String get value {
    switch (this) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.completed:
        return 'completed';
      case PaymentStatus.failed:
        return 'failed';
      case PaymentStatus.refunded:
        return 'refunded';
    }
  }

  static PaymentStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return PaymentStatus.pending;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }
}

extension DeliveryStatusExtension on DeliveryStatus {
  String get value {
    switch (this) {
      case DeliveryStatus.pending:
        return 'pending';
      case DeliveryStatus.assigned:
        return 'assigned';
      case DeliveryStatus.pickedUp:
        return 'picked_up';
      case DeliveryStatus.inTransit:
        return 'in_transit';
      case DeliveryStatus.delivered:
        return 'delivered';
      case DeliveryStatus.failed:
        return 'failed';
    }
  }

  static DeliveryStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return DeliveryStatus.pending;
      case 'assigned':
        return DeliveryStatus.assigned;
      case 'picked_up':
        return DeliveryStatus.pickedUp;
      case 'in_transit':
        return DeliveryStatus.inTransit;
      case 'delivered':
        return DeliveryStatus.delivered;
      case 'failed':
        return DeliveryStatus.failed;
      default:
        return DeliveryStatus.pending;
    }
  }
}

extension ProductionStatusExtension on ProductionStatus {
  String get value {
    switch (this) {
      case ProductionStatus.pending:
        return 'pending';
      case ProductionStatus.inProduction:
        return 'in_production';
      case ProductionStatus.qualityCheck:
        return 'quality_check';
      case ProductionStatus.readyToShip:
        return 'ready_to_ship';
      case ProductionStatus.shipped:
        return 'shipped';
      case ProductionStatus.delivered:
        return 'delivered';
      case ProductionStatus.cancelled:
        return 'cancelled';
    }
  }

  static ProductionStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return ProductionStatus.pending;
      case 'in_production':
        return ProductionStatus.inProduction;
      case 'quality_check':
        return ProductionStatus.qualityCheck;
      case 'ready_to_ship':
        return ProductionStatus.readyToShip;
      case 'shipped':
        return ProductionStatus.shipped;
      case 'delivered':
        return ProductionStatus.delivered;
      case 'cancelled':
        return ProductionStatus.cancelled;
      default:
        return ProductionStatus.pending;
    }
  }
}

extension AgeRangeExtension on AgeRange {
  String get value {
    switch (this) {
      case AgeRange.teens:
        return 'teens';
      case AgeRange.twenties:
        return '20s';
      case AgeRange.thirties:
        return '30s';
      case AgeRange.forties:
        return '40s';
      case AgeRange.fifties:
        return '50s';
      case AgeRange.sixties:
        return '60s';
      case AgeRange.seventiesPlus:
        return '70s+';
    }
  }

  static AgeRange fromString(String value) {
    switch (value) {
      case 'teens':
        return AgeRange.teens;
      case '20s':
        return AgeRange.twenties;
      case '30s':
        return AgeRange.thirties;
      case '40s':
        return AgeRange.forties;
      case '50s':
        return AgeRange.fifties;
      case '60s':
        return AgeRange.sixties;
      case '70s+':
        return AgeRange.seventiesPlus;
      default:
        return AgeRange.twenties;
    }
  }
}