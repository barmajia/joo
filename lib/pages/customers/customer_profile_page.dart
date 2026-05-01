import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/storage/userStorage.dart';
import 'package:aurora/services/app_logger.dart';
import 'package:aurora/pages/widgets/customer_drawer.dart';
import 'package:aurora/gen_l10n/app_localizations.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    AppLogger.logPageView('CustomerProfile');
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadProfile() {
    final userStorage = Provider.of<UserStorage>(context, listen: false);
    final user = userStorage.currentUser;

    if (user != null) {
      _nameController.text = user.name ?? '';
      _emailController.text = user.email ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      AppLogger.info('Updating customer profile', context: 'CustomerProfile');

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'full_name': _nameController.text.trim(),
        });
      }

      AppLogger.info('Profile updated successfully', context: 'CustomerProfile');

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e, stack) {
      AppLogger.error('Failed to update profile', context: 'CustomerProfile', error: e, stackTrace: stack);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.profile),
        centerTitle: true,
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            )
          else
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      drawer: const CustomerDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Consumer<UserStorage>(
          builder: (context, userStorage, _) {
            final user = userStorage.currentUser;

            return Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.teal.withValues(alpha: 0.1),
                        child: Text(
                          user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: theme.colorScheme.primary,
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildProfileField(
                          label: 'Full Name',
                          controller: _nameController,
                          icon: Icons.person,
                          enabled: _isEditing,
                        ),
                        const Divider(height: 24),
                        _buildProfileField(
                          label: 'Email',
                          controller: _emailController,
                          icon: Icons.email,
                          enabled: false,
                          hint: user?.email ?? 'Not set',
                        ),
                        const Divider(height: 24),
                        _buildProfileField(
                          label: 'Phone',
                          controller: _phoneController,
                          icon: Icons.phone,
                          enabled: _isEditing,
                          hint: 'Add phone number',
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.verified_user, color: Colors.teal),
                    title: const Text('Account Status'),
                    subtitle: const Text('Verified Customer'),
                    trailing: Icon(Icons.check_circle, color: Colors.green[600]),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: const Text('Order History'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pushNamed(context, '/customer-orders'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.location_on),
                        title: const Text('Delivery Addresses'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pushNamed(context, '/customer-addresses'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.help_outline),
                        title: Text(localizations.helpSupport),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _isEditing = false);
                        _loadProfile();
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(width: 16),
        Expanded(
          child: enabled
              ? TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: hint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: keyboardType,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      controller.text.isNotEmpty || hint != null
                          ? controller.text.isNotEmpty
                              ? controller.text
                              : hint!
                          : 'Not set',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}