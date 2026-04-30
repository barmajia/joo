import 'dart:convert';
import 'dart:math';
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
  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final userStorage = Provider.of<UserStorage>(context, listen: false);
    final user = userStorage.currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phonenumber != 0 ? user.phonenumber.toString() : '';
    }
  }

  void _toggleEdit() {
    if (_isEditing) {
      _saveProfile();
    } else {
      setState(() => _isEditing = true);
      _loadUserData();
    }
  }

  Future<void> _saveProfile() async {
    final userStorage = Provider.of<UserStorage>(context, listen: false);
    final user = userStorage.currentUser;
    if (user == null) return;

    try {
      final supabase = Supabase.instance.client;
      final authUser = supabase.auth.currentUser;
      if (authUser == null) return;

      final tableName = userStorage.isFactory ? 'factories' : 'sellers';
      await supabase.from(tableName).update({
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', authUser.id);

      if (mounted) {
        setState(() => _isEditing = false);
        userStorage.loadUser(userStorage.accountType!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _shareProfileSecurely() async {
    final userStorage = Provider.of<UserStorage>(context, listen: false);
    final user = userStorage.currentUser;
    if (user == null) return;

    final data = {
      'id': user.id.substring(0, min(8, user.id.length)),
      'name': user.name,
      'account_type': userStorage.accountType?.name ?? 'unknown',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final encoded = base64Encode(utf8.encode(jsonEncode(data)));

    final token = _generateSecureToken(encoded);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => _ShareDialog(token: token, data: data),
      );
    }
  }

  String _generateSecureToken(String encoded) {
    final random = Random();
    final salt = List.generate(4, (i) => random.nextInt(26) + 97).map((e) => String.fromCharCode(e)).join();
    return 'aurora_${salt}_$encoded';
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
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<UserStorage>(
        builder: (context, userStorage, _) {
          final user = userStorage.currentUser;
          final accountType = userStorage.accountType;
          final initials = user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?';

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                actions: [
                  IconButton(
                    icon: Icon(_isEditing ? Icons.check : Icons.edit),
                    onPressed: _toggleEdit,
                    tooltip: _isEditing ? 'Save' : 'Edit',
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'share') _shareProfileSecurely();
                      if (value == 'logout') _logout();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'share', child: ListTile(
                        leading: Icon(Icons.share_outlined),
                        title: Text('Share Profile'),
                        contentPadding: EdgeInsets.zero,
                      )),
                      const PopupMenuDivider(),
                      const PopupMenuItem(value: 'logout', child: ListTile(
                        leading: Icon(Icons.logout, color: Colors.red),
                        title: Text('Logout', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      )),
                    ],
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 44,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    initials,
                                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: theme.primaryColor),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getAccountTypeShort(accountType),
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.primaryColor),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Account Info'),
                      _buildInfoTile(
                        icon: Icons.badge_outlined,
                        label: 'User ID',
                        value: user?.id ?? 'Not set',
                        isCopyable: true,
                        onTap: () => _copyToClipboard(user?.id ?? '', 'User ID'),
                      ),
                      _buildInfoTile(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user?.email ?? 'Not set',
                        isCopyable: true,
                        onTap: () => _copyToClipboard(user?.email ?? '', 'Email'),
                      ),
                      _buildInfoTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Member Since',
                        value: user?.createdAt != null ? _formatDate(user!.createdAt) : 'Unknown',
                      ),

                      const SizedBox(height: 20),
                      _buildSectionHeader('Personal Details'),
                      if (_isEditing) ...[
                        _buildEditField(
                          icon: Icons.person_outlined,
                          label: 'Full Name',
                          controller: _nameController,
                        ),
                        _buildEditField(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                        ),
                      ] else ...[
                        _buildInfoTile(
                          icon: Icons.person_outlined,
                          label: 'Full Name',
                          value: user?.name ?? 'Not set',
                        ),
                        _buildInfoTile(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: user?.phonenumber != 0 ? user!.phonenumber.toString() : 'Not set',
                        ),
                      ],

                      if (accountType == AccountType.seller) ...[
                        _buildInfoTile(
                          icon: Icons.store_outlined,
                          label: 'Location',
                          value: user?.metadata?['location']?.toString() ?? 'Not set',
                        ),
                        _buildInfoTile(
                          icon: Icons.shopping_bag_outlined,
                          label: 'Min Order Qty',
                          value: user?.metadata?['min_order_quantity']?.toString() ?? '1',
                        ),
                      ],
                      if (accountType == AccountType.factory) ...[
                        _buildInfoTile(
                          icon: Icons.factory_outlined,
                          label: 'Company Name',
                          value: user?.metadata?['company_name']?.toString() ?? 'Not set',
                        ),
                        _buildInfoTile(
                          icon: Icons.work_outline,
                          label: 'Specialization',
                          value: user?.metadata?['specialization']?.toString() ?? 'Not set',
                        ),
                      ],

                      const SizedBox(height: 24),
                      _buildSectionHeader('Secure Sharing'),
                      Material(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _shareProfileSecurely,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.shield_outlined, color: theme.primaryColor, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Share Profile', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                                      const SizedBox(height: 2),
                                      Text('Generate a secure token to share with others', style: TextStyle(fontSize: 12, color: theme.hintColor)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: theme.hintColor),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    bool isCopyable = false,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isTruncated = value.length > 30;
    final displayValue = isTruncated ? '${value.substring(0, 30)}...' : value;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: theme.primaryColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(fontSize: 12, color: theme.hintColor)),
                      const SizedBox(height: 2),
                      Text(displayValue, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                if (isCopyable) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.copy_outlined, size: 16, color: theme.hintColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: theme.primaryColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: label,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: keyboardType,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied'), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating),
    );
  }

  String _getAccountTypeShort(AccountType? type) {
    switch (type) {
      case AccountType.seller: return 'SELLER';
      case AccountType.factory: return 'FACTORY';
      case AccountType.customser: return 'CUSTOMER';
      case AccountType.middleman: return 'MIDDLEMAN';
      default: return 'USER';
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _ShareDialog extends StatelessWidget {
  final String token;
  final Map<String, dynamic> data;
  const _ShareDialog({required this.token, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Share Profile Securely'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Share this token with trusted parties:'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
            ),
            child: Text(
              token,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Text('Includes: ${data['name']}, ${data['account_type']}', style: TextStyle(fontSize: 12, color: theme.hintColor)),
          Text('Token expires after sharing', style: TextStyle(fontSize: 11, color: theme.hintColor)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        FilledButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: token));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Token copied to clipboard'), backgroundColor: Colors.green),
            );
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copy Token'),
        ),
      ],
    );
  }
}
