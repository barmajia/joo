import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../locale/locale_provider.dart';
import '../l10n/app_localizations.dart';
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
    Provider.of<AppSettingsProvider>(
      context,
      listen: false,
    ).setBiometricLock(value);
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
          _buildSwitchTile(
            icon: Icons.fingerprint_outlined,
            iconColor: Colors.indigo,
            title: localizations.biometricLock,
            subtitle: localizations.requireFingerprint,
            value: Provider.of<AppSettingsProvider>(context).biometricLock,
            onChanged: (v) => _toggleBiometric(context, v),
          ),
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
            subtitle: 'Aurora v1.0.0',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildSettingTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: Colors.green,
            title: localizations.privacyPolicy,
            subtitle: localizations.howWeHandleData,
            onTap: () => _showComingSoon(context, localizations.privacyPolicy),
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
