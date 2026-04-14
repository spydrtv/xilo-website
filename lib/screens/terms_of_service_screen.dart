import 'package:flutter/material.dart';
import '../theme/theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          Text('TERMS OF SERVICE', style: text.titleLarge),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Last updated: April 11, 2026',
            style: text.bodySmall?.copyWith(color: appColors.subtleText),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          const _Section(
            number: '1',
            title: 'Acceptance of Terms',
            body:
                'By accessing or using XILO Music (the "Service"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, please do not use the Service. These Terms apply to all users of the Service, including visitors, registered users, and content creators.',
          ),
          const _Section(
            number: '2',
            title: 'Description of Service',
            body:
                'XILO Music is a music streaming and distribution platform for independent and AI-generated music. The mobile app provides streaming access to the catalog. The website additionally offers music purchases, licensing, and creator uploads. Features available to you depend on your subscription plan and the platform you are using.',
          ),
          const _Section(
            number: '3',
            title: 'User Accounts',
            bullets: [
              'You must provide accurate and complete information when creating an account.',
              'You are responsible for maintaining the confidentiality of your account credentials.',
              'You are responsible for all activity that occurs under your account.',
              'You must be at least 13 years of age to create an account.',
              'We reserve the right to suspend or terminate accounts that violate these Terms.',
            ],
          ),
          const _Section(
            number: '4',
            title: 'Subscriptions and Payments',
            body:
                'XILO Music offers free and paid subscription tiers. Paid subscriptions are billed on a monthly or annual basis. All payments are processed securely by Stripe. You authorize us to charge your payment method on a recurring basis until you cancel. You may cancel your subscription at any time; cancellation takes effect at the end of the current billing period. We do not offer refunds for partial billing periods.',
          ),
          const _Section(
            number: '5',
            title: 'Music Purchases and Licensing',
            body:
                'Music purchased or licensed through XILO Music is subject to the license terms specified at the time of purchase. Purchased tracks are for personal or licensed commercial use only, as selected. You may not redistribute, resell, or sublicense purchased content. Sync and commercial licenses grant specific rights as described in your license agreement. All rights not expressly granted are reserved by the respective rights holders.',
          ),
          const _Section(
            number: '6',
            title: 'Intellectual Property',
            body:
                'All music, artwork, logos, and content available on XILO Music are the property of their respective creators and rights holders. The XILO Music platform, branding, and interface are the property of XILO. You may not copy, reproduce, distribute, or create derivative works from any content on the platform without explicit written permission from the rights holder.',
          ),
          const _Section(
            number: '7',
            title: 'Prohibited Use',
            bullets: [
              'You may not use the Service for any unlawful purpose.',
              'You may not scrape, crawl, or systematically download content from the platform.',
              'You may not attempt to gain unauthorized access to any part of the Service.',
              'You may not transmit any harmful, offensive, or disruptive content.',
              'You may not use the Service to infringe on the intellectual property rights of others.',
              'You may not share your account credentials with others or allow concurrent unauthorized sessions.',
            ],
          ),
          const _Section(
            number: '8',
            title: 'Disclaimer of Warranties',
            body:
                'The Service is provided "as is" and "as available" without warranties of any kind, either express or implied. We do not warrant that the Service will be uninterrupted, error-free, or free of viruses or other harmful components. We do not warrant that the content available on the platform will meet your requirements or expectations.',
          ),
          const _Section(
            number: '9',
            title: 'Limitation of Liability',
            body:
                'To the fullest extent permitted by applicable law, XILO Music shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of, or inability to use, the Service. Our total liability to you for any claim arising from these Terms or the Service shall not exceed the amount you paid us in the twelve months preceding the claim.',
          ),
          const _Section(
            number: '10',
            title: 'Changes to These Terms',
            body:
                'We may update these Terms from time to time. Any material changes will be communicated via the app or email where reasonably possible. Your continued use of the Service after changes are posted constitutes your acceptance of the revised Terms. We encourage you to review these Terms periodically.',
          ),
          const _Section(
            number: '11',
            title: 'Governing Law',
            body:
                'These Terms are governed by and construed in accordance with applicable law. Any disputes arising from these Terms or the Service shall be resolved through binding arbitration or in the courts of competent jurisdiction, as applicable.',
          ),
          const _Section(
            number: '12',
            title: 'Contact Us',
            body:
                'If you have any questions about these Terms of Service, please contact us at:\ninfo@xilostudio.com',
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
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  title,
                  style: text.titleSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          if (body != null)
            Text(
              body!,
              style: text.bodyMedium?.copyWith(
                color: appColors.subtleText,
                height: 1.6,
              ),
            ),
          if (bullets != null)
            ...bullets!.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Container(
                        width: 5,
                        height: 5,
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
              ),
            ),
        ],
      ),
    );
  }
}
