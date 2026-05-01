class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String? content;
  final String messageType; // 'text', 'image', 'file', 'deal_proposal'
  final String? attachmentUrl;
  final String? attachmentName;
  final int? attachmentSize;
  final bool isDeleted;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    this.messageType = 'text',
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentSize,
    this.isDeleted = false,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      content: json['content'],
      messageType: json['message_type'] ?? 'text',
      attachmentUrl: json['attachment_url'],
      attachmentName: json['attachment_name'],
      attachmentSize: json['attachment_size'],
      isDeleted: json['is_deleted'] ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType,
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
      'attachment_size': attachmentSize,
      'is_deleted': isDeleted,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    String? messageType,
    String? attachmentUrl,
    String? attachmentName,
    int? attachmentSize,
    bool? isDeleted,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentSize: attachmentSize ?? this.attachmentSize,
      isDeleted: isDeleted ?? this.isDeleted,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isText => messageType == 'text';
  bool get isImage => messageType == 'image';
  bool get isFile => messageType == 'file';
  bool get isDealProposal => messageType == 'deal_proposal';
  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;
}
