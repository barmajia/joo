import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/factory/models/connection_model.dart';
import 'package:aurora/factory/models/notification_model.dart';

class ConnectionService {
  final _supabase = Supabase.instance.client;

  ConnectionService();

  Future<FactoryConnection?> requestConnection({
    required String factoryId,
    required String sellerId,
    String? notes,
  }) async {
    try {
      debugPrint(
        '[ConnectionService] Requesting connection: factory=$factoryId, seller=$sellerId',
      );

      final response = await _supabase
          .rpc(
            'request_factory_connection',
            params: {
              'p_factory_id': factoryId,
              'p_seller_id': sellerId,
              if (notes != null) 'p_notes': notes,
            },
          )
          .select()
          .single();

      debugPrint('[ConnectionService] Connection request response: $response');

      final data = response;
      if (data.containsKey('id')) {
        return FactoryConnection.fromJson(data);
      }

      return null;
    } catch (e, stack) {
      debugPrint('[ConnectionService.requestConnection] Error: $e\n$stack');
      return null;
    }
  }

  Future<FactoryConnection?> approveConnection(String connectionId) async {
    try {
      debugPrint('[ConnectionService] Approving connection: $connectionId');

      final response = await _supabase
          .rpc(
            'approve_factory_connection',
            params: {'p_connection_id': connectionId},
          )
          .select()
          .single();

      debugPrint('[ConnectionService] Approve response: $response');

      final data = response;
      if (data.containsKey('id')) {
        return FactoryConnection.fromJson(data);
      }

      return null;
    } catch (e, stack) {
      debugPrint('[ConnectionService.approveConnection] Error: $e\n$stack');
      return null;
    }
  }

  Future<bool> rejectConnection(String connectionId, {String? reason}) async {
    try {
      debugPrint('[ConnectionService] Rejecting connection: $connectionId');

      await _supabase
          .from('factory_connections')
          .update({
            'status': 'rejected',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', connectionId);

      return true;
    } catch (e, stack) {
      debugPrint('[ConnectionService.rejectConnection] Error: $e\n$stack');
      return false;
    }
  }

  Future<List<FactoryConnection>> getMyConnections({
    required String userId,
    String? statusFilter,
  }) async {
    try {
      List<dynamic> response;

      if (statusFilter != null) {
        response = await _supabase
            .from('factory_connections')
            .select()
            .or('factory_id.eq.$userId,seller_id.eq.$userId')
            .eq('status', statusFilter)
            .order('created_at', ascending: false);
      } else {
        response = await _supabase
            .from('factory_connections')
            .select()
            .or('factory_id.eq.$userId,seller_id.eq.$userId')
            .order('created_at', ascending: false);
      }

      return response.map((json) => FactoryConnection.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[ConnectionService.getMyConnections] Error: $e');
      return [];
    }
  }

  Future<List<FactoryConnection>> getPendingRequests(String userId) async {
    try {
      final response = await _supabase
          .from('factory_connections')
          .select()
          .eq('seller_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return response.map((json) => FactoryConnection.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[ConnectionService.getPendingRequests] Error: $e');
      return [];
    }
  }

  Future<List<FactoryConnection>> getSentRequests(String userId) async {
    try {
      final response = await _supabase
          .from('factory_connections')
          .select()
          .eq('factory_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return response.map((json) => FactoryConnection.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[ConnectionService.getSentRequests] Error: $e');
      return [];
    }
  }

  Future<bool> removeConnection(String connectionId) async {
    try {
      await _supabase
          .from('factory_connections')
          .delete()
          .eq('id', connectionId);
      return true;
    } catch (e) {
      debugPrint('[ConnectionService.removeConnection] Error: $e');
      return false;
    }
  }

  Future<AppNotification?> sendConnectionNotification({
    required String toUserId,
    required String fromUserId,
    required String connectionId,
    required String fromUserName,
    required String accountType,
  }) async {
    try {
      final notificationData = {
        'user_id': toUserId,
        'title': 'New Connection Request',
        'message': '$fromUserName wants to connect with you as a $accountType',
        'type': 'system',
        'priority': 'medium',
        'is_read': false,
        'reference_type': 'factory_connection',
        'reference_id': connectionId,
        'metadata': {
          'type': 'connection_request',
          'connection_id': connectionId,
          'from_user_id': fromUserId,
          'from_user_name': fromUserName,
          'account_type': accountType,
        },
      };

      final response = await _supabase
          .from('notifications')
          .insert(notificationData)
          .select()
          .single();

      return AppNotification.fromJson(response);
    } catch (e) {
      debugPrint('[ConnectionService.sendConnectionNotification] Error: $e');
      return null;
    }
  }

  Future<List<AppNotification>> getNotifications({
    required String userId,
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId);

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((json) => AppNotification.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[ConnectionService.getNotifications] Error: $e');
      return [];
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('[ConnectionService.markNotificationAsRead] Error: $e');
    }
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);
      return response.length;
    } catch (e) {
      debugPrint('[ConnectionService.getUnreadNotificationCount] Error: $e');
      return 0;
    }
  }
}
