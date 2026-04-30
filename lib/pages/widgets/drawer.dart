import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aurora/gen_l10n/app_localizations.dart';
import 'package:aurora/storage/userStorage.dart';
import 'package:aurora/users/account_type.dart';

class FixidDrawer extends StatelessWidget {
  const FixidDrawer({super.key});

  String _getAccountTypeName(
    AccountType? accountType,
    AppLocalizations localizations,
  ) {
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
        return Icons.store;
      case AccountType.factory:
        return Icons.precision_manufacturing;
      case AccountType.customser:
        return Icons.person;
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

    return Drawer(
      child: Column(
        children: [
          // Animated Header
          Consumer<UserStorage>(
            builder: (context, userStorage, _) {
              final user = userStorage.currentUser;
              final accountType = userStorage.accountType;
              final initials = user?.name.isNotEmpty == true
                  ? user!.name[0].toUpperCase()
                  : '?';

              return TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 32,
                    left: 20,
                    right: 20,
                    bottom: 24,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryColor,
                        theme.primaryColor.withAlpha(178),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Hero(
                            tag: 'drawer_avatar',
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white,
                              child: Text(
                                initials,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (user?.name.isNotEmpty == true) ...[
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
                                ],
                                if (user?.email.isNotEmpty == true) ...[
                                  Text(
                                    user!.email,
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(204),
                                      fontSize: 12,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getAccountTypeIcon(accountType),
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getAccountTypeName(accountType, localizations),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Menu Items
          Expanded(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(30 * (1 - value), 0),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_outlined,
                    title: localizations.home,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushReplacementNamed('/home');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    title: localizations.profile,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/profile');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.inventory_2_outlined,
                    title: localizations.products,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/seller_product');
                    },
                  ),
                  Consumer<UserStorage>(
                    builder: (context, userStorage, _) {
                      if (userStorage.isSeller) {
                        return _buildDrawerItem(
                          icon: Icons.people_outline,
                          title: localizations.customers,
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
                    icon: Icons.analytics_outlined,
                    title: localizations.analytics,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/analytics');
                    },
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    title: localizations.settings,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/settings');
                    },
                  ),
                ],
              ),
            ),
          ),

          // Logout
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: InkWell(
                onTap: () => _handleLogout(context),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red[400], size: 20),
                      const SizedBox(width: 12),
                      Text(
                        localizations.logout,
                        style: TextStyle(
                          color: Colors.red[400],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 24),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    final userStorage = Provider.of<UserStorage>(context, listen: false);
    userStorage.logout();
    Navigator.pop(context);
    Navigator.of(context).pushReplacementNamed('/welcome');
  }
}
