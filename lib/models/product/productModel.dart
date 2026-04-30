import 'dart:convert';

class Product {
  final String? id;
  final String? asin;
  final String? sku;
  final String sellerId;
  final String title;
  final String description;
  final String brand;
  final String currency;
  final double? price;
  final int quantity;
  final String status;
  final String? brandId;
  final bool isLocalBrand;
  final Map<String, dynamic>? attributes;
  final String? colorHex;
  final String? category;
  final String? subcategory;
  final List<ProductImage>? images;
  final double averageRating;
  final int reviewCount;
  final bool allowChat;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    this.asin,
    this.sku,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.brand,
    this.currency = 'USD',
    this.price,
    this.quantity = 0,
    this.status = 'draft',
    this.brandId,
    this.isLocalBrand = false,
    this.attributes,
    this.colorHex,
    this.category,
    this.subcategory,
    this.images,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.allowChat = true,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String?,
      asin: json['asin'] as String?,
      sku: json['sku'] as String?,
      sellerId: json['seller_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      brand: json['brand'] as String,
      currency: json['currency'] as String? ?? 'USD',
      price: (json['price'] as num?)?.toDouble(),
      quantity: json['quantity'] as int? ?? 0,
      status: json['status'] as String? ?? 'draft',
      brandId: json['brand_id'] as String?,
      isLocalBrand: json['is_local_brand'] as bool? ?? false,
      attributes: json['attributes'] as Map<String, dynamic>?,
      colorHex: json['color_hex'] as String?,
      category: json['category'] as String?,
      subcategory: json['subcategory'] as String?,
      images: json['images'] != null
          ? (json['images'] as List)
              .map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      allowChat: json['allow_chat'] as bool? ?? true,
      isDeleted: json['is_deleted'] as bool? ?? false,
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
      'asin': asin,
      'sku': sku,
      'seller_id': sellerId,
      'title': title,
      'description': description,
      'brand': brand,
      'currency': currency,
      'price': price,
      'quantity': quantity,
      'status': status,
      'brand_id': brandId,
      'is_local_brand': isLocalBrand,
      'attributes': attributes,
      'color_hex': colorHex,
      'category': category,
      'subcategory': subcategory,
      'images': images?.map((e) => e.toJson()).toList(),
      'average_rating': averageRating,
      'review_count': reviewCount,
      'allow_chat': allowChat,
      'is_deleted': isDeleted,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String? get mainImage {
    if (images != null && images!.isNotEmpty) {
      return images!.first.url;
    }
    return null;
  }

  bool get isInStock => quantity > 0;

  bool get isActive => status == 'active';

  Product copyWith({
    String? id,
    String? asin,
    String? sku,
    String? sellerId,
    String? title,
    String? description,
    String? brand,
    String? currency,
    double? price,
    int? quantity,
    String? status,
    String? brandId,
    bool? isLocalBrand,
    Map<String, dynamic>? attributes,
    String? colorHex,
    String? category,
    String? subcategory,
    List<ProductImage>? images,
    double? averageRating,
    int? reviewCount,
    bool? allowChat,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      asin: asin ?? this.asin,
      sku: sku ?? this.sku,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      currency: currency ?? this.currency,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      brandId: brandId ?? this.brandId,
      isLocalBrand: isLocalBrand ?? this.isLocalBrand,
      attributes: attributes ?? this.attributes,
      colorHex: colorHex ?? this.colorHex,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      images: images ?? this.images,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      allowChat: allowChat ?? this.allowChat,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ProductImage {
  final String? url;
  final String? id;

  ProductImage({this.url, this.id});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      url: json['url'] as String?,
      id: json['id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'url': url, 'id': id};
}
