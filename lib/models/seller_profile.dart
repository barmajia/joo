class SellerProfile {
  final String userId;
  final String email;
  final String fullName;
  final String? firstname;
  final String? secondName;
  final String? thirdname;
  final String? fourthName;
  final String? phone;
  final String? location;
  final String currency;
  final String accountType;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double? latitude;
  final double? longitude;
  final bool isFactory;
  final String? factoryLicenseUrl;
  final int minOrderQuantity;
  final double wholesaleDiscount;

  SellerProfile({
    required this.userId,
    required this.email,
    required this.fullName,
    this.firstname,
    this.secondName,
    this.thirdname,
    this.fourthName,
    this.phone,
    this.location,
    this.currency = 'USD',
    this.accountType = 'seller',
    this.isVerified = false,
    required this.createdAt,
    this.updatedAt,
    this.latitude,
    this.longitude,
    this.isFactory = false,
    this.factoryLicenseUrl,
    this.minOrderQuantity = 1,
    this.wholesaleDiscount = 0,
  });

  factory SellerProfile.fromMap(Map<String, dynamic> map) {
    return SellerProfile(
      userId: map['user_id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['full_name'] ?? '',
      firstname: map['firstname'],
      secondName: map['second_name'],
      thirdname: map['thirdname'],
      fourthName: map['fourth_name'],
      phone: map['phone'],
      location: map['location'],
      currency: map['currency'] ?? 'USD',
      accountType: map['account_type'] ?? 'seller',
      isVerified: map['is_verified'] ?? false,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      isFactory: map['is_factory'] ?? false,
      factoryLicenseUrl: map['factory_license_url'],
      minOrderQuantity: map['min_order_quantity'] ?? 1,
      wholesaleDiscount: (map['wholesale_discount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'email': email,
      'full_name': fullName,
      'firstname': firstname,
      'second_name': secondName,
      'thirdname': thirdname,
      'fourth_name': fourthName,
      'phone': phone,
      'location': location,
      'currency': currency,
      'account_type': accountType,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'is_factory': isFactory,
      'factory_license_url': factoryLicenseUrl,
      'min_order_quantity': minOrderQuantity,
      'wholesale_discount': wholesaleDiscount,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory SellerProfile.fromJson(Map<String, dynamic> json) => SellerProfile.fromMap(json);
}