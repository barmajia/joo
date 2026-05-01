import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:aurora/factory/models/chat_conversation_model.dart';
import 'package:aurora/factory/models/chat_message_model.dart';
import 'package:aurora/factory/services/chat_service.dart';
import 'package:aurora/factory/services/chat_vault_storage.dart';

class ChatController {
  final ChatService _chatService = ChatService();
  ChatVaultStorage? _chatVault;

  StreamController<List<ChatMessage>>? _messagesController;
  Stream<List<ChatMessage>>? _messagesStream;

  ChatConversation? _currentConversation;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;

  ChatConversation? get currentConversation => _currentConversation;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMessages => _messages.isNotEmpty;

  Future<ChatVaultStorage> get _vault async {
    _chatVault ??= await ChatVaultStorage.getInstance();
    return _chatVault!;
  }

  Future<ChatConversation?> initializeChat({
    required String currentUserId,
    required String otherUserId,
    required String currentUserType,
    required String otherUserType,
    String? productId,
  }) async {
    _isLoading = true;
    _error = null;
    debugPrint(
      '[ChatController] Initializing chat between $currentUserId and $otherUserId',
    );

    try {
      final conversation = await _chatService.getOrCreateConversation(
        user1Id: currentUserId,
        user2Id: otherUserId,
        user1Type: currentUserType,
        user2Type: otherUserType,
        productId: productId,
      );

      if (conversation == null) {
        _error = 'Failed to create or find conversation';
        _isLoading = false;
        return null;
      }

      _currentConversation = conversation;

      await loadMessages(conversation.id);

      await _chatService.markMessagesAsRead(
        conversationId: conversation.id,
        userId: currentUserId,
      );

      _setupRealtimeSubscription(conversation.id);

      _isLoading = false;
      debugPrint('[ChatController] Chat initialized: ${conversation.id}');
      return conversation;
    } catch (e, stack) {
      _error = e.toString();
      _isLoading = false;
      debugPrint('[ChatController.initializeChat] Error: $e\n$stack');
      return null;
    }
  }

  Future<void> loadMessages(String conversationId, {bool refresh = false}) async {
    try {
      final vault = await _vault;

      if (!refresh) {
        final cached = vault.getCachedMessages(conversationId);
        if (cached.isNotEmpty) {
          _messages = cached;
          debugPrint(
            '[ChatController] Loaded ${cached.length} messages from cache',
          );
        }
      }

      final messages = await _chatService.getMessages(
        conversationId: conversationId,
      );

      _messages = messages;
      await vault.cacheMessages(conversationId, messages);

      debugPrint(
        '[ChatController] Loaded ${messages.length} messages from service',
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('[ChatController.loadMessages] Error: $e');
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
      final message = await _chatService.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        content: content,
        messageType: messageType,
        attachmentUrl: attachmentUrl,
        attachmentName: attachmentName,
        attachmentSize: attachmentSize,
      );

      if (message != null) {
        _messages.add(message);
        final vault = await _vault;
        await vault.cacheMessages(conversationId, _messages);
        debugPrint('[ChatController] Message sent: ${message.id}');
      }

      return message;
    } catch (e) {
      _error = e.toString();
      debugPrint('[ChatController.sendMessage] Error: $e');
      return null;
    }
  }

  Future<List<ChatConversation>> loadConversationList(String userId) async {
    _isLoading = true;
    _error = null;

    try {
      final vault = await _vault;
      final cached = vault.getCachedConversations(userId);
      if (cached.isNotEmpty) {
        debugPrint(
          '[ChatController] Loaded ${cached.length} conversations from cache',
        );
      }

      final conversations = await _chatService.getConversationsForUser(
        userId: userId,
      );

      await vault.cacheConversations(userId, conversations);

      _isLoading = false;
      debugPrint(
        '[ChatController] Loaded ${conversations.length} conversations',
      );
      return conversations;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      debugPrint('[ChatController.loadConversationList] Error: $e');
      return [];
    }
  }

  Future<int> getUnreadBadgeCount(String userId) async {
    try {
      return await _chatService.getUnreadCount(userId);
    } catch (e) {
      debugPrint('[ChatController.getUnreadBadgeCount] Error: $e');
      return 0;
    }
  }

  void _setupRealtimeSubscription(String conversationId) {
    _messagesController = StreamController<List<ChatMessage>>.broadcast();
    _messagesStream = _messagesController?.stream;

    _chatService.subscribeToMessages(conversationId).listen((messages) {
      _messages = messages;
      _messagesController?.add(messages);
      debugPrint(
        '[ChatController] Realtime update: ${messages.length} messages',
      );
    });
  }

  Stream<List<ChatMessage>>? get messagesStream => _messagesStream;

  Future<void> deleteMessage(String messageId) async {
    try {
      final success = await _chatService.deleteMessage(messageId);
      if (success) {
        _messages.removeWhere((m) => m.id == messageId);
        if (_currentConversation != null) {
          final vault = await _vault;
          await vault.cacheMessages(_currentConversation!.id, _messages);
        }
        debugPrint('[ChatController] Message deleted: $messageId');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('[ChatController.deleteMessage] Error: $e');
    }
  }

  Future<void> clearCurrentChatCache() async {
    try {
      if (_currentConversation != null) {
        final vault = await _vault;
        await vault.clearConversationCache(_currentConversation!.id);
        debugPrint('[ChatController] Cleared current chat cache');
      }
    } catch (e) {
      debugPrint('[ChatController.clearCurrentChatCache] Error: $e');
    }
  }

  void dispose() {
    _chatService.dispose();
    _messagesController?.close();
    _messagesController = null;
    _messagesStream = null;
    _currentConversation = null;
    _messages.clear();
    debugPrint('[ChatController] Disposed');
  }
}
