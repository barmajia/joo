import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../locale/locale_provider.dart';
import '../l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: Text(localizations.theme),
            subtitle: Text(_getThemeName(themeProvider.currentTheme)),
            onTap: () => _showThemeBottomSheet(context),
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.color_lens),
            title: const Text('Use Dynamic Colors (Material You)'),
            value: themeProvider.useDynamicColors,
            onChanged: (value) {
              themeProvider.toggleDynamicColors();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(localizations.language),
            subtitle: Text(_getLanguageName(localeProvider.locale, localizations)),
            onTap: () => _showLanguageBottomSheet(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {},
          ),
        ],
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

  String _getLanguageName(Locale locale, AppLocalizations localizations) {
    if (locale.languageCode == 'ar') {
      return localizations.arabic;
    }
    return localizations.english;
  }

  void _showThemeBottomSheet(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
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
}

class _ThemeBottomSheet extends StatelessWidget {
  final ThemeStyle selectedTheme;
  final Function(ThemeStyle) onSelect;

  const _ThemeBottomSheet({required this.selectedTheme, required this.onSelect});

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
          const Text(
            'Select Theme',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  const _ThemeCard({required this.theme, required this.isSelected, required this.onTap});

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
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8)]
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
              if (theme.toString().contains('light'))
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colors[2],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                  ),
                ),
              if (!theme.toString().contains('light'))
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
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
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 2,
                      ),
                    ],
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
        return [const Color(0xFFE0E7FF), const Color(0xFFC7D2FE), const Color(0xFF6366F1)];
      case ThemeStyle.elegantLight:
        return [const Color(0xFFFEF3C7), const Color(0xFFFDE68A), const Color(0xFF1E3A8A)];
      case ThemeStyle.modernDark:
        return [const Color(0xFF1E293B), const Color(0xFF334155), const Color(0xFF818CF8)];
      case ThemeStyle.elegantDark:
        return [const Color(0xFF1E293B), const Color(0xFF334155), const Color(0xFF94A3B8)];
      case ThemeStyle.amoledDark:
        return [const Color(0xFF121212), const Color(0xFF1E1E1E), const Color(0xFF00BCD4)];
      case ThemeStyle.cyberpunk:
        return [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D), const Color(0xFF00FF00)];
      case ThemeStyle.forest:
        return [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7), const Color(0xFF166534)];
      case ThemeStyle.ocean:
        return [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD), const Color(0xFF0284C7)];
      case ThemeStyle.sunset:
        return [const Color(0xFFFEF2F2), const Color(0xFFFECACA), const Color(0xFFBE123C)];
      case ThemeStyle.monochrome:
        return [const Color(0xFFF5F5F5), const Color(0xFFE5E5E5), const Color(0xFF404040)];
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
          const Text(
            'Select Language',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(localizations.english),
            trailing: currentLocale.languageCode == 'en'
                ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () => onSelect(const Locale('en', '')),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(localizations.arabic),
            trailing: currentLocale.languageCode == 'ar'
                ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () => onSelect(const Locale('ar', '')),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}