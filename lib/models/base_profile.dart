import 'package:aurora/users/account_type.dart';

/// Unified base profile class for all user types (Seller, Factory, Customer, Middleman)
/// This reduces code duplication and provides a consistent interface across the app.
abstract class BaseProfile {
  final String userId;
  final String email;
  final String fullName;
  final String? phone;
  final String? location;
  final String currency;
  final AccountType accountType;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double? latitude;
  final double? longitude;
  final String? websiteUrl;
  final Map<String, dynamic>? metadata;

  BaseProfile({
    required this.userId,
    required this.email,
    required this.fullName,
    this.phone,
    this.location,
    this.currency = 'USD',
    required this.accountType,
    this.isVerified = false,
    required this.createdAt,
    this.updatedAt,
    this.latitude,
    this.longitude,
    this.websiteUrl,
    this.metadata,
  });

  /// Check if this profile belongs to a business account (seller or factory)
  bool get isBusinessAccount => 
      accountType == AccountType.seller || accountType == AccountType.factory;

  /// Check if profile has complete basic information
  bool get isProfileComplete => 
      fullName.isNotEmpty && 
      phone != null && 
      phone!.isNotEmpty &&
      location != null && 
      location!.isNotEmpty;

  /// Get verification status as a human-readable string
  String get verificationStatus => isVerified ? 'Verified' : 'Pending Verification';

  Map<String, dynamic> toBaseMap() {
    return {
      'user_id': userId,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'location': location,
      'currency': currency,
      'account_type': accountType.name,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'website_url': websiteUrl,
    };
  }
  
  @override
  String toString() {
    return '$runtimeType(userId: $userId, email: $email, accountType: $accountType)';
  }
}
