import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Deals discovery screen – turquoise gradient hero, category circles,
/// deal cards with discount badges & countdowns, brand grid.
class DealsScreen extends StatelessWidget {
  const DealsScreen({super.key});

  // ── Deal categories ──
  static const _categories = [
    _Category('Restaurants &\nNightlife', 62),
    _Category('Shopping', 48),
    _Category('Beauty &\nWellness', 31),
    _Category('Leisure &\nCulture', 19),
    _Category('Services', 19),
    _Category('Experiences', 15),
  ];

  // ── Popular deals ──
  static const _deals = [
    _Deal(
      '20% Off Your Dinner Bill',
      'Urban Plate Kitchen & Bar',
      'Hatikva Quarter',
      '20% OFF',
      '2d : 14h',
      true,
    ),
    _Deal(
      'Flat ₪300 Off on Orders Above ₪2,999',
      'Nike Store',
      'Modiin City Center',
      'FLAT ₪300 OFF',
      '3d : 05h',
      false,
    ),
    _Deal(
      'Buy 1 Get 1 Free on All Beverages',
      'mCaffeine',
      'Modiin Mall',
      'BUY 1 GET 1',
      '1d : 08h',
      true,
    ),
    _Deal(
      '20% Off Your Dinner Bill',
      'Urban Plate Kitchen & Bar',
      'Hatikva Quarter',
      '20% OFF',
      '2d : 14h',
      true,
    ),
  ];

  // ── Brand cards ──
  static const _brands = [
    _Brand('Upto 80% Off'),
    _Brand('50-90% Off'),
    _Brand('50-90% Off'),
    _Brand('50-90% Off'),
    _Brand('50-90% Off'),
    _Brand('50-90% Off'),
    _Brand('50-90% Off'),
    _Brand('50-90% Off'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Stack(
              children: [
                // ═══════════════════════════════════
                // Scrollable content
                // ═══════════════════════════════════
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero area with gradient
                      _buildHero(context),
                      const SizedBox(height: 20),

                      // Hero banner
                      _buildBanner(),
                      const SizedBox(height: 12),

                      // Page dots
                      _buildPageDots(),
                      const SizedBox(height: 16),

                      // "Explore Deals by Category"
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Explore Deals by Category',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category circles
                      _buildCategoryRow(),
                      const SizedBox(height: 24),

                      // "Popular Deals in Modiin"
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Popular Deals in Modiin',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Deal cards with fade + "View All"
                      _buildDealCards(),
                      const SizedBox(height: 24),

                      // "Most Popular Brands"
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Most Popular Brands',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Brand grid
                      _buildBrandGrid(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Hero with turquoise gradient background
  // ═══════════════════════════════════════════════
  Widget _buildHero(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Stack(
        children: [
          // Turquoise gradient wash
          Container(
            width: double.infinity,
            height: 210,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF17A9D0).withValues(alpha: 0.2),
                  const Color(0xFF17A9D0).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),

          // Back button
          Positioned(
            left: 15,
            top: 10,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: const SizedBox(
                width: 24,
                height: 24,
                child: Icon(IconsaxPlusLinear.arrow_left,
                    size: 24, color: Color(0xFF3D3D3D)),
              ),
            ),
          ),

          // "Deals" title
          Positioned(
            top: 13,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Deals',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          // Big heading
          Positioned(
            top: 57,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 54),
              child: Text(
                'Best Deals &\nOffers in Modiin',
                style: GoogleFonts.rubik(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  height: 39 / 32,
                  color: const Color(0xFF001650),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Subtitle
          Positioned(
            top: 148,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Explore local deals, discounts, and limited-time offers across Modiin.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 19 / 16,
                  color: const Color(0xFF6D6D6D),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Hero banner (361×200)
  // ═══════════════════════════════════════════════
  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0058B5), Color(0xFF010A36)],
          ),
        ),
        child: Center(
          child: Icon(
            IconsaxPlusBold.discount_shape,
            size: 48,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Page dots (3 dots, middle active)
  // ═══════════════════════════════════════════════
  Widget _buildPageDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Container(
          width: 20,
          height: 4,
          margin: EdgeInsets.only(right: i < 2 ? 3 : 0),
          decoration: BoxDecoration(
            color: i == 1
                ? const Color(0xFF123A72)
                : const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(50),
          ),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════
  // Category circles (horizontal scroll)
  // ═══════════════════════════════════════════════
  Widget _buildCategoryRow() {
    return SizedBox(
      height: 144,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 16),
        itemCount: _categories.length,
        itemBuilder: (_, i) => _CategoryCircle(category: _categories[i]),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Deal cards with fade gradient + "View All"
  // ═══════════════════════════════════════════════
  Widget _buildDealCards() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (int i = 0; i < _deals.length; i++) ...[
                _DealCard(deal: _deals[i], index: i),
                if (i < _deals.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        ),

        // Fade gradient overlay at bottom
        Positioned(
          left: 16,
          right: 16,
          bottom: 0,
          height: 222,
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00FFFFFF),
                    Color(0xFFFFFFFF),
                  ],
                ),
              ),
            ),
          ),
        ),

        // "View All" button
        Positioned(
          left: 0,
          right: 0,
          bottom: 18,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border.all(color: const Color(0xFF123A72), width: 1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Text(
                'View All',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF123A72),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // Brand grid (2×4)
  // ═══════════════════════════════════════════════
  Widget _buildBrandGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: List.generate(_brands.length, (i) {
          return _BrandCard(brand: _brands[i]);
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Data models
// ═══════════════════════════════════════════════
class _Category {
  final String name;
  final int count;
  const _Category(this.name, this.count);
}

class _Deal {
  final String title;
  final String business;
  final String location;
  final String badge;
  final String countdown;
  final bool residentsOnly;

  const _Deal(
    this.title,
    this.business,
    this.location,
    this.badge,
    this.countdown,
    this.residentsOnly,
  );
}

class _Brand {
  final String discount;
  const _Brand(this.discount);
}

// ═══════════════════════════════════════════════
// Category circle (64px avatar + name + count)
// ═══════════════════════════════════════════════
class _CategoryCircle extends StatelessWidget {
  final _Category category;
  const _CategoryCircle({required this.category});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          // Circle avatar
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0058B5), Color(0xFF010A36)],
              ),
            ),
            child: Center(
              child: Icon(
                IconsaxPlusBold.discount_shape,
                size: 24,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Name
          Text(
            category.name,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Count
          Text(
            '${category.count} Deals',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF5F5E5A),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Deal card – image + brand logo + discount badge + info + button
// ═══════════════════════════════════════════════
class _DealCard extends StatelessWidget {
  final _Deal deal;
  final int index;
  const _DealCard({required this.deal, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/deal/deal_$index'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area with brand logo + discount badge
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                // Image placeholder
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0058B5), Color(0xFF010A36)],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      IconsaxPlusBold.discount_shape,
                      size: 40,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),

                // Brand logo (bottom-left)
                Positioned(
                  left: 12,
                  top: 141,
                  child: Container(
                    width: 47,
                    height: 47,
                    padding: const EdgeInsets.all(2.3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0058B5), Color(0xFF010A36)],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          IconsaxPlusBold.shop,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),

                // Discount badge (top-left)
                Positioned(
                  left: 12,
                  top: 12,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info section
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  deal.title,
                  style: GoogleFonts.rubik(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 25 / 20,
                    color: const Color(0xFF0A1230),
                  ),
                ),
                const SizedBox(height: 8),

                // Business name
                Text(
                  deal.business,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF5F5E5A),
                  ),
                ),
                const SizedBox(height: 12),

                // Location
                Row(
                  children: [
                    const Icon(IconsaxPlusBold.location,
                        size: 16, color: Color(0xFF17A9D0)),
                    const SizedBox(width: 8),
                    Text(
                      deal.location,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF5F5E5A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Countdown + Residents Only row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Countdown
                    Row(
                      children: [
                        const Icon(IconsaxPlusLinear.clock,
                            size: 16, color: Color(0xFF123A72)),
                        const SizedBox(width: 8),
                        Text(
                          deal.countdown,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Time Left',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6D6D6D),
                          ),
                        ),
                      ],
                    ),
                    // Residents Only
                    if (deal.residentsOnly)
                      Row(
                        children: [
                          const Icon(IconsaxPlusLinear.crown_1,
                              size: 16, color: Color(0xFFFB7901)),
                          const SizedBox(width: 8),
                          Text(
                            'Residents Only',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFFB7901),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // "View Deal" button
                Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF123A72),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Center(
                    child: Text(
                      'View Deal',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Brand card (173.5×174) – pink banner + logo + rewards button
// ═══════════════════════════════════════════════
class _BrandCard extends StatelessWidget {
  final _Brand brand;
  const _BrandCard({required this.brand});

  @override
  Widget build(BuildContext context) {
    // Calculate width for 2-column grid with 12px gap
    final cardWidth =
        (MediaQuery.of(context).size.width.clamp(0, 430) - 32 - 12) / 2;

    return SizedBox(
      width: cardWidth,
      height: 174,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE7E7E7)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Pink discount banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFE6E6),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
              ),
              child: Center(
                child: Text(
                  brand.discount,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFE90052),
                  ),
                ),
              ),
            ),

            // Logo area
            Expanded(
              child: Center(
                child: Icon(
                  IconsaxPlusBold.shop,
                  size: 32,
                  color: const Color(0xFF123A72).withValues(alpha: 0.15),
                ),
              ),
            ),

            // "Upto 5% Rewards" button
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF123A72),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Center(
                  child: Text(
                    'Upto 5% Rewards',
                    style: GoogleFonts.inter(
                      fontSize: 12,
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
    );
  }
}
