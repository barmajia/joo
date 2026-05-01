import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/factory/models/notification_model.dart';
import 'package:aurora/factory/services/connection_service.dart';
import 'package:aurora/factory/services/chat_service.dart';
import 'package:aurora/pages/chat/chat_conversation_page.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _connectionService = ConnectionService();
  final _chatService = ChatService();

  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _error = 'Please log in to view notifications';
          _isLoading = false;
        });
        return;
      }

      final notifications = await _connectionService.getNotifications(
        userId: userId,
      );

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<AppNotification> get _unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  List<AppNotification> get _connectionRequests =>
      _notifications.where((n) => n.isConnectionRequest).toList();

  Future<void> _handleConnectionRequest(
    AppNotification notification,
    String action,
  ) async {
    final connectionId = notification.connectionId;
    if (connectionId == null) return;

    try {
      if (action == 'approve') {
        await _connectionService.approveConnection(connectionId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connection approved'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (action == 'reject') {
        await _connectionService.rejectConnection(connectionId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connection rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      await _connectionService.markNotificationAsRead(notification.id);
      _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _openChat(AppNotification notification) async {
    final fromUserId = notification.fromUserId;
    if (fromUserId == null) return;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      final conversation = await _chatService.getOrCreateConversation(
        user1Id: currentUserId,
        user2Id: fromUserId,
        user1Type: 'seller',
        user2Type: 'factory',
      );

      if (conversation != null && mounted) {
        await _connectionService.markNotificationAsRead(notification.id);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatConversationPage(
              conversation: conversation,
              currentUserId: currentUserId,
              otherUserId: fromUserId,
              otherUserType: 'factory',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
            Tab(text: 'Connection Requests'),
          ],
        ),
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
                        onPressed: _loadNotifications,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNotificationList(_notifications),
                    _buildNotificationList(_unreadNotifications),
                    _buildNotificationList(_connectionRequests),
                  ],
                ),
    );
  }

  Widget _buildNotificationList(List<AppNotification> notifications) {
    if (notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No notifications',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationTile(notification);
        },
      ),
    );
  }

  Widget _buildNotificationTile(AppNotification notification) {
    final isConnectionReq = notification.isConnectionRequest;
    final icon = _getIconForType(notification.type);
    final iconColor = notification.isRead ? Colors.grey : Theme.of(context).primaryColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: notification.isRead
                  ? Colors.grey.shade100
                  : Theme.of(context).primaryColor.withAlpha(30),
              child: Icon(icon, color: iconColor),
            ),
            if (!notification.isRead)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              notification.timeAgo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: isConnectionReq
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () =>
                        _handleConnectionRequest(notification, 'approve'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () =>
                        _handleConnectionRequest(notification, 'reject'),
                  ),
                ],
              )
            : IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () => _openChat(notification),
              ),
        isThreeLine: true,
        onTap: () {
          if (!notification.isRead) {
            _connectionService.markNotificationAsRead(notification.id);
            _loadNotifications();
          }
          if (isConnectionReq) {
            _handleConnectionRequest(notification, 'approve');
          }
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_cart;
      case 'message':
        return Icons.message;
      case 'deal':
        return Icons.handshake;
      case 'system':
        return Icons.info;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
