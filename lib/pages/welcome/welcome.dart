import 'package:flutter/material.dart';
import 'package:aurora/pages/auth/sellers/login.dart';
import 'package:aurora/pages/auth/factories/login.dart';
import 'package:aurora/pages/auth/customers/login.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.storefront,
                      size: 100,
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Aurora',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose your account type to continue',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 48),
                    _buildOptionButton(
                      context,
                      icon: Icons.person,
                      title: 'Customer',
                      subtitle: 'I want to buy products',
                      color: Colors.teal,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CustomerLoginPage()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Or register as a business',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    _buildOptionButton(
                      context,
                      icon: Icons.store,
                      title: 'Seller',
                      subtitle: 'I want to sell products',
                      color: const Color(0xFF6366F1),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildOptionButton(
                      context,
                      icon: Icons.factory,
                      title: 'Factory',
                      subtitle: 'I manufacture products',
                      color: Colors.orange,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FactoryLoginPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}
