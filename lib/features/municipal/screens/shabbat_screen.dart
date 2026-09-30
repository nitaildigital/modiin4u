import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../providers/shabbat_providers.dart';
import '../widgets/shabbat_widgets.dart';
import 'web_shabbat_screen.dart';

/// Shabbat & Holidays, at /shabbat — where the Municipal page's "Shabbat &
/// Holidays" tile leads. It led nowhere.
///
/// The coming Shabbat with its parasha or holiday and both times, then the
/// holidays of the next three months, all from Hebcal for Modi'in. Figma has
/// the tile but no page, so this is built from the Municipal card's own
/// look.
class ShabbatScreen extends ConsumerWidget {
  const ShabbatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) return const WebShabbatContent();
        return _buildMobile(context, ref);
      },
    );
  }

  Widget _buildMobile(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final hebrew = Localizations.localeOf(context).languageCode == 'he';
    final week = ref.watch(shabbatWeekProvider);
    final holidays = ref.watch(upcomingHolidaysProvider);

    Widget failed(VoidCallback retry) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            l.shabbatLoadError,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: MAccountColors.value,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: retry, child: Text(l.tryAgain)),
        ],
      ),
    );

    const loading = Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(child: CircularProgressIndicator()),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      const MBackArrow(color: Color(0xFF3D3D3D)),
                      Expanded(
                        child: Center(
                          child: Text(
                            l.shabbatAndHolidaysTitle,
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
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(shabbatWeekProvider);
                      ref.invalidate(upcomingHolidaysProvider);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        MediaQuery.paddingOf(context).bottom + 24,
                      ),
                      children: [
                        week.when(
                          loading: () => loading,
                          error: (_, _) =>
                              failed(() => ref.invalidate(shabbatWeekProvider)),
                          data: (w) =>
                              ShabbatWeekPanel(week: w, l: l, hebrew: hebrew),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          l.upcomingHolidays,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        holidays.when(
                          loading: () => loading,
                          error: (_, _) => failed(
                            () => ref.invalidate(upcomingHolidaysProvider),
                          ),
                          data: (days) =>
                              HolidayList(days: days, l: l, hebrew: hebrew),
                        ),
                        const SizedBox(height: 24),
                        HebcalCredit(l: l),
                      ],
                    ),
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
