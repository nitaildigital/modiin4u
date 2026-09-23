import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/theme/app_colors.dart';

import '../../../shared/widgets/network_photo.dart';
import '../data/map_pois.dart';
import '../providers/map_providers.dart';
import '../widgets/map_pin_bitmap.dart';
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
class _MobileMapContent extends ConsumerStatefulWidget {
  const _MobileMapContent();

  @override
  ConsumerState<_MobileMapContent> createState() => _MobileMapContentState();
}

class _MobileMapContentState extends ConsumerState<_MobileMapContent> {
  final _activeLayers = <String>{'Businesses'};
  gmaps.GoogleMapController? _mapController;
  MapPoi? _selectedPoi;
  String _mapSearchQuery = '';

  /// Markers are bitmaps that have to be drawn before the map can show them,
  /// so they are built off to the side and the map picks them up on the next
  /// frame. Keyed by the POI's route, which is unique per pin.
  Map<String, gmaps.Marker> _markers = {};
  int _markerBuild = 0;

  /// Set when the selected pin changes, since that alters how it is drawn
  /// without changing which pins are on screen.
  bool _pinsNeedRedraw = false;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Redraws the marker set. Each call takes a ticket, and a build that
  /// finishes after a newer one started throws its result away rather than
  /// overwriting it.
  Future<void> _rebuildMarkers(List<MapPoi> pois) async {
    final ticket = ++_markerBuild;
    final ratio = MediaQuery.devicePixelRatioOf(context);

    final built = <String, gmaps.Marker>{};
    for (final poi in pois) {
      final icon = await MapPinBitmap.of(
        color: poi.color,
        icon: poi.icon,
        isSelected: _selectedPoi == poi,
        devicePixelRatio: ratio,
      );
      // `route` is nullable, and a pin still needs an id; the name and
      // position are unique enough to stand in.
      final id = poi.route ?? '${poi.name}@${poi.position}';
      built[id] = gmaps.Marker(
        markerId: gmaps.MarkerId(id),
        position: gmaps.LatLng(poi.position.latitude, poi.position.longitude),
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        onTap: () => setState(() {
          _selectedPoi = poi;
          _pinsNeedRedraw = true;
        }),
      );
    }

    if (!mounted || ticket != _markerBuild) return;
    setState(() => _markers = built);
  }

  static const _layers = [
    ('Businesses', IconsaxPlusBold.shop, Color(0xFF17A9D0)),
    ('Events', IconsaxPlusBold.calendar_1, Color(0xFF9032E1)),
    ('Parkings', IconsaxPlusBold.car, Color(0xFF31AC4E)),
    ('Real Estate', IconsaxPlusBold.house_2, Color(0xFF006BF6)),
  ];

  List<MapPoi> get _visiblePois {
    // Pins come from the database; an empty list while it loads simply means
    // no markers yet, which is what the map should show.
    final all = ref.watch(mapPoisProvider).valueOrNull ?? const <MapPoi>[];
    var pois = all.where((p) => _activeLayers.contains(p.layer));
    if (_mapSearchQuery.isNotEmpty) {
      final q = _mapSearchQuery.toLowerCase();
      pois = pois.where(
        (p) =>
            p.name.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q),
      );
    }
    return pois.toList();
  }

  @override
  Widget build(BuildContext context) {
    // Drawing a marker is asynchronous, so it cannot happen during build; the
    // set is refreshed just after, and only when it has actually changed.
    final pois = _visiblePois;
    final wanted = {for (final p in pois) p.route ?? '${p.name}@${p.position}'};
    if (!setEquals(wanted, _markers.keys.toSet()) || _pinsNeedRedraw) {
      _pinsNeedRedraw = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _rebuildMarkers(pois);
      });
    }

    return Stack(
      children: [
        // ── Map ──
        gmaps.GoogleMap(
          initialCameraPosition: gmaps.CameraPosition(
            target: gmaps.LatLng(modiinCenter.latitude, modiinCenter.longitude),
            zoom: 15,
          ),
          minMaxZoomPreference: const gmaps.MinMaxZoomPreference(12, 18),
          markers: _markers.values.toSet(),
          onMapCreated: (c) => _mapController = c,
          onTap: (_) => setState(() {
            _selectedPoi = null;
            _pinsNeedRedraw = true;
          }),
          // The screen draws its own search bar, chips and buttons over the
          // map, so Google's are turned off rather than stacked under them.
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          // The card sits at the foot of the screen; this keeps Google's
          // required attribution above it rather than behind it.
          padding: EdgeInsets.only(bottom: _selectedPoi == null ? 0 : 280),
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
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'חיפוש מקומות, עסקים ואירועים',
                              hintStyle: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
                                color: const Color(0xFF6D6D6D),
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
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
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              label,
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
                _mapController?.animateCamera(
                  gmaps.CameraUpdate.newLatLngZoom(
                    gmaps.LatLng(modiinCenter.latitude, modiinCenter.longitude),
                    15,
                  ),
                );
              }),
              const SizedBox(height: 8),
              _MapFab(IconsaxPlusLinear.add, () {
                _mapController?.animateCamera(gmaps.CameraUpdate.zoomIn());
              }),
              const SizedBox(height: 8),
              _MapFab(IconsaxPlusLinear.minus, () {
                _mapController?.animateCamera(gmaps.CameraUpdate.zoomOut());
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
                NetworkPhoto(
                  url: poi.photos.isEmpty ? null : poi.photos.first,
                  width: 120,
                  height: 140,
                  radius: BorderRadius.circular(8),
                  gradient: [
                    poi.color.withValues(alpha: 0.16),
                    poi.color.withValues(alpha: 0.08),
                  ],
                  icon: poi.icon,
                  iconSize: 40,
                  iconColor: poi.color,
                ),
                const SizedBox(width: 12),
                // Details
                Expanded(child: SizedBox(height: 140, child: _buildDetails())),
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
                        'לפרטים מלאים',
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
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
          style: TextStyle(
            fontFamily: AppFonts.inter,
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
          style: TextStyle(
            fontFamily: AppFonts.inter,
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
              const Icon(
                IconsaxPlusBold.star_1,
                size: 16,
                color: Color(0xFFFFC107),
              ),
              const SizedBox(width: 8),
              Text(
                poi.rating!.toString(),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${poi.reviewCount ?? 0})',
                style: TextStyle(
                  fontFamily: AppFonts.inter,
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
              const Icon(
                IconsaxPlusLinear.eye,
                size: 16,
                color: AppColors.navy,
              ),
              const SizedBox(width: 8),
              Text(
                '${poi.viewCount}',
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Views',
                style: TextStyle(
                  fontFamily: AppFonts.inter,
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
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.turquoise,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          poi.price ?? poi.name,
          style: TextStyle(
            fontFamily: AppFonts.inter,
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
              const Icon(
                IconsaxPlusLinear.ruler,
                size: 14,
                color: Color(0xFF6D6D6D),
              ),
              const SizedBox(width: 8),
              Text(
                poi.area!,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 12,
                  color: const Color(0xFF3D3D3D),
                ),
              ),
              const SizedBox(width: 16),
            ],
            if (poi.rooms != null) ...[
              const Icon(
                IconsaxPlusLinear.building_3,
                size: 14,
                color: Color(0xFF6D6D6D),
              ),
              const SizedBox(width: 8),
              Text(
                poi.rooms!,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 12,
                  color: const Color(0xFF3D3D3D),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        // Floor
        if (poi.floor != null)
          Row(
            children: [
              const Icon(
                IconsaxPlusLinear.building,
                size: 14,
                color: Color(0xFF6D6D6D),
              ),
              const SizedBox(width: 8),
              Text(
                poi.floor!,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 12,
                  color: const Color(0xFF3D3D3D),
                ),
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
          style: TextStyle(
            fontFamily: AppFonts.inter,
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
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            color: const Color(0xFF5F5E5A),
          ),
        ),
        const SizedBox(height: 8),
        // Time
        if (poi.time != null)
          _infoRow(IconsaxPlusLinear.clock, poi.time!, AppColors.turquoise),
        const SizedBox(height: 4),
        // Venue
        if (poi.venue != null)
          _infoRow(IconsaxPlusLinear.location, poi.venue!, AppColors.turquoise),
        const Spacer(),
        // Price + Interested
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (poi.eventPrice != null)
              Text(
                poi.eventPrice!,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
            if (poi.interestedCount != null)
              Row(
                children: [
                  const Icon(
                    IconsaxPlusBold.star_1,
                    size: 16,
                    color: AppColors.turquoise,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${poi.interestedCount} מתעניינים',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
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
          style: TextStyle(
            fontFamily: AppFonts.inter,
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
          style: TextStyle(
            fontFamily: AppFonts.inter,
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
            style: TextStyle(
              fontFamily: AppFonts.inter,
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
