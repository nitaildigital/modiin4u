import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Terms & Conditions screen – "Last updated" date row, scrollable
/// legal text with 10 titled sections.
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ═══════════════════════════════════
                // Back button + title
                // ═══════════════════════════════════
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: Icon(
                            IconsaxPlusLinear.arrow_left,
                            size: 24,
                            color: Color(0xFF3D3D3D),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Terms & Conditions',
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F1F1F),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ═══════════════════════════════════
                // Last updated row
                // ═══════════════════════════════════
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Icon(
                        IconsaxPlusLinear.clock,
                        size: 16,
                        color: Color(0xFF6D6D6D),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Last updated: 22 May 2026',
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF3D3D3D),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ═══════════════════════════════════
                // Scrollable sections
                // ═══════════════════════════════════
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _sections.length,
                    itemBuilder: (context, index) {
                      final section = _sections[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.title,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0A1230),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              section.body,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Legal content sections
// ═══════════════════════════════════════════════

class _TermsSection {
  final String title;
  final String body;
  const _TermsSection(this.title, this.body);
}

const _sections = <_TermsSection>[
  _TermsSection(
    'Conditions of Use',
    'By using the Modiin4U app, you agree to be bound by these Terms & '
        'Conditions. If you do not agree with any part of these terms, you '
        'should not use the app. Modiin4U reserves the right to modify or '
        'replace these terms at any time. Your continued use of the app '
        'following any changes constitutes acceptance of those changes.',
  ),
  _TermsSection(
    'Privacy Policy',
    'Your privacy is important to us. Our Privacy Policy explains how we '
        'collect, use, and protect your personal information. By using '
        'Modiin4U, you consent to the collection and use of information as '
        'described in our Privacy Policy. We do not sell your personal data '
        'to third parties.',
  ),
  _TermsSection(
    'Intellectual Property',
    'All content, logos, graphics, and software used in the Modiin4U app '
        'are the property of Modiin4U or its licensors and are protected by '
        'intellectual property laws. You may not reproduce, distribute, or '
        'create derivative works from any content without our prior written '
        'consent.',
  ),
  _TermsSection(
    'User Account',
    'To access certain features, you may need to create an account. You '
        'are responsible for maintaining the confidentiality of your account '
        'credentials and for all activities that occur under your account. '
        'You agree to notify us immediately of any unauthorized use of your '
        'account.',
  ),
  _TermsSection(
    'User Conduct',
    'You agree to use Modiin4U only for lawful purposes. You must not '
        'post misleading, offensive, or harmful content. Harassment, spam, '
        'impersonation, and any form of abuse toward other users or '
        'businesses listed on the platform are strictly prohibited and may '
        'result in account suspension or termination.',
  ),
  _TermsSection(
    'Listings and Content',
    'Business listings, events, deals, and real estate information are '
        'provided for informational purposes only. While we strive to keep '
        'content accurate and up to date, Modiin4U does not guarantee the '
        'accuracy, completeness, or reliability of any listing or user-'
        'submitted content.',
  ),
  _TermsSection(
    'Step Counter & Challenges',
    'The step counter and related fitness challenges are for recreational '
        'purposes only. Step data is tracked locally on your device and is '
        'not intended to provide medical or health advice. Modiin4U is not '
        'liable for any health-related decisions made based on step tracking '
        'data.',
  ),
  _TermsSection(
    'Limitation of Liability',
    'Modiin4U is provided "as is" without warranties of any kind. We '
        'shall not be liable for any indirect, incidental, special, or '
        'consequential damages arising out of or in connection with the use '
        'of the app. Our total liability shall not exceed the amount you '
        'paid for the app, if any.',
  ),
  _TermsSection(
    'Changes to These Terms',
    'We may update these Terms & Conditions from time to time. When we '
        'do, we will revise the "Last updated" date at the top of this page. '
        'We encourage you to review these terms periodically to stay '
        'informed about any changes. Continued use of the app after changes '
        'are posted constitutes your acceptance of the revised terms.',
  ),
  _TermsSection(
    'Contact Us',
    'If you have any questions or concerns about these Terms & '
        'Conditions, please contact us at support@modiin4u.co.il. We will '
        'do our best to respond within 24 hours during business days '
        '(Sunday–Thursday, 9:00 AM – 5:00 PM IST).',
  ),
];
