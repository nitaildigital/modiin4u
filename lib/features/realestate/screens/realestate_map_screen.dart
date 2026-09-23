import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/router/app_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';

/// Real-estate dedicated map view – shows property pins on the map
/// with a search bar and a "View as List" toggle.
class RealEstateMapScreen extends StatefulWidget {
  const RealEstateMapScreen({super.key});

  @override
  State<RealEstateMapScreen> createState() => _RealEstateMapScreenState();
}

class _RealEstateMapScreenState extends State<RealEstateMapScreen> {
  int? _selectedPin;

  // Modi'in center
  static const _center = LatLng(31.8928, 35.0104);

  // ── Property pins ──
  static final _properties = [
    _Property('₪3,650,000', '21 Sderot El Melachot', 140, 6, 3,
        const LatLng(31.8960, 35.0080)),
    _Property('₪3,790,000', '84 Menachem Begin Road', 133, 4, 2,
        const LatLng(31.8945, 35.0120)),
    _Property('₪5,690,000', '73 Sarah Amano Street', 145, 4, 3,
        const LatLng(31.8910, 35.0060)),
    _Property('₪3,050,000', '37 Ella Valley Street', 145, 4, 3,
        const LatLng(31.8890, 35.0140)),
    _Property('₪4,200,000', '15 Hashmonaim Blvd', 120, 5, 2,
        const LatLng(31.8975, 35.0050)),
    _Property('₪2,850,000', '8 Hapardes Street', 95, 4, 2,
        const LatLng(31.8930, 35.0180)),
    _Property('₪6,100,000', '22 Moriah Heights', 180, 7, 3,
        const LatLng(31.8870, 35.0100)),
    _Property('₪3,400,000', '5 Avni Chen Lane', 110, 5, 2,
        const LatLng(31.8955, 35.0160)),
    _Property('₪4,750,000', '31 Buchman Boulevard', 155, 6, 3,
        const LatLng(31.8920, 35.0040)),
    _Property('₪2,990,000', '19 Emek Hashalom', 100, 4, 2,
        const LatLng(31.8985, 35.0130)),
    _Property('₪3,950,000', '42 Reut Circle', 135, 5, 3,
        const LatLng(31.8905, 35.0190)),
    _Property('₪5,200,000', '7 Maccabim Road', 160, 6, 3,
        const LatLng(31.8940, 35.0020)),
    _Property('₪3,100,000', '28 Shimshon Street', 108, 4, 2,
        const LatLng(31.8965, 35.0200)),
    _Property('₪4,500,000', '14 Dvora Hanevia', 148, 5, 3,
        const LatLng(31.8880, 35.0070)),
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
                  onTap: (_, __) => setState(() => _selectedPin = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.modiin4u.app',
                  ),
                  MarkerLayer(
                    markers: List.generate(_properties.length, (i) {
                      final p = _properties[i];
                      final isSelected = _selectedPin == i;
                      return Marker(
                        point: p.position,
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedPin = i),
                          child: _PropertyPin(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border:
                        Border.all(color: const Color(0xFFE7E7E7)),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: 0.1),
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
                          'Search by location, neighborhood...',
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
              // Selected pin card (bottom sheet)
              // ═══════════════════════════════════
              if (_selectedPin != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 80,
                  child: _PropertyCard(
                    property: _properties[_selectedPin!],
                    onClose: () =>
                        setState(() => _selectedPin = null),
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
                    onTap: () => context.goOrPush('/realestate'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: 0.25),
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
// Property data model
// ═══════════════════════════════════════════════
class _Property {
  final String price;
  final String address;
  final int area;
  final int rooms;
  final int floor;
  final LatLng position;

  const _Property(
    this.price,
    this.address,
    this.area,
    this.rooms,
    this.floor,
    this.position,
  );
}

// ═══════════════════════════════════════════════
// Property map pin (white circle + blue inner circle + icon)
// ═══════════════════════════════════════════════
class _PropertyPin extends StatelessWidget {
  final bool isSelected;

  const _PropertyPin({this.isSelected = false});

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
            color: isSelected
                ? const Color(0xFF17A9D0)
                : const Color(0xFF006BF6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            IconsaxPlusLinear.user,
            size: 12,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Selected property card
// ═══════════════════════════════════════════════
class _PropertyCard extends StatelessWidget {
  final _Property property;
  final VoidCallback onClose;

  const _PropertyCard({
    required this.property,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image placeholder
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
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
                    IconsaxPlusBold.home_2,
                    size: 40,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                // Close button
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 16, color: Color(0xFF3D3D3D)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Price + FOR SALE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                property.price,
                style: TextStyle(fontFamily: AppFonts.rubik, 
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A1230),
                ),
              ),
              Text(
                'FOR SALE',
                style: TextStyle(fontFamily: AppFonts.inter, 
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF17A9D0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Address
          Row(
            children: [
              const Icon(IconsaxPlusBold.location,
                  size: 14, color: Color(0xFF17A9D0)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  property.address,
                  style: TextStyle(fontFamily: AppFonts.inter, 
                    fontSize: 13,
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
                  '${property.area} m²'),
              const SizedBox(width: 24),
              _chip(IconsaxPlusLinear.building_3,
                  '${property.rooms} Rooms'),
              const SizedBox(width: 24),
              _chip(IconsaxPlusLinear.building_4,
                  'Floor ${property.floor}'),
            ],
          ),
          const SizedBox(height: 12),

          // View Details button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => context.push('/listing/1'),
              child: Container(
                height: 40,
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
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontFamily: AppFonts.inter, 
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF3D3D3D),
          ),
        ),
      ],
    );
  }
}
