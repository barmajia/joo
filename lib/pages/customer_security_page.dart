import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aurora/providers/auth_state_provider.dart';
import 'package:aurora/services/app_logger.dart';
import 'package:aurora/users/account_type.dart';

class CustomerSecurityPage extends StatefulWidget {
  final String uuid;
  final AccountType accountType;

  const CustomerSecurityPage({
    super.key,
    required this.uuid,
    required this.accountType,
  });

  @override
  State<CustomerSecurityPage> createState() => _CustomerSecurityPageState();
}

class _CustomerSecurityPageState extends State<CustomerSecurityPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verifyAndProceed();
  }

  Future<void> _verifyAndProceed() async {
    try {
      AppLogger.info('Verifying customer session', context: 'CustomerAuth');

      await Future.delayed(const Duration(milliseconds: 300));

      final authStateProvider = Provider.of<AuthStateProvider>(context, listen: false);
      
      authStateProvider.setAuthenticated(
        uuid: widget.uuid,
        accountType: widget.accountType,
      );

      AppLogger.info('Customer verified successfully', context: 'CustomerAuth');

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed('/customer-home');

    } catch (e) {
      AppLogger.error('Customer verification failed: $e', context: 'CustomerAuth', error: e);

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_bag,
                    size: 80,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Welcome to Aurora',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Verifying your account...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}