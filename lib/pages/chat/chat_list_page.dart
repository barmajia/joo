import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/factory/controllers/chat_controller.dart';
import 'package:aurora/factory/models/chat_conversation_model.dart';
import 'package:aurora/factory/models/chat_participant_model.dart';
import 'package:aurora/factory/utils/chat_utils.dart';
import 'chat_conversation_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatController _chatController = ChatController();
  List<ChatConversation> _conversations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _error = 'Please log in to view chats';
          _isLoading = false;
        });
        return;
      }

      final conversations = await _chatController.loadConversationList(userId);

      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openConversation(ChatConversation conversation) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final otherUserId = conversation.getOtherParticipantId(userId) ?? '';
    if (otherUserId.isEmpty) return;

    final otherParticipant = conversation.participants?.firstWhere(
      (p) => p.userId != userId,
      orElse: () => ChatParticipant(
        conversationId: conversation.id,
        userId: '',
        joinedAt: DateTime.now(),
        accountType: 'user',
        role: 'customer',
      ),
    );

    final otherUserType = otherParticipant?.accountType ?? 'user';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatConversationPage(
          conversation: conversation,
          currentUserId: userId,
          otherUserId: otherUserId,
          otherUserType: otherUserType,
        ),
      ),
    );

    _loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadConversations,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _conversations.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No conversations yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadConversations,
                      child: ListView.builder(
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = _conversations[index];
                          return _buildConversationTile(conversation);
                        },
                      ),
                    ),
    );
  }

  Widget _buildConversationTile(ChatConversation conversation) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final displayName = ChatUtils.getConversationDisplayName(conversation, userId);
    final lastMessage = conversation.lastMessage ?? 'No messages yet';
    final hasUnread = conversation.unreadCount > 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        child: Text(
          ChatUtils.getInitials(displayName),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        displayName,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (conversation.lastMessageAt != null)
            Text(
              ChatUtils.getTimeAgo(conversation.lastMessageAt!),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          if (hasUnread) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
      onTap: () => _openConversation(conversation),
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }
}
