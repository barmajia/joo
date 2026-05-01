import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aurora/factory/models/chat_conversation_model.dart';
import 'package:aurora/factory/models/chat_message_model.dart';

class ChatVaultStorage {
  static ChatVaultStorage? _instance;
  SharedPreferences? _prefs;

  ChatVaultStorage._();

  static Future<ChatVaultStorage> getInstance() async {
    if (_instance == null) {
      _instance = ChatVaultStorage._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[ChatVaultStorage._init] Error: $e');
    }
  }

  String _getConversationsKey(String userId) => 'chat_conversations_$userId';
  String _getMessagesKey(String conversationId) => 'chat_messages_$conversationId';
  String _getSecureMessageKey(String messageId) => 'secure_msg_$messageId';

  Future<void> cacheConversations(
    String userId,
    List<ChatConversation> conversations,
  ) async {
    try {
      if (_prefs == null) await _init();
      final jsonList = conversations.map((c) => c.toJson()).toList();
      await _prefs?.setString(
        _getConversationsKey(userId),
        jsonEncode(jsonList),
      );
      debugPrint(
        '[ChatVaultStorage] Cached ${conversations.length} conversations for $userId',
      );
    } catch (e) {
      debugPrint('[ChatVaultStorage.cacheConversations] Error: $e');
    }
  }

  List<ChatConversation> getCachedConversations(String userId) {
    try {
      if (_prefs == null) return [];
      final jsonString = _prefs?.getString(_getConversationsKey(userId));
      if (jsonString == null || jsonString.isEmpty) return [];
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => ChatConversation.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[ChatVaultStorage.getCachedConversations] Error: $e');
      return [];
    }
  }

  Future<void> cacheMessages(
    String conversationId,
    List<ChatMessage> messages,
  ) async {
    try {
      if (_prefs == null) await _init();
      final jsonList = messages.map((m) => m.toJson()).toList();
      await _prefs?.setString(
        _getMessagesKey(conversationId),
        jsonEncode(jsonList),
      );
      debugPrint(
        '[ChatVaultStorage] Cached ${messages.length} messages for $conversationId',
      );
    } catch (e) {
      debugPrint('[ChatVaultStorage.cacheMessages] Error: $e');
    }
  }

  List<ChatMessage> getCachedMessages(String conversationId) {
    try {
      if (_prefs == null) return [];
      final jsonString = _prefs?.getString(_getMessagesKey(conversationId));
      if (jsonString == null || jsonString.isEmpty) return [];
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => ChatMessage.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[ChatVaultStorage.getCachedMessages] Error: $e');
      return [];
    }
  }

  Future<void> saveSecureMessage({
    required String messageId,
    required String content,
  }) async {
    try {
      if (_prefs == null) await _init();
      await _prefs?.setString(
        _getSecureMessageKey(messageId),
        content,
      );
      debugPrint('[ChatVaultStorage] Saved secure message $messageId');
    } catch (e) {
      debugPrint('[ChatVaultStorage.saveSecureMessage] Error: $e');
    }
  }

  String? getSecureMessage(String messageId) {
    try {
      if (_prefs == null) return null;
      return _prefs?.getString(_getSecureMessageKey(messageId));
    } catch (e) {
      debugPrint('[ChatVaultStorage.getSecureMessage] Error: $e');
      return null;
    }
  }

  Future<void> deleteSecureMessage(String messageId) async {
    try {
      if (_prefs == null) await _init();
      await _prefs?.remove(_getSecureMessageKey(messageId));
    } catch (e) {
      debugPrint('[ChatVaultStorage.deleteSecureMessage] Error: $e');
    }
  }

  Future<void> clearConversationCache(String conversationId) async {
    try {
      if (_prefs == null) await _init();
      await _prefs?.remove(_getMessagesKey(conversationId));
      debugPrint(
        '[ChatVaultStorage] Cleared cache for conversation $conversationId',
      );
    } catch (e) {
      debugPrint('[ChatVaultStorage.clearConversationCache] Error: $e');
    }
  }

  Future<void> clearUserChatCache(String userId) async {
    try {
      if (_prefs == null) await _init();
      await _prefs?.remove(_getConversationsKey(userId));
      debugPrint('[ChatVaultStorage] Cleared chat cache for $userId');
    } catch (e) {
      debugPrint('[ChatVaultStorage.clearUserChatCache] Error: $e');
    }
  }

  Future<void> clearAllChatCache() async {
    try {
      if (_prefs == null) await _init();
      final keys = _prefs?.getKeys() ?? <String>{};
      final chatKeys = keys.where(
        (key) => key.startsWith('chat_') || key.startsWith('secure_msg_'),
      );
      for (final key in chatKeys) {
        await _prefs?.remove(key);
      }
      debugPrint('[ChatVaultStorage] Cleared all chat cache');
    } catch (e) {
      debugPrint('[ChatVaultStorage.clearAllChatCache] Error: $e');
    }
  }

  Future<bool> hasCachedConversations(String userId) async {
    try {
      if (_prefs == null) await _init();
      return _prefs?.containsKey(_getConversationsKey(userId)) ?? false;
    } catch (e) {
      debugPrint('[ChatVaultStorage.hasCachedConversations] Error: $e');
      return false;
    }
  }

  Future<bool> hasCachedMessages(String conversationId) async {
    try {
      if (_prefs == null) await _init();
      return _prefs?.containsKey(_getMessagesKey(conversationId)) ?? false;
    } catch (e) {
      debugPrint('[ChatVaultStorage.hasCachedMessages] Error: $e');
      return false;
    }
  }
}
