import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../storage/userStorage.dart';
import '../../users/user_provider.dart';
import '../../theme/theme_provider.dart';
import '../auth/customer_login_page.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({Key? key}) : super(key: key);

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final user = context.read<UserProvider>().user;
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final updatedData = {
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      await apiService.updateUserProfile(userProvider.user!.id, updatedData);
      await userProvider.loadUser();

      setState(() => _isEditing = false);
      _showSuccess('Profile updated successfully');
    } catch (e) {
      _showError('Failed to update profile: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final storage = UserStorage();

        await apiService.signOut();
        await storage.clearUser();
        userProvider.clearUser();

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const CustomerLoginPage()),
            (route) => false,
          );
        }
      } catch (e) {
        _showError('Logout failed: ${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() => _isEditing = false);
                _initControllers();
              },
            ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => await userProvider.loadUser(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Profile Avatar
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.fullName ?? 'Customer',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Profile Information
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              CustomTextField(
                                controller: _fullNameController,
                                label: 'Full Name',
                                icon: Icons.person_outlined,
                                enabled: _isEditing,
                                validator: (v) => v!.isEmpty ? 'Enter your name' : null,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _emailController,
                                label: 'Email',
                                icon: Icons.email_outlined,
                                enabled: false, // Email cannot be changed
                                helperText: 'Email cannot be changed',
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _phoneController,
                                label: 'Phone Number',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                enabled: _isEditing,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      if (_isEditing)
                        CustomButton(
                          text: 'Save Changes',
                          isLoading: _isLoading,
                          onPressed: _saveProfile,
                        )
                      else
                        Column(
                          children: [
                            _buildActionTile(
                              icon: Icons.receipt_long,
                              title: 'Order History',
                              subtitle: 'View all your orders',
                              onTap: () {
                                // Navigate to orders
                                Navigator.pushNamed(context, '/customer-orders');
                              },
                            ),
                            _buildActionTile(
                              icon: Icons.location_on,
                              title: 'My Addresses',
                              subtitle: 'Manage delivery addresses',
                              onTap: () => _showComingSoon(),
                            ),
                            _buildActionTile(
                              icon: Icons.payment,
                              title: 'Payment Methods',
                              subtitle: 'Manage cards and payment options',
                              onTap: () => _showComingSoon(),
                            ),
                            _buildActionTile(
                              icon: Icons.notifications,
                              title: 'Notifications',
                              subtitle: 'Manage notification preferences',
                              onTap: () => _showComingSoon(),
                            ),
                            _buildActionTile(
                              icon: Icons.help_outline,
                              title: 'Help & Support',
                              subtitle: 'Contact us for assistance',
                              onTap: () => _showComingSoon(),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.logout, color: Colors.red),
                              title: const Text(
                                'Logout',
                                style: TextStyle(color: Colors.red),
                              ),
                              onTap: _logout,
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      
                      // App Version
                      Text(
                        'Aurora v1.0.0',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This feature is coming soon!')),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
