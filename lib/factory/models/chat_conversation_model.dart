import 'chat_participant_model.dart';

class ChatConversation {
  final String id;
  final String name;
  final String type; // 'direct' or 'group'
  final String? context; // 'general', 'product', 'deal', etc.
  final String? productId;
  final bool isArchived;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatParticipant>? participants;

  ChatConversation({
    required this.id,
    required this.name,
    this.type = 'direct',
    this.context,
    this.productId,
    this.isArchived = false,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.participants,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'direct',
      context: json['context'],
      productId: json['product_id'],
      isArchived: json['is_archived'] ?? false,
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      participants: json['conversation_participants'] != null
          ? (json['conversation_participants'] as List)
              .map((e) => ChatParticipant.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'context': context,
      'product_id': productId,
      'is_archived': isArchived,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ChatConversation copyWith({
    String? id,
    String? name,
    String? type,
    String? context,
    String? productId,
    bool? isArchived,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatParticipant>? participants,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      context: context ?? this.context,
      productId: productId ?? this.productId,
      isArchived: isArchived ?? this.isArchived,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      participants: participants ?? this.participants,
    );
  }

  String? getOtherParticipantId(String currentUserId) {
    if (participants == null || participants!.isEmpty) return null;
    try {
      final other = participants!.firstWhere(
        (p) => p.userId != currentUserId,
        orElse: () => ChatParticipant(
          conversationId: id,
          userId: '',
          joinedAt: DateTime.now(),
        ),
      );
      return other.userId.isNotEmpty ? other.userId : null;
    } catch (e) {
      return null;
    }
  }

  String? getOtherParticipantName(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return otherId;
  }
}
