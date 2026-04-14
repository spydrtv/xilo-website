import 'package:flutter/material.dart';
import '../theme/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          Text(
            'PRIVACY POLICY',
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            'Last updated: April 11, 2026',
            style: text.bodySmall?.copyWith(color: appColors.subtleText),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          _Section(
            number: '1',
            title: 'Introduction',
            body:
                'Welcome to XILO Music ("we," "our," or "us"). XILO Music is the official music platform for various independent and AI artists, allowing users to stream, purchase, and collect music. This Privacy Policy explains how we collect, use, and protect your information when you use our app or website.',
          ),
          _Section(
            number: '2',
            title: 'Information We Collect',
            bullets: const [
              'Email address — collected when you create an account or sign in.',
              'Display name — optionally provided by you in your profile settings.',
              'Purchase history — records of tracks and albums you have purchased.',
              'Subscription status — your current plan (free, monthly, or annual).',
              'Playlist data — playlists you create within the app.',
            ],
          ),
          _Section(
            number: '3',
            title: 'Payment Information',
            body:
                'All payments are processed securely by Stripe. XILO does not store your credit card number, billing address, or any sensitive payment details. Stripe\'s privacy policy is available at stripe.com/privacy.',
          ),
          _Section(
            number: '4',
            title: 'How We Use Your Information',
            bullets: const [
              'To provide access to your purchased music and subscription content.',
              'To manage your account and authenticate your identity.',
              'To display your library, playlists, and purchase history.',
              'To process subscription billing and renewals via Stripe.',
            ],
          ),
          _Section(
            number: '5',
            title: 'Data Sharing',
            body:
                'We do not sell, rent, or share your personal information with third parties, except as necessary to provide our services (e.g., Stripe for payment processing). We do not use your data for advertising purposes.',
          ),
          _Section(
            number: '6',
            title: 'Data Retention',
            body:
                'We retain your account data for as long as your account is active. If you wish to delete your account and associated data, please contact us at the email address below.',
          ),
          _Section(
            number: '7',
            title: 'Security',
            body:
                'We take reasonable measures to protect your information from unauthorized access, disclosure, or loss. All data is transmitted over encrypted HTTPS connections.',
          ),
          _Section(
            number: '8',
            title: 'Children\'s Privacy',
            body:
                'XILO is not directed at children under the age of 13. We do not knowingly collect personal information from children under 13. If you believe a child has provided us with their information, please contact us and we will delete it.',
          ),
          _Section(
            number: '9',
            title: 'Your Rights',
            body:
                'You may request access to, correction of, or deletion of your personal data at any time by contacting us. You may also update your display name directly in the app\'s Settings page.',
          ),
          _Section(
            number: '10',
            title: 'Changes to This Policy',
            body:
                'We may update this Privacy Policy from time to time. Any changes will be posted on this page with an updated date. Continued use of XILO after changes constitutes acceptance of the new policy.',
          ),
          _Section(
            number: '11',
            title: 'Contact Us',
            body:
                'If you have any questions about this Privacy Policy, please contact us at: info@xilostudio.com',
          ),
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String number;
  final String title;
  final String? body;
  final List<String>? bullets;

  const _Section({
    required this.number,
    required this.title,
    this.body,
    this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  number,
                  style: text.labelSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  title,
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          if (body != null)
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(
                body!,
                style: text.bodyMedium?.copyWith(
                  color: appColors.subtleText,
                  height: 1.6,
                ),
              ),
            ),
          if (bullets != null)
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: bullets!.map((bullet) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: Text(
                          bullet,
                          style: text.bodyMedium?.copyWith(
                            color: appColors.subtleText,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
