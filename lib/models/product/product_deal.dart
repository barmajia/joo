class ProductDeal {
  final String? id;
  final String sellerId;
  final String productId;
  final String? categoryId;
  final String? subcategory;
  final String dealType;
  final double? discountPercent;
  final double? fixedPrice;
  final int minQuantity;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductDeal({
    this.id,
    required this.sellerId,
    required this.productId,
    this.categoryId,
    this.subcategory,
    this.dealType = 'discount',
    this.discountPercent,
    this.fixedPrice,
    this.minQuantity = 1,
    this.startsAt,
    this.endsAt,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductDeal.fromJson(Map<String, dynamic> json) {
    return ProductDeal(
      id: json['id'] as String?,
      sellerId: json['seller_id'] as String,
      productId: json['product_id'] as String,
      dealType: json['deal_type'] as String? ?? 'discount',
      discountPercent: (json['discount_percent'] as num?)?.toDouble(),
      fixedPrice: (json['fixed_price'] as num?)?.toDouble(),
      minQuantity: json['min_quantity'] as int? ?? 1,
      startsAt: json['starts_at'] != null
          ? DateTime.parse(json['starts_at'] as String)
          : null,
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'seller_id': sellerId,
      'product_id': productId,
      'deal_type': dealType,
      'discount_percent': discountPercent,
      'fixed_price': fixedPrice,
      'min_quantity': minQuantity,
      'starts_at': startsAt?.toIso8601String(),
      'ends_at': endsAt?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isExpired {
    if (endsAt == null) return false;
    return DateTime.now().isAfter(endsAt!);
  }

  bool get isActiveNow {
    if (!isActive) return false;
    if (isExpired) return false;
    if (startsAt != null && DateTime.now().isBefore(startsAt!)) return false;
    return true;
  }

  double? getDealPrice(double originalPrice) {
    if (!isActiveNow) return null;
    if (fixedPrice != null) return fixedPrice;
    if (discountPercent != null) {
      return originalPrice * (1 - discountPercent! / 100);
    }
    return null;
  }
}
