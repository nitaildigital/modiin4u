import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/web_chrome.dart' show kContactEmail;

/// The page's name while there is no published text to take it from — the
/// same names the footer links print.
String sitePageFallbackTitle(L l, String slug) => switch (slug) {
  'accessibility' => l.sitePageAccessibilityTitle,
  'terms' => l.sitePageTermsTitle,
  'privacy' => l.privacyPolicy,
  'delete-account' => l.deleteAccount,
  _ => l.sitePageAboutTitle,
};

/// "29.9.2026" — digits and dots, which read the same way round in a Hebrew
/// line and an English one.
String sitePageDate(DateTime d) => '${d.day}.${d.month}.${d.year}';

/// What the page shows until the client has written and published it: that
/// the content is coming, and nothing in its place.
class SitePageComingSoon extends StatelessWidget {
  final String message;
  final double fontSize;

  const SitePageComingSoon({
    super.key,
    required this.message,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 1.5,
        vertical: fontSize * 2.5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Column(
        children: [
          Icon(
            IconsaxPlusLinear.document_text,
            size: fontSize * 2,
            color: const Color(0xFF6D6D6D),
          ),
          SizedBox(height: fontSize * 0.75),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: fontSize,
              height: 1.5,
              color: const Color(0xFF3D3D3D),
            ),
          ),
        ],
      ),
    );
  }
}

/// The one link on /delete-account that asks for an account to be deleted:
/// an e-mail to the office with the subject the page's own text tells people
/// to use. Google Play wants a way to ask for deletion without the app, and
/// someone who has uninstalled it can tap this rather than copy an address.
///
/// The message says which account. Signed in (the app, where the page is
/// reachable too), it carries the account's name, e-mail, phone and id, so
/// the office knows exactly which one without asking back. Signed out — the
/// website, where residents do not sign in (accounts are the app's) — it is
/// a short form with those lines to fill in, sent from the address the
/// account was made with.
///
/// Shown whether or not the client has published the page's text — the
/// request has to work before the words around it are final.
class SiteDeletionRequestButton extends ConsumerWidget {
  final bool hebrew;
  final double fontSize;

  const SiteDeletionRequestButton({
    super.key,
    required this.hebrew,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String t(String en, String he) => hebrew ? he : en;
    final me = ref.watch(authProvider);
    String line(String en, String he, String value) => '${t(en, he)}: $value';
    final body = [
      t('Please delete my Modiin4u account.', 'אבקש למחוק את החשבון שלי במודיעין בשבילך.'),
      '',
      if (me != null) ...[
        line('Name', 'שם', me.name),
        line('E-mail', 'אימייל', me.email),
        if (me.phone.trim().isNotEmpty) line('Phone', 'טלפון', me.phone),
        line('Account ID', 'מזהה חשבון', me.id),
      ] else ...[
        line('Name', 'שם', ''),
        line('E-mail I signed up with', 'האימייל שאיתו נרשמתי', ''),
        line('Phone', 'טלפון', ''),
        '',
        t('(Please send this from the e-mail address you signed up with.)',
            '(נא לשלוח מכתובת האימייל שאיתה נרשמתם.)'),
      ],
    ].join('\r\n');
    // Encoded by hand: Uri's queryParameters writes spaces as "+", which
    // some mail apps put in the subject line as they are.
    final subject = Uri.encodeComponent(t('Delete my account', 'מחיקת חשבון'));
    final mail = Uri.parse(
      'mailto:$kContactEmail?subject=$subject&body=${Uri.encodeComponent(body)}',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: fontSize * 3.125,
          child: ElevatedButton.icon(
            onPressed: () => launchUrl(mail),
            icon: Icon(IconsaxPlusLinear.trash, size: fontSize * 1.25),
            label: Text(
              t('Request account deletion', 'בקשה למחיקת חשבון'),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.midBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: fontSize * 1.75),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              elevation: 0,
            ),
          ),
        ),
        SizedBox(height: fontSize * 0.6),
        // The address under the button, for someone whose browser has no
        // mail app to open.
        SelectableText(
          t('Or write to $kContactEmail', 'או כתבו אל $kContactEmail'),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: fontSize * 0.875,
            color: const Color(0xFF6D6D6D),
          ),
        ),
      ],
    );
  }
}
