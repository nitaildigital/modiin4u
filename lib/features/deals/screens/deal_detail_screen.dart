import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Deal detail screen – hero image, brand logo, business info,
/// deal info, validity/restrictions rows, more deals, bottom CTA bar.
class DealDetailScreen extends StatelessWidget {
  final String dealId;
  const DealDetailScreen({super.key, required this.dealId});

  // ── More deals from this business ──
  static const _morDeals = [
    _MoreDeal('15% Off Weekend Dinner', '15% OFF', '2d : 14h'),
    _MoreDeal(
        'Buy 1 Get 1 Free on Selected Drinks', 'BUY 1 GET 1', '3d : 6h'),
    _MoreDeal('25% Off Family Meal', '25% OFF', '3d : 6h'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                // ═══════════════════════════════════
                // Scrollable content
                // ═══════════════════════════════════
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHero(context),
                        const SizedBox(height: 50), // space for brand logo
                        _buildBusinessInfo(),
                        _buildDealInfo(),
                        _buildDealDetails(),
                        const SizedBox(height: 24),
                        _buildMoreDeals(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // ═══════════════════════════════════
                // Sticky bottom CTA bar
                // ═══════════════════════════════════
                _buildBottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Hero image (260px) with back/heart buttons + brand logo
  // ═══════════════════════════════════════════════
  Widget _buildHero(BuildContext context) {
    return SizedBox(
      height: 310, // 260 hero + space for overlapping logo
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Hero image
          Container(
            width: double.infinity,
            height: 260,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF0058B5), Color(0xFF010A36)],
              ),
            ),
            child: Stack(
              children: [
                // Dark overlay gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0x66000000),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Placeholder icon
                Center(
                  child: Icon(
                    IconsaxPlusBold.discount_shape,
                    size: 60,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),

                // "Show all photos" pill (bottom-right)
                Positioned(
                  right: 12,
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(IconsaxPlusLinear.gallery,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Show all photos',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Back button
          Positioned(
            left: 12,
            top: MediaQuery.of(context).padding.top + 7,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(IconsaxPlusLinear.arrow_left,
                      size: 20, color: Color(0xFF3D3D3D)),
                ),
              ),
            ),
          ),

          // Heart button
          Positioned(
            right: 12,
            top: MediaQuery.of(context).padding.top + 7,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(IconsaxPlusLinear.heart,
                    size: 20, color: Color(0xFF3D3D3D)),
              ),
            ),
          ),

          // Brand logo (overlapping bottom-left)
          Positioned(
            left: 16,
            top: 210,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0058B5), Color(0xFF010A36)],
                ),
              ),
              child: Center(
                child: Icon(
                  IconsaxPlusBold.shop,
                  size: 36,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Business name + address
  // ═══════════════════════════════════════════════
  Widget _buildBusinessInfo() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE7E7E7)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business name
          Text(
            'Urban Plate Kitchen & Bar',
            style: GoogleFonts.rubik(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              height: 34 / 28,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          // Location row
          Row(
            children: [
              const Icon(IconsaxPlusLinear.location,
                  size: 16, color: Color(0xFF888888)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '21 Sderot El Melachot, Modi\'in Maccabim-Re\'ut',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6D6D6D),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '2.1 km away',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Deal title + description
  // ═══════════════════════════════════════════════
  Widget _buildDealInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '20% Off Your Dinner Bill',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF123A72),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enjoy 20% off your total dinner bill when dining at '
            'Urban Plate Kitchen & Bar.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: const Color(0xFF6D6D6D),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Deal details: valid until, hours, restrictions
  // ═══════════════════════════════════════════════
  Widget _buildDealDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Valid Until
          _DetailRow(
            icon: IconsaxPlusLinear.calendar_1,
            title: 'Valid Until',
            subtitle: '30 August 2026',
          ),
          const SizedBox(height: 20),

          // Valid Days & Hours
          _DetailRow(
            icon: IconsaxPlusLinear.clock,
            title: 'Valid Days & Hours',
            subtitle: 'Mon – Sun · 6:00 PM – 10:00 PM',
          ),
          const SizedBox(height: 20),

          // Restrictions
          _DetailRow(
            icon: IconsaxPlusLinear.info_circle,
            title: 'Restrictions',
            subtitle:
                'Registered residents only\nOne redemption per user\n'
                'Cannot be combined with other offers\nNot valid on public holidays',
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // "More Deals from Urban Plate Kitchen & Bar"
  // ═══════════════════════════════════════════════
  Widget _buildMoreDeals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'More Deals from Urban Plate Kitchen & Bar',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Horizontal scroll
        SizedBox(
          height: 213,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, right: 16),
            itemCount: _morDeals.length,
            itemBuilder: (_, i) {
              return Padding(
                padding: EdgeInsets.only(
                    right: i < _morDeals.length - 1 ? 12 : 0),
                child: _MoreDealCard(deal: _morDeals[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // Bottom CTA bar: Redeem Deal + Get Direction / Call Business
  // ═══════════════════════════════════════════════
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE7E7E7)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "Redeem Deal" primary button
            Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF123A72),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(IconsaxPlusLinear.scan_barcode,
                        size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Redeem Deal',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Two outline buttons
            Row(
              children: [
                // Get Direction
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFF123A72), width: 1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(IconsaxPlusLinear.routing,
                              size: 20, color: Color(0xFF123A72)),
                          const SizedBox(width: 8),
                          Text(
                            'Get Direction',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF123A72),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),

                // Call Business
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFF123A72), width: 1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(IconsaxPlusLinear.call,
                              size: 20, color: Color(0xFF123A72)),
                          const SizedBox(width: 8),
                          Text(
                            'Call Business',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF123A72),
                            ),
                          ),
                        ],
                      ),
                    ),
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
// Detail row – icon circle + title + subtitle
// ═══════════════════════════════════════════════
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon circle
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFFEEF3FB),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, size: 20, color: const Color(0xFF123A72)),
          ),
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                  color: const Color(0xFF5F5E5A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// More deal data model
// ═══════════════════════════════════════════════
class _MoreDeal {
  final String title;
  final String badge;
  final String countdown;
  const _MoreDeal(this.title, this.badge, this.countdown);
}

// ═══════════════════════════════════════════════
// More deal card (252×213, horizontal scroll)
// ═══════════════════════════════════════════════
class _MoreDealCard extends StatelessWidget {
  final _MoreDeal deal;
  const _MoreDealCard({required this.deal});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 252,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + badge
          SizedBox(
            height: 140,
            child: Stack(
              children: [
                Container(
                  width: 252,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0058B5), Color(0xFF010A36)],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      IconsaxPlusBold.discount_shape,
                      size: 32,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                // Discount badge
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFB7901),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      deal.badge,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            deal.title,
            style: GoogleFonts.rubik(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 20 / 16,
              color: const Color(0xFF0A1230),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Countdown
          Row(
            children: [
              const Icon(IconsaxPlusLinear.clock,
                  size: 14, color: Color(0xFF6D6D6D)),
              const SizedBox(width: 6),
              Text(
                deal.countdown,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Time Left',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6D6D6D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
