import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../providers/shabbat_providers.dart';
import '../widgets/shabbat_widgets.dart';
import '../../../core/router/app_router.dart' show AppNavigation;

// ═══════════════════════════════════════════════════════════
// Shabbat & Holidays — desktop
//
// Laid out like the site's information pages: navbar and footer, one
// column. The coming Shabbat, then the holidays of the next three months,
// from Hebcal for Modi'in.
// ═══════════════════════════════════════════════════════════

const _kColumnWidth = 720.0;

class WebShabbatContent extends ConsumerStatefulWidget {
  const WebShabbatContent({super.key});

  @override
  ConsumerState<WebShabbatContent> createState() => _WebShabbatContentState();
}

class _WebShabbatContentState extends ConsumerState<WebShabbatContent>
    with WebLanguageState<WebShabbatContent> {
  bool get _isHebrew => webIsHebrew.value;

  /// The navbar's toggle is this page's language, not the app's locale.
  static final _en = lookupL(const Locale('en'));
  static final _he = lookupL(const Locale('he'));
  L get _l => _isHebrew ? _he : _en;

  void _back() => context.canPop() ? context.back('/municipal') : context.go('/municipal');

  @override
  Widget build(BuildContext context) {
    final week = ref.watch(shabbatWeekProvider);
    final holidays = ref.watch(upcomingHolidaysProvider);

    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(isHebrew: _isHebrew, activeId: null),
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
                              _backLink(),
                              const SizedBox(height: 24),
                              Text(
                                _l.shabbatAndHolidaysTitle,
                                style: TextStyle(
                                  fontFamily: AppFonts.nunito,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1C1C1E),
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 32),
                              week.when(
                                loading: _loading,
                                error: (_, _) => _failed(
                                  () => ref.invalidate(shabbatWeekProvider),
                                ),
                                data: (w) => ShabbatWeekPanel(
                                  week: w,
                                  l: _l,
                                  hebrew: _isHebrew,
                                  large: true,
                                ),
                              ),
                              const SizedBox(height: 40),
                              Text(
                                _l.upcomingHolidays,
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1C1C1E),
                                ),
                              ),
                              const SizedBox(height: 12),
                              holidays.when(
                                loading: _loading,
                                error: (_, _) => _failed(
                                  () =>
                                      ref.invalidate(upcomingHolidaysProvider),
                                ),
                                data: (days) => HolidayList(
                                  days: days,
                                  l: _l,
                                  hebrew: _isHebrew,
                                  large: true,
                                ),
                              ),
                              const SizedBox(height: 32),
                              HebcalCredit(l: _l, fontSize: 14),
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

  Widget _loading() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 60),
    child: Center(child: CircularProgressIndicator()),
  );

  Widget _failed(VoidCallback retry) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _l.shabbatLoadError,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 16,
            color: const Color(0xFF6D6D6D),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: retry, child: Text(_l.tryAgain)),
      ],
    ),
  );

  Widget _backLink() {
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
              _l.sitePageBack,
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
}
