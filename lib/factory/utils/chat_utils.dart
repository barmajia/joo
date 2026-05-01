import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:aurora/factory/models/chat_message_model.dart';
import 'package:aurora/factory/models/chat_conversation_model.dart';
import 'package:aurora/factory/models/chat_participant_model.dart';

class ChatUtils {
  ChatUtils._();

  static String formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length == 1) return name.substring(0, 1).toUpperCase();
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }

  static String generateConversationName(
    String currentUserId,
    List<ChatParticipant> participants,
  ) {
    try {
      if (participants.isEmpty) return 'Chat';
      
      ChatParticipant? other;
      try {
        other = participants.firstWhere(
          (p) => p.userId != currentUserId,
        );
      } catch (e) {
        other = null;
      }
      
      if (other == null || other.userId.isEmpty) return 'Chat';
      final userId = other.userId;
      return userId.substring(0, min(8, userId.length));
    } catch (e) {
      return 'Chat';
    }
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static List<ChatMessage> groupMessagesByDate(List<ChatMessage> messages) {
    return messages.toList();
  }

  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  static bool shouldShowDateSeparator(
    ChatMessage current,
    ChatMessage? previous,
  ) {
    if (previous == null) return true;
    return !isSameDay(current.createdAt, previous.createdAt);
  }

  static String getConversationDisplayName(
    ChatConversation conversation,
    String currentUserId,
  ) {
    final otherId = conversation.getOtherParticipantId(currentUserId);
    if (otherId != null) {
      return 'User ${otherId.substring(0, min(8, otherId.length))}';
    }
    return conversation.name;
  }

  static int min(int a, int b) => a < b ? a : b;
}
