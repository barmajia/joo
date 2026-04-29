import 'package:aurora/models/analysis/enums.dart';

class Commission {
  final String id;
  final String middleManId;
  final String? orderId;
  final String? dealId;
  final double amount;
  final double commissionRate;
  final CommissionStatus status;
  final DateTime createdAt;
  final DateTime? paidAt;

  Commission({
    required this.id,
    required this.middleManId,
    this.orderId,
    this.dealId,
    required this.amount,
    required this.commissionRate,
    this.status = CommissionStatus.pending,
    DateTime? createdAt,
    this.paidAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isPending => status == CommissionStatus.pending;
  bool get isPaid => status == CommissionStatus.paid;
  bool get isWithdrawn => status == CommissionStatus.withdrawn;

  double get earnings => amount * (commissionRate / 100);

  factory Commission.fromMap(Map<String, dynamic> map) {
    return Commission(
      id: map['id'] as String? ?? '',
      middleManId: map['middle_man_id'] as String? ?? '',
      orderId: map['order_id'] as String?,
      dealId: map['deal_id'] as String?,
      amount: _parseNumeric(map['amount']),
      commissionRate: _parseNumeric(map['commission_rate']),
      status: CommissionStatusExtension.fromString(
          map['status'] as String? ?? 'pending'),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      paidAt: map['paid_at'] != null
          ? DateTime.tryParse(map['paid_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'middle_man_id': middleManId,
      'order_id': orderId,
      'deal_id': dealId,
      'amount': amount,
      'commission_rate': commissionRate,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
    };
  }

  Commission copyWith({
    String? id,
    String? middleManId,
    String? orderId,
    String? dealId,
    double? amount,
    double? commissionRate,
    CommissionStatus? status,
    DateTime? createdAt,
    DateTime? paidAt,
  }) {
    return Commission(
      id: id ?? this.id,
      middleManId: middleManId ?? this.middleManId,
      orderId: orderId ?? this.orderId,
      dealId: dealId ?? this.dealId,
      amount: amount ?? this.amount,
      commissionRate: commissionRate ?? this.commissionRate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  static double _parseNumeric(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}