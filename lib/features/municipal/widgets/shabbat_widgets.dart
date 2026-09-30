import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/month_names.dart';
import '../providers/shabbat_providers.dart';

/// The Shabbat card's warm colours, the same on the phone and the website.
const kShabbatBg = Color(0xFFFEF8EF);
const kShabbatAccent = Color(0xFFD68200);
const _kGrey = Color(0xFF6D6D6D);
const _kText = Color(0xFF1F1F1F);

/// "2–3 Oct 2026", or "31 Oct–1 Nov 2026" across a month's end.
String shabbatDates(L l, ShabbatWeek w) {
  final f = w.friday, s = w.saturday;
  final from = f.month == s.month
      ? '${f.day}'
      : '${f.day} ${l.monthShort(f.month)}';
  return '$from–${s.day} ${l.monthShort(s.month)} ${s.year}';
}

/// What this Shabbat is: its holiday when one falls on it, else its parasha.
String? shabbatName(ShabbatWeek w, bool hebrew) {
  if (w.holidays.isNotEmpty) {
    return w.holidays.map((h) => h.of(hebrew)).join(' · ');
  }
  return w.parasha?.of(hebrew);
}

/// A clock or moon, the label, and the time in bold.
class ShabbatTimeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final double fontSize;

  const ShabbatTimeRow({
    super.key,
    required this.icon,
    required this.label,
    required this.time,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: fontSize + 2, color: _kGrey),
        const SizedBox(width: 8),
        Flexible(
          // Two lines rather than an ellipsis: "Candle lighting" does not fit
          // the phone's half-width card in English.
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: fontSize,
              color: _kGrey,
              height: 1.21,
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Digits read left to right in Hebrew too.
        Text(
          time,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: _kText,
            height: 1.21,
          ),
        ),
      ],
    );
  }
}

/// The coming Shabbat, large: dates, parasha or holiday, and both times.
class ShabbatWeekPanel extends StatelessWidget {
  final ShabbatWeek week;
  final L l;
  final bool hebrew;
  final bool large;

  const ShabbatWeekPanel({
    super.key,
    required this.week,
    required this.l,
    required this.hebrew,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = shabbatName(week, hebrew);
    final body = large ? 16.0 : 14.0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(large ? 24 : 16),
      decoration: BoxDecoration(
        color: kShabbatBg,
        border: Border.all(color: kShabbatAccent.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                IconsaxPlusLinear.candle,
                size: large ? 24 : 20,
                color: kShabbatAccent,
              ),
              const SizedBox(width: 8),
              Text(
                l.upcomingShabbat,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: large ? 20 : 16,
                  fontWeight: FontWeight.w600,
                  color: _kText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            shabbatDates(l, week),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: body,
              color: _kGrey,
            ),
          ),
          if (name != null) ...[
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: body,
                fontWeight: FontWeight.w500,
                color: kShabbatAccent,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (week.candles != null)
            ShabbatTimeRow(
              icon: IconsaxPlusLinear.clock,
              label: l.candleLighting,
              time: week.candles!,
              fontSize: body,
            ),
          if (week.candles != null && week.havdalah != null)
            const SizedBox(height: 10),
          if (week.havdalah != null)
            ShabbatTimeRow(
              icon: IconsaxPlusLinear.moon,
              label: l.havdalahLabel,
              time: week.havdalah!,
              fontSize: body,
            ),
        ],
      ),
    );
  }
}

/// The holidays of the coming months, one row a day.
class HolidayList extends StatelessWidget {
  final List<HolidayDay> days;
  final L l;
  final bool hebrew;
  final bool large;

  const HolidayList({
    super.key,
    required this.days,
    required this.l,
    required this.hebrew,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = large ? 16.0 : 14.0;
    if (days.isEmpty) {
      return Text(
        l.noUpcomingHolidays,
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: size,
          color: _kGrey,
        ),
      );
    }
    return Column(
      children: [
        for (final (i, d) in days.indexed)
          Container(
            padding: EdgeInsets.symmetric(vertical: large ? 14 : 12),
            decoration: BoxDecoration(
              border: i == days.length - 1
                  ? null
                  : const Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: large ? 110 : 84,
                  child: Text(
                    '${d.date.day} ${l.monthShort(d.date.month)}',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: size,
                      fontWeight: FontWeight.w500,
                      color: AppColors.midBlue,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    d.name.of(hebrew),
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: size,
                      color: _kText,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The credit Hebcal's licence asks for, linking to it.
class HebcalCredit extends StatelessWidget {
  final L l;
  final double fontSize;
  const HebcalCredit({super.key, required this.l, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => launchUrl(
          Uri.parse('https://www.hebcal.com'),
          mode: LaunchMode.inAppBrowserView,
        ),
        child: Text(
          l.shabbatTimesCredit,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: fontSize,
            color: _kGrey,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
