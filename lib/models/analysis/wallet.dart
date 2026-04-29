import 'package:aurora/models/analysis/enums.dart';

class Wallet {
  final String id;
  final String userId;
  final double balance;
  final double pendingBalance;
  final double totalDeposited;
  final double totalWithdrawn;
  final double totalEarned;
  final double totalSpent;
  final String currency;
  final bool isActive;
  final bool isLocked;
  final String? lockReason;
  final DateTime? lockedAt;
  final DateTime? lastTransactionAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wallet({
    required this.id,
    required this.userId,
    this.balance = 0,
    this.pendingBalance = 0,
    this.totalDeposited = 0,
    this.totalWithdrawn = 0,
    this.totalEarned = 0,
    this.totalSpent = 0,
    this.currency = 'EGP',
    this.isActive = true,
    this.isLocked = false,
    this.lockReason,
    this.lockedAt,
    this.lastTransactionAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get availableBalance => isLocked ? 0 : balance;

  bool get canWithdraw => isActive && !isLocked && balance > 0;

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      balance: _parseNumeric(map['balance']),
      pendingBalance: _parseNumeric(map['pending_balance']),
      totalDeposited: _parseNumeric(map['total_deposited']),
      totalWithdrawn: _parseNumeric(map['total_withdrawn']),
      totalEarned: _parseNumeric(map['total_earned']),
      totalSpent: _parseNumeric(map['total_spent']),
      currency: map['currency'] as String? ?? 'EGP',
      isActive: map['is_active'] as bool? ?? true,
      isLocked: map['is_locked'] as bool? ?? false,
      lockReason: map['lock_reason'] as String?,
      lockedAt: map['locked_at'] != null
          ? DateTime.tryParse(map['locked_at'].toString())
          : null,
      lastTransactionAt: map['last_transaction_at'] != null
          ? DateTime.tryParse(map['last_transaction_at'].toString())
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'balance': balance,
      'pending_balance': pendingBalance,
      'total_deposited': totalDeposited,
      'total_withdrawn': totalWithdrawn,
      'total_earned': totalEarned,
      'total_spent': totalSpent,
      'currency': currency,
      'is_active': isActive,
      'is_locked': isLocked,
      'lock_reason': lockReason,
      'locked_at': lockedAt?.toIso8601String(),
      'last_transaction_at': lastTransactionAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Wallet copyWith({
    String? id,
    String? userId,
    double? balance,
    double? pendingBalance,
    double? totalDeposited,
    double? totalWithdrawn,
    double? totalEarned,
    double? totalSpent,
    String? currency,
    bool? isActive,
    bool? isLocked,
    String? lockReason,
    DateTime? lockedAt,
    DateTime? lastTransactionAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      totalDeposited: totalDeposited ?? this.totalDeposited,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      totalEarned: totalEarned ?? this.totalEarned,
      totalSpent: totalSpent ?? this.totalSpent,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      isLocked: isLocked ?? this.isLocked,
      lockReason: lockReason ?? this.lockReason,
      lockedAt: lockedAt ?? this.lockedAt,
      lastTransactionAt: lastTransactionAt ?? this.lastTransactionAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static double _parseNumeric(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class WalletTransaction {
  final String id;
  final String userId;
  final TransactionType transactionType;
  final double amount;
  final String? description;
  final String? referenceType;
  final String? referenceId;
  final double? balanceAfter;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.userId,
    required this.transactionType,
    required this.amount,
    this.description,
    this.referenceType,
    this.referenceId,
    this.balanceAfter,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isCredit =>
      transactionType == TransactionType.credit ||
      transactionType == TransactionType.deposit ||
      transactionType == TransactionType.commission;

  bool get isDebit =>
      transactionType == TransactionType.debit ||
      transactionType == TransactionType.withdrawal ||
      transactionType == TransactionType.purchase;

  factory WalletTransaction.fromMap(Map<String, dynamic> map) {
    return WalletTransaction(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      transactionType: TransactionTypeExtension.fromString(
          map['transaction_type'] as String? ?? 'credit'),
      amount: _parseNumeric(map['amount']),
      description: map['description'] as String?,
      referenceType: map['reference_type'] as String?,
      referenceId: map['reference_id'] as String?,
      balanceAfter: map['balance_after'] != null
          ? _parseNumeric(map['balance_after'])
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'transaction_type': transactionType.value,
      'amount': amount,
      'description': description,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'balance_after': balanceAfter,
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