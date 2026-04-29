import 'account_type.dart';

class Users {
  final String id;
  final String email;
  final String name;
  final String password;
  final AccountType accountType;
  final int phonenumber;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isactive;
  final Map<String, dynamic>? metadata;

  Users({
    this.id = '',
    this.email = '',
    this.name = '',
    this.password = '',
    this.accountType = AccountType.seller,
    this.phonenumber = 0,
    DateTime? createdAt,
    this.lastLoginAt,
    this.isactive = true,
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Users.zero() => Users();

  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      password: json['password'] as String? ?? '',
      accountType: _parseAccountType(json['account_type'] as String?),
      phonenumber: json['phonenumber'] as int? ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      isactive: json['isactive'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  static AccountType _parseAccountType(String? value) {
    if (value == null || value.isEmpty) return AccountType.seller;
    for (var type in AccountType.values) {
      if (type.name == value) return type;
    }
    return AccountType.seller;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'password': password,
      'account_type': accountType.name,
      'phonenumber': phonenumber,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'isactive': isactive,
      'metadata': metadata,
    };
  }

  Users copyWith({
    String? id,
    String? email,
    String? name,
    String? password,
    AccountType? accountType,
    int? phonenumber,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isactive,
    Map<String, dynamic>? metadata,
  }) {
    return Users(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      password: password ?? this.password,
      accountType: accountType ?? this.accountType,
      phonenumber: phonenumber ?? this.phonenumber,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isactive: isactive ?? this.isactive,
      metadata: metadata ?? this.metadata,
    );
  }
}