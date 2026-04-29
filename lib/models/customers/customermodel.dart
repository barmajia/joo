import 'package:aurora/models/analysis/enums.dart';

class Customer {
  final String id;
  final String? userId;
  final String name;
  final String phone;
  final AgeRange? ageRange;
  final String? email;
  final String? notes;
  final int totalOrders;
  final double totalSpent;
  final DateTime? lastPurchaseDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String sellerId;
  final double? latitude;
  final double? longitude;

  Customer({
    required this.id,
    this.userId,
    required this.name,
    this.phone = '',
    this.ageRange,
    this.email,
    this.notes,
    this.totalOrders = 0,
    this.totalSpent = 0,
    this.lastPurchaseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.sellerId,
    this.latitude,
    this.longitude,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isActive => totalOrders > 0;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String?,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      ageRange: map['age_range'] != null
          ? AgeRangeExtension.fromString(map['age_range'] as String)
          : null,
      email: map['email'] as String?,
      notes: map['notes'] as String?,
      totalOrders: map['total_orders'] as int? ?? 0,
      totalSpent: _parseNumeric(map['total_spent']),
      lastPurchaseDate: map['last_purchase_date'] != null
          ? DateTime.tryParse(map['last_purchase_date'].toString())
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
      sellerId: map['seller_id'] as String? ?? '',
      latitude: map['latitude'] != null ? _parseNumeric(map['latitude']) : null,
      longitude: map['longitude'] != null ? _parseNumeric(map['longitude']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'age_range': ageRange?.value,
      'email': email,
      'notes': notes,
      'total_orders': totalOrders,
      'total_spent': totalSpent,
      'last_purchase_date': lastPurchaseDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'seller_id': sellerId,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  Customer copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    AgeRange? ageRange,
    String? email,
    String? notes,
    int? totalOrders,
    double? totalSpent,
    DateTime? lastPurchaseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? sellerId,
    double? latitude,
    double? longitude,
  }) {
    return Customer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      ageRange: ageRange ?? this.ageRange,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSpent: totalSpent ?? this.totalSpent,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sellerId: sellerId ?? this.sellerId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  static double _parseNumeric(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class CustomerAddress {
  final String id;
  final String customerId;
  final String label;
  final String fullAddress;
  final String? street;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime createdAt;

  CustomerAddress({
    required this.id,
    required this.customerId,
    required this.label,
    required this.fullAddress,
    this.street,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.latitude,
    this.longitude,
    this.isDefault = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CustomerAddress.fromMap(Map<String, dynamic> map) {
    return CustomerAddress(
      id: map['id'] as String? ?? '',
      customerId: map['customer_id'] as String? ?? '',
      label: map['label'] as String? ?? 'Home',
      fullAddress: map['full_address'] as String? ?? map['address'] as String? ?? '',
      street: map['street'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      zipCode: map['zip_code'] as String?,
      country: map['country'] as String?,
      latitude: map['latitude'] != null ? _parseNumeric(map['latitude']) : null,
      longitude: map['longitude'] != null ? _parseNumeric(map['longitude']) : null,
      isDefault: map['is_default'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'label': label,
      'full_address': fullAddress,
      'street': street,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
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