import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aurora/gen_l10n/app_localizations.dart';
import 'package:aurora/theme/theme_provider.dart';
import 'package:aurora/locale/locale_provider.dart';
import 'package:aurora/pages/widgets/customer_drawer.dart';

class CustomerSettingsPage extends StatelessWidget {
  const CustomerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settings),
        centerTitle: true,
      ),
      drawer: const CustomerDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.palette_outlined, color: Colors.purple),
              title: Text(localizations.theme),
              subtitle: Text(Provider.of<ThemeProvider>(context).currentTheme.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language, color: Colors.blue),
              title: const Text('Language'),
              subtitle: Text(Provider.of<LocaleProvider>(context).locale.languageCode == 'ar' 
                  ? localizations.arabic 
                  : localizations.english),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'About',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(localizations.appVersion),
                  subtitle: const Text('Aurora v0.1.0'),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: Colors.green),
                  title: Text(localizations.privacyPolicy),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/privacy-policy'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: Colors.blue),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/terms-of-service'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}