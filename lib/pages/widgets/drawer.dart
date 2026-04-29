import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aurora/l10n/app_localizations.dart';
import 'package:aurora/storage/storage.dart';
import 'package:aurora/storage/userStorage.dart';
import 'package:aurora/users/account_type.dart';

class FixidDrawer extends StatefulWidget {
  const FixidDrawer({super.key});

  @override
  State<FixidDrawer> createState() => _FixidDrawerState();
}

class _FixidDrawerState extends State<FixidDrawer> {
  bool _isSeller = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userStorage = Provider.of<UserStorage>(context, listen: false);
      userStorage.loadUser(AccountType.seller).then((_) {
        final user = userStorage.currentUser;
        if (mounted) {
          setState(() {
            _isSeller = user?.accountType == AccountType.seller;
          });
        }
      });
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              left: 20,
              right: 20,
              bottom: 24,
            ),
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
            child: Consumer<UserStorage>(
              builder: (context, userStorage, _) {
                final user = userStorage.currentUser;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: Text(
                        user?.name.isNotEmpty == true
                            ? user!.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (user?.id.isNotEmpty == true) ...[
                      Text(
                        'UUID',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user!.id.length > 12
                            ? '${user.id.substring(0, 12)}...'
                            : user.id,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (user?.name.isNotEmpty == true) ...[
                      Text(
                        user!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    if (user?.email.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        user!.email,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getAccountTypeName(user?.accountType),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildDrawerItem(
                  icon: Icons.home,
                  title: localizations.home,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushReplacementNamed('/home');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.person,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/profile');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.store,
                  title: 'My Shop',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.inventory_2,
                  title: 'Products',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                if (_isSeller) ...[
                  _buildDrawerItem(
                    icon: Icons.people,
                    title: 'Customers',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/customers');
                    },
                  ),
                ],
                _buildDrawerItem(
                  icon: Icons.analytics,
                  title: 'Analytics',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 8),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: localizations.settings,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/settings');
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.logout,
                  color: Colors.red[400],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red[400],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(icon, size: 22),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}