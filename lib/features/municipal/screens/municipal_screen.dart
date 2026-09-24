import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/month_names.dart';
import 'web_municipal_screen.dart';

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
    _Service(l.svcParking, IconsaxPlusLinear.car, '/parking'),
    _Service(l.svcShabbat, IconsaxPlusLinear.candle, null),
    _Service(l.svcInstitutions, IconsaxPlusLinear.bank, null),
    _Service(l.svcHealth, IconsaxPlusLinear.health, null),
    _Service(l.svcEducation, IconsaxPlusLinear.book_1, null),
    _Service(l.svcTransport, IconsaxPlusLinear.bus, null),
    _Service(l.svcEmergency, IconsaxPlusLinear.danger, null),
    _Service(l.svcParks, IconsaxPlusLinear.tree, null),
    _Service(l.svcForms, IconsaxPlusLinear.document_text, null),
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
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 115 / 120,
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
  final IconData icon;
  final String? route;
  const _Service(this.label, this.icon, this.route);
}

// ═══════════════════════════════════════════════
// Shabbat quick-info card (warm orange theme)
// ═══════════════════════════════════════════════
class _ShabbatCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Container(
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
                // Icon circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD68200).withValues(alpha: 0.3),
                      width: 0.86,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      IconsaxPlusLinear.candle,
                      size: 24,
                      color: Color(0xFFD68200),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.upcomingShabbat,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      color: const Color(0xFF0A1230),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Date
          Text(
            () {
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
          // A candle-lighting time used to sit here, printed as "Starts
          // 18:42" every week of the year. It is an astronomical time that
          // moves with the date and the town, and the project has no zmanim
          // source, so the row is gone rather than guessed — the same call
          // made for the parking card above.
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Parking quick-info card (light blue theme)
// ═══════════════════════════════════════════════
/// A way into the parking screen.
///
/// It used to read "Parking Right Now — Modiin Center — High availability".
/// Nothing measures how full a car park is, so the claim is gone and the
/// card is a link.
class _ParkingCard extends StatelessWidget {
  const _ParkingCard();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return GestureDetector(
      onTap: () => context.push('/parking'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF6FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    IconsaxPlusLinear.car,
                    size: 18,
                    color: Color(0xFF0A1230),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.parkingInModiin,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      height: 1.4,
                      color: const Color(0xFF0A1230),
                    ),
                  ),
                ),
                const Icon(
                  IconsaxPlusLinear.arrow_left_2,
                  size: 16,
                  color: Color(0xFF0A1230),
                ),
              ],
            ),
          ],
        ),
      ),
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
      onTap: service.route != null ? () => context.push(service.route!) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE7E7E7)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              service.icon,
              size: 32,
              // A tile with nowhere to go is shown greyed, so it reads as
              // not ready rather than as broken.
              color: ready ? const Color(0xFF123A72) : const Color(0xFFB4BAC6),
            ),
            const SizedBox(height: 9),
            Text(
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
