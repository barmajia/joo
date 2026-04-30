class ProductSecret {
  final String? id;
  final String productId;
  final String secretKey;
  final String encryptedValue;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductSecret({
    this.id,
    required this.productId,
    required this.secretKey,
    required this.encryptedValue,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductSecret.fromJson(Map<String, dynamic> json) {
    return ProductSecret(
      id: json['id'] as String?,
      productId: json['product_id'] as String,
      secretKey: json['secret_key'] as String,
      encryptedValue: json['encrypted_value'] as String,
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
      'product_id': productId,
      'secret_key': secretKey,
      'encrypted_value': encryptedValue,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
