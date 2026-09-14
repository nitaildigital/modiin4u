import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'web_listing_detail_screen.dart';

class ListingDetailScreen extends StatelessWidget {
  final String listingId;
  const ListingDetailScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return WebListingDetailContent(listingId: listingId);
        }
        return _MobileListingDetailContent(listingId: listingId);
      },
    );
  }
}

class _MobileListingDetailContent extends StatefulWidget {
  final String listingId;
  const _MobileListingDetailContent({required this.listingId});

  @override
  State<_MobileListingDetailContent> createState() => _MobileListingDetailContentState();
}

class _MobileListingDetailContentState extends State<_MobileListingDetailContent> {
  int _selectedThumb = 0;
  bool _aboutExpanded = false;

  // ── Mock data ──
  static const _price = '₪3,650,000';
  static const _address = '21 Sderot El Melachot, Modi\'in Maccabim-Re\'ut';
  static const _distance = '2.1 km away';
  static const _area = 140;
  static const _bedrooms = 3;
  static const _bathrooms = 3;
  static const _agentName = 'Zeev Schumacher';
  static const _agentCompany = 'RGF Properties, Modiin';
  static const _aboutProperty =
      'New directly from the contractor, mini penthouse 6 rooms, '
      'excellent location in Avni Chen neighborhood, back apartment!! '
      'Occupancy 4 months from signing the contract, built 140 m², '
      'balcony 18 m². Payment schedule 20/80 without attachments.';

  static const _aboutNeighborhood1 =
      'Moriah is one of the southernmost neighborhoods of Modi\'in-Maccabim-Re\'ut. '
      'Formerly known as Buchman South, the neighborhood began to be populated in 2007 '
      'and is characterized primarily by private homes and semi-detached houses.';

  static const _aboutNeighborhood2 =
      'The neighborhood takes its name from women from ancient Jewish history, '
      'including the four matriarchs and biblical heroines, which is also reflected '
      'in many of the street names throughout the neighborhood. Today, Moriah combines '
      'residential living with parks, recreation, education and neighborhood shopping. '
      'Its southern location also places residents close to major roads and the city\'s '
      'southern open spaces.';

  static const _specs = [
    _Spec('Balcony', 'Yes', IconsaxPlusBold.element_3),
    _Spec('Parking', 'Yes', IconsaxPlusBold.car),
    _Spec('Elevator', 'Yes', IconsaxPlusBold.arrow_3),
    _Spec('Protected Space', 'Yes', IconsaxPlusBold.shield_tick),
  ];

  static const _nearbyListings = [
    _NearbyListing('₪3,790,000', '84 Menachem Begin Road', 133, 4, 2, true, false),
    _NearbyListing('₪5,690,000', '73 Sarah Amano Street', 145, 4, 3, false, false),
    _NearbyListing('₪3,050,000', '37 Ella Valley Street, Modiin', 145, 4, 3, false, false),
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
                // ═══════════════════════════════════
                // 1. Hero image
                // ═══════════════════════════════════
                _buildHeroImage(),

                // ═══════════════════════════════════
                // 2. Image thumbnails
                // ═══════════════════════════════════
                const SizedBox(height: 16),
                _buildThumbnailRow(),

                // ═══════════════════════════════════
                // 3. Price
                // ═══════════════════════════════════
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Text(
                    _price,
                    style: GoogleFonts.rubik(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),

                // ═══════════════════════════════════
                // 4. Address + distance
                // ═══════════════════════════════════
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      const Icon(IconsaxPlusLinear.location,
                          size: 16, color: Color(0xFF888888)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _address,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6D6D6D),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _distance,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                // ═══════════════════════════════════
                // 5. Stats row: Area / Bedrooms / Bathrooms
                // ═══════════════════════════════════
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Row(
                    children: [
                      _StatCard(
                        icon: IconsaxPlusLinear.maximize_3,
                        value: '$_area',
                        unit: 'm²',
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        icon: IconsaxPlusLinear.building_3,
                        value: '$_bedrooms',
                        unit: 'Bedrooms',
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        icon: IconsaxPlusLinear.courthouse,
                        value: '$_bathrooms',
                        unit: 'Bathrooms',
                      ),
                    ],
                  ),
                ),

                // ═══════════════════════════════════
                // 6. Agent section
                // ═══════════════════════════════════
                _buildAgentSection(),

                // ═══════════════════════════════════
                // 7. About This Property
                // ═══════════════════════════════════
                _buildSection('About This Property', _aboutProperty),

                // ═══════════════════════════════════
                // 8. Property Specifications (2×2 grid)
                // ═══════════════════════════════════
                _buildSpecsGrid(),

                // ═══════════════════════════════════
                // 9. Where You'll Be (map)
                // ═══════════════════════════════════
                _buildMapSection(),

                // ═══════════════════════════════════
                // 10. About Moriah (neighborhood)
                // ═══════════════════════════════════
                _buildNeighborhoodSection(),

                // ═══════════════════════════════════
                // 11. Properties in Moriah
                // ═══════════════════════════════════
                _buildNearbyProperties(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────
  // Hero image (260px) with gradient + nav buttons
  // ───────────────────────────────────────────────
  Widget _buildHeroImage() {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image placeholder with gradient
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
                  child: Icon(
                    IconsaxPlusBold.home_2,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                // Dark bottom gradient
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 1.0],
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

          // Back button (top-left)
          Positioned(
            left: 12,
            top: 51,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  IconsaxPlusLinear.arrow_left,
                  size: 20,
                  color: Color(0xFF3D3D3D),
                ),
              ),
            ),
          ),

          // Heart button (top-right)
          Positioned(
            right: 12,
            top: 51,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                IconsaxPlusLinear.heart,
                size: 20,
                color: Color(0xFF3D3D3D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────
  // Image thumbnail row
  // ───────────────────────────────────────────────
  Widget _buildThumbnailRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(5, (index) {
          final isSelected = _selectedThumb == index;
          return Padding(
            padding: EdgeInsets.only(right: index < 4 ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedThumb = index),
              child: Container(
                width: 66,
                height: 44,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    const Color(0xFF0058B5),
                    const Color(0xFF010A36),
                    index * 0.2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  border: isSelected
                      ? Border.all(
                          color: const Color(0xFF123A72), width: 2)
                      : null,
                ),
                child: Center(
                  child: Icon(
                    IconsaxPlusBold.image,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ───────────────────────────────────────────────
  // Agent section
  // ───────────────────────────────────────────────
  Widget _buildAgentSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agent',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Avatar placeholder
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFD0D0D0),
                  ),
                  child: const Icon(IconsaxPlusBold.user,
                      size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _agentName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _agentCompany,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6D6D6D),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 37,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF123A72),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Center(
                    child: Text(
                      'Contact',
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

  // ───────────────────────────────────────────────
  // Generic section: title + body text
  // ───────────────────────────────────────────────
  Widget _buildSection(String title, String body) {
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
          Text(
            body,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF3D3D3D),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────
  // Property Specifications 2×2 grid
  // ───────────────────────────────────────────────
  Widget _buildSpecsGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Property Specifications',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          // Row 1
          Row(
            children: [
              Expanded(child: _SpecCard(spec: _specs[0])),
              const SizedBox(width: 12),
              Expanded(child: _SpecCard(spec: _specs[1])),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2
          Row(
            children: [
              Expanded(child: _SpecCard(spec: _specs[2])),
              const SizedBox(width: 12),
              Expanded(child: _SpecCard(spec: _specs[3])),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────
  // Where You'll Be (map preview)
  // ───────────────────────────────────────────────
  Widget _buildMapSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where You\'ll Be',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 230,
              width: double.infinity,
              child: Stack(
                children: [
                  // Map placeholder
                  Container(
                    color: const Color(0xFFE8F0F8),
                    child: Center(
                      child: Icon(
                        IconsaxPlusBold.map_1,
                        size: 60,
                        color: const Color(0xFF123A72)
                            .withValues(alpha: 0.15),
                      ),
                    ),
                  ),

                  // Pin marker
                  Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: 0.25),
                            blurRadius: 2.74,
                            offset: const Offset(0, 2.74),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xFF006BF6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            IconsaxPlusLinear.user,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // "Sign up with Email" floating button on map
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 17,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              IconsaxPlusLinear.map_1,
                              size: 16,
                              color: Color(0xFF0A1230),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'View on Map',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF0A1230),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────
  // About Moriah (neighborhood) with fade + Read More
  // ───────────────────────────────────────────────
  Widget _buildNeighborhoodSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Moriah',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _aboutNeighborhood1,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF3D3D3D),
                      height: 1.6,
                    ),
                  ),
                  if (_aboutExpanded) ...[
                    const SizedBox(height: 12),
                    Text(
                      _aboutNeighborhood2,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF3D3D3D),
                        height: 1.6,
                      ),
                    ),
                  ],
                  if (!_aboutExpanded) const SizedBox(height: 80),
                ],
              ),
              // White gradient overlay (only when collapsed)
              if (!_aboutExpanded)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 120,
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
            ],
          ),
          // Read More button
          Center(
            child: GestureDetector(
              onTap: () =>
                  setState(() => _aboutExpanded = !_aboutExpanded),
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
                  _aboutExpanded ? 'Show Less' : 'Read More',
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
    );
  }

  // ───────────────────────────────────────────────
  // Properties in Moriah
  // ───────────────────────────────────────────────
  Widget _buildNearbyProperties() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Properties in Moriah',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_nearbyListings.length, (index) {
            final listing = _nearbyListings[index];
            return Padding(
              padding: EdgeInsets.only(
                  bottom: index < _nearbyListings.length - 1 ? 16 : 0),
              child: _NearbyListingCard(listing: listing),
            );
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Stat card (area / bedrooms / bathrooms)
// ═══════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 77,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE7E7E7)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF4F4F4F)),
            Row(
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF3D3D3D),
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
// Spec data model
// ═══════════════════════════════════════════════
class _Spec {
  final String name;
  final String value;
  final IconData icon;

  const _Spec(this.name, this.value, this.icon);
}

// ═══════════════════════════════════════════════
// Spec card (Balcony/Parking/Elevator/Protected Space)
// ═══════════════════════════════════════════════
class _SpecCard extends StatelessWidget {
  final _Spec spec;
  const _SpecCard({required this.spec});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(spec.icon, size: 32, color: const Color(0xFF123A72)),
          const SizedBox(height: 12),
          Text(
            spec.name,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            spec.value,
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
// Nearby listing data model
// ═══════════════════════════════════════════════
class _NearbyListing {
  final String price;
  final String address;
  final int area;
  final int rooms;
  final int floor;
  final bool isNew;
  final bool viaBroker;

  const _NearbyListing(
    this.price,
    this.address,
    this.area,
    this.rooms,
    this.floor,
    this.isNew,
    this.viaBroker,
  );
}

// ═══════════════════════════════════════════════
// Nearby listing card
// ═══════════════════════════════════════════════
class _NearbyListingCard extends StatelessWidget {
  final _NearbyListing listing;
  const _NearbyListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  child: Icon(
                    IconsaxPlusBold.home_2,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),

              // Heart button
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    IconsaxPlusLinear.heart,
                    size: 20,
                    color: Color(0xFF123A72),
                  ),
                ),
              ),

              // New badge
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
                    child: Text(
                      'New',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Via Broker badge
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
                    child: Text(
                      'Via Broker',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0033AC),
                      ),
                    ),
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
              // Price + FOR SALE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    listing.price,
                    style: GoogleFonts.rubik(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A1230),
                    ),
                  ),
                  Text(
                    'FOR SALE',
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

              // Area / Rooms / Floor chips
              Row(
                children: [
                  _DetailChip(
                    icon: IconsaxPlusLinear.maximize_3,
                    text: '${listing.area} m²',
                  ),
                  const SizedBox(width: 31),
                  _DetailChip(
                    icon: IconsaxPlusLinear.building_3,
                    text: '${listing.rooms} Rooms',
                  ),
                  const SizedBox(width: 31),
                  _DetailChip(
                    icon: IconsaxPlusLinear.building_4,
                    text: 'Floor ${listing.floor}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// Detail chip (area / rooms / floor) for nearby cards
// ═══════════════════════════════════════════════
class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
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
