import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aurora/providers/auth_state_provider.dart';
import 'package:aurora/services/auth_check_service.dart';
import 'package:aurora/services/app_logger.dart';
import 'package:aurora/users/account_type.dart';
import 'package:aurora/pages/auth/sellers/login.dart';
import 'package:aurora/pages/auth/factories/login.dart';
import 'package:aurora/pages/auth/customers/login.dart';

class SecurityPage extends StatefulWidget {
  final String uuid;
  final AccountType accountType;

  const SecurityPage({
    super.key,
    required this.uuid,
    required this.accountType,
  });

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool _isAuthenticating = false;
  String? _errorMessage;
  String _authMethod = 'biometric';

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      AppLogger.info('Starting security authentication for ${widget.accountType}', context: 'Security');

      await Future.delayed(const Duration(milliseconds: 500));

      final authStateProvider = Provider.of<AuthStateProvider>(context, listen: false);
      
      authStateProvider.setAuthenticated(
        uuid: widget.uuid,
        accountType: widget.accountType,
      );

      AppLogger.info('Security authentication successful', context: 'Security');
      
      _navigateToHome();

    } catch (e) {
      AppLogger.error('Security authentication failed: $e', context: 'Security', error: e);
      
      setState(() {
        _errorMessage = 'Authentication failed. Please try again.';
        _isAuthenticating = false;
      });
    }
  }

  void _navigateToHome() {
    if (!mounted) return;

    String route;
    switch (widget.accountType) {
      case AccountType.seller:
        route = '/home';
        break;
      case AccountType.factory:
        route = '/home';
        break;
      case AccountType.customser:
        route = '/customer-home';
        break;
      case AccountType.middleman:
        route = '/home';
        break;
    }

    AppLogger.logNavigation('SecurityPage', route);
    
    Navigator.of(context).pushReplacementNamed(route);
  }

  void _showLoginOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Login Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Go to Login'),
              onTap: () {
                Navigator.pop(context);
                _goToLogin();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Create New Account'),
              onTap: () {
                Navigator.pop(context);
                _goToLogin();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _goToLogin() async {
    final authService = AuthCheckService();
    await authService.clearAuth();
    
    if (!mounted) return;

    Widget loginPage;
    switch (widget.accountType) {
      case AccountType.seller:
        loginPage = const LoginPage();
        break;
      case AccountType.factory:
        loginPage = const FactoryLoginPage();
        break;
      case AccountType.customser:
      case AccountType.middleman:
        loginPage = const CustomerLoginPage();
        break;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => loginPage),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fingerprint,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Security Check',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Please authenticate to continue',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_isAuthenticating)
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Verifying...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                )
              else if (_errorMessage != null)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _authenticate,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _showLoginOptions,
                      child: const Text('Use Different Account'),
                    ),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: _authenticate,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Authenticate'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Account Type: ${_getAccountTypeName(widget.accountType)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${widget.uuid.substring(0, 8)}...',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAccountTypeName(AccountType type) {
    switch (type) {
      case AccountType.seller:
        return 'Seller';
      case AccountType.factory:
        return 'Factory';
      case AccountType.customser:
        return 'Customer';
      case AccountType.middleman:
        return 'Middleman';
    }
  }
}