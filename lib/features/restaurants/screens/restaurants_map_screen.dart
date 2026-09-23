import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';
import 'web_restaurants_map_screen.dart';

/// Restaurants map view — responsive wrapper.
/// Desktop (> 1100px) renders the web search + map layout; mobile keeps the app UI.
class RestaurantsMapScreen extends StatelessWidget {
  const RestaurantsMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return const WebRestaurantsMapContent();
        }
        return const _MobileRestaurantsMapContent();
      },
    );
  }
}

/// Mobile layout – shows restaurant, coffee shop, and bar pins on
/// the map with a search bar, tappable popup cards, and a "View as List" toggle.
class _MobileRestaurantsMapContent extends StatefulWidget {
  const _MobileRestaurantsMapContent();

  @override
  State<_MobileRestaurantsMapContent> createState() =>
      _MobileRestaurantsMapContentState();
}

class _MobileRestaurantsMapContentState
    extends State<_MobileRestaurantsMapContent> {
  int? _selectedPin;

  // Modi'in center
  static const _center = LatLng(31.8928, 35.0104);

  // ── Restaurant pins (green #31AC4E) ──
  static final _restaurants = [
    _RestaurantPin(
      'Shipudey Hatikva',
      'Israeli Dining',
      '3 Yona Hanavi Street, Modiin',
      4.8, 254, 428,
      _PinType.restaurant,
      const LatLng(31.8960, 35.0080),
    ),
    _RestaurantPin(
      'Pasta Basta',
      'Dining',
      'HaOmanut St 2, Modiin',
      4.8, 254, 428,
      _PinType.restaurant,
      const LatLng(31.8945, 35.0120),
    ),
    _RestaurantPin(
      'Sushi Bar Modiin',
      'Dining',
      '21 Sderot Modi\'in',
      4.8, 254, 428,
      _PinType.restaurant,
      const LatLng(31.8910, 35.0060),
    ),
    _RestaurantPin(
      'Japan Japan Modiin',
      'Restaurant',
      'Main St 15, Tel Aviv',
      4.5, 200, 250,
      _PinType.restaurant,
      const LatLng(31.8890, 35.0140),
    ),
    _RestaurantPin(
      'Sea & Spice',
      'Restaurant',
      'HaNahalım St 8, Modiin',
      4.5, 200, 250,
      _PinType.restaurant,
      const LatLng(31.8975, 35.0050),
    ),
    _RestaurantPin(
      'Orta Abylai Khan',
      'Restaurant',
      'Main St 15, Tel Aviv',
      4.5, 200, 250,
      _PinType.restaurant,
      const LatLng(31.8930, 35.0180),
    ),
    _RestaurantPin(
      'Japonica Dostyk',
      'Restaurant',
      'Derech Modiin 6, Modiin',
      4.5, 200, 250,
      _PinType.restaurant,
      const LatLng(31.8870, 35.0100),
    ),
    _RestaurantPin(
      'Mangal Doner',
      'Restaurant',
      'HaNahalım St 8, Modiin',
      4.5, 200, 250,
      _PinType.restaurant,
      const LatLng(31.8955, 35.0160),
    ),

    // ── Coffee shop pins (blue #006BF6) ──
    _RestaurantPin(
      'Fresh Coffee',
      'Israeli Cafe',
      'HaNahalım St 8, Modiin',
      4.8, 128, 187,
      _PinType.coffee,
      const LatLng(31.8920, 35.0040),
    ),
    _RestaurantPin(
      '3:16 John Caffe',
      'Cafe',
      'HaMaccabim, Modi\'in',
      4.8, 345, 745,
      _PinType.coffee,
      const LatLng(31.8985, 35.0130),
    ),
    _RestaurantPin(
      'Coffee Station',
      'Cafe',
      'HaMaccabim, Modi\'in',
      4.8, 345, 745,
      _PinType.coffee,
      const LatLng(31.8905, 35.0190),
    ),
    _RestaurantPin(
      'Landwer Café',
      'Cafe',
      'HaNahalım St 8, Modiin',
      4.5, 200, 250,
      _PinType.coffee,
      const LatLng(31.8940, 35.0020),
    ),
    _RestaurantPin(
      'Aroma Espresso',
      'Cafe',
      'Azrieli Modiin, Modiin',
      4.6, 320, 410,
      _PinType.coffee,
      const LatLng(31.8965, 35.0200),
    ),
    _RestaurantPin(
      'Cofix',
      'Cafe',
      'HaMaccabim Blvd, Modiin',
      4.3, 180, 290,
      _PinType.coffee,
      const LatLng(31.8880, 35.0070),
    ),
    _RestaurantPin(
      'Cafe Cafe',
      'Cafe',
      'Yigal Alon St, Modiin',
      4.4, 210, 330,
      _PinType.coffee,
      const LatLng(31.8950, 35.0095),
    ),
    _RestaurantPin(
      'Greg Café',
      'Cafe',
      'Emek Ayalon Mall, Modiin',
      4.5, 275, 380,
      _PinType.coffee,
      const LatLng(31.8935, 35.0150),
    ),

    // ── Bar pins (red #CC0001) ──
    _RestaurantPin(
      'Jim\'s Bar',
      'Bar',
      'HaNahalım St 8, Modiin',
      4.8, 128, 187,
      _PinType.bar,
      const LatLng(31.8942, 35.0055),
    ),
    _RestaurantPin(
      'The Duke',
      'Bar',
      'Main St 15, Tel Aviv',
      4.5, 200, 250,
      _PinType.bar,
      const LatLng(31.8898, 35.0115),
    ),
    _RestaurantPin(
      'The Gourmet Burger',
      'Bar',
      'King St 3, Jerusalem',
      4.7, 300, 320,
      _PinType.bar,
      const LatLng(31.8970, 35.0175),
    ),
    _RestaurantPin(
      'Perry\'s Bar',
      'Bar',
      'Derech Modiin 6, Modiin',
      4.5, 200, 250,
      _PinType.bar,
      const LatLng(31.8915, 35.0030),
    ),
    _RestaurantPin(
      'Murphy\'s Pub',
      'Bar',
      'Azrieli Modiin, Modiin',
      4.3, 150, 190,
      _PinType.bar,
      const LatLng(31.8958, 35.0140),
    ),
    _RestaurantPin(
      'Whiskey Bar',
      'Bar',
      'Emek Ayalon, Modiin',
      4.6, 180, 230,
      _PinType.bar,
      const LatLng(31.8928, 35.0088),
    ),
    _RestaurantPin(
      'The Tap House',
      'Bar',
      'HaPardes St, Modiin',
      4.4, 160, 210,
      _PinType.bar,
      const LatLng(31.8882, 35.0165),
    ),
    _RestaurantPin(
      'Beerhouse',
      'Bar',
      'Shimshon Blvd, Modiin',
      4.5, 220, 280,
      _PinType.bar,
      const LatLng(31.8973, 35.0045),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Stack(
            children: [
              // ═══════════════════════════════════
              // Map
              // ═══════════════════════════════════
              FlutterMap(
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 14.5,
                  onTap: (_, _) => setState(() => _selectedPin = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.modiin4u.app',
                  ),
                  MarkerLayer(
                    markers: List.generate(_restaurants.length, (i) {
                      final r = _restaurants[i];
                      final isSelected = _selectedPin == i;
                      return Marker(
                        point: r.position,
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPin = i),
                          child: _MapPin(
                            type: r.type,
                            isSelected: isSelected,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),

              // ═══════════════════════════════════
              // Search bar
              // ═══════════════════════════════════
              Positioned(
                top: 58,
                left: 16,
                right: 16,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE7E7E7)),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                          style: TextStyle(fontFamily: AppFonts.inter, 
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

              // ═══════════════════════════════════
              // Selected pin card overlay
              // ═══════════════════════════════════
              if (_selectedPin != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 80,
                  child: _RestaurantCard(
                    restaurant: _restaurants[_selectedPin!],
                    onClose: () => setState(() => _selectedPin = null),
                  ),
                ),

              // ═══════════════════════════════════
              // "View as List" floating button
              // ═══════════════════════════════════
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Center(
                  child: GestureDetector(
                    onTap: () => context.push('/restaurants'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
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
                          const Icon(
                            IconsaxPlusLinear.menu,
                            size: 16,
                            color: Color(0xFF0A1230),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'View as List',
                            style: TextStyle(fontFamily: AppFonts.inter, 
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
    );
  }
}

// ═══════════════════════════════════════════════
// Data model
// ═══════════════════════════════════════════════
enum _PinType { restaurant, coffee, bar }

class _RestaurantPin {
  final String name;
  final String category;
  final String address;
  final double rating;
  final int reviews;
  final int views;
  final _PinType type;
  final LatLng position;

  const _RestaurantPin(
    this.name,
    this.category,
    this.address,
    this.rating,
    this.reviews,
    this.views,
    this.type,
    this.position,
  );
}

// ═══════════════════════════════════════════════
// Map pin widget – white circle + colored inner circle + icon
// Green = restaurant, Blue = coffee, Red = bar
// ═══════════════════════════════════════════════
class _MapPin extends StatelessWidget {
  final _PinType type;
  final bool isSelected;

  const _MapPin({required this.type, this.isSelected = false});

  Color get _color => switch (type) {
        _PinType.restaurant => const Color(0xFF31AC4E),
        _PinType.coffee => const Color(0xFF006BF6),
        _PinType.bar => const Color(0xFFCC0001),
      };

  IconData get _icon => switch (type) {
        _PinType.restaurant => IconsaxPlusBold.verify,
        _PinType.coffee => IconsaxPlusBold.coffee,
        _PinType.bar => IconsaxPlusBold.cup,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 2.28,
            offset: const Offset(0, 2.28),
          ),
        ],
        border: isSelected
            ? Border.all(color: const Color(0xFF123A72), width: 2)
            : null,
      ),
      child: Center(
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: _color,
            shape: BoxShape.circle,
          ),
          child: Icon(_icon, size: 12, color: Colors.white),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Restaurant popup card (horizontal layout: image + info)
// ═══════════════════════════════════════════════
class _RestaurantCard extends StatelessWidget {
  final _RestaurantPin restaurant;
  final VoidCallback onClose;

  const _RestaurantCard({
    required this.restaurant,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: image + info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                width: 120,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0058B5), Color(0xFF010A36)],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        IconsaxPlusBold.reserve,
                        size: 32,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    // Close button
                    Positioned(
                      right: 4,
                      top: 4,
                      child: GestureDetector(
                        onTap: onClose,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 14, color: Color(0xFF3D3D3D)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Info column
              Expanded(
                child: SizedBox(
                  height: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        restaurant.name,
                        style: TextStyle(fontFamily: AppFonts.rubik, 
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 25 / 20,
                          color: const Color(0xFF0A1230),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Category
                      Text(
                        restaurant.category,
                        style: TextStyle(fontFamily: AppFonts.inter, 
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF5F5E5A),
                        ),
                      ),
                      const SizedBox(height: 11),

                      // Address
                      Row(
                        children: [
                          const Icon(IconsaxPlusBold.location,
                              size: 14, color: Color(0xFF17A9D0)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              restaurant.address,
                              style: TextStyle(fontFamily: AppFonts.inter, 
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF5F5E5A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Rating
                      Row(
                        children: [
                          const Icon(IconsaxPlusBold.star_1,
                              size: 16, color: Color(0xFFFFC107)),
                          const SizedBox(width: 8),
                          Text(
                            restaurant.rating.toString(),
                            style: TextStyle(fontFamily: AppFonts.inter, 
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${restaurant.reviews})',
                            style: TextStyle(fontFamily: AppFonts.inter, 
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF6D6D6D),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Views
                      Row(
                        children: [
                          const Icon(IconsaxPlusLinear.eye,
                              size: 16, color: Color(0xFF0A1230)),
                          const SizedBox(width: 8),
                          Text(
                            '${restaurant.views}',
                            style: TextStyle(fontFamily: AppFonts.inter, 
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Views',
                            style: TextStyle(fontFamily: AppFonts.inter, 
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
              ),
            ],
          ),
          const SizedBox(height: 12),

          // "View Full Details" button
          GestureDetector(
            onTap: () => context.push(
                '/business/restaurant_${restaurant.name.hashCode}'),
            child: Container(
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
                    Text(
                      'View Full Details',
                      style: TextStyle(fontFamily: AppFonts.inter, 
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      IconsaxPlusLinear.arrow_right_3,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
