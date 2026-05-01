import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../locale/locale_provider.dart';
import '../gen_l10n/app_localizations.dart';
import '../storage/storage.dart';
import '../providers/app_settings_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _autoSync = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final sync = await Storage.getBool('auto_sync');
    if (mounted) setState(() => _autoSync = sync);
  }

  Future<void> _toggleAutoSync(bool value) async {
    await Storage.saveBool('auto_sync', value);
    setState(() => _autoSync = value);
  }

  Future<void> _toggleAnimations(BuildContext context, bool value) async {
    Provider.of<AppSettingsProvider>(
      context,
      listen: false,
    ).setReduceAnimations(value);
  }

  Future<void> _toggleBiometric(BuildContext context, bool value) async {
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);

    debugPrint('[Settings] _toggleBiometric called with value: $value');

    await settings.setBiometricLock(value);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Biometric lock enabled! Lock app and reopen to test.'
                : 'Biometric lock disabled',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showBiometricInfo(BuildContext context, String status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.fingerprint, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Biometric Lock'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your device does not support biometric authentication. Here are possible reasons:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.phone_android, 'Device not supported'),
            _buildInfoRow(Icons.fingerprint, 'No biometrics enrolled'),
            _buildInfoRow(Icons.lock, 'Security not configured'),
            const SizedBox(height: 16),
            Text(
              'To fix: Go to your phone Settings → Security → Set up fingerprint or face ID',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
);
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSecurityTile(BuildContext context) {
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);
    final isSecurityEnabled = settings.isSecurityEnabled;

    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSecurityEnabled
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isSecurityEnabled ? Icons.lock : Icons.lock_open,
            color: isSecurityEnabled ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          isSecurityEnabled ? 'Security Enabled' : 'Enable Security',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isSecurityEnabled
              ? 'PIN/Fingerprint active'
              : 'Set up PIN and biometric to secure app',
        ),
        trailing: Icon(
          isSecurityEnabled ? Icons.check_circle : Icons.arrow_forward_ios,
          color: isSecurityEnabled ? Colors.green : Colors.grey,
          size: 20,
        ),
        onTap: () => _showSecuritySetupDialog(context),
      ),
    );
  }

  void _showSecuritySetupDialog(BuildContext context) {
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);

    if (settings.isSecurityEnabled) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Security Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.lock_reset),
                title: const Text('Change Password'),
                onTap: () {
                  Navigator.pop(context);
                  _showPasswordSetupDialog(context, isChanging: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.fingerprint),
                title: const Text('Biometric Lock'),
                trailing: Switch(
                  value: settings.biometricLock,
                  onChanged: (v) {
                    Navigator.pop(context);
                    _toggleBiometric(context, v);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.lock_open, color: Colors.red),
                title: const Text(
                  'Disable Security',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _disableSecurity(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else {
      _showPasswordSetupDialog(context);
    }
  }

  void _showPasswordSetupDialog(
    BuildContext context, {
    bool isChanging = false,
  }) {
    String? selectedType;
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isChanging ? 'Change Password' : 'Set Up Security'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isChanging) ...[
                    const Text(
                      'Choose password type:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    RadioListTile<String>(
                      title: const Text('PIN (4-6 digits)'),
                      value: 'pin',
                      groupValue: selectedType,
                      onChanged: (v) => setState(() => selectedType = v),
                    ),
                    RadioListTile<String>(
                      title: const Text('Password'),
                      value: 'password',
                      groupValue: selectedType,
                      onChanged: (v) => setState(() => selectedType = v),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: isChanging ? 'New Password' : 'Enter Password',
                      hintText: selectedType == 'pin'
                          ? '4-6 digits'
                          : 'Enter password',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: selectedType == 'pin'
                        ? TextInputType.number
                        : TextInputType.text,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Re-enter password',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: selectedType == 'pin'
                        ? TextInputType.number
                        : TextInputType.text,
                  ),
                  const SizedBox(height: 16),
                  if (!isChanging)
                    const Text(
                      '💡 After setting password, you can also enable fingerprint lock',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedType == null && !isChanging) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select password type'),
                      ),
                    );
                    return;
                  }
                  if (passwordController.text.isEmpty ||
                      confirmController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter both passwords'),
                      ),
                    );
                    return;
                  }
                  if (passwordController.text != confirmController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passwords do not match')),
                    );
                    return;
                  }
                  if (selectedType == 'pin' &&
                      passwordController.text.length < 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PIN must be at least 4 digits'),
                      ),
                    );
                    return;
                  }

                  // Save password
                  final settings = Provider.of<AppSettingsProvider>(
                    dialogContext,
                    listen: false,
                  );
                  await settings.setAppPassword(passwordController.text);

                  Navigator.pop(dialogContext);

                  // Ask for biometric
                  _askForBiometricSetup(context);
                },
                child: Text(isChanging ? 'Save' : 'Next'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _askForBiometricSetup(BuildContext context) async {
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.fingerprint, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Enable Fingerprint?'),
          ],
        ),
        content: const Text(
          'Would you like to also enable fingerprint unlock? '
          'This will allow you to quickly unlock the app using your fingerprint.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );

if (confirm == true && context.mounted) {
      // First, try to authenticate with biometric - this will trigger the system fingerprint prompt
      // The user can then enroll their fingerprint if not already done
      final biometricSuccess = await settings.authenticateBiometric();
      
      if (!biometricSuccess) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fingerprint not set up. Please enroll in phone settings.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // If biometric auth succeeded, enable biometric lock
      await settings.setBiometricLock(true);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Security enabled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Security enabled with PIN/Password!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _disableSecurity(BuildContext context) async {
    final settings = Provider.of<AppSettingsProvider>(context, listen: false);

    // First verify identity
    final verifyPassword = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Verify Your Identity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your PIN/Password to disable security:'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'PIN/Password',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Disable'),
            ),
          ],
        );
      },
    );

    if (verifyPassword == null || verifyPassword.isEmpty) return;

    // Verify password
    final isValid = await settings.authenticatePassword(verifyPassword);
    if (!isValid) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect PIN/Password'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Now disable
    await settings.setBiometricLock(false);
    await settings.setAppPassword('');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Security disabled'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, localizations.appearance),
          _buildSettingTile(
            icon: Icons.palette_outlined,
            iconColor: Colors.purple,
            title: localizations.theme,
            subtitle: _getThemeName(
              Provider.of<ThemeProvider>(context).currentTheme,
            ),
            onTap: () => _showThemeBottomSheet(context),
          ),
          const SizedBox(height: 8),
          _buildSwitchTile(
            icon: Icons.color_lens_outlined,
            iconColor: Colors.deepPurple,
            title: localizations.dynamicColors,
            subtitle: localizations.useMaterialYou,
            value: Provider.of<ThemeProvider>(context).useDynamicColors,
            onChanged: (v) => Provider.of<ThemeProvider>(
              context,
              listen: false,
            ).toggleDynamicColors(),
          ),
          const SizedBox(height: 8),
          _buildLanguageTile(context, localizations),
          const SizedBox(height: 8),
          _buildSwitchTile(
            icon: Icons.animation_outlined,
            iconColor: Colors.teal,
            title: localizations.reduceAnimations,
            subtitle: localizations.improvePerformance,
            value: Provider.of<AppSettingsProvider>(context).reduceAnimations,
            onChanged: (v) => _toggleAnimations(context, v),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(context, localizations.syncData),
          _buildSwitchTile(
            icon: Icons.sync_outlined,
            iconColor: Colors.blue,
            title: localizations.autoSync,
            subtitle: localizations.automaticallySync,
            value: _autoSync,
            onChanged: _toggleAutoSync,
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(context, localizations.security),
          _buildSecurityTile(context),
          const SizedBox(height: 8),
          _buildSettingTile(
            icon: Icons.key_outlined,
            iconColor: Colors.redAccent,
            title: localizations.changePassword,
            subtitle: localizations.updatePassword,
            onTap: () => _showChangePasswordDialog(context),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(context, localizations.account),
          _buildSettingTile(
            icon: Icons.person_outlined,
            iconColor: theme.primaryColor,
            title: localizations.editProfile,
            subtitle: localizations.updateInformation,
            onTap: () => Navigator.of(context).pushNamed('/profile'),
          ),
          const SizedBox(height: 8),
          _buildSettingTile(
            icon: Icons.notifications_outlined,
            iconColor: Colors.amber,
            title: localizations.notifications,
            subtitle: localizations.manageNotifications,
            onTap: () => _showComingSoon(context, localizations.notifications),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(context, localizations.about),
          _buildSettingTile(
            icon: Icons.info_outline,
            iconColor: Colors.grey,
            title: localizations.appVersion,
            subtitle: 'Aurora v0.1.0',
            onTap: () => Navigator.of(context).pushNamed('/about'),
          ),
          const SizedBox(height: 8),
          _buildSettingTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: Colors.green,
            title: localizations.privacyPolicy,
            subtitle: localizations.howWeHandleData,
            onTap: () => Navigator.of(context).pushNamed('/privacy-policy'),
          ),
          const SizedBox(height: 8),
          _buildSettingTile(
            icon: Icons.description_outlined,
            iconColor: Colors.blue,
            title: 'Terms of Service',
            subtitle: 'User agreement and conditions',
            onTap: () => Navigator.of(context).pushNamed('/terms-of-service'),
          ),
          const SizedBox(height: 8),
          _buildSettingTile(
            icon: Icons.help_outline,
            iconColor: Colors.blueGrey,
            title: localizations.helpSupport,
            subtitle: localizations.getAssistance,
            onTap: () => _showComingSoon(context, localizations.helpSupport),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: isDestructive ? Colors.red : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: theme.hintColor),
                    ),
                  ],
                ),
              ),
              Icon(
                isDestructive ? Icons.warning_amber : Icons.chevron_right,
                color: isDestructive ? Colors.red : theme.hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final theme = Theme.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final langName = localeProvider.locale.languageCode == 'ar'
        ? localizations.arabic
        : localizations.english;

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _showLanguageBottomSheet(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.language_outlined,
                  color: Colors.blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Language',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      langName,
                      style: TextStyle(fontSize: 12, color: theme.hintColor),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.hintColor),
            ],
          ),
        ),
      ),
    );
  }

  String _getThemeName(ThemeStyle theme) {
    switch (theme) {
      case ThemeStyle.modernLight:
        return 'Modern Light';
      case ThemeStyle.elegantLight:
        return 'Elegant Light';
      case ThemeStyle.modernDark:
        return 'Modern Dark';
      case ThemeStyle.elegantDark:
        return 'Elegant Dark';
      case ThemeStyle.amoledDark:
        return 'AMOLED Dark';
      case ThemeStyle.cyberpunk:
        return 'Cyberpunk';
      case ThemeStyle.forest:
        return 'Forest';
      case ThemeStyle.ocean:
        return 'Ocean';
      case ThemeStyle.sunset:
        return 'Sunset';
      case ThemeStyle.monochrome:
        return 'Monochrome';
    }
  }

  void _showThemeBottomSheet(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ThemeBottomSheet(
        selectedTheme: themeProvider.currentTheme,
        onSelect: (theme) {
          themeProvider.setTheme(theme);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _LanguageBottomSheet(
        currentLocale: localeProvider.locale,
        localizations: localizations,
        onSelect: (locale) {
          localeProvider.setLocale(locale);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildCacheItem(String name, String size) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.folder_outlined, size: 16),
          const SizedBox(width: 8),
          Text(name),
          const Spacer(),
          Text(size, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.changePassword),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(labelText: localizations.newPassword),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.passwordChanged)),
                );
              }
            },
            child: Text(localizations.save),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    final localizations = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - ${localizations.comingSoon}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ThemeBottomSheet extends StatelessWidget {
  final ThemeStyle selectedTheme;
  final Function(ThemeStyle) onSelect;
  const _ThemeBottomSheet({
    required this.selectedTheme,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            localizations.selectTheme,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: ThemeStyle.values.length,
              itemBuilder: (context, index) {
                final theme = ThemeStyle.values[index];
                final isSelected = theme == selectedTheme;
                return _ThemeCard(
                  theme: theme,
                  isSelected: isSelected,
                  onTap: () => onSelect(theme),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final ThemeStyle theme;
  final bool isSelected;
  final VoidCallback onTap;
  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getThemeColors(theme);
    final name = _getThemeName(theme);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors[0], colors[1]],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: Text(
                  name,
                  style: TextStyle(
                    color: _getTextColor(theme),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Icon(
                    Icons.check_circle,
                    color: _getTextColor(theme),
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getThemeColors(ThemeStyle theme) {
    switch (theme) {
      case ThemeStyle.modernLight:
        return [
          const Color(0xFFE0E7FF),
          const Color(0xFFC7D2FE),
          const Color(0xFF6366F1),
        ];
      case ThemeStyle.elegantLight:
        return [
          const Color(0xFFFEF3C7),
          const Color(0xFFFDE68A),
          const Color(0xFF1E3A8A),
        ];
      case ThemeStyle.modernDark:
        return [
          const Color(0xFF1E293B),
          const Color(0xFF334155),
          const Color(0xFF818CF8),
        ];
      case ThemeStyle.elegantDark:
        return [
          const Color(0xFF1E293B),
          const Color(0xFF334155),
          const Color(0xFF94A3B8),
        ];
      case ThemeStyle.amoledDark:
        return [
          const Color(0xFF121212),
          const Color(0xFF1E1E1E),
          const Color(0xFF00BCD4),
        ];
      case ThemeStyle.cyberpunk:
        return [
          const Color(0xFF1A1A1A),
          const Color(0xFF2D2D2D),
          const Color(0xFF00FF00),
        ];
      case ThemeStyle.forest:
        return [
          const Color(0xFFF0FDF4),
          const Color(0xFFDCFCE7),
          const Color(0xFF166534),
        ];
      case ThemeStyle.ocean:
        return [
          const Color(0xFFE0F2FE),
          const Color(0xFFBAE6FD),
          const Color(0xFF0284C7),
        ];
      case ThemeStyle.sunset:
        return [
          const Color(0xFFFEF2F2),
          const Color(0xFFFECACA),
          const Color(0xFFBE123C),
        ];
      case ThemeStyle.monochrome:
        return [
          const Color(0xFFF5F5F5),
          const Color(0xFFE5E5E5),
          const Color(0xFF404040),
        ];
    }
  }

  String _getThemeName(ThemeStyle theme) {
    switch (theme) {
      case ThemeStyle.modernLight:
        return 'Modern Light';
      case ThemeStyle.elegantLight:
        return 'Elegant Light';
      case ThemeStyle.modernDark:
        return 'Modern Dark';
      case ThemeStyle.elegantDark:
        return 'Elegant Dark';
      case ThemeStyle.amoledDark:
        return 'AMOLED Dark';
      case ThemeStyle.cyberpunk:
        return 'Cyberpunk';
      case ThemeStyle.forest:
        return 'Forest';
      case ThemeStyle.ocean:
        return 'Ocean';
      case ThemeStyle.sunset:
        return 'Sunset';
      case ThemeStyle.monochrome:
        return 'Monochrome';
    }
  }

  Color _getTextColor(ThemeStyle theme) {
    switch (theme) {
      case ThemeStyle.modernLight:
      case ThemeStyle.elegantLight:
      case ThemeStyle.forest:
      case ThemeStyle.ocean:
      case ThemeStyle.sunset:
      case ThemeStyle.monochrome:
        return const Color(0xFF1E293B);
      default:
        return Colors.white;
    }
  }
}

class _LanguageBottomSheet extends StatelessWidget {
  final Locale currentLocale;
  final AppLocalizations localizations;
  final Function(Locale) onSelect;
  const _LanguageBottomSheet({
    required this.currentLocale,
    required this.localizations,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            localizations.selectLanguage,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(localizations.english),
            trailing: currentLocale.languageCode == 'en'
                ? Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () => onSelect(const Locale('en', '')),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(localizations.arabic),
            trailing: currentLocale.languageCode == 'ar'
                ? Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () => onSelect(const Locale('ar', '')),
          ),
        ],
      ),
    );
  }
}
