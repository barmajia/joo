import 'package:flutter/material.dart';
import 'package:aurora/gen_l10n/app_localizations.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.privacyPolicy),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                Icons.privacy_tip_outlined,
                size: 60,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Privacy Policy',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Last updated: May 2026',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: '1. Introduction',
              content:
                  'Welcome to Aurora. This Privacy Policy explains how we collect, '
                  'use, disclose, and safeguard your information when you use our '
                  'mobile application and services.',
            ),
            _buildSection(
              context,
              title: '2. Information We Collect',
              content:
                  'We collect information that you provide directly to us, including:\n\n'
                  '• Account information (name, email, phone number)\n'
                  '• Business profile information\n'
                  '• Product and inventory data\n'
                  '• Customer and transaction data\n'
                  '• Communication data when you contact us',
            ),
            _buildSection(
              context,
              title: '3. How We Use Your Information',
              content:
                  'We use the information we collect to:\n\n'
                  '• Provide, maintain, and improve our services\n'
                  '• Process transactions and send related information\n'
                  '• Send you technical notices, updates, and support messages\n'
                  '• Respond to your comments, questions, and requests\n'
                  '• Communicate with you about products, services, and events',
            ),
            _buildSection(
              context,
              title: '4. Data Storage and Security',
              content:
                  'Your data is stored securely using Supabase (PostgreSQL) and '
                  'local encrypted storage. We implement appropriate technical and '
                  'organizational measures to protect your personal data against '
                  'unauthorized access, alteration, disclosure, or destruction.',
            ),
            _buildSection(
              context,
              title: '5. Data Sharing',
              content:
                  'We do not sell your personal information. We may share your '
                  'information with:\n\n'
                  '• Service providers who assist in our operations\n'
                  '• Business partners with your consent\n'
                  '• Legal authorities when required by law',
            ),
            _buildSection(
              context,
              title: '6. Your Rights',
              content:
                  'You have the right to:\n\n'
                  '• Access your personal data\n'
                  '• Correct inaccurate data\n'
                  '• Request deletion of your data\n'
                  '• Object to processing\n'
                  '• Export your data in a portable format',
            ),
            _buildSection(
              context,
              title: '7. Cookies and Tracking',
              content:
                  'We use local storage to maintain your session and preferences. '
                  'We do not use third-party tracking cookies in our mobile application.',
            ),
            _buildSection(
              context,
              title: '8. Children\'s Privacy',
              content:
                  'Our services are not intended for children under 13. We do not '
                  'knowingly collect personal information from children under 13.',
            ),
            _buildSection(
              context,
              title: '9. Changes to This Policy',
              content:
                  'We may update this Privacy Policy from time to time. We will '
                  'notify you of any changes by posting the new policy on this page '
                  'and updating the "Last updated" date.',
            ),
            _buildSection(
              context,
              title: '10. Contact Us',
              content:
                  'If you have any questions about this Privacy Policy, please '
                  'contact us at: privacy@aurora.app',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}