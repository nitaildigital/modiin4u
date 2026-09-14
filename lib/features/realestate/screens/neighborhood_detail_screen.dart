import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'web_neighborhood_detail_screen.dart';

class NeighborhoodDetailScreen extends StatelessWidget {
  final String neighborhoodId;
  const NeighborhoodDetailScreen({super.key, required this.neighborhoodId});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return WebNeighborhoodDetailContent(neighborhoodId: neighborhoodId);
        }
        return _MobileNeighborhoodDetailContent(neighborhoodId: neighborhoodId);
      },
    );
  }
}

class _MobileNeighborhoodDetailContent extends StatefulWidget {
  final String neighborhoodId;
  const _MobileNeighborhoodDetailContent({required this.neighborhoodId});

  @override
  State<_MobileNeighborhoodDetailContent> createState() =>
      _MobileNeighborhoodDetailContentState();
}

class _MobileNeighborhoodDetailContentState extends State<_MobileNeighborhoodDetailContent> {
  int _selectedThumb = 0;

  // ── Mock data ──
  static const _name = 'Moriah';
  static const _city = 'Modiin';

  static const _aboutParagraphs = [
    'Moriah is one of the southernmost neighborhoods of Modi\'in-Maccabim-Re\'ut. '
        'Formerly known as Buchman South, the neighborhood began to be populated in 2007 '
        'and is characterized primarily by private homes and semi-detached houses.',
    'The neighborhood takes its name from women from ancient Jewish history, '
        'including the four matriarchs and biblical heroines, which is also reflected '
        'in many of the street names throughout the neighborhood.',
    'Today, Moriah combines residential living with parks, recreation, education '
        'and neighborhood shopping. Its southern location also places residents close '
        'to major roads and the city\'s southern open spaces.',
  ];

  static const _stats = [
    _NeighStat('12', 'Properties for Sale', IconsaxPlusBold.home_2),
    _NeighStat('18', 'Businesses in the Area', IconsaxPlusBold.shop),
    _NeighStat('6', 'Parks & Playgrounds', IconsaxPlusBold.tree),
    _NeighStat('7', 'Schools & Kindergardens', IconsaxPlusBold.teacher),
  ];

  static final _saleListings = [
    _NListing(
      price: '₪3,650,000',
      address: '3 Yona Hanavi Street, Modiin',
      area: 140,
      rooms: 6,
      floor: 3,
      isNew: true,
      viaBroker: true,
    ),
    _NListing(
      price: '₪3,790,000',
      address: '84 Menachem Begin Road',
      area: 133,
      rooms: 4,
      floor: 2,
      isNew: true,
      viaBroker: false,
    ),
  ];

  static final _rentListings = [
    _NListing(
      price: '₪7,500',
      perMonth: '/ In the month',
      address: 'Weizmann Street Heritage Modiin',
      area: 140,
      rooms: 6,
      floor: 3,
      isNew: true,
      viaBroker: true,
      isRent: true,
    ),
    _NListing(
      price: '₪12,000',
      perMonth: '/ In the month',
      address: '12 Yitzhak Shamir Street, Modiin (Legacy)',
      area: 122,
      rooms: 4,
      floor: 2,
      isNew: false,
      viaBroker: false,
      isRent: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero image
                _buildHeroImage(),

                // 2. Thumbnails
                const SizedBox(height: 16),
                _buildThumbnailRow(),

                // 3. Neighborhood name
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Text(
                    _name,
                    style: GoogleFonts.rubik(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),

                // 4. City
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      const Icon(IconsaxPlusLinear.location,
                          size: 16, color: Color(0xFF888888)),
                      const SizedBox(width: 8),
                      Text(
                        _city,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6D6D6D),
                        ),
                      ),
                    ],
                  ),
                ),

                // 5. Stats grid (2×2)
                _buildStatsGrid(),

                // 6. About
                _buildAboutSection(),

                // 7. Apartments for Sale
                _buildListingSection(
                  'Apartments for Sale in Moriah',
                  _saleListings,
                ),

                // 8. Apartments for Rent
                _buildListingSection(
                  'Apartments for Rent in Moriah',
                  _rentListings,
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────
  // Hero image
  // ─────────────────────────────────
  Widget _buildHeroImage() {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0.0, -0.5),
                end: Alignment(0.0, 1.0),
                colors: [Color(0xFF0058B5), Color(0xFF010A36)],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(IconsaxPlusBold.buildings_2,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.15)),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Back button
          Positioned(
            left: 12,
            top: 51,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(IconsaxPlusLinear.arrow_left,
                    size: 20, color: Color(0xFF3D3D3D)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────
  // Thumbnail row
  // ─────────────────────────────────
  Widget _buildThumbnailRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(5, (i) {
          final selected = _selectedThumb == i;
          return Padding(
            padding: EdgeInsets.only(right: i < 4 ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedThumb = i),
              child: Container(
                width: 66,
                height: 44,
                decoration: BoxDecoration(
                  color: Color.lerp(const Color(0xFF0058B5),
                      const Color(0xFF010A36), i * 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: selected
                      ? Border.all(
                          color: const Color(0xFF123A72), width: 2)
                      : null,
                ),
                child: Center(
                  child: Icon(IconsaxPlusBold.image,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.3)),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────
  // Stats grid 2×2
  // ─────────────────────────────────
  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _StatCard(stat: _stats[0])),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(stat: _stats[1])),
              ],
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _StatCard(stat: _stats[2])),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(stat: _stats[3])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────
  // About section
  // ─────────────────────────────────
  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About $_name',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          ..._aboutParagraphs.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  p,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF3D3D3D),
                    height: 1.6,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ─────────────────────────────────
  // Listing section with fade + View All
  // ─────────────────────────────────
  Widget _buildListingSection(String title, List<_NListing> listings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          // Listing cards
          ...listings
              .map((l) => _ListingCard(listing: l)),

          // Fade gradient + View All
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Gradient overlay
              Container(
                height: 100,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00FFFFFF), Color(0xFFFFFFFF)],
                  ),
                ),
              ),
              // View All button
              Positioned(
                bottom: 10,
                child: GestureDetector(
                  onTap: () => context.go('/realestate'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: const Color(0xFF123A72)),
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
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Neighborhood stat data
// ═══════════════════════════════════════════════
class _NeighStat {
  final String value;
  final String label;
  final IconData icon;
  const _NeighStat(this.value, this.label, this.icon);
}

// ═══════════════════════════════════════════════
// Stat card widget
// ═══════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final _NeighStat stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stat.icon, size: 32, color: const Color(0xFF123A72)),
          const SizedBox(height: 12),
          Text(
            stat.value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            stat.label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Listing data model
// ═══════════════════════════════════════════════
class _NListing {
  final String price;
  final String? perMonth;
  final String address;
  final int area;
  final int rooms;
  final int floor;
  final bool isNew;
  final bool viaBroker;
  final bool isRent;

  const _NListing({
    required this.price,
    this.perMonth,
    required this.address,
    required this.area,
    required this.rooms,
    required this.floor,
    this.isNew = false,
    this.viaBroker = false,
    this.isRent = false,
  });
}

// ═══════════════════════════════════════════════
// Listing card widget
// ═══════════════════════════════════════════════
class _ListingCard extends StatelessWidget {
  final _NListing listing;
  const _ListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0058B5), Color(0xFF010A36)],
                    ),
                  ),
                  child: Center(
                    child: Icon(IconsaxPlusBold.home_2,
                        size: 48,
                        color:
                            Colors.white.withValues(alpha: 0.15)),
                  ),
                ),
                // Heart
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle),
                    child: const Icon(IconsaxPlusLinear.heart,
                        size: 20, color: Color(0xFF123A72)),
                  ),
                ),
                // Badges
                if (listing.viaBroker)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCD6EE),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text('Via Broker',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0033AC))),
                    ),
                  ),
                if (listing.isNew)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF17A9D0),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text('New',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          listing.price,
                          style: GoogleFonts.rubik(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0A1230),
                          ),
                        ),
                        if (listing.perMonth != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            listing.perMonth!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF5F5E5A),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      listing.isRent ? 'FOR RENT' : 'FOR SALE',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF17A9D0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Address
                Row(
                  children: [
                    const Icon(IconsaxPlusBold.location,
                        size: 16, color: Color(0xFF17A9D0)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        listing.address,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF5F5E5A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Area / Rooms / Floor
                Row(
                  children: [
                    _chip(IconsaxPlusLinear.maximize_3,
                        '${listing.area} m²'),
                    const SizedBox(width: 31),
                    _chip(IconsaxPlusLinear.building_3,
                        '${listing.rooms} Rooms'),
                    const SizedBox(width: 31),
                    _chip(IconsaxPlusLinear.building_4,
                        'Floor ${listing.floor}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6D6D6D)),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF3D3D3D),
          ),
        ),
      ],
    );
  }
}
