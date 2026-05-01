import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/factory/models/connection_model.dart';
import 'package:aurora/factory/services/connection_service.dart';

class ConnectionsListPage extends StatefulWidget {
  const ConnectionsListPage({super.key});

  @override
  State<ConnectionsListPage> createState() => _ConnectionsListPageState();
}

class _ConnectionsListPageState extends State<ConnectionsListPage> {
  final _connectionService = ConnectionService();

  List<FactoryConnection> _connections = [];
  bool _isLoading = true;
  String? _error;
  int _selectedTab = 0; // 0=All, 1=Pending, 2=Accepted

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _error = 'Please log in to view connections';
          _isLoading = false;
        });
        return;
      }

      final connections = await _connectionService.getMyConnections(
        userId: userId,
      );

      setState(() {
        _connections = connections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<FactoryConnection> get _filteredConnections {
    switch (_selectedTab) {
      case 1:
        return _connections.where((c) => c.isPending).toList();
      case 2:
        return _connections.where((c) => c.isAccepted).toList();
      default:
        return _connections;
    }
  }

  Future<void> _handleApprove(FactoryConnection connection) async {
    try {
      await _connectionService.approveConnection(connection.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadConnections();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleReject(FactoryConnection connection) async {
    try {
      await _connectionService.rejectConnection(connection.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      _loadConnections();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleRemove(FactoryConnection connection) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Connection'),
        content: const Text('Are you sure you want to remove this connection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _connectionService.removeConnection(connection.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connection removed'),
              backgroundColor: Colors.grey,
            ),
          );
        }
        _loadConnections();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConnections,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Theme.of(context).primaryColor.withAlpha(20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('All', 0),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton('Pending', 1),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton('Accepted', 2),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadConnections,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredConnections.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedTab == 1
                                      ? 'No pending connections'
                                      : _selectedTab == 2
                                          ? 'No accepted connections'
                                          : 'No connections yet',
                                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredConnections.length,
                            itemBuilder: (context, index) {
                              final connection = _filteredConnections[index];
                              return _buildConnectionTile(connection);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedTab = index;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.grey[700],
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
          ),
        ),
      ),
      child: Text(label),
    );
  }

  Widget _buildConnectionTile(FactoryConnection connection) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final otherUserId = connection.getOtherUserId(currentUserId);
    final isPending = connection.isPending;
    final isAccepted = connection.isAccepted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAccepted
              ? Colors.green[100]
              : isPending
                  ? Colors.orange[100]
                  : Colors.grey[200],
          child: Icon(
            Icons.people,
            color: isAccepted
                ? Colors.green
                : isPending
                    ? Colors.orange
                    : Colors.grey,
          ),
        ),
        title: Text('User: ${otherUserId.substring(0, otherUserId.length.clamp(0, 8))}...'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${connection.status}'),
            Text(
              'Created: ${connection.createdAt.toString().substring(0, 10)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: isPending
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _handleApprove(connection),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _handleReject(connection),
                  ),
                ],
              )
            : isAccepted
                ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () => _handleRemove(connection),
                  )
                : null,
        isThreeLine: true,
      ),
    );
  }
}
