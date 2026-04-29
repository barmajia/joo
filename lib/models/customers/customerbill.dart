import 'package:aurora/models/analysis/enums.dart';
import 'package:aurora/models/customers/customermodel.dart';

class Order {
  final String id;
  final String userId;
  final String? sellerId;
  final OrderStatus status;
  final double subtotal;
  final double discount;
  final double tax;
  final double shipping;
  final double total;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String? paymentIntentId;
  final String? shippingAddressId;
  final CustomerAddress? shippingAddressSnapshot;
  final Map<String, dynamic>? metadata;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? confirmedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? dealId;
  final double? commissionRate;
  final double? commissionAmount;
  final String? deliveryId;
  final DeliveryStatus deliveryStatus;
  final DateTime? pickedUpAt;
  final String? deliveryNotes;
  final double? deliveryFee;
  final ProductionStatus productionStatus;
  final DateTime? productionStartedAt;
  final DateTime? productionCompletedAt;
  final bool? qualityCheckPassed;
  final String? middleManId;
  final bool codVerificationRequired;
  final bool codVerified;
  final DateTime? codVerifiedAt;
  final double? codCollectionAmount;
  final String? codCollectedBy;
  final CodCollectionStatus codCollectionStatus;
  final DateTime? codDepositDeadline;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.userId,
    this.sellerId,
    this.status = OrderStatus.pending,
    this.subtotal = 0,
    this.discount = 0,
    this.tax = 0,
    this.shipping = 0,
    required this.total,
    this.paymentMethod = PaymentMethod.cash,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentIntentId,
    this.shippingAddressId,
    this.shippingAddressSnapshot,
    this.metadata,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.confirmedAt,
    this.shippedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.dealId,
    this.commissionRate,
    this.commissionAmount,
    this.deliveryId,
    this.deliveryStatus = DeliveryStatus.pending,
    this.pickedUpAt,
    this.deliveryNotes,
    this.deliveryFee,
    this.productionStatus = ProductionStatus.pending,
    this.productionStartedAt,
    this.productionCompletedAt,
    this.qualityCheckPassed,
    this.middleManId,
    this.codVerificationRequired = false,
    this.codVerified = false,
    this.codVerifiedAt,
    this.codCollectionAmount,
    this.codCollectedBy,
    this.codCollectionStatus = CodCollectionStatus.pending,
    this.codDepositDeadline,
    this.items = const [],
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isPending => status == OrderStatus.pending;
  bool get isConfirmed => status == OrderStatus.confirmed;
  bool get isProcessing => status == OrderStatus.processing;
  bool get isShipped => status == OrderStatus.shipped;
  bool get isDelivered => status == OrderStatus.delivered;
  bool get isCancelled => status == OrderStatus.cancelled || status == OrderStatus.refunded;

  bool get isCod => paymentMethod == PaymentMethod.cod;
  bool get needsCodVerification => isCod && codVerificationRequired && !codVerified;

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      sellerId: map['seller_id'] as String?,
      status: OrderStatusExtension.fromString(map['status'] as String? ?? 'pending'),
      subtotal: _parseNumeric(map['subtotal']),
      discount: _parseNumeric(map['discount']),
      tax: _parseNumeric(map['tax']),
      shipping: _parseNumeric(map['shipping']),
      total: _parseNumeric(map['total']),
      paymentMethod: PaymentMethodExtension.fromString(
          map['payment_method'] as String? ?? 'cash'),
      paymentStatus: PaymentStatusExtension.fromString(
          map['payment_status'] as String? ?? 'pending'),
      paymentIntentId: map['payment_intent_id'] as String?,
      shippingAddressId: map['shipping_address_id'] as String?,
      shippingAddressSnapshot: map['shipping_address_snapshot'] != null
          ? CustomerAddress.fromMap(
              map['shipping_address_snapshot'] as Map<String, dynamic>)
          : null,
      metadata: map['metadata'] is Map<String, dynamic>
          ? map['metadata'] as Map<String, dynamic>
          : null,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
      confirmedAt: map['confirmed_at'] != null
          ? DateTime.tryParse(map['confirmed_at'].toString())
          : null,
      shippedAt: map['shipped_at'] != null
          ? DateTime.tryParse(map['shipped_at'].toString())
          : null,
      deliveredAt: map['delivered_at'] != null
          ? DateTime.tryParse(map['delivered_at'].toString())
          : null,
      cancelledAt: map['cancelled_at'] != null
          ? DateTime.tryParse(map['cancelled_at'].toString())
          : null,
      dealId: map['deal_id'] as String?,
      commissionRate: map['commission_rate'] != null
          ? _parseNumeric(map['commission_rate'])
          : null,
      commissionAmount: map['commission_amount'] != null
          ? _parseNumeric(map['commission_amount'])
          : null,
      deliveryId: map['delivery_id'] as String?,
      deliveryStatus: DeliveryStatusExtension.fromString(
          map['delivery_status'] as String? ?? 'pending'),
      pickedUpAt: map['picked_up_at'] != null
          ? DateTime.tryParse(map['picked_up_at'].toString())
          : null,
      deliveryNotes: map['delivery_notes'] as String?,
      deliveryFee: map['delivery_fee'] != null
          ? _parseNumeric(map['delivery_fee'])
          : null,
      productionStatus: ProductionStatusExtension.fromString(
          map['production_status'] as String? ?? 'pending'),
      productionStartedAt: map['production_started_at'] != null
          ? DateTime.tryParse(map['production_started_at'].toString())
          : null,
      productionCompletedAt: map['production_completed_at'] != null
          ? DateTime.tryParse(map['production_completed_at'].toString())
          : null,
      qualityCheckPassed: map['quality_check_passed'] as bool?,
      middleManId: map['middle_man_id'] as String?,
      codVerificationRequired:
          map['cod_verification_required'] as bool? ?? false,
      codVerified: map['cod_verified'] as bool? ?? false,
      codVerifiedAt: map['cod_verified_at'] != null
          ? DateTime.tryParse(map['cod_verified_at'].toString())
          : null,
      codCollectionAmount: map['cod_collection_amount'] != null
          ? _parseNumeric(map['cod_collection_amount'])
          : null,
      codCollectedBy: map['cod_collected_by'] as String?,
      codCollectionStatus: CodCollectionStatusExtension.fromString(
          map['cod_collection_status'] as String? ?? 'pending'),
      codDepositDeadline: map['cod_deposit_deadline'] != null
          ? DateTime.tryParse(map['cod_deposit_deadline'].toString())
          : null,
      items: map['items'] is List
          ? (map['items'] as List)
              .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'seller_id': sellerId,
      'status': status.value,
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'shipping': shipping,
      'total': total,
      'payment_method': paymentMethod.value,
      'payment_status': paymentStatus.value,
      'payment_intent_id': paymentIntentId,
      'shipping_address_id': shippingAddressId,
      'shipping_address_snapshot': shippingAddressSnapshot?.toMap(),
      'metadata': metadata,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'confirmed_at': confirmedAt?.toIso8601String(),
      'shipped_at': shippedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'deal_id': dealId,
      'commission_rate': commissionRate,
      'commission_amount': commissionAmount,
      'delivery_id': deliveryId,
      'delivery_status': deliveryStatus.value,
      'picked_up_at': pickedUpAt?.toIso8601String(),
      'delivery_notes': deliveryNotes,
      'delivery_fee': deliveryFee,
      'production_status': productionStatus.value,
      'production_started_at': productionStartedAt?.toIso8601String(),
      'production_completed_at': productionCompletedAt?.toIso8601String(),
      'quality_check_passed': qualityCheckPassed,
      'middle_man_id': middleManId,
      'cod_verification_required': codVerificationRequired,
      'cod_verified': codVerified,
      'cod_verified_at': codVerifiedAt?.toIso8601String(),
      'cod_collection_amount': codCollectionAmount,
      'cod_collected_by': codCollectedBy,
      'cod_collection_status': codCollectionStatus.value,
      'cod_deposit_deadline': codDepositDeadline?.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    String? sellerId,
    OrderStatus? status,
    double? subtotal,
    double? discount,
    double? tax,
    double? shipping,
    double? total,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    String? paymentIntentId,
    String? shippingAddressId,
    CustomerAddress? shippingAddressSnapshot,
    Map<String, dynamic>? metadata,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? confirmedAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    String? dealId,
    double? commissionRate,
    double? commissionAmount,
    String? deliveryId,
    DeliveryStatus? deliveryStatus,
    DateTime? pickedUpAt,
    String? deliveryNotes,
    double? deliveryFee,
    ProductionStatus? productionStatus,
    DateTime? productionStartedAt,
    DateTime? productionCompletedAt,
    bool? qualityCheckPassed,
    String? middleManId,
    bool? codVerificationRequired,
    bool? codVerified,
    DateTime? codVerifiedAt,
    double? codCollectionAmount,
    String? codCollectedBy,
    CodCollectionStatus? codCollectionStatus,
    DateTime? codDepositDeadline,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sellerId: sellerId ?? this.sellerId,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      shipping: shipping ?? this.shipping,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      shippingAddressId: shippingAddressId ?? this.shippingAddressId,
      shippingAddressSnapshot: shippingAddressSnapshot ?? this.shippingAddressSnapshot,
      metadata: metadata ?? this.metadata,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      dealId: dealId ?? this.dealId,
      commissionRate: commissionRate ?? this.commissionRate,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      deliveryId: deliveryId ?? this.deliveryId,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      productionStatus: productionStatus ?? this.productionStatus,
      productionStartedAt: productionStartedAt ?? this.productionStartedAt,
      productionCompletedAt: productionCompletedAt ?? this.productionCompletedAt,
      qualityCheckPassed: qualityCheckPassed ?? this.qualityCheckPassed,
      middleManId: middleManId ?? this.middleManId,
      codVerificationRequired: codVerificationRequired ?? this.codVerificationRequired,
      codVerified: codVerified ?? this.codVerified,
      codVerifiedAt: codVerifiedAt ?? this.codVerifiedAt,
      codCollectionAmount: codCollectionAmount ?? this.codCollectionAmount,
      codCollectedBy: codCollectedBy ?? this.codCollectedBy,
      codCollectionStatus: codCollectionStatus ?? this.codCollectionStatus,
      codDepositDeadline: codDepositDeadline ?? this.codDepositDeadline,
      items: items ?? this.items,
    );
  }

  static double _parseNumeric(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final String? productId;
  final String asin;
  final String productName;
  final String? productImage;
  final String? brand;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final Map<String, dynamic>? attributes;
  final DateTime createdAt;

  OrderItem({
    required this.id,
    required this.orderId,
    this.productId,
    required this.asin,
    required this.productName,
    this.productImage,
    this.brand,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.attributes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as String? ?? '',
      orderId: map['order_id'] as String? ?? '',
      productId: map['product_id'] as String?,
      asin: map['asin'] as String? ?? '',
      productName: map['product_name'] as String? ?? '',
      productImage: map['product_image'] as String?,
      brand: map['brand'] as String?,
      quantity: map['quantity'] as int? ?? 1,
      unitPrice: _parseNumeric(map['unit_price']),
      totalPrice: _parseNumeric(map['total_price']),
      attributes: map['attributes'] is Map<String, dynamic>
          ? map['attributes'] as Map<String, dynamic>
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'asin': asin,
      'product_name': productName,
      'product_image': productImage,
      'brand': brand,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'attributes': attributes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static double _parseNumeric(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

extension CodCollectionStatusExtension on CodCollectionStatus {
  String get value {
    switch (this) {
      case CodCollectionStatus.pending:
        return 'pending';
      case CodCollectionStatus.collected:
        return 'collected';
      case CodCollectionStatus.failed:
        return 'failed';
      case CodCollectionStatus.refunded:
        return 'refunded';
    }
  }

  static CodCollectionStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return CodCollectionStatus.pending;
      case 'collected':
        return CodCollectionStatus.collected;
      case 'failed':
        return CodCollectionStatus.failed;
      case 'refunded':
        return CodCollectionStatus.refunded;
      default:
        return CodCollectionStatus.pending;
    }
  }
}