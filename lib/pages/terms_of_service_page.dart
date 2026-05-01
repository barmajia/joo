import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                Icons.description_outlined,
                size: 60,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Terms of Service',
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
              title: '1. Acceptance of Terms',
              content:
                  'By accessing and using Aurora, you accept and agree to be '
                  'bound by the terms and provisions of this agreement. If you do '
                  'not agree to these terms, please do not use our services.',
            ),
            _buildSection(
              context,
              title: '2. Description of Service',
              content:
                  'Aurora is a B2B marketplace mobile application that enables '
                  'sellers and factories to manage products, track analytics, '
                  'process orders, and communicate with business partners.',
            ),
            _buildSection(
              context,
              title: '3. User Accounts',
              content:
                  'To use Aurora, you must create an account. You are responsible '
                  'for:\n\n'
                  '• Maintaining the confidentiality of your account credentials\n'
                  '• All activities that occur under your account\n'
                  '• Providing accurate and complete information\n'
                  '• Notifying us immediately of any unauthorized access',
            ),
            _buildSection(
              context,
              title: '4. User Conduct',
              content:
                  'You agree NOT to:\n\n'
                  '• Use the service for any unlawful purpose\n'
                  '• Attempt to gain unauthorized access to any part of the service\n'
                  '• Transmit viruses, malware, or other harmful code\n'
                  '• Interfere with the proper operation of the service\n'
                  '• Impersonate any person or entity\n'
                  '• Engage in any activity that violates applicable laws',
            ),
            _buildSection(
              context,
              title: '5. Business Data',
              content:
                  'You retain ownership of all business data you upload to Aurora. '
                  'By using the service, you grant us permission to store and '
                  'process your data to provide the services you request.',
            ),
            _buildSection(
              context,
              title: '6. Intellectual Property',
              content:
                  'Aurora and its original content, features, and functionality '
                  'are owned by us and are protected by copyright, trademark, and '
                  'other intellectual property laws. You may not copy, modify, or '
                  'distribute our proprietary content without permission.',
            ),
            _buildSection(
              context,
              title: '7. Payment and Transactions',
              content:
                  'Aurora facilitates business transactions between users. We do '
                  'not process payments directly. Users are responsible for:\n\n'
                  '• Verifying the legitimacy of business partners\n'
                  '• Negotiating and agreeing on transaction terms\n'
                  '• Resolving disputes directly with other parties\n'
                  '• Complying with applicable tax and financial regulations',
            ),
            _buildSection(
              context,
              title: '8. Disclaimer of Warranties',
              content:
                  'THE SERVICE IS PROVIDED ON AN "AS IS" AND "AS AVAILABLE" BASIS. '
                  'WE MAKE NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING BUT NOT '
                  'LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR '
                  'A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.',
            ),
            _buildSection(
              context,
              title: '9. Limitation of Liability',
              content:
                  'IN NO EVENT SHALL WE BE LIABLE FOR ANY INDIRECT, INCIDENTAL, '
                  'SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING OUT OF '
                  'YOUR USE OF OR INABILITY TO USE THE SERVICE. OUR TOTAL '
                  'LIABILITY SHALL NOT EXCEED THE AMOUNT PAID BY YOU, IF ANY.',
            ),
            _buildSection(
              context,
              title: '10. Indemnification',
              content:
                  'You agree to indemnify, defend, and hold harmless Aurora and its '
                  'officers, directors, employees, and agents from any claims, '
                  'damages, liabilities, costs, or expenses arising from your '
                  'use of the service or violation of these terms.',
            ),
            _buildSection(
              context,
              title: '11. Termination',
              content:
                  'We may terminate or suspend your account and access to the '
                  'service immediately, without prior notice or liability, for '
                  'any reason, including breach of these terms. Upon termination, '
                  'your right to use the service will immediately cease.',
            ),
            _buildSection(
              context,
              title: '12. Governing Law',
              content:
                  'These Terms shall be governed by and construed in accordance '
                  'with applicable laws. Any disputes arising under these terms '
                  'shall be subject to the exclusive jurisdiction of the courts '
                  'in your jurisdiction.',
            ),
            _buildSection(
              context,
              title: '13. Changes to Terms',
              content:
                  'We reserve the right to modify these terms at any time. We will '
                  'provide notice of material changes by posting the updated terms '
                  'within the app. Your continued use after such changes constitutes '
                  'acceptance of the new terms.',
            ),
            _buildSection(
              context,
              title: '14. Contact Information',
              content:
                  'If you have any questions about these Terms of Service, please '
                  'contact us at: legal@aurora.app',
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