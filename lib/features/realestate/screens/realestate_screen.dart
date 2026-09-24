import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/theme/app_colors.dart';
import 'web_realestate_screen.dart';

// ═══════════════════════════════════════════════
// Property type chips
// ═══════════════════════════════════════════════
class _PropertyType {
  final String name;
  final IconData icon;
  const _PropertyType(this.name, this.icon);
}

const _propertyTypes = [
  _PropertyType('Apartment', IconsaxPlusBold.building_4),
  _PropertyType('Penthouse', IconsaxPlusBold.building_3),
  _PropertyType('Garden Apartment', IconsaxPlusBold.house),
  _PropertyType('Duplex', IconsaxPlusBold.building),
  _PropertyType('Villa', IconsaxPlusBold.house_2),
  _PropertyType('Studio', IconsaxPlusBold.lamp),
];

// ═══════════════════════════════════════════════
// Listing model
// ═══════════════════════════════════════════════
class _Listing {
  final String price;
  final String? perMonth;
  final String saleTag;
  final String address;
  final String area;
  final String rooms;
  final String floor;
  final bool isNew;
  final bool viaBroker;
  final Color imageBg;

  const _Listing({
    required this.price,
    this.perMonth,
    required this.saleTag,
    required this.address,
    required this.area,
    required this.rooms,
    required this.floor,
    this.isNew = false,
    this.viaBroker = false,
    this.imageBg = const Color(0xFFE8EEF4),
  });
}

// ── Demo data ──
final _saleListings = [
  const _Listing(
    price: '₪3,650,000',
    saleTag: 'FOR SALE',
    address: '3 Yona Hanavi Street, Modiin',
    area: '140 m²',
    rooms: '6 Rooms',
    floor: 'Floor 3',
    isNew: true,
    viaBroker: true,
    imageBg: Color(0xFFD4E4F7),
  ),
  const _Listing(
    price: '₪3,790,000',
    saleTag: 'FOR SALE',
    address: '84 Menachem Begin Road',
    area: '133 m²',
    rooms: '4 Rooms',
    floor: 'Floor 2',
    isNew: true,
    imageBg: Color(0xFFE0D4C8),
  ),
  const _Listing(
    price: '₪5,690,000',
    saleTag: 'FOR SALE',
    address: '73 Sarah Amano Street',
    area: '145 m²',
    rooms: '4 Rooms',
    floor: 'Floor 3',
    imageBg: Color(0xFFC8D8E0),
  ),
  const _Listing(
    price: '₪3,050,000',
    saleTag: 'FOR SALE',
    address: '37 Ella Valley Street, Modiin',
    area: '145 m²',
    rooms: '4 Rooms',
    floor: 'Floor 3',
    imageBg: Color(0xFFD8E8D4),
  ),
];

final _rentListings = [
  const _Listing(
    price: '₪7,500',
    perMonth: '/ In the month',
    saleTag: 'FOR RENT',
    address: 'Weizmann Street Heritage Modiin',
    area: '140 m²',
    rooms: '6 Rooms',
    floor: 'Floor 3',
    isNew: true,
    viaBroker: true,
    imageBg: Color(0xFFE4D8F0),
  ),
  const _Listing(
    price: '₪12,000',
    perMonth: '/ In the month',
    saleTag: 'FOR RENT',
    address: '12 Yitzhak Shamir Street, Modiin (Legacy)',
    area: '122 m²',
    rooms: '4 Rooms',
    floor: 'Floor 2',
    isNew: true,
    imageBg: Color(0xFFD4E0F0),
  ),
  const _Listing(
    price: '₪6,500',
    perMonth: '/ In the month',
    saleTag: 'FOR RENT',
    address: 'Yitzhak Rabin Modiin Street',
    area: '122 m²',
    rooms: '4 Rooms',
    floor: 'Floor 2',
    viaBroker: true,
    imageBg: Color(0xFFF0E4D4),
  ),
  const _Listing(
    price: '₪8,500',
    perMonth: '/ In the month',
    saleTag: 'FOR RENT',
    address: '37 Ella Valley Street, Modiin',
    area: '122 m²',
    rooms: '4 Rooms',
    floor: 'Floor 2',
    imageBg: Color(0xFFE8E0D8),
  ),
];

// ═══════════════════════════════════════════════
// Real Estate Screen
// ═══════════════════════════════════════════════
class RealEstateScreen extends StatelessWidget {
  const RealEstateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return const WebRealEstateContent();
        }
        return const _MobileRealEstateContent();
      },
    );
  }
}

class _MobileRealEstateContent extends StatefulWidget {
  const _MobileRealEstateContent();

  @override
  State<_MobileRealEstateContent> createState() =>
      _MobileRealEstateContentState();
}

class _MobileRealEstateContentState extends State<_MobileRealEstateContent> {
  int _activeTab = 0; // 0 = For Sale, 1 = For Rent
  int _selectedType = -1;

  List<_Listing> get _listings =>
      _activeTab == 0 ? _saleListings : _rentListings;

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
                // ── Scrollable listing cards ──
                CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 290)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _ListingCard(listing: _listings[index]),
                          ),
                          childCount: _listings.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 72)),
                  ],
                ),

                // ── Fixed header ──
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: const Color(0xE6FFFFFF),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        // Title
                        Text(
                          'Filter Your Discover Feed',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Search bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFE7E7E7),
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                const Icon(
                                  IconsaxPlusLinear.search_normal_1,
                                  size: 18,
                                  color: Color(0xFF6D6D6D),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Search by location, neighborhood...',
                                    style: TextStyle(
                                      fontFamily: AppFonts.inter,
                                      fontSize: 14,
                                      color: const Color(0xFF6D6D6D),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  IconsaxPlusLinear.setting_4,
                                  size: 20,
                                  color: AppColors.midBlue,
                                ),
                                const SizedBox(width: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Property type chips
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _propertyTypes.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final type = _propertyTypes[index];
                              final selected = _selectedType == index;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _selectedType = selected ? -1 : index;
                                }),
                                child: Container(
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.midBlue
                                          : const Color(0xFFE7E7E7),
                                      width: selected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        type.icon,
                                        size: 32,
                                        color: AppColors.midBlue,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        type.name,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: AppFonts.inter,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        // For Sale / For Rent tabs
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              _TabButton(
                                label: 'For Sale',
                                active: _activeTab == 0,
                                onTap: () => setState(() => _activeTab = 0),
                              ),
                              const SizedBox(width: 20),
                              _TabButton(
                                label: 'For Rent',
                                active: _activeTab == 1,
                                onTap: () => setState(() => _activeTab = 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // ── Floating map button ──
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            IconsaxPlusLinear.map_1,
                            size: 16,
                            color: AppColors.navy,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Sign up with Email',
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.navy,
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
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Tab button
// ═══════════════════════════════════════════════
class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.midBlue : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: active ? 20 : 16,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? AppColors.midBlue : const Color(0xFF6D6D6D),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Listing card (full-width image + details)
// ═══════════════════════════════════════════════
class _ListingCard extends StatelessWidget {
  final _Listing listing;

  const _ListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Image ──
        Stack(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: listing.imageBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  IconsaxPlusLinear.image,
                  size: 48,
                  color: Color(0xFFBDBDBD),
                ),
              ),
            ),
            // Badges
            if (listing.viaBroker)
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCD6EE),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    'Via Broker',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0033AC),
                    ),
                  ),
                ),
              ),
            if (listing.isNew)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.turquoise,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    'New',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
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
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  IconsaxPlusLinear.heart,
                  size: 23,
                  color: AppColors.midBlue,
                ),
              ),
            ),
          ],
        ),

        // ── Details ──
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price + tag row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        listing.price,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                      if (listing.perMonth != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          listing.perMonth!,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                            color: const Color(0xFF5F5E5A),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    listing.saleTag,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.turquoise,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Address
              Row(
                children: [
                  const Icon(
                    IconsaxPlusLinear.location,
                    size: 16,
                    color: AppColors.turquoise,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      listing.address,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        color: const Color(0xFF5F5E5A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Area · Rooms · Floor
              Row(
                children: [
                  _detailChip(IconsaxPlusLinear.ruler, listing.area),
                  const SizedBox(width: 31),
                  _detailChip(IconsaxPlusLinear.building_3, listing.rooms),
                  const SizedBox(width: 31),
                  _detailChip(IconsaxPlusLinear.building, listing.floor),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6D6D6D)),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 12,
            color: const Color(0xFF3D3D3D),
          ),
        ),
      ],
    );
  }
}
