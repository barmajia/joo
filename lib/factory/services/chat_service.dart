import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/factory/models/chat_conversation_model.dart';
import 'package:aurora/factory/models/chat_message_model.dart';
import 'package:aurora/factory/models/chat_participant_model.dart';

class ChatService {
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _conversationsChannel;

  ChatService();

  Future<ChatConversation?> getOrCreateConversation({
    required String user1Id,
    required String user2Id,
    required String user1Type,
    required String user2Type,
    String? productId,
  }) async {
    try {
      debugPrint('[ChatService] Checking for existing conversation between $user1Id and $user2Id');

      final existing = await _findExistingConversation(
        user1Id: user1Id,
        user2Id: user2Id,
      );

      if (existing != null) {
        debugPrint('[ChatService] Found existing conversation: ${existing.id}');
        return existing;
      }

      debugPrint('[ChatService] Creating new conversation');
      return await _createNewConversation(
        user1Id: user1Id,
        user2Id: user2Id,
        user1Type: user1Type,
        user2Type: user2Type,
        productId: productId,
      );
    } catch (e, stack) {
      debugPrint('[ChatService.getOrCreateConversation] Error: $e\n$stack');
      return null;
    }
  }

  Future<ChatConversation?> _findExistingConversation({
    required String user1Id,
    required String user2Id,
  }) async {
    try {
      final response = await _supabase
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', user1Id);

      if (response.isEmpty) return null;

      for (final participant in response) {
        final conversationId = participant['conversation_id'];

        final otherParticipant = await _supabase
            .from('conversation_participants')
            .select()
            .eq('conversation_id', conversationId)
            .eq('user_id', user2Id)
            .maybeSingle();

        if (otherParticipant != null) {
          final conversation = await _supabase
              .from('conversations')
              .select('*, conversation_participants(*)')
              .eq('id', conversationId)
              .maybeSingle();

          if (conversation != null) {
            return ChatConversation.fromJson(conversation);
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('[ChatService._findExistingConversation] Error: $e');
      return null;
    }
  }

  Future<ChatConversation?> _createNewConversation({
    required String user1Id,
    required String user2Id,
    required String user1Type,
    required String user2Type,
    String? productId,
  }) async {
    try {
      final conversationName = 'Chat $user1Id - $user2Id';
      final conversationData = {
        'name': conversationName,
        'type': 'direct',
        'context': productId != null ? 'product' : 'general',
        'product_id': productId,
        'is_archived': false,
        'unread_count': 0,
      };

      final conversationResponse = await _supabase
          .from('conversations')
          .insert(conversationData)
          .select()
          .single();

      final conversationId = conversationResponse['id'];

      final participants = [
        {
          'conversation_id': conversationId,
          'user_id': user1Id,
          'account_type': user1Type,
          'role': user1Type,
        },
        {
          'conversation_id': conversationId,
          'user_id': user2Id,
          'account_type': user2Type,
          'role': user2Type,
        },
      ];

      await _supabase.from('conversation_participants').insert(participants);

      final fullConversation = await _supabase
          .from('conversations')
          .select('*, conversation_participants(*)')
          .eq('id', conversationId)
          .single();

      return ChatConversation.fromJson(fullConversation);
    } catch (e, stack) {
      debugPrint('[ChatService._createNewConversation] Error: $e\n$stack');
      return null;
    }
  }

  Future<ChatMessage?> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    String messageType = 'text',
    String? attachmentUrl,
    String? attachmentName,
    int? attachmentSize,
  }) async {
    try {
      final messageData = {
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': content,
        'message_type': messageType,
        'attachment_url': attachmentUrl,
        'attachment_name': attachmentName,
        'attachment_size': attachmentSize,
        'is_deleted': false,
      };

      final response = await _supabase
          .from('messages')
          .insert(messageData)
          .select()
          .single();

      await _supabase.from('conversations').update({
        'last_message': messageType == 'text' ? content : '[Attachment]',
        'last_message_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', conversationId);

      return ChatMessage.fromJson(response);
    } catch (e, stack) {
      debugPrint('[ChatService.sendMessage] Error: $e\n$stack');
      return null;
    }
  }

  Future<List<ChatMessage>> getMessages({
    required String conversationId,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    try {
      var query = _supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(limit);

      if (beforeMessageId != null) {
        final beforeMessage = await _supabase
            .from('messages')
            .select('created_at')
            .eq('id', beforeMessageId)
            .single();

        final beforeTime = beforeMessage['created_at'];
        final response = await _supabase
            .from('messages')
            .select()
            .eq('conversation_id', conversationId)
            .eq('is_deleted', false)
            .lt('created_at', beforeTime)
            .order('created_at', ascending: false)
            .limit(limit);
        
        return response
            .map((json) => ChatMessage.fromJson(json))
            .toList()
            .reversed
            .toList();
      }

      final response = await query;
      return response
          .map((json) => ChatMessage.fromJson(json))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      debugPrint('[ChatService.getMessages] Error: $e');
      return [];
    }
  }

  Future<List<ChatConversation>> getConversationsForUser({
    required String userId,
    bool includeArchived = false,
  }) async {
    try {
      final participantResponse = await _supabase
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', userId);

      if (participantResponse.isEmpty) return [];

      final conversationIds =
          participantResponse.map((e) => e['conversation_id']).toList();

      final response = await _supabase
          .from('conversations')
          .select('*, conversation_participants(*)')
          .filter('id', 'in', conversationIds)
          .order('last_message_at', ascending: false);

      var conversations =
          response.map((json) => ChatConversation.fromJson(json)).toList();

      if (!includeArchived) {
        conversations = conversations
            .where((c) => c.isArchived == false)
            .toList();
      }

      return conversations;
    } catch (e) {
      debugPrint('[ChatService.getConversationsForUser] Error: $e');
      return [];
    }
  }

  Future<void> markMessagesAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from('messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .isFilter('read_at', null);

      await _supabase
          .from('conversations')
          .update({'unread_count': 0})
          .eq('id', conversationId);
    } catch (e) {
      debugPrint('[ChatService.markMessagesAsRead] Error: $e');
    }
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('conversations')
          .select('unread_count')
          .filter('id', 'in', [
            await _supabase
                .from('conversation_participants')
                .select('conversation_id')
                .eq('user_id', userId)
                .then((value) => value.map((e) => e['conversation_id']).toList())
          ]);

      return response.fold<int>(0, (sum, item) => sum + (item['unread_count'] as int? ?? 0));
    } catch (e) {
      debugPrint('[ChatService.getUnreadCount] Error: $e');
      return 0;
    }
  }

  Stream<List<ChatMessage>> subscribeToMessages(String conversationId) {
    final controller = StreamController<List<ChatMessage>>();

    _messagesChannel = _supabase
        .channel('public:messages:conversation_id=eq.$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            debugPrint(
              '[ChatService] New message received: ${payload.toString()}',
            );
            getMessages(conversationId: conversationId).then((messages) {
              if (!controller.isClosed) {
                controller.add(messages);
              }
            });
          },
        )
        .subscribe();

    return controller.stream;
  }

  void unsubscribeFromMessages() {
    _messagesChannel?.unsubscribe();
    _messagesChannel = null;
  }

  Future<bool> deleteMessage(String messageId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_deleted': true})
          .eq('id', messageId);
      return true;
    } catch (e) {
      debugPrint('[ChatService.deleteMessage] Error: $e');
      return false;
    }
  }

  Future<void> dispose() async {
    unsubscribeFromMessages();
    _conversationsChannel?.unsubscribe();
  }
}
