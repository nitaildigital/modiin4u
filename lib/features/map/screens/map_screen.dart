import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/theme/app_colors.dart';

import '../data/map_pois.dart';
import 'web_map_screen.dart';


/// Map – responsive wrapper.
/// Desktop (> 1100px) renders the "Explore Modiin" web map; mobile keeps the
/// app UI.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return const WebMapContent();
        }
        return const _MobileMapContent();
      },
    );
  }
}

// ═══════════════════════════════════════════════
// Mobile Map Screen
// ═══════════════════════════════════════════════
class _MobileMapContent extends StatefulWidget {
  const _MobileMapContent();

  @override
  State<_MobileMapContent> createState() => _MobileMapContentState();
}

class _MobileMapContentState extends State<_MobileMapContent> {
  final _activeLayers = <String>{'Businesses'};
  final _mapController = MapController();
  MapPoi? _selectedPoi;
  String _mapSearchQuery = '';

  static const _layers = [
    ('Businesses', IconsaxPlusBold.shop, Color(0xFF17A9D0)),
    ('Events', IconsaxPlusBold.calendar_1, Color(0xFF9032E1)),
    ('Parkings', IconsaxPlusBold.car, Color(0xFF31AC4E)),
    ('Real Estate', IconsaxPlusBold.house_2, Color(0xFF006BF6)),
  ];

  List<MapPoi> get _visiblePois {
    var pois = mapPois.where((p) => _activeLayers.contains(p.layer));
    if (_mapSearchQuery.isNotEmpty) {
      final q = _mapSearchQuery.toLowerCase();
      pois = pois.where(
          (p) => p.name.toLowerCase().contains(q) || p.category.toLowerCase().contains(q));
    }
    return pois.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Map ──
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: modiinCenter,
            initialZoom: 15.0,
            minZoom: 12,
            maxZoom: 18,
            onTap: (_, _) => setState(() => _selectedPoi = null),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.modiin4u.app',
              maxZoom: 19,
            ),
            MarkerLayer(
              markers: _visiblePois.map((poi) {
                final isSelected = _selectedPoi == poi;
                return Marker(
                  point: poi.position,
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPoi = poi),
                    child: _MapPin(
                      color: poi.color,
                      icon: poi.icon,
                      isSelected: isSelected,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // ── Search bar + Filter chips ──
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: const Color(0xFFE7E7E7)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 16,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
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
                          child: TextField(
                            onChanged: (val) => setState(() {
                              _mapSearchQuery = val;
                              _selectedPoi = null;
                            }),
                            style: GoogleFonts.inter(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search for places, businesses, or events',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF6D6D6D),
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filter chips
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _layers.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final (label, icon, color) = _layers[index];
                    final active = _activeLayers.contains(label);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (active) {
                            _activeLayers.remove(label);
                          } else {
                            _activeLayers.add(label);
                          }
                          _selectedPoi = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE7E7E7)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 16,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Checkbox
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.midBlue
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(3),
                                border: active
                                    ? null
                                    : Border.all(
                                        color: const Color(0xFFBDBDBD),
                                        width: 1.5,
                                      ),
                              ),
                              child: active
                                  ? const Icon(Icons.check,
                                      size: 14, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              label,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // ── Zoom controls ──
        Positioned(
          right: 16,
          bottom: _selectedPoi != null ? 310 : 110,
          child: Column(
            children: [
              _MapFab(IconsaxPlusLinear.gps, () {
                _mapController.move(modiinCenter, 15);
              }),
              const SizedBox(height: 8),
              _MapFab(IconsaxPlusLinear.add, () {
                final zoom = _mapController.camera.zoom;
                _mapController.move(_mapController.camera.center, zoom + 1);
              }),
              const SizedBox(height: 8),
              _MapFab(IconsaxPlusLinear.minus, () {
                final zoom = _mapController.camera.zoom;
                _mapController.move(_mapController.camera.center, zoom - 1);
              }),
            ],
          ),
        ),

        // ── Selected POI card ──
        if (_selectedPoi != null)
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 369),
                child: _PoiCard(
                  poi: _selectedPoi!,
                  onClose: () => setState(() => _selectedPoi = null),
                  onTap: () {
                    if (_selectedPoi?.route != null) {
                      context.push(_selectedPoi!.route!);
                    }
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// Map pin (Figma-style: white bg, colored circle, icon)
// ═══════════════════════════════════════════════
class _MapPin extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool isSelected;

  const _MapPin({
    required this.color,
    required this.icon,
    this.isSelected = false,
  });

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
            color: const Color(0x40000000),
            blurRadius: isSelected ? 6 : 2.29,
            offset: const Offset(0, 2.29),
          ),
        ],
        border: isSelected
            ? Border.all(color: color, width: 2)
            : null,
      ),
      child: Center(
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 13, color: Colors.white),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Map floating action button
// ═══════════════════════════════════════════════
class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapFab(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.midBlue, size: 22),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Selected POI detail card (per-layer layout)
// ═══════════════════════════════════════════════
class _PoiCard extends StatelessWidget {
  final MapPoi poi;
  final VoidCallback onClose;
  final VoidCallback onTap;

  const _PoiCard({
    required this.poi,
    required this.onClose,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top content row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder
                Container(
                  width: 120,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: poi.color.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: Icon(poi.icon, size: 40, color: poi.color),
                  ),
                ),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: SizedBox(
                    height: 140,
                    child: _buildDetails(),
                  ),
                ),
              ],
            ),
          ),
          // View Full Details button
          if (poi.route != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.midBlue,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View Full Details',
                        style: GoogleFonts.inter(
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

  Widget _buildDetails() {
    switch (poi.layer) {
      case 'Real Estate':
        return _buildRealEstateDetails();
      case 'Events':
        return _buildEventDetails();
      case 'Parkings':
        return _buildParkingDetails();
      default:
        return _buildBusinessDetails();
    }
  }

  // ── Restaurant / Business card ──
  Widget _buildBusinessDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          poi.name,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          poi.category,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF5F5E5A),
          ),
        ),
        const SizedBox(height: 8),
        // Address
        if (poi.address != null)
          _infoRow(
            IconsaxPlusLinear.location,
            poi.address!,
            AppColors.turquoise,
          ),
        const Spacer(),
        // Rating
        if (poi.rating != null) ...[
          Row(
            children: [
              const Icon(IconsaxPlusBold.star_1,
                  size: 16, color: Color(0xFFFFC107)),
              const SizedBox(width: 8),
              Text(
                poi.rating!.toString(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${poi.reviewCount ?? 0})',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6D6D6D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        // Views
        if (poi.viewCount != null)
          Row(
            children: [
              const Icon(IconsaxPlusLinear.eye,
                  size: 16, color: AppColors.navy),
              const SizedBox(width: 8),
              Text(
                '${poi.viewCount}',
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
                  color: const Color(0xFF6D6D6D),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ── Real Estate card ──
  Widget _buildRealEstateDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (poi.saleTag != null)
          Text(
            poi.saleTag!,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.turquoise,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          poi.price ?? poi.name,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        // Address
        if (poi.address != null)
          _infoRow(
            IconsaxPlusLinear.location,
            poi.address!,
            AppColors.turquoise,
          ),
        const Spacer(),
        // Area + Rooms row
        Row(
          children: [
            if (poi.area != null) ...[
              const Icon(IconsaxPlusLinear.ruler,
                  size: 14, color: Color(0xFF6D6D6D)),
              const SizedBox(width: 8),
              Text(
                poi.area!,
                style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF3D3D3D)),
              ),
              const SizedBox(width: 16),
            ],
            if (poi.rooms != null) ...[
              const Icon(IconsaxPlusLinear.building_3,
                  size: 14, color: Color(0xFF6D6D6D)),
              const SizedBox(width: 8),
              Text(
                poi.rooms!,
                style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF3D3D3D)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        // Floor
        if (poi.floor != null)
          Row(
            children: [
              const Icon(IconsaxPlusLinear.building,
                  size: 14, color: Color(0xFF6D6D6D)),
              const SizedBox(width: 8),
              Text(
                poi.floor!,
                style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF3D3D3D)),
              ),
            ],
          ),
      ],
    );
  }

  // ── Event card ──
  Widget _buildEventDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          poi.name,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          poi.category,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF5F5E5A),
          ),
        ),
        const SizedBox(height: 8),
        // Time
        if (poi.time != null)
          _infoRow(
            IconsaxPlusLinear.clock,
            poi.time!,
            AppColors.turquoise,
          ),
        const SizedBox(height: 4),
        // Venue
        if (poi.venue != null)
          _infoRow(
            IconsaxPlusLinear.location,
            poi.venue!,
            AppColors.turquoise,
          ),
        const Spacer(),
        // Price + Interested
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (poi.eventPrice != null)
              Text(
                poi.eventPrice!,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
            if (poi.interestedCount != null)
              Row(
                children: [
                  const Icon(IconsaxPlusBold.star_1,
                      size: 16, color: AppColors.turquoise),
                  const SizedBox(width: 4),
                  Text(
                    '${poi.interestedCount} interested',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3D3D3D),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  // ── Parking card (simple) ──
  Widget _buildParkingDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          poi.name,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          poi.category,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF5F5E5A),
          ),
        ),
        const SizedBox(height: 8),
        if (poi.address != null)
          _infoRow(
            IconsaxPlusLinear.location,
            poi.address!,
            AppColors.turquoise,
          ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF5F5E5A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
