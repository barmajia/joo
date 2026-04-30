import 'package:aurora/models/analysis/goals/goal_enums.dart';

class SellerGoal {
  final String id;
  final String sellerId;
  final GoalType type;
  final double targetValue;
  final double currentValue;
  final DateTime startDate;
  final DateTime endDate;
  final GoalStatus status;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  SellerGoal({
    required this.id,
    required this.sellerId,
    required this.type,
    required this.targetValue,
    this.currentValue = 0,
    required this.startDate,
    required this.endDate,
    this.status = GoalStatus.active,
    this.description,
    this.metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get progressPercentage {
    if (targetValue == 0) return 0;
    return ((currentValue / targetValue) * 100).clamp(0, 100);
  }

  bool get isAchieved => currentValue >= targetValue;

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  int get daysElapsed {
    return DateTime.now()
        .difference(startDate)
        .inDays
        .clamp(0, endDate.difference(startDate).inDays);
  }

  double get dailyTargetNeeded {
    if (daysRemaining == 0) return 0;
    final remaining = targetValue - currentValue;
    return remaining > 0 ? remaining / daysRemaining : 0;
  }

  factory SellerGoal.fromMap(Map<String, dynamic> map) {
    return SellerGoal(
      id: map['id'] as String? ?? '',
      sellerId: map['seller_id'] as String? ?? '',
      type: GoalTypeExtension.fromString(map['type'] as String? ?? 'revenue'),
      targetValue: _parseNumeric(map['target_value']),
      currentValue: _parseNumeric(map['current_value'] ?? 0),
      startDate: DateTime.tryParse(map['start_date']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(map['end_date']?.toString() ?? '') ?? DateTime.now(),
      status: GoalStatusExtension.fromString(map['status'] as String? ?? 'active'),
      description: map['description'] as String?,
      metadata: map['metadata'] is Map<String, dynamic>
          ? map['metadata'] as Map<String, dynamic>
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
      'seller_id': sellerId,
      'type': type.name,
      'target_value': targetValue,
      'current_value': currentValue,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'status': status.name,
      'description': description,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SellerGoal copyWith({
    String? id,
    String? sellerId,
    GoalType? type,
    double? targetValue,
    double? currentValue,
    DateTime? startDate,
    DateTime? endDate,
    GoalStatus? status,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SellerGoal(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
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

class Achievement {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final String badgeIcon;
  final String category;
  final int points;
  final DateTime earnedAt;
  final Map<String, dynamic>? metadata;

  Achievement({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.badgeIcon,
    required this.category,
    this.points = 0,
    required this.earnedAt,
    this.metadata,
  });

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as String? ?? '',
      sellerId: map['seller_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      badgeIcon: map['badge_icon'] as String? ?? '',
      category: map['category'] as String? ?? '',
      points: map['points'] as int? ?? 0,
      earnedAt: DateTime.tryParse(map['earned_at']?.toString() ?? '') ?? DateTime.now(),
      metadata: map['metadata'] is Map<String, dynamic>
          ? map['metadata'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seller_id': sellerId,
      'title': title,
      'description': description,
      'badge_icon': badgeIcon,
      'category': category,
      'points': points,
      'earned_at': earnedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  static List<Achievement> getDefaultAchievements() {
    return [
      Achievement(
        id: 'first_sale',
        sellerId: '',
        title: 'First Sale',
        description: 'Congratulations on your first sale!',
        badgeIcon: '🎉',
        category: 'milestone',
        points: 10,
        earnedAt: DateTime.now(),
      ),
      Achievement(
        id: 'hundred_sales',
        sellerId: '',
        title: 'Century Club',
        description: 'Reached 100 sales',
        badgeIcon: '💯',
        category: 'milestone',
        points: 50,
        earnedAt: DateTime.now(),
      ),
      Achievement(
        id: 'top_rated',
        sellerId: '',
        title: 'Top Rated Seller',
        description: 'Maintained 4.8+ rating for 30 days',
        badgeIcon: '⭐',
        category: 'quality',
        points: 100,
        earnedAt: DateTime.now(),
      ),
      Achievement(
        id: 'fast_shipper',
        sellerId: '',
        title: 'Speed Demon',
        description: 'Shipped 50 orders within 24 hours',
        badgeIcon: '🚀',
        category: 'efficiency',
        points: 75,
        earnedAt: DateTime.now(),
      ),
      Achievement(
        id: 'revenue_king',
        sellerId: '',
        title: 'Revenue King',
        description: 'Earned $10,000 in total revenue',
        badgeIcon: '👑',
        category: 'revenue',
        points: 150,
        earnedAt: DateTime.now(),
      ),
    ];
  }
}
