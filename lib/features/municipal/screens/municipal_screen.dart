import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
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
  static final _services = [
    _Service('Parking', IconsaxPlusLinear.clock, '/parking'),
    _Service('Shabbat &\nHolidays', IconsaxPlusLinear.candle, null),
    _Service('Public\nInstitutions', IconsaxPlusLinear.bank, null),
    _Service('Health', IconsaxPlusLinear.health, null),
    _Service('Education', IconsaxPlusLinear.book_1, null),
    _Service('Transportation', IconsaxPlusLinear.bus, null),
    _Service('Emergency', IconsaxPlusLinear.danger, null),
    _Service('Parks', IconsaxPlusLinear.tree, null),
    _Service('Forms', IconsaxPlusLinear.document_text, null),
  ];

  @override
  Widget build(BuildContext context) {
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
                'Municipal',
                style: GoogleFonts.inter(
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
                          'Search municipal services...',
                          style: GoogleFonts.inter(
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
                        'Quick Info',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F1F1F),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Quick Info cards
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _ShabbatCard()),
                          SizedBox(width: 12),
                          Expanded(child: _ParkingCard()),
                        ],
                      ),
                      const SizedBox(height: 36),

                      // ── Municipal Services ──
                      Text(
                        'Municipal Services',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F1F1F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Explore services and information',
                        style: GoogleFonts.inter(
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
                        children: _services
                            .map((s) => _ServiceCard(service: s))
                            .toList(),
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
  const _ShabbatCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 141,
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
              border: Border(
                bottom: BorderSide(color: Color(0xFFE7E7E7)),
              ),
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
                    'Upcoming Shabbat',
                    style: GoogleFonts.inter(
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
          const Spacer(),

          // Date
          Text(
            'Sep 12–13, 2026',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF0A1230),
            ),
          ),
          const SizedBox(height: 12),

          // Time row
          Row(
            children: [
              const Icon(
                IconsaxPlusLinear.clock,
                size: 14,
                color: Color(0xFF6D6D6D),
              ),
              const SizedBox(width: 7),
              Text(
                'Starts 18:42',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF0A1230),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Parking quick-info card (light blue theme)
// ═══════════════════════════════════════════════
class _ParkingCard extends StatelessWidget {
  const _ParkingCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/parking'),
      child: Container(
        height: 141,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7FD),
          border: Border.all(color: const Color(0xFFD9E8F4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top section with border-bottom
            Container(
              padding: const EdgeInsets.only(bottom: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE7E7E7)),
                ),
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
                        color:
                            const Color(0xFF123A72).withValues(alpha: 0.3),
                        width: 0.86,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        IconsaxPlusLinear.clock,
                        size: 24,
                        color: Color(0xFF123A72),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Parking Right Now',
                      style: GoogleFonts.inter(
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
            const Spacer(),

            // Location
            Text(
              'Modiin Center',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF0A1230),
              ),
            ),
            const SizedBox(height: 12),

            // Availability row
            Row(
              children: [
                const Icon(
                  IconsaxPlusLinear.chart_1,
                  size: 14,
                  color: Color(0xFF0A1230),
                ),
                const SizedBox(width: 7),
                Text(
                  'High availability',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF0A1230),
                  ),
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
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: service.route != null
          ? () => context.push(service.route!)
          : null,
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
              color: const Color(0xFF123A72),
            ),
            const SizedBox(height: 9),
            Text(
              service.label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: const Color(0xFF0A1230),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
