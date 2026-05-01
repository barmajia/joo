class ChatParticipant {
  final String conversationId;
  final String userId;
  final DateTime joinedAt;
  final String accountType; // 'seller', 'factory', 'user', etc.
  final String role; // 'customer', 'seller', 'factory', etc.

  ChatParticipant({
    required this.conversationId,
    required this.userId,
    required this.joinedAt,
    this.accountType = 'user',
    this.role = 'customer',
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      conversationId: json['conversation_id'] ?? '',
      userId: json['user_id'] ?? '',
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : DateTime.now(),
      accountType: json['account_type'] ?? 'user',
      role: json['role'] ?? 'customer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'user_id': userId,
      'joined_at': joinedAt.toIso8601String(),
      'account_type': accountType,
      'role': role,
    };
  }

  ChatParticipant copyWith({
    String? conversationId,
    String? userId,
    DateTime? joinedAt,
    String? accountType,
    String? role,
  }) {
    return ChatParticipant(
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      joinedAt: joinedAt ?? this.joinedAt,
      accountType: accountType ?? this.accountType,
      role: role ?? this.role,
    );
  }

  bool get isSeller => accountType == 'seller';
  bool get isFactory => accountType == 'factory';
  bool get isUser => accountType == 'user';
}
