import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/factory/services/connection_service.dart';
import 'package:aurora/factory/models/connection_model.dart';
import 'package:aurora/gen_l10n/app_localizations.dart';

class ConnectViaTokenPage extends StatefulWidget {
  const ConnectViaTokenPage({super.key});

  @override
  State<ConnectViaTokenPage> createState() => _ConnectViaTokenPageState();
}

class _ConnectViaTokenPageState extends State<ConnectViaTokenPage> {
  final _tokenController = TextEditingController();
  final _connectionService = ConnectionService();

  Map<String, dynamic>? _decodedData;
  bool _isDecoding = false;
  bool _isConnecting = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _decodeToken() {
    setState(() {
      _error = null;
      _successMessage = null;
      _decodedData = null;
      _isDecoding = true;
    });

    try {
      final token = _tokenController.text.trim();
      if (token.isEmpty) {
        throw Exception('Please enter a token');
      }

      if (!token.startsWith('aurora_')) {
        throw Exception('Invalid token format');
      }

      // Extract base64 part after 'aurora_${salt}_'
      final parts = token.split('_');
      if (parts.length < 3) {
        throw Exception('Invalid token structure');
      }

      final base64Part = parts.last;
      final decoded = utf8.decode(base64Decode(base64Part));
      final data = jsonDecode(decoded) as Map<String, dynamic>;

      if (!data.containsKey('id') || !data.containsKey('name')) {
        throw Exception('Token missing required fields');
      }

      setState(() {
        _decodedData = data;
        _isDecoding = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isDecoding = false;
      });
    }
  }

  Future<void> _sendConnectionRequest() async {
    if (_decodedData == null) return;

    setState(() {
      _isConnecting = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Please log in to connect');
      }

      final targetUserId = _decodedData!['id'].toString();
      final targetName = _decodedData!['name'].toString();
      final targetAccountType = _decodedData!['account_type'].toString();

      // Determine factoryId and sellerId based on account types
      final currentUserType = await _getCurrentUserType();

      String factoryId;
      String sellerId;

      if (targetAccountType == 'factory') {
        factoryId = targetUserId;
        sellerId = currentUser.id;
      } else if (targetAccountType == 'seller') {
        factoryId = currentUser.id;
        sellerId = targetUserId;
      } else {
        throw Exception(
          'Connection only supported between factory and seller',
        );
      }

      // Check not connecting to self
      if (factoryId == sellerId) {
        throw Exception('Cannot connect to yourself');
      }

      // Check if connection already exists
      final existing = await _connectionService.getMyConnections(
        userId: currentUser.id,
      );

      final alreadyExists = existing.any(
        (conn) =>
            conn.factoryId == factoryId && conn.sellerId == sellerId ||
            conn.factoryId == sellerId && conn.sellerId == factoryId,
      );

      if (alreadyExists) {
        throw Exception('Connection already exists');
      }

      // Send connection request
      final connection = await _connectionService.requestConnection(
        factoryId: factoryId,
        sellerId: sellerId,
        notes: 'Connection request via token from $targetName',
      );

      if (connection == null) {
        throw Exception('Failed to send connection request');
      }

      // Send notification to the other user
      await _connectionService.sendConnectionNotification(
        toUserId: targetUserId,
        fromUserId: currentUser.id,
        connectionId: connection.id,
        fromUserName: _decodedData!['name'] ?? 'Unknown',
        accountType: currentUserType,
      );

      setState(() {
        _successMessage =
            'Connection request sent to $targetName successfully!';
        _isConnecting = false;
        _tokenController.clear();
        _decodedData = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isConnecting = false;
      });
    }
  }

  Future<String> _getCurrentUserType() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return 'unknown';

      final response = await Supabase.instance.client
          .from('users')
          .select('account_type')
          .eq('user_id', userId)
          .single();

      return response['account_type'] ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect via Token')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.link, size: 80, color: Color(0xFF6366F1)),
            const SizedBox(height: 24),
            Text(
              'Connect with Another User',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Paste the token shared by the other user',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _tokenController,
              decoration: InputDecoration(
                labelText: 'Paste Token Here',
                hintText: 'aurora_xxx_...',
                prefixIcon: const Icon(Icons.token),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _tokenController.clear();
                    setState(() {
                      _decodedData = null;
                      _error = null;
                      _successMessage = null;
                    });
                  },
                ),
              ),
              maxLines: 3,
              onSubmitted: (_) => _decodeToken(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isDecoding ? null : _decodeToken,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isDecoding
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Decode Token'),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_successMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_decodedData != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Preview',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Name', _decodedData!['name'] ?? 'Unknown'),
                      _buildInfoRow('ID', _decodedData!['id'] ?? 'Unknown'),
                      _buildInfoRow(
                        'Account Type',
                        _decodedData!['account_type'] ?? 'Unknown',
                      ),
                      if (_decodedData!.containsKey('timestamp')) ...[
                        _buildInfoRow(
                          'Timestamp',
                          DateTime.fromMillisecondsSinceEpoch(
                            _decodedData!['timestamp'],
                          ).toString(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _isConnecting ? null : _sendConnectionRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),
                          child: _isConnecting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Connect'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
