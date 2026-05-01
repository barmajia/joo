import 'package:aurora/models/base_profile.dart';
import 'package:aurora/users/account_type.dart';

class FactoryProfile extends BaseProfile {
  final String? companyName;
  final Map<String, dynamic>? capacityInfo;
  final String? businessLicenseUrl;
  final String? locationText;
  final int? productionCapacity;
  final String? specialization;
  final Map<String, dynamic>? settings;
  final List<dynamic>? customers;

  FactoryProfile({
    required String userId,
    required String email,
    required String fullName,
    this.companyName,
    String? phone,
    String? location,
    String currency = 'USD',
    bool isVerified = false,
    required DateTime createdAt,
    DateTime? updatedAt,
    this.capacityInfo,
    this.businessLicenseUrl,
    this.locationText,
    this.productionCapacity,
    this.specialization,
    this.settings,
    this.customers,
    double? latitude,
    double? longitude,
    String? websiteUrl,
    Map<String, dynamic>? metadata,
  }) : super(
          userId: userId,
          email: email,
          fullName: fullName,
          phone: phone,
          location: location,
          currency: currency,
          accountType: AccountType.factory,
          isVerified: isVerified,
          createdAt: createdAt,
          updatedAt: updatedAt,
          latitude: latitude,
          longitude: longitude,
          websiteUrl: websiteUrl,
          metadata: metadata,
        );

  factory FactoryProfile.fromMap(Map<String, dynamic> map) {
    return FactoryProfile(
      userId: map['user_id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['full_name'] ?? '',
      companyName: map['company_name'],
      phone: map['phone'],
      location: map['location'],
      currency: map['currency'] ?? 'USD',
      isVerified: map['is_verified'] ?? false,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
      capacityInfo: map['capacity_info'],
      businessLicenseUrl: map['business_license_url'],
      locationText: map['location_text'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      websiteUrl: map['website_url'],
      productionCapacity: map['production_capacity'],
      specialization: map['specialization'],
      settings: map['settings'],
      customers: map['customers'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ...toBaseMap(),
      'company_name': companyName,
      'capacity_info': capacityInfo,
      'business_license_url': businessLicenseUrl,
      'location_text': locationText,
      'production_capacity': productionCapacity,
      'specialization': specialization,
      'settings': settings,
      'customers': customers,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory FactoryProfile.fromJson(Map<String, dynamic> json) => 
      FactoryProfile.fromMap(json);

  FactoryProfile copyWith({
    String? userId,
    String? email,
    String? fullName,
    String? companyName,
    String? phone,
    String? location,
    String? currency,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? capacityInfo,
    String? businessLicenseUrl,
    String? locationText,
    int? productionCapacity,
    String? specialization,
    Map<String, dynamic>? settings,
    List<dynamic>? customers,
    double? latitude,
    double? longitude,
    String? websiteUrl,
    Map<String, dynamic>? metadata,
  }) {
    return FactoryProfile(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      companyName: companyName ?? this.companyName,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      currency: currency ?? this.currency,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      capacityInfo: capacityInfo ?? this.capacityInfo,
      businessLicenseUrl: businessLicenseUrl ?? this.businessLicenseUrl,
      locationText: locationText ?? this.locationText,
      productionCapacity: productionCapacity ?? this.productionCapacity,
      specialization: specialization ?? this.specialization,
      settings: settings ?? this.settings,
      customers: customers ?? this.customers,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get factory display name
  String get displayName => companyName ?? fullName;

  /// Check if factory is verified and ready for orders
  bool get isReadyForOrders => isVerified && productionCapacity != null;

  /// Get lead time from settings
  int get leadTimeDays => settings?['lead_time_days'] as int? ?? 7;

  /// Check if factory accepts rush orders
  bool get acceptsRushOrders => settings?['accepts_rush_orders'] as bool? ?? false;
}
