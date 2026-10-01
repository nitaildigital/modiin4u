import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/month_names.dart';
import '../providers/municipal_links.dart';
import '../providers/shabbat_providers.dart';
import '../widgets/shabbat_widgets.dart';
import 'web_municipal_screen.dart';
import '../providers/parking_providers.dart';

/// Municipal – responsive wrapper.
class MunicipalScreen extends StatelessWidget {
  const MunicipalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) return const WebMunicipalContent();
        return const _MobileMunicipalContent();
      },
    );
  }
}

/// Municipal screen – city services hub with quick-info cards
/// (Shabbat & Parking) and a 3×3 service category grid.
class _MobileMunicipalContent extends StatelessWidget {
  const _MobileMunicipalContent();

  // ── Service grid items ──
  /// Eight of these nine have no destination yet, and tapping them did
  /// nothing at all — no screen, no message. They are shown greyed with
  /// "coming soon" until the client tells us what each should contain, so a
  /// resident can see which ones are ready rather than tapping dead tiles.
  static List<_Service> _servicesFor(L l) => [
    // Icons are the Figma "Municipal" frame's (643:6301).
    _Service(l.svcParking, 'assets/icons/m_municipal_parking.svg', '/parking'),
    _Service(l.svcShabbat, 'assets/icons/m_municipal_shabbat.svg', '/shabbat'),
    _Service(
      l.svcInstitutions,
      'assets/icons/m_municipal_institutions.svg',
      '/municipal/institutions',
    ),
    _Service(l.svcHealth, 'assets/icons/m_municipal_health.svg', '/municipal/health'),
    _Service(l.svcEducation, 'assets/icons/m_municipal_education.svg', '/municipal/education'),
    _Service(l.svcTransport, 'assets/icons/m_municipal_transport.svg', '/municipal/transport'),
    _Service(l.svcEmergency, 'assets/icons/m_municipal_emergency.svg', '/municipal/emergency'),
    _Service(l.svcParks, 'assets/icons/m_municipal_parks.svg', '/parks'),
    _Service(l.svcForms, 'assets/icons/m_municipal_forms.svg', kMunicipalFormsUrl),
  ];

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            children: [
              const SizedBox(height: 13),

              // ═══════════════════════════════════
              // Title
              // ═══════════════════════════════════
              Text(
                l.municipal,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),

              // ═══════════════════════════════════
              // Search bar
              // ═══════════════════════════════════
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE7E7E7)),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        IconsaxPlusLinear.search_normal_1,
                        size: 18,
                        color: Color(0xFF6D6D6D),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.searchMunicipal,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6D6D6D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ═══════════════════════════════════
              // Scrollable content
              // ═══════════════════════════════════
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Quick Info ──
                      Text(
                        l.quickInfo,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F1F1F),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Quick Info cards
                      const IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _ShabbatCard()),
                            SizedBox(width: 12),
                            Expanded(child: _ParkingCard()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ── Municipal Services ──
                      Text(
                        l.municipalServices,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F1F1F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.exploreServices,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6D6D6D),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Service grid 3×3
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              mainAxisExtent: 120,
                            ),
                        children: _servicesFor(
                          l,
                        ).map((s) => _ServiceCard(service: s)).toList(),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Data model
// ═══════════════════════════════════════════════
class _Service {
  final String label;

  /// An SVG under assets/icons.
  final String icon;
  final String? route;
  const _Service(this.label, this.icon, this.route);
}

// ═══════════════════════════════════════════════
// Shabbat quick-info card (warm orange theme)
// ═══════════════════════════════════════════════
class _ShabbatCard extends ConsumerWidget {
  /// The Friday and Saturday of the coming weekend. See the note on the
  /// screen's own copy: the card used to print one fixed date for everyone.
  static (DateTime friday, DateTime saturday) _upcomingShabbat() {
    final now = DateTime.now();
    final daysToFriday = (DateTime.friday - now.weekday + 7) % 7;
    final friday = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: now.weekday == DateTime.saturday ? -1 : daysToFriday));
    return (friday, friday.add(const Duration(days: 1)));
  }

  const _ShabbatCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final week = ref.watch(shabbatWeekProvider).valueOrNull;
    return GestureDetector(
      onTap: () => context.push('/shabbat'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF8EF),
          border: Border.all(
            color: const Color(0xFFD68200).withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top section with border-bottom
            Container(
              padding: const EdgeInsets.only(bottom: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/m_municipal_shabbat_circle.svg',
                    width: 48,
                    height: 48,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _TwoLineTitle(l.upcomingShabbat)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Date: Hebcal's once it has answered, the coming weekend's
            // until then.
            Text(
              week != null
                  ? shabbatDates(l, week)
                  : () {
                      final (fri, sat) = _upcomingShabbat();
                      return '${fri.day} ${l.monthShort(fri.month)}'
                          '–${sat.day} ${l.monthShort(sat.month)} ${sat.year}';
                    }(),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF0A1230),
              ),
            ),
            // Candle lighting and Havdalah, as the website's card has them.
            // They come from Hebcal for Modi'in; a fixed "Starts 18:42" stood
            // here once, for every week of the year. Until the times arrive,
            // or if they cannot be fetched, the rows are left out rather than
            // guessed.
            if (week?.candles != null) ...[
              const SizedBox(height: 8),
              ShabbatTimeRow(
                icon: IconsaxPlusLinear.clock,
                label: l.candleLighting,
                time: week!.candles!,
                fontSize: 12,
              ),
            ],
            if (week?.havdalah != null) ...[
              const SizedBox(height: 6),
              ShabbatTimeRow(
                icon: IconsaxPlusLinear.moon,
                label: l.havdalahLabel,
                time: week!.havdalah!,
                fontSize: 12,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Parking quick-info card (light blue theme)
// ═══════════════════════════════════════════════
/// A way into the parking screen, with what is true about the car parks.
///
/// The frame's card reads "Parking Right Now — Modiin Center — High
/// availability". Nothing measures how full a car park is, so availability
/// is never claimed. Its two lines carry what the data does know: with the
/// person's location, the nearest car park and how far it is (and free, if
/// it is); without it, how many car parks the city has and how many are
/// free. While the car parks load, or if there are none, the lower half
/// stays empty.
class _ParkingCard extends ConsumerWidget {
  const _ParkingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final english = Localizations.localeOf(context).languageCode == 'en';
    final lots = ref.watch(parkingLotsProvider).valueOrNull ?? const [];
    final nearest = ref.watch(nearestParkingProvider).valueOrNull;
    final freeCount = lots.where((p) => p.isFree == true).length;
    final style = TextStyle(
      fontFamily: AppFonts.inter,
      fontSize: 12,
      color: const Color(0xFF0A1230),
    );
    Widget line(IconData icon, String text) => Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF17A9D0)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
    final List<Widget> details;
    if (nearest != null) {
      final km = (nearest.metres / 1000).toStringAsFixed(1);
      final name = english && (nearest.lot.nameEn ?? '').isNotEmpty
          ? nearest.lot.nameEn!
          : nearest.lot.name;
      details = [
        line(IconsaxPlusLinear.location, name),
        const SizedBox(height: 6),
        line(
          IconsaxPlusLinear.routing_2,
          '$km ${l.kmUnit}${nearest.lot.isFree == true ? ' · ${l.free}' : ''}',
        ),
      ];
    } else if (lots.isNotEmpty) {
      details = [
        line(IconsaxPlusLinear.car, l.parkingLotCount(lots.length)),
        if (freeCount > 0) ...[
          const SizedBox(height: 6),
          line(IconsaxPlusLinear.tick_circle, l.parkingFreeCount(freeCount)),
        ],
      ];
    } else {
      details = const [];
    }
    return GestureDetector(
      onTap: () => context.push('/parking'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7FD),
          border: Border.all(color: const Color(0xFFD9E8F4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/m_municipal_parking_circle.svg',
                    width: 48,
                    height: 48,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _TwoLineTitle(l.parkingInModiin)),
                  const Icon(
                    IconsaxPlusLinear.arrow_left_2,
                    size: 16,
                    color: Color(0xFF0A1230),
                  ),
                ],
              ),
            ),
            if (details.isNotEmpty) ...[const SizedBox(height: 12), ...details],
          ],
        ),
      ),
    );
  }
}

/// A card's title as the frame sets it: the first word in Inter Regular 14,
/// the rest under it in Semi Bold.
class _TwoLineTitle extends StatelessWidget {
  final String text;
  const _TwoLineTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final space = text.indexOf(' ');
    final first = space < 0 ? text : text.substring(0, space);
    final rest = space < 0 ? '' : text.substring(space + 1);
    final style = TextStyle(
      fontFamily: AppFonts.inter,
      fontSize: 14,
      height: 1.4,
      color: const Color(0xFF0A1230),
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: first),
          if (rest.isNotEmpty)
            TextSpan(
              text: '\n$rest',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
        ],
      ),
      style: style,
    );
  }
}

// ═══════════════════════════════════════════════
// Service grid card (115×120)
// ═══════════════════════════════════════════════
class _ServiceCard extends StatelessWidget {
  final _Service service;

  bool get ready => service.route != null;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // A web address opens outside the app (Forms: the municipality's page).
      onTap: switch (service.route) {
        null => null,
        final r when r.startsWith('http') => () => openMunicipalLink(r),
        final r => () => context.push(r),
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE7E7E7)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              service.icon,
              width: 32,
              height: 32,
              // A tile with nowhere to go is shown greyed, so it reads as
              // not ready rather than as broken.
              colorFilter: ready
                  ? null
                  : const ColorFilter.mode(Color(0xFFB4BAC6), BlendMode.srcIn),
            ),
            const SizedBox(height: 9),
            // Scaled down rather than broken mid-word: "Transportation" is
            // wider than the tile in English.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                service.label,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: ready
                      ? const Color(0xFF0A1230)
                      : const Color(0xFF9AA1AE),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (!ready) ...[
              const SizedBox(height: 4),
              Text(
                L.of(context).comingSoon,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 10,
                  color: const Color(0xFF9AA1AE),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
