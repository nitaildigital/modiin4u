import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/web_chrome.dart';
import 'terms_conditions_screen.dart' show kTermsSections;

// ═══════════════════════════════════════════════════════════
// Web Terms & Conditions — desktop
//
// Ten sections of legal prose. The extra width goes into type size and
// leading rather than line length: set across 1600px a paragraph is
// unreadable, so the column stays at a comfortable measure and the words
// simply get bigger than the phone could afford them.
//
// The sections themselves are the ones the phone screen shows — the same
// list, read from the one place it is written.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF6D6D6D);
const _kHeading = Color(0xFF1C1C1E);
const _kSectionTitle = Color(0xFF0A1230);

/// About 75 characters a line at 16px, which is what long prose wants.
const _kColumnWidth = 720.0;

class WebTermsConditionsContent extends StatefulWidget {
  const WebTermsConditionsContent({super.key});

  @override
  State<WebTermsConditionsContent> createState() =>
      _WebTermsConditionsContentState();
}

class _WebTermsConditionsContentState extends State<WebTermsConditionsContent> {
  bool _isHebrew = false;

  String _t(String en, String he) => _isHebrew ? he : en;

  void _back() => context.canPop() ? context.pop() : context.go('/settings');

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: null,
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 56),
                    WebSection(
                      child: Center(
                        child: SizedBox(
                          width: _kColumnWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBackLink(),
                              const SizedBox(height: 24),
                              _buildHeader(),
                              const SizedBox(height: 40),
                              _buildSections(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                    WebFooter(isHebrew: _isHebrew),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackLink() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _back,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isHebrew
                  ? IconsaxPlusLinear.arrow_right_3
                  : IconsaxPlusLinear.arrow_left,
              size: 20,
              color: AppColors.midBlue,
            ),
            const SizedBox(width: 8),
            Text(
              _t('Back to Settings', 'חזרה להגדרות'),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.midBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Terms & Conditions', 'תנאים והגבלות'),
          style: TextStyle(
            fontFamily: AppFonts.nunito,
            fontSize: 40,
            fontWeight: FontWeight.w600,
            color: _kHeading,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(IconsaxPlusLinear.clock, size: 16, color: _kGreyText),
            const SizedBox(width: 8),
            Text(
              _t('Last updated: 22 May 2026', 'עודכן לאחרונה: 22 במאי 2026'),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                color: _kGreyText,
              ),
            ),
          ],
        ),
        // The terms exist in English only, and a Hebrew reader who has just
        // switched the page over should be told that rather than left
        // wondering why the page did not change.
        if (_isHebrew) ...[
          const SizedBox(height: 12),
          Text(
            'התנאים מנוסחים באנגלית בלבד.',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: _kGreyText,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSections() {
    // The prose is English, so it is laid out left to right whichever way
    // the rest of the page runs — otherwise its punctuation lands on the
    // wrong end of every sentence.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(kTermsSections.length, (index) {
          final section = kTermsSections[index];
          final last = index == kTermsSections.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _kSectionTitle,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  section.body,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.75,
                    color: Colors.black,
                  ),
                ),
                if (!last) ...[
                  const SizedBox(height: 40),
                  const Divider(height: 1, color: _kBorder),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}
