import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';

/// The page's name while there is no published text to take it from — the
/// same names the footer links print.
String sitePageFallbackTitle(L l, String slug) => switch (slug) {
  'accessibility' => l.sitePageAccessibilityTitle,
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
