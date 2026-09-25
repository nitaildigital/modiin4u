import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/web_chrome.dart';

// ═══════════════════════════════════════════════════════════
// Web Games — the placeholder, at desktop width
//
// Games are still awaiting a product decision: which ones, what they
// score and whether there is a leaderboard are all open questions, and
// nothing in the database holds an answer. So this page stays a
// placeholder — a centred card that says so — rather than a wall of
// invented tiles. The extra width is used to keep the card centred and
// the same size it wants to be, not to stretch it.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF5F5E5A);

class WebGamesContent extends StatefulWidget {
  const WebGamesContent({super.key});

  @override
  State<WebGamesContent> createState() => _WebGamesContentState();
}

class _WebGamesContentState extends State<WebGamesContent> {
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
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPlaceholder(),
                    const SizedBox(height: 120),
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

  Widget _buildPlaceholder() {
    return Padding(
      padding: const EdgeInsets.only(top: 96),
      child: WebSection(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 56),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _kBorder),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // The one flourish on the page, in the brand gradient the
                  // rest of the site already uses.
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: Icon(
                        IconsaxPlusLinear.game,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _t('Games', 'משחקים'),
                    style: TextStyle(
                      fontFamily: AppFonts.nunito,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: AppColors.midBlue,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _t('Coming soon', 'בקרוב'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _kGreyText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _t(
                      'There is nothing to play here yet. Which games this page will carry has not been decided, so it holds no scores and no leaderboard.',
                      'עדיין אין כאן מה לשחק. טרם הוחלט אילו משחקים יופיעו בעמוד הזה, ולכן אין בו ניקוד ואין טבלת מובילים.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 15,
                      color: _kGreyText,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Somewhere to go from a page that does nothing.
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => context.go('/'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.midBlue,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          _t('Explore Modiin', 'גלו את מודיעין'),
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
