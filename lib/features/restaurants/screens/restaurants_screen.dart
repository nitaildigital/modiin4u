import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'web_restaurants_screen.dart';

/// Restaurants discovery screen — responsive wrapper.
/// Desktop (> 1100px) renders the full web layout; mobile keeps the app UI.
class RestaurantsScreen extends StatelessWidget {
  const RestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return const WebRestaurantsContent();
        }
        return const _MobileRestaurantsContent();
      },
    );
  }
}

/// Mobile layout — hero banner, cuisine category cards,
/// vertical restaurant/coffee/bar listings with fade + "View All",
/// and horizontal "Most Loved" / "Lunch Nearby" rows.
class _MobileRestaurantsContent extends StatefulWidget {
  const _MobileRestaurantsContent();

  @override
  State<_MobileRestaurantsContent> createState() => _MobileRestaurantsContentState();
}

class _MobileRestaurantsContentState extends State<_MobileRestaurantsContent> {
  int _bannerPage = 1; // 0-indexed, starts on second dot active

  // ── Cuisine categories ──
  static const _cuisines = [
    _Cuisine('Japanese', 12),
    _Cuisine('Sushi', 10),
    _Cuisine('Italian', 8),
    _Cuisine('Asian', 9),
    _Cuisine('Israeli', 14),
    _Cuisine('Mediterranean', 7),
    _Cuisine('Burgers', 6),
  ];

  // ── Popular Restaurants ──
  static const _popularRestaurants = [
    _Place(
      'Shipudey Hatikva',
      'Israeli Dining',
      'Weizmann Street Heritage Modiin',
      4.8, 254, 428,
      isKosher: true,
      badgeColor: _BadgeColor.green,
    ),
    _Place(
      'Pasta Basta',
      'Dining',
      'HaOmanut St 2, Modiin',
      4.8, 254, 428,
      badgeColor: _BadgeColor.green,
    ),
    _Place(
      'Sushi Bar Modiin',
      'Dining',
      '21 Sderot Modi\'in-Maccabim-Re\'ut, Israel',
      4.8, 254, 428,
      badgeColor: _BadgeColor.green,
    ),
  ];

  // ── Coffee Shops ──
  static const _coffeeShops = [
    _Place(
      'Fresh Coffee',
      'Israeli Cafe',
      'HaNahalım St 8, Modiin',
      4.8, 128, 187,
      badgeColor: _BadgeColor.blue,
    ),
    _Place(
      '3:16 John Caffe',
      'Cafe',
      'HaMaccabim, Modi\'in-Maccabim-Re\'ut, Israel',
      4.8, 345, 745,
      badgeColor: _BadgeColor.blue,
    ),
    _Place(
      'Coffee Station',
      'Cafe',
      'HaMaccabim, Modi\'in-Maccabim-Re\'ut, Israel',
      4.8, 345, 745,
      badgeColor: _BadgeColor.blue,
    ),
  ];

  // ── Bars ──
  static const _bars = [
    _Place(
      'Jim\'s Bar',
      'Bar',
      'HaNahalım St 8, Modiin',
      4.8, 128, 187,
      badgeColor: _BadgeColor.red,
    ),
    _Place(
      'The Duke',
      'Cafe',
      'Main St 15, Tel Aviv',
      4.5, 200, 250,
      badgeColor: _BadgeColor.red,
    ),
    _Place(
      'The Gourmet Burger',
      'Bar',
      'King St 3, Jerusalem',
      4.7, 300, 320,
      badgeColor: _BadgeColor.red,
    ),
  ];

  // ── Most Loved (horizontal) ──
  static const _mostLoved = [
    _HPlace('Japan Japan Modiin', 'Restaurant', 'Main St 15, Tel Aviv', 4.5, 200, 250),
    _HPlace('Perry\'s Bar', 'Bar', 'Derech Modiin 6, Modiin', 4.5, 200, 250),
    _HPlace('Landwer Café', 'Bar', 'HaNahalım St 8, Modiin', 4.5, 200, 250),
    _HPlace('Sea & Spice', 'Restaurant', 'HaNahalım St 8, Modiin', 4.5, 200, 250),
  ];

  // ── Lunch Nearby (horizontal, with delivery time) ──
  static const _lunchNearby = [
    _HPlace('Orta Abylai Khan', 'Restaurant', 'Main St 15, Tel Aviv', 4.5, 200, null, deliveryTime: '30–40 min'),
    _HPlace('Japonica Dostyk', 'Restaurant', 'Derech Modiin 6, Modiin', 4.5, 200, null, deliveryTime: '25–35 min'),
    _HPlace('Marshal Abylai Khana', 'Restaurant', 'HaNahalım St 8, Modiin', 4.5, 200, null, deliveryTime: '30–40 min'),
    _HPlace('Mangal Doner Kaskelen', 'Restaurant', 'HaNahalım St 8, Modiin', 4.5, 200, null, deliveryTime: '35–45 min'),
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
                      const SizedBox(height: 100), // space for sticky header
                      const SizedBox(height: 16),

                      // Hero banner
                      _buildHeroBanner(),
                      const SizedBox(height: 12),

                      // Page dots
                      _buildPageDots(),
                      const SizedBox(height: 16),

                      // "Explore Modiin"
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Explore Modiin',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Cuisine category cards
                      _buildCuisineRow(),
                      const SizedBox(height: 24),

                      // Popular Restaurants
                      _buildVerticalSection(
                        'Popular Restaurants in Modiin',
                        _popularRestaurants,
                        'View All Restaurants',
                      ),
                      const SizedBox(height: 40),

                      // Coffee Shops
                      _buildVerticalSection(
                        'Coffee Shops in Modiin',
                        _coffeeShops,
                        'View All Coffee Shops',
                      ),
                      const SizedBox(height: 40),

                      // Bars
                      _buildVerticalSection(
                        'Bars in Modiin',
                        _bars,
                        'View All Bars',
                      ),
                      const SizedBox(height: 40),

                      // Most Loved
                      _buildHorizontalSection('Most Loved in Modiin', _mostLoved),
                      const SizedBox(height: 40),

                      // Lunch Nearby
                      _buildHorizontalSection('Lunch Nearby', _lunchNearby),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),

                // ═══════════════════════════════════
                // Frosted sticky header
                // ═══════════════════════════════════
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildStickyHeader(),
                ),

                // ═══════════════════════════════════
                // Floating "View on Map" button
                // ═══════════════════════════════════
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => context.push('/map'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(IconsaxPlusLinear.map,
                                size: 16, color: Color(0xFF0A1230)),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Sticky header: title + search bar
  // ═══════════════════════════════════════════════
  Widget _buildStickyHeader() {
    return ClipRect(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
        ),
        child: Column(
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(
                      IconsaxPlusLinear.arrow_left,
                      size: 24,
                      color: Color(0xFF3D3D3D),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Restaurants',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40), // balance back button
                ],
              ),
            ),

            // Search bar
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
                        'Search restaurant, cuisine, or location...',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6D6D6D),
                        ),
                      ),
                    ),
                    const Icon(
                      IconsaxPlusLinear.setting_4,
                      size: 20,
                      color: Color(0xFF123A72),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Hero banner
  // ═══════════════════════════════════════════════
  Widget _buildHeroBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 200,
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
            IconsaxPlusBold.reserve,
            size: 48,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Page dots
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
            color: i == _bannerPage
                ? const Color(0xFF123A72)
                : const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(50),
          ),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════
  // Cuisine category horizontal row
  // ═══════════════════════════════════════════════
  Widget _buildCuisineRow() {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 16),
        itemCount: _cuisines.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _CuisineCard(cuisine: _cuisines[i]),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Vertical section (3 cards + fade + "View All")
  // ═══════════════════════════════════════════════
  Widget _buildVerticalSection(
    String title,
    List<_Place> places,
    String viewAllLabel,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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

          // Cards stack with fade
          Stack(
            children: [
              Column(
                children: [
                  for (int i = 0; i < places.length; i++) ...[
                    _PlaceCard(place: places[i]),
                    if (i < places.length - 1) const SizedBox(height: 16),
                  ],
                ],
              ),

              // Fade gradient overlay at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 222,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00FFFFFF),
                        Colors.white,
                      ],
                    ),
                  ),
                ),
              ),

              // "View All" button
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      height: 40,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: const Color(0xFF123A72)),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Center(
                        child: Text(
                          viewAllLabel,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF123A72),
                          ),
                        ),
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

  // ═══════════════════════════════════════════════
  // Horizontal section (scroll cards)
  // ═══════════════════════════════════════════════
  Widget _buildHorizontalSection(String title, List<_HPlace> places) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 266,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 18, right: 18),
            itemCount: places.length,
            separatorBuilder: (_, _) => const SizedBox(width: 20),
            itemBuilder: (_, i) =>
                _HPlaceCard(place: places[i]),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// Data models
// ═══════════════════════════════════════════════
enum _BadgeColor { green, blue, red }

class _Cuisine {
  final String name;
  final int count;
  const _Cuisine(this.name, this.count);
}

class _Place {
  final String name;
  final String type;
  final String address;
  final double rating;
  final int reviews;
  final int views;
  final bool isKosher;
  final _BadgeColor badgeColor;

  const _Place(
    this.name,
    this.type,
    this.address,
    this.rating,
    this.reviews,
    this.views, {
    this.isKosher = false,
    this.badgeColor = _BadgeColor.green,
  });
}

class _HPlace {
  final String name;
  final String type;
  final String address;
  final double rating;
  final int reviews;
  final int? views;
  final String? deliveryTime;

  const _HPlace(
    this.name,
    this.type,
    this.address,
    this.rating,
    this.reviews,
    this.views, {
    this.deliveryTime,
  });
}

// ═══════════════════════════════════════════════
// Cuisine category card (120 × 142.5)
// ═══════════════════════════════════════════════
class _CuisineCard extends StatelessWidget {
  final _Cuisine cuisine;
  const _CuisineCard({required this.cuisine});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 90,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0058B5), Color(0xFF010A36)],
              ),
            ),
            child: Center(
              child: Icon(
                IconsaxPlusBold.reserve,
                size: 24,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
          // Label
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cuisine.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0A1230),
                  ),
                ),
                const SizedBox(height: 2.5),
                Text(
                  '${cuisine.count} places',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF5F5E5A),
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
// Full-width place card (361 × 340)
// ═══════════════════════════════════════════════
class _PlaceCard extends StatelessWidget {
  final _Place place;
  const _PlaceCard({required this.place});

  Color get _badgeCircleColor => switch (place.badgeColor) {
        _BadgeColor.green => const Color(0xFF31AC4E),
        _BadgeColor.blue => const Color(0xFF006BF6),
        _BadgeColor.red => const Color(0xFFCC0001),
      };

  IconData get _badgeIcon => switch (place.badgeColor) {
        _BadgeColor.green => IconsaxPlusBold.verify,
        _BadgeColor.blue => IconsaxPlusBold.coffee,
        _BadgeColor.red => IconsaxPlusBold.cup,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/business/restaurant_${place.name.hashCode}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                // Image
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
                      IconsaxPlusBold.reserve,
                      size: 40,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),

                // Kosher badge
                if (place.isKosher)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      height: 27,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0033AC),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(IconsaxPlusLinear.shield_tick,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Kosher',
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
                    child: const Center(
                      child: Icon(IconsaxPlusLinear.heart,
                          size: 23, color: Color(0xFF123A72)),
                    ),
                  ),
                ),

                // Places badge (colored circle)
                Positioned(
                  right: 12,
                  bottom: -20,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _badgeCircleColor,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Icon(_badgeIcon,
                          size: 20, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + type
                Text(
                  place.name,
                  style: GoogleFonts.rubik(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1230),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  place.type,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF5F5E5A),
                  ),
                ),
                const SizedBox(height: 12),

                // Address
                Row(
                  children: [
                    const Icon(IconsaxPlusBold.location,
                        size: 16, color: Color(0xFF17A9D0)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        place.address,
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
                const SizedBox(height: 12),

                // Rating + views row
                Row(
                  children: [
                    // Star rating
                    const Icon(IconsaxPlusBold.star_1,
                        size: 16, color: Color(0xFFFFC107)),
                    const SizedBox(width: 8),
                    Text(
                      place.rating.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${place.reviews})',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6D6D6D),
                      ),
                    ),
                    const SizedBox(width: 40),

                    // Views
                    const Icon(IconsaxPlusLinear.eye,
                        size: 16, color: Color(0xFF0A1230)),
                    const SizedBox(width: 8),
                    Text(
                      '${place.views}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Views',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6D6D6D),
                      ),
                    ),
                  ],
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
// Horizontal place card (250 × 266)
// ═══════════════════════════════════════════════
class _HPlaceCard extends StatelessWidget {
  final _HPlace place;
  const _HPlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/business/h_${place.name.hashCode}'),
      child: SizedBox(
        width: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 150,
              child: Stack(
                children: [
                  Container(
                    width: 250,
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
                        IconsaxPlusBold.reserve,
                        size: 32,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(IconsaxPlusLinear.heart,
                            size: 19, color: Color(0xFF123A72)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Name + type
            Text(
              place.name,
              style: GoogleFonts.rubik(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0A1230),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              place.type,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF5F5E5A),
              ),
            ),
            const SizedBox(height: 12),

            // Address
            Row(
              children: [
                const Icon(IconsaxPlusBold.location,
                    size: 16, color: Color(0xFF17A9D0)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    place.address,
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
            const Spacer(),

            // Rating + views/time row
            Row(
              children: [
                const Icon(IconsaxPlusBold.star_1,
                    size: 16, color: Color(0xFFFFC107)),
                const SizedBox(width: 8),
                Text(
                  place.rating.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${place.reviews})',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6D6D6D),
                  ),
                ),
                const SizedBox(width: 40),

                if (place.views != null) ...[
                  const Icon(IconsaxPlusLinear.eye,
                      size: 16, color: Color(0xFF0A1230)),
                  const SizedBox(width: 8),
                  Text(
                    '${place.views}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Views',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6D6D6D),
                    ),
                  ),
                ] else if (place.deliveryTime != null) ...[
                  const Icon(IconsaxPlusLinear.clock,
                      size: 16, color: Color(0xFF5D5D5D)),
                  const SizedBox(width: 8),
                  Text(
                    place.deliveryTime!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
