import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/web_chrome.dart';

// ═══════════════════════════════════════════════════════════
// Web Notifications — desktop
//
// Deliberately one empty state in a reading column.
//
// The schema has `admin_notifications` and nothing for residents, so there
// is no source to read and nothing to list. Six notifications were once
// written into the phone screen's source — an offer nobody had made, an
// event the reader was told they had confirmed — and they were removed. This
// page does not bring them back at a wider width, and there is no "mark all
// as read" for a list with nothing in it.
//
// The width it gains goes to the chrome: the bell in every header opens this
// page, and on a laptop it used to open a 430px column in an empty window.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF6D6D6D);
const _kHeading = Color(0xFF1C1C1E);
const _kIconGrey = Color(0xFF6D6D6D);

const _kColumnWidth = 720.0;

class WebNotificationsContent extends StatefulWidget {
  const WebNotificationsContent({super.key});

  @override
  State<WebNotificationsContent> createState() =>
      _WebNotificationsContentState();
}

class _WebNotificationsContentState extends State<WebNotificationsContent> {
  /// The phone screen is written in Hebrew only. Here the one sentence it
  /// says exists in both, so the page follows the navbar's toggle like every
  /// other web screen rather than opening in its own language.
  bool _isHebrew = false;

  String _t(String en, String he) => _isHebrew ? he : en;

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
                              Text(
                                _t('Notifications', 'התראות'),
                                style: TextStyle(
                                  fontFamily: AppFonts.nunito,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w600,
                                  color: _kHeading,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 32),
                              _buildEmptyState(),
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
        // The bell opens this page from anywhere, so back goes wherever the
        // reader came from — and to the home page if they opened the URL
        // directly and there is nothing to pop.
        onTap: () => context.canPop() ? context.pop() : context.go('/'),
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
              _t('Back', 'חזרה'),
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

  /// Said plainly, as on the phone. An empty scroll area reads as a page that
  /// failed to load, and this one has not failed — there is nothing yet.
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 32),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              IconsaxPlusLinear.notification,
              size: 32,
              color: _kIconGrey,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _t('No notifications', 'אין התראות'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _kHeading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t(
              'When there are updates for you, they will appear here.',
              'כשיהיו עדכונים עבורכם, הם יופיעו כאן.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: _kGreyText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
