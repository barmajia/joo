import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aurora/gen_l10n/app_localizations.dart';
import '../providers/app_settings_provider.dart';

class AppLockScreen extends StatefulWidget {
  final Widget child;
  const AppLockScreen({super.key, required this.child});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final List<TextEditingController> _pinControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isError = false;
  bool _hasChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasChecked) {
      _hasChecked = true;
      _checkLockState();
    }
  }

  Future<void> _checkLockState() async {
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);

    if (!settings.isSecurityEnabled) {
      settings.setUnlocked();
      return;
    }

    if (settings.biometricLock) {
      final success = await settings.authenticateBiometric();
      if (success) {
        settings.setUnlocked();
        return;
      }
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(
                Icons.lock_outline,
                size: 80,
                color: theme.primaryColor.withOpacity(0.8),
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
                            ? Colors.red.withOpacity(0.1)
                            : theme.colorScheme.primaryContainer.withOpacity(
                                0.3,
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _isError
                                ? Colors.red
                                : theme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _isError
                                ? Colors.red
                                : theme.primaryColor.withOpacity(0.3),
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(localizations.unlock),
                ),
              ),
              const SizedBox(height: 16),
              if (settings.biometricLock)
                TextButton.icon(
                  onPressed: () async {
                    final success = await settings.authenticateBiometric();
                    if (success && mounted) settings.setUnlocked();
                  },
                  icon: const Icon(Icons.fingerprint),
                  label: Text(localizations.useBiometric),
                ),
              const Spacer(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
