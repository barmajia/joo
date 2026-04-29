import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:aurora/storage/userStorage.dart';
import 'package:aurora/users/account_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userStorage = Provider.of<UserStorage>(context, listen: false);
      userStorage.loadUser(AccountType.seller);
    });
  }

  String _getAccountTypeName(AccountType? accountType) {
    if (accountType == null) return 'Unknown';
    switch (accountType) {
      case AccountType.seller:
        return 'Seller';
      case AccountType.factory:
        return 'Factory';
      case AccountType.customser:
        return 'Customer';
      case AccountType.middleman:
        return 'Middle Man';
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: Consumer<UserStorage>(
        builder: (context, userStorage, _) {
          final user = userStorage.currentUser;
          final isSeller = user?.accountType == AccountType.seller;
          final isFactory = user?.accountType == AccountType.factory;

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (user?.id.isNotEmpty == true)
                        _buildCopyableField(
                          user!.id,
                          'UUID',
                          Icons.fingerprint,
                        ),
                      const SizedBox(height: 8),
                      if (user?.name.isNotEmpty == true)
                        Text(
                          user!.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (user?.email.isNotEmpty == true)
                        _buildCopyableField(
                          user!.email,
                          'Email',
                          Icons.email,
                        ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getAccountTypeName(user?.accountType),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (isSeller) ...[
                        _buildModernInfoCard(
                          context,
                          icon: Icons.store,
                          title: 'Store Location',
                          value: user?.metadata?['location'] ?? 'Not set',
                        ),
                        _buildModernInfoCard(
                          context,
                          icon: Icons.phone,
                          title: 'Phone Number',
                          value: user?.phonenumber != 0 ? user!.phonenumber.toString() : 'Not set',
                        ),
                        _buildModernInfoCard(
                          context,
                          icon: Icons.shopping_bag,
                          title: 'Min Order Qty',
                          value: user?.metadata?['min_order_quantity']?.toString() ?? '1',
                        ),
                      ],
                      if (isFactory) ...[
                        _buildModernInfoCard(
                          context,
                          icon: Icons.factory,
                          title: 'Company Name',
                          value: user?.metadata?['company_name'] ?? 'Not set',
                        ),
                        _buildModernInfoCard(
                          context,
                          icon: Icons.location_on,
                          title: 'Location',
                          value: user?.metadata?['location'] ?? 'Not set',
                        ),
                        _buildModernInfoCard(
                          context,
                          icon: Icons.phone,
                          title: 'Phone Number',
                          value: user?.phonenumber != 0 ? user!.phonenumber.toString() : 'Not set',
                        ),
                        _buildModernInfoCard(
                          context,
                          icon: Icons.speed,
                          title: 'Production Capacity',
                          value: user?.metadata?['production_capacity']?.toString() ?? 'Not set',
                        ),
                        _buildModernInfoCard(
                          context,
                          icon: Icons.work,
                          title: 'Specialization',
                          value: user?.metadata?['specialization'] ?? 'Not set',
                        ),
                      ],
                      _buildModernInfoCard(
                        context,
                        icon: Icons.calendar_today,
                        title: 'Member Since',
                        value: user?.createdAt.toString().split(' ')[0] ?? 'Unknown',
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCopyableField(String text, String label, IconData icon) {
    return InkWell(
      onTap: () => _copyToClipboard(text, label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.copy, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}