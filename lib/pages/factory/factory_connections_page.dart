import 'package:flutter/material.dart';
import 'package:aurora/gen_l10n/app_localizations.dart';
import 'package:aurora/models/customers/customermodel.dart';

class FactoryConnectionsPage extends StatefulWidget {
  const FactoryConnectionsPage({super.key});

  @override
  State<FactoryConnectionsPage> createState() => _FactoryConnectionsPageState();
}

class _FactoryConnectionsPageState extends State<FactoryConnectionsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<_Factory> _connectedFactories = [];
  final List<_Factory> _nearbyFactories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFactories();
  }

  Future<void> _loadFactories() async {
    // Simulate loading - in real app, fetch from API
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Factory Connections'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(
              icon: Icon(Icons.handshake),
              text: 'Connected',
            ),
            const Tab(
              icon: Icon(Icons.near_me),
              text: 'Nearby',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildConnectedFactories(),
                _buildNearbyFactories(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showConnectFactoryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Connect Factory'),
      ),
    );
  }

  Widget _buildConnectedFactories() {
    if (_connectedFactories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.factory, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No connected factories',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect with factories to import products',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _connectedFactories.length,
      itemBuilder: (context, index) {
        final factory = _connectedFactories[index];
        return _buildFactoryCard(factory, isConnected: true);
      },
    );
  }

  Widget _buildNearbyFactories() {
    if (_nearbyFactories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.near_me, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No nearby factories found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure location permissions are enabled',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadFactories,
              icon: const Icon(Icons.refresh),
              label: const Text('Search Again'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _nearbyFactories.length,
      itemBuilder: (context, index) {
        final factory = _nearbyFactories[index];
        return _buildFactoryCard(factory, isConnected: false);
      },
    );
  }

  Widget _buildFactoryCard(_Factory factory, {required bool isConnected}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.withValues(alpha: 0.2),
                  child: const Icon(Icons.factory, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        factory.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        factory.specialization,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Connected',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  factory.distance,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.inventory_2, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${factory.productsCount} products',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showFactoryDetails(factory),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: isConnected
                      ? ElevatedButton.icon(
                          onPressed: () => _importFromFactory(factory),
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Import'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => _connectToFactory(factory),
                          icon: const Icon(Icons.link, size: 16),
                          label: const Text('Connect'),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showConnectFactoryDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.factory, color: Colors.orange),
            SizedBox(width: 8),
            Text('Connect Factory'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Scan QR Code'),
              subtitle: const Text('Scan factory\'s connection QR'),
              onTap: () {
                Navigator.pop(context);
                // Open QR scanner
              },
            ),
            ListTile(
              leading: const Icon(Icons.vpn_key),
              title: const Text('Enter Token'),
              subtitle: const Text('Enter factory profile token'),
              onTap: () {
                Navigator.pop(context);
                _showTokenInputDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.near_me),
              title: const Text('Find Nearby'),
              subtitle: const Text('Discover factories nearby'),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(1);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
        ],
      ),
    );
  }

  void _showTokenInputDialog(BuildContext context) {
    final tokenController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Factory Token'),
        content: TextField(
          controller: tokenController,
          decoration: const InputDecoration(
            labelText: 'Profile Token',
            hintText: 'Enter factory\'s share profile token',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Connect with token
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showFactoryDetails(_Factory factory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                    child: const Icon(Icons.factory, size: 30, color: Colors.orange),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          factory.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          factory.specialization,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow(Icons.location_on, 'Location', factory.distance),
              _buildDetailRow(Icons.inventory_2, 'Products', '${factory.productsCount} products available'),
              _buildDetailRow(Icons.calendar_today, 'Connected Since', factory.connectedSince),
              _buildDetailRow(Icons.security, 'Connection', 'Secure (Token-based)'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _importFromFactory(factory);
                },
                icon: const Icon(Icons.download),
                label: const Text('Import Products'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey[600])),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _importFromFactory(_Factory factory) {
    // Show import options
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.select_all),
            title: const Text('Import All Products'),
            onTap: () {
              Navigator.pop(context);
              // Import all products
            },
          ),
          ListTile(
            leading: const Icon(Icons.filter_list),
            title: const Text('Select Products'),
            onTap: () {
              Navigator.pop(context);
              // Show product selection
            },
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync New Products'),
            onTap: () {
              Navigator.pop(context);
              // Sync only new products
            },
          ),
        ],
      ),
    );
  }

  void _connectToFactory(_Factory factory) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect to Factory'),
        content: Text('Do you want to connect with ${factory.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Connect to factory
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}

class _Factory {
  final String id;
  final String name;
  final String specialization;
  final String distance;
  final int productsCount;
  final String connectedSince;

  _Factory({
    required this.id,
    required this.name,
    required this.specialization,
    required this.distance,
    required this.productsCount,
    required this.connectedSince,
  });
}