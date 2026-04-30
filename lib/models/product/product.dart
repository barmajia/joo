import 'dart:convert';

class AuroraProduct {
  final String? asin;
  final String? sku;
  final String? sellerId;
  final String? title;
  final String? description;
  final String? brand;
  final double? price;
  final double? sellingPrice;
  final int? quantity;
  final String? status;
  final String? category;
  final String? subcategory;
  final Map<String, dynamic>? attributes;
  final String? colorHex;
  final String? brandId;
  final bool? isLocalBrand;
  final String? currency;
  final List<ProductImage>? images;
  final String? qrData;
  final double? averageRating;
  final int? reviewCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AuroraProduct({
    this.asin,
    this.sku,
    this.sellerId,
    this.title,
    this.description,
    this.brand,
    this.price,
    this.sellingPrice,
    this.quantity,
    this.status,
    this.category,
    this.subcategory,
    this.attributes,
    this.colorHex,
    this.brandId,
    this.isLocalBrand,
    this.currency,
    this.images,
    this.qrData,
    this.averageRating,
    this.reviewCount,
    this.createdAt,
    this.updatedAt,
  });

  factory AuroraProduct.fromJson(Map<String, dynamic> json) {
    return AuroraProduct(
      asin: json['asin'] as String?,
      sku: json['sku'] as String?,
      sellerId: json['seller_id'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      brand: json['brand'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      sellingPrice: (json['selling_price'] as num?)?.toDouble(),
      quantity: json['quantity'] as int?,
      status: json['status'] as String?,
      category: json['category'] as String?,
      subcategory: json['subcategory'] as String?,
      attributes: json['attributes'] as Map<String, dynamic>?,
      colorHex: json['color_hex'] as String?,
      brandId: json['brand_id'] as String?,
      isLocalBrand: json['is_local_brand'] as bool?,
      currency: json['currency'] as String?,
      images: json['images'] != null
          ? (json['images'] as List)
                .map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      qrData: json['qr_data'] as String?,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int?,
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
      'asin': asin,
      'sku': sku,
      'seller_id': sellerId,
      'title': title,
      'description': description,
      'brand': brand,
      'price': price,
      'selling_price': sellingPrice,
      'quantity': quantity,
      'status': status,
      'category': category,
      'subcategory': subcategory,
      'attributes': attributes,
      'color_hex': colorHex,
      'brand_id': brandId,
      'is_local_brand': isLocalBrand,
      'currency': currency,
      'images': images?.map((e) => e.toJson()).toList(),
      'qr_data': qrData,
      'average_rating': averageRating,
      'review_count': reviewCount,
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

  bool get isInStock => (quantity ?? 0) > 0;
}

class ProductImage {
  final String? url;
  final String? id;

  ProductImage({this.url, this.id});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(url: json['url'] as String?, id: json['id'] as String?);
  }

  Map<String, dynamic> toJson() => {'url': url, 'id': id};
}
