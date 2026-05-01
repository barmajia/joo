import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:aurora/gen_l10n/app_localizations.dart';
import '../providers/app_settings_provider.dart';

class AppLockScreen extends StatefulWidget {
  final Widget child;
  const AppLockScreen({super.key, required this.child});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> with WidgetsBindingObserver {
  final List<TextEditingController> _pinControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isError = false;
  bool _hasChecked = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasChecked) {
      _hasChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkLockState();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _lockApp();
    } else if (state == AppLifecycleState.resumed) {
      _checkLockState();
    }
  }

  void _lockApp() {
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    if (settings.isSecurityEnabled && settings.isUnlocked) {
      settings.lockApp();
      if (mounted) setState(() {});
    }
  }

  Future<void> _checkLockState() async {
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    
    debugPrint('[AppLockScreen] isSecurityEnabled: ${settings.isSecurityEnabled}');
    debugPrint('[AppLockScreen] isUnlocked: ${settings.isUnlocked}');
    debugPrint('[AppLockScreen] biometricLock: ${settings.biometricLock}');

    if (!settings.isSecurityEnabled) {
      debugPrint('[AppLockScreen] No security enabled, unlocking...');
      settings.setUnlocked();
      return;
    }

    if (settings.isUnlocked) {
      debugPrint('[AppLockScreen] Already unlocked, returning...');
      return;
    }

    // Auto-authenticate with biometric if enabled
    if (settings.biometricLock) {
      debugPrint('[AppLockScreen] Biometric enabled, trying to authenticate...');
      // Give a small delay for the UI to be ready
      await Future.delayed(const Duration(milliseconds: 500));
      await _authenticateWithBiometric();
      return;
    }

    // If password is enabled, show the PIN entry
    debugPrint('[AppLockScreen] Showing PIN entry...');
    if (mounted) setState(() {});
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    try {
      final settings = Provider.of<AppSettingsProvider>(context, listen: false);
      final success = await settings.authenticateBiometric();
      if (success && mounted) {
        settings.setUnlocked();
        HapticFeedback.lightImpact();
      }
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  void _goToLogin(BuildContext context) async {
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    
    // Show confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go to Login'),
        content: const Text(
          'This will clear your session and return to the login page. '
          'You will need to log in again to access the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Disable security locks temporarily and clear session
    settings.setBiometricLock(false);
    settings.lockApp();
    
    // Navigate to welcome/login page
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (var c in _pinControllers) c.dispose();
    for (var n in _pinFocusNodes) n.dispose();
    super.dispose();
  }

  void _onPinChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _pinFocusNodes[index + 1].requestFocus();
    }
  }

  Future<void> _submitPin() async {
    final pin = _pinControllers.map((c) => c.text).join();
    if (pin.length < 4) return;

    setState(() {
      _isLoading = true;
      _isError = false;
    });

    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    final isValid = await settings.authenticatePassword(pin);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isError = !isValid;
      });
      if (!isValid) {
        for (var c in _pinControllers) c.clear();
        _pinFocusNodes[0].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettingsProvider>(context);
    final localizations = AppLocalizations.of(context)!;

    if (settings.isUnlocked || !settings.isSecurityEnabled) {
      return widget.child;
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 80,
                        color: theme.primaryColor.withValues(alpha: 0.8),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        localizations.enterPin,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizations.enterPinCode,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: 48,
                            child: TextField(
                              controller: _pinControllers[index],
                              focusNode: _pinFocusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              obscureText: true,
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: _isError
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : theme.colorScheme.primaryContainer
                                          .withValues(alpha: 0.3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _isError
                                        ? Colors.red
                                        : theme.primaryColor.withValues(
                                            alpha: 0.3,
                                          ),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _isError
                                        ? Colors.red
                                        : theme.primaryColor.withValues(
                                            alpha: 0.3,
                                          ),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: theme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (value) => _onPinChanged(value, index),
                            ),
                          );
                        }),
                      ),
                      if (_isError) ...[
                        const SizedBox(height: 16),
                        Text(
                          localizations.incorrectPin,
                          style: TextStyle(
                            color: Colors.red[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      // Always show biometric option if enabled
                      if (settings.biometricLock) ...[
                        Container(
                          width: double.infinity,
                          height: 56,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ElevatedButton.icon(
                            onPressed: _isAuthenticating
                                ? null
                                : _authenticateWithBiometric,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _isAuthenticating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.fingerprint, size: 24),
                            label: Text(
                              _isAuthenticating
                                  ? 'Authenticating...'
                                  : 'Unlock with Biometric',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitPin,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(localizations.unlock),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Forgot password - go back to login
                      TextButton(
                        onPressed: () => _goToLogin(context),
                        child: Text(
                          'Forgot Password? Login Again',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
