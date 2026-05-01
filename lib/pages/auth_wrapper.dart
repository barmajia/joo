import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora/providers/auth_state_provider.dart';
import 'package:aurora/services/auth_check_service.dart';
import 'package:aurora/services/app_logger.dart';
import 'package:aurora/users/account_type.dart';
import 'package:aurora/pages/security_page.dart';
import 'package:aurora/pages/customer_security_page.dart';
import 'package:aurora/pages/welcome/welcome.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authCheckService = AuthCheckService();
  bool _isChecking = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      AppLogger.info('Starting auth wrapper check', context: 'AuthWrapper');

      final result = await _authCheckService.checkAuth();

      if (!mounted) return;

      if (result.isValid) {
        AppLogger.info('Stored credentials valid, checking current session', context: 'AuthWrapper');
        
        final currentUser = Supabase.instance.client.auth.currentUser;
        
        if (currentUser != null && currentUser.id == result.uuid) {
          AppLogger.info('User session matches stored credentials', context: 'AuthWrapper');
          
          final authStateProvider = Provider.of<AuthStateProvider>(context, listen: false);
          authStateProvider.setAuthenticated(
            uuid: result.uuid!,
            accountType: result.accountType!,
            email: currentUser.email,
          );

          if (result.accountType == AccountType.customser) {
            _showCustomerSecurityPage(result.uuid!, result.accountType!);
          } else {
            _showSecurityPage(result.uuid!, result.accountType!);
          }
        } else if (currentUser != null) {
          AppLogger.info('User session exists but different UUID, checking account type', context: 'AuthWrapper');
          
          await _handleCurrentUser(currentUser);
        } else {
          AppLogger.info('No current session, need to login', context: 'AuthWrapper');
          _navigateTo('/welcome');
        }
      } else {
        AppLogger.info('No valid stored credentials', context: 'AuthWrapper');
        
        final currentUser = Supabase.instance.client.auth.currentUser;
        
        if (currentUser != null) {
          await _handleCurrentUser(currentUser);
        } else {
          _navigateTo('/welcome');
        }
      }
    } catch (e, stack) {
      AppLogger.error('Auth check failed: $e', context: 'AuthWrapper', error: e, stackTrace: stack);
      
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _handleCurrentUser(dynamic currentUser) async {
    try {
      final accountType = await _getAccountTypeFromProfile(currentUser.id);
      
      if (accountType != null) {
        final authStateProvider = Provider.of<AuthStateProvider>(context, listen: false);
        
        await _authCheckService.saveAuth(
          uuid: currentUser.id,
          accountType: accountType,
        );
        
        authStateProvider.setAuthenticated(
          uuid: currentUser.id,
          accountType: accountType,
          email: currentUser.email,
        );

        if (accountType == AccountType.customser) {
          _navigateTo('/customer-home');
        } else {
          _showSecurityPage(currentUser.id, accountType);
        }
      } else {
        await _authCheckService.clearAuth();
        _navigateTo('/welcome');
      }
    } catch (e) {
      AppLogger.error('Failed to handle current user: $e', context: 'AuthWrapper', error: e);
      _navigateTo('/welcome');
    }
  }

  Future<AccountType?> _getAccountTypeFromProfile(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('accountType')
          .eq('id', userId)
          .single();
      
      final accountTypeStr = response['accountType'] as String?;
      
      if (accountTypeStr == null) return null;
      
      switch (accountTypeStr.toLowerCase()) {
        case 'seller':
          return AccountType.seller;
        case 'factory':
          return AccountType.factory;
        case 'customer':
        case 'customser':
          return AccountType.customser;
        case 'middleman':
          return AccountType.middleman;
        default:
          return null;
      }
    } catch (e) {
      AppLogger.error('Failed to get account type: $e', context: 'AuthWrapper', error: e);
      return null;
    }
  }

  void _showSecurityPage(String uuid, AccountType accountType) {
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SecurityPage(
          uuid: uuid,
          accountType: accountType,
        ),
      ),
    );
  }

  void _navigateTo(String route) {
    if (!mounted) return;
    
    AppLogger.logNavigation('AuthWrapper', route);
    
    Navigator.of(context).pushReplacementNamed(route);
  }

  void _showCustomerSecurityPage(String uuid, AccountType accountType) {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CustomerSecurityPage(
          uuid: uuid,
          accountType: accountType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront, size: 80, color: Color(0xFF6366F1)),
              const SizedBox(height: 24),
              const Text(
                'Aurora',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Checking authentication...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Authentication Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isChecking = true;
                      _errorMessage = null;
                    });
                    _checkAuthentication();
                  },
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _navigateTo('/welcome'),
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}