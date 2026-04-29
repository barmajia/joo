class FactoryProfile {
  final String userId;
  final String email;
  final String fullName;
  final String? companyName;
  final String? phone;
  final String? location;
  final String currency;
  final String accountType;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? capacityInfo;
  final String? businessLicenseUrl;
  final bool isFactory;
  final double? latitude;
  final String? locationText;
  final double? longitude;
  final int? productionCapacity;
  final String? specialization;
  final String? websiteUrl;
  final Map<String, dynamic>? settings;
  final List<dynamic>? customers;

  FactoryProfile({
    required this.userId,
    required this.email,
    required this.fullName,
    this.companyName,
    this.phone,
    this.location,
    this.currency = 'USD',
    this.accountType = 'factory',
    this.isVerified = false,
    required this.createdAt,
    this.updatedAt,
    this.capacityInfo,
    this.businessLicenseUrl,
    this.isFactory = true,
    this.latitude,
    this.locationText,
    this.longitude,
    this.productionCapacity,
    this.specialization,
    this.websiteUrl,
    this.settings,
    this.customers,
  });

  factory FactoryProfile.fromMap(Map<String, dynamic> map) {
    return FactoryProfile(
      userId: map['user_id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['full_name'] ?? '',
      companyName: map['company_name'],
      phone: map['phone'],
      location: map['location'],
      currency: map['currency'] ?? 'USD',
      accountType: map['account_type'] ?? 'factory',
      isVerified: map['is_verified'] ?? false,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      capacityInfo: map['capacity_info'],
      businessLicenseUrl: map['business_license_url'],
      isFactory: map['is_factory'] ?? true,
      latitude: map['latitude']?.toDouble(),
      locationText: map['location_text'],
      longitude: map['longitude']?.toDouble(),
      productionCapacity: map['production_capacity'],
      specialization: map['specialization'],
      websiteUrl: map['website_url'],
      settings: map['settings'],
      customers: map['customers'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'email': email,
      'full_name': fullName,
      'company_name': companyName,
      'phone': phone,
      'location': location,
      'currency': currency,
      'account_type': accountType,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'capacity_info': capacityInfo,
      'business_license_url': businessLicenseUrl,
      'is_factory': isFactory,
      'latitude': latitude,
      'location_text': locationText,
      'longitude': longitude,
      'production_capacity': productionCapacity,
      'specialization': specialization,
      'website_url': websiteUrl,
      'settings': settings,
      'customers': customers,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory FactoryProfile.fromJson(Map<String, dynamic> json) => FactoryProfile.fromMap(json);
}