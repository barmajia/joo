import 'package:aurora/models/base_profile.dart';
import 'package:aurora/users/account_type.dart';

class SellerProfile extends BaseProfile {
  final String? firstname;
  final String? secondName;
  final String? thirdname;
  final String? fourthName;
  final bool isFactory;
  final String? factoryLicenseUrl;
  final int minOrderQuantity;
  final double wholesaleDiscount;
  final bool acceptsReturns;
  final String? productionCapacity;
  final DateTime? verifiedAt;
  final bool allowProductChats;
  final bool allowCustomRequests;
  final String? avatarUrl;
  final String? bio;
  final int responseRate;
  final bool allowMiddlemanPromo;
  final bool requireMiddlemanApproval;
  final String? storeSlug;
  final String? storeName;
  final int currentTemplateId;

  SellerProfile({
    required String userId,
    required String email,
    required String fullName,
    this.firstname,
    this.secondName,
    this.thirdname,
    this.fourthName,
    String? phone,
    String? location,
    String currency = 'USD',
    bool isVerified = false,
    required DateTime createdAt,
    DateTime? updatedAt,
    double? latitude,
    double? longitude,
    String? websiteUrl,
    Map<String, dynamic>? metadata,
    this.isFactory = false,
    this.factoryLicenseUrl,
    this.minOrderQuantity = 1,
    this.wholesaleDiscount = 0,
    this.acceptsReturns = true,
    this.productionCapacity,
    this.verifiedAt,
    this.allowProductChats = true,
    this.allowCustomRequests = false,
    this.avatarUrl,
    this.bio,
    this.responseRate = 0,
    this.allowMiddlemanPromo = true,
    this.requireMiddlemanApproval = false,
    this.storeSlug,
    this.storeName,
    this.currentTemplateId = 1,
  }) : super(
          userId: userId,
          email: email,
          fullName: fullName,
          phone: phone,
          location: location,
          currency: currency,
          accountType: AccountType.seller,
          isVerified: isVerified,
          createdAt: createdAt,
          updatedAt: updatedAt,
          latitude: latitude,
          longitude: longitude,
          websiteUrl: websiteUrl,
          metadata: metadata,
        );

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
      isVerified: map['is_verified'] ?? false,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      websiteUrl: map['website_url'],
      isFactory: map['is_factory'] ?? false,
      factoryLicenseUrl: map['factory_license_url'],
      minOrderQuantity: map['min_order_quantity'] ?? 1,
      wholesaleDiscount: (map['wholesale_discount'] ?? 0).toDouble(),
      acceptsReturns: map['accepts_returns'] ?? true,
      productionCapacity: map['production_capacity'],
      verifiedAt: map['verified_at'] != null 
          ? DateTime.parse(map['verified_at']) 
          : null,
      allowProductChats: map['allow_product_chats'] ?? true,
      allowCustomRequests: map['allow_custom_requests'] ?? false,
      avatarUrl: map['avatar_url'],
      bio: map['bio'],
      responseRate: map['response_rate'] ?? 0,
      allowMiddlemanPromo: map['allow_middleman_promo'] ?? true,
      requireMiddlemanApproval: map['require_middleman_approval'] ?? false,
      storeSlug: map['store_slug'],
      storeName: map['store_name'],
      currentTemplateId: map['current_template_id'] ?? 1,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...toBaseMap(),
      'firstname': firstname,
      'second_name': secondName,
      'thirdname': thirdname,
      'fourth_name': fourthName,
      'is_factory': isFactory,
      'factory_license_url': factoryLicenseUrl,
      'min_order_quantity': minOrderQuantity,
      'wholesale_discount': wholesaleDiscount,
      'accepts_returns': acceptsReturns,
      'production_capacity': productionCapacity,
      'verified_at': verifiedAt?.toIso8601String(),
      'allow_product_chats': allowProductChats,
      'allow_custom_requests': allowCustomRequests,
      'avatar_url': avatarUrl,
      'bio': bio,
      'response_rate': responseRate,
      'allow_middleman_promo': allowMiddlemanPromo,
      'require_middleman_approval': requireMiddlemanApproval,
      'store_slug': storeSlug,
      'store_name': storeName,
      'current_template_id': currentTemplateId,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory SellerProfile.fromJson(Map<String, dynamic> json) => 
      SellerProfile.fromMap(json);

  @override
  SellerProfile copyWith({
    String? userId,
    String? email,
    String? fullName,
    String? firstname,
    String? secondName,
    String? thirdname,
    String? fourthName,
    String? phone,
    String? location,
    String? currency,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? latitude,
    double? longitude,
    String? websiteUrl,
    Map<String, dynamic>? metadata,
    bool? isFactory,
    String? factoryLicenseUrl,
    int? minOrderQuantity,
    double? wholesaleDiscount,
    bool? acceptsReturns,
    String? productionCapacity,
    DateTime? verifiedAt,
    bool? allowProductChats,
    bool? allowCustomRequests,
    String? avatarUrl,
    String? bio,
    int? responseRate,
    bool? allowMiddlemanPromo,
    bool? requireMiddlemanApproval,
    String? storeSlug,
    String? storeName,
    int? currentTemplateId,
  }) {
    return SellerProfile(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      firstname: firstname ?? this.firstname,
      secondName: secondName ?? this.secondName,
      thirdname: thirdname ?? this.thirdname,
      fourthName: fourthName ?? this.fourthName,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      currency: currency ?? this.currency,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      metadata: metadata ?? this.metadata,
      isFactory: isFactory ?? this.isFactory,
      factoryLicenseUrl: factoryLicenseUrl ?? this.factoryLicenseUrl,
      minOrderQuantity: minOrderQuantity ?? this.minOrderQuantity,
      wholesaleDiscount: wholesaleDiscount ?? this.wholesaleDiscount,
      acceptsReturns: acceptsReturns ?? this.acceptsReturns,
      productionCapacity: productionCapacity ?? this.productionCapacity,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      allowProductChats: allowProductChats ?? this.allowProductChats,
      allowCustomRequests: allowCustomRequests ?? this.allowCustomRequests,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      responseRate: responseRate ?? this.responseRate,
      allowMiddlemanPromo: allowMiddlemanPromo ?? this.allowMiddlemanPromo,
      requireMiddlemanApproval: requireMiddlemanApproval ?? this.requireMiddlemanApproval,
      storeSlug: storeSlug ?? this.storeSlug,
      storeName: storeName ?? this.storeName,
      currentTemplateId: currentTemplateId ?? this.currentTemplateId,
    );
  }

  /// Get seller-specific display name
  String get displayName => storeName ?? fullName;

  /// Check if seller can accept custom orders
  bool get canAcceptCustomOrders => allowCustomRequests && isVerified;

  /// Calculate wholesale price for a given quantity
  double getWholesalePrice(double basePrice, int quantity) {
    if (quantity < minOrderQuantity) return basePrice;
    final discount = wholesaleDiscount > 0 ? wholesaleDiscount : 0;
    return basePrice * (1 - (discount / 100));
  }
}
