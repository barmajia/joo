import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aurora/gen_l10n/app_localizations.dart';
import 'package:aurora/storage/userStorage.dart';
import 'package:aurora/users/account_type.dart';
import 'package:aurora/pages/chat/chat_list_page.dart';

class FixidDrawer extends StatelessWidget {
  const FixidDrawer({super.key});

  String _getAccountTypeName(AccountType? accountType, AppLocalizations localizations) {
    if (accountType == null) return localizations.unknown;
    switch (accountType) {
      case AccountType.seller:
        return localizations.seller;
      case AccountType.factory:
        return localizations.factory;
      case AccountType.customser:
        return localizations.customer;
      case AccountType.middleman:
        return localizations.middleMan;
    }
  }

  IconData _getAccountTypeIcon(AccountType? accountType) {
    switch (accountType) {
      case AccountType.seller:
        return Icons.store_rounded;
      case AccountType.factory:
        return Icons.precision_manufacturing;
      case AccountType.customser:
        return Icons.person_rounded;
      case AccountType.middleman:
        return Icons.handshake;
      default:
        return Icons.account_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Modern Header with Gradient
          Consumer<UserStorage>(
            builder: (context, userStorage, _) {
              final user = userStorage.currentUser;
              final accountType = userStorage.accountType;
              final initials = user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?';

              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Hero(
                              tag: 'drawer_avatar',
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    initials,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (user?.name.isNotEmpty == true)
                                    Text(
                                      user!.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (user?.email.isNotEmpty == true) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      user!.email,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getAccountTypeIcon(accountType),
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getAccountTypeName(accountType, localizations),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Menu Items with Sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildDrawerSectionHeader('MAIN'),
                _buildDrawerItem(
                  icon: Icons.home_rounded,
                  title: localizations.home,
                  isActive: ModalRoute.of(context)?.settings.name == '/home',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushReplacementNamed('/home');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.person_rounded,
                  title: localizations.profile,
                  isActive: ModalRoute.of(context)?.settings.name == '/profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/profile');
                  },
                ),
                const SizedBox(height: 8),
                _buildDrawerSectionHeader('BUSINESS'),
                _buildDrawerItem(
                  icon: Icons.inventory_2_rounded,
                  title: localizations.products,
                  isActive: ModalRoute.of(context)?.settings.name == '/seller_product',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/seller_product');
                  },
                ),
                Consumer<UserStorage>(
                  builder: (context, userStorage, _) {
                    if (userStorage.isSeller) {
                      return _buildDrawerItem(
                        icon: Icons.people_rounded,
                        title: localizations.customers,
                        isActive: ModalRoute.of(context)?.settings.name == '/customers',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).pushNamed('/customers');
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.analytics_rounded,
                  title: localizations.analytics,
                  isActive: ModalRoute.of(context)?.settings.name == '/analytics',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/analytics');
                  },
                ),
                const SizedBox(height: 8),
                _buildDrawerSectionHeader('COMMUNICATION'),
                _buildDrawerItem(
                  icon: Icons.chat_bubble_rounded,
                  title: 'Chats',
                  badge: '3',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/chat');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.people_rounded,
                  title: 'Connections',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/connections');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.notifications_rounded,
                  title: localizations.notifications,
                  badge: '5',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/notifications');
                  },
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                _buildDrawerItem(
                  icon: Icons.settings_rounded,
                  title: localizations.settings,
                  isActive: ModalRoute.of(context)?.settings.name == '/settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/settings');
                  },
                ),
              ],
            ),
          ),

          // Logout Button
          Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Material(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => _handleLogout(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, color: Colors.red[600], size: 22),
                            const SizedBox(width: 12),
                            Text(
                              localizations.logout,
                              style: TextStyle(
                                color: Colors.red[600],
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SafeArea(child: SizedBox(height: 8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
    String? badge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isActive ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.blue.withValues(alpha: 0.1),
          highlightColor: Colors.blue.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.blue.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isActive ? Colors.blue[700] : Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? Colors.blue[700] : Colors.grey[800],
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isActive)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Colors.blue[700],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red[400]),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.logout),
          ],
        ),
        content: Text(AppLocalizations.of(context)!.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final userStorage = Provider.of<UserStorage>(context, listen: false);
              userStorage.logout();
              Navigator.pop(context);
              Navigator.of(context).pushReplacementNamed('/welcome');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.logout),
          ),
        ],
      ),
    );
  }
}
