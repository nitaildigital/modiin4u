import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

import '../../../shared/widgets/network_photo.dart';
import '../data/map_pois.dart';
import '../providers/map_providers.dart';
import '../../../shared/widgets/app_map.dart';
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

const _kNavy = Color(0xFF0A1230);
const _kGrey = Color(0xFF5F5E5A);
const _kBodyText = Color(0xFF3D3D3D);
const _kHint = Color(0xFF6D6D6D);
const _kBorder = Color(0xFFE7E7E7);
const _kTurquoise = Color(0xFF17A9D0);

/// The frame's shadow on the search bar, the chips and the card.
const _kShadow = [
  BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
];

/// How the Figma frame "Map" (521:4754) draws each layer, in its order: the
/// pin, and the colour behind a photo that is missing.
///
/// The frame's colours — blue businesses, purple events, turquoise parking,
/// green property — are the ones the website's map already follows. The
/// phone had drawn businesses turquoise and property blue from `mapLayers`,
/// which would now have made a business and a car park the same colour.
const _phoneLayers = [
  (
    layer: 'Businesses',
    pin: 'assets/web/map/pin_biz.svg',
    color: Color(0xFF006BF6),
  ),
  (
    layer: 'Events',
    pin: 'assets/web/map/pin_events.svg',
    color: Color(0xFF9032E1),
  ),
  (
    layer: 'Parkings',
    pin: 'assets/web/map/pin_parking.svg',
    color: Color(0xFF17A9D0),
  ),
  (
    layer: 'Real Estate',
    pin: 'assets/web/map/pin_re.svg',
    color: Color(0xFF31AC4E),
  ),
];

({String layer, String pin, Color color}) _lookOf(String layer) =>
    _phoneLayers.firstWhere(
      (l) => l.layer == layer,
      orElse: () => _phoneLayers.first,
    );

// ═══════════════════════════════════════════════
// Mobile Map Screen
// ═══════════════════════════════════════════════
class _MobileMapContent extends ConsumerStatefulWidget {
  const _MobileMapContent();

  @override
  ConsumerState<_MobileMapContent> createState() => _MobileMapContentState();
}

class _MobileMapContentState extends ConsumerState<_MobileMapContent> {
  /// Every layer on, as the frame draws it.
  final _activeLayers = <String>{for (final l in _phoneLayers) l.layer};
  MapPoi? _selectedPoi;
  String _mapSearchQuery = '';

  static String _markerId(MapPoi poi) =>
      poi.route ?? '${poi.name}@${poi.position}';

  static String _layerLabel(BuildContext context, String layer) {
    final l = L.of(context);
    return switch (layer) {
      'Businesses' => l.mapLayerBusinesses,
      'Events' => l.mapLayerEvents,
      'Parkings' => l.mapLayerParkings,
      _ => l.mapLayerRealEstate,
    };
  }

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
            (p.nameEn ?? '').toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            (p.address ?? '').toLowerCase().contains(q),
      );
    }
    return pois.toList();
  }

  void _toggleLayer(String layer) {
    setState(() {
      if (!_activeLayers.remove(layer)) _activeLayers.add(layer);
      if (_selectedPoi?.layer == layer) _selectedPoi = null;
    });
  }

  void _clearSelection() => setState(() => _selectedPoi = null);

  @override
  Widget build(BuildContext context) {
    final pois = _visiblePois;

    return Stack(
      children: [
        // ── Map ──
        // Google's map (AppMap): the native widget in the app, Google's
        // tiles in a browser — where the app widget drew a grey page, since
        // the website does not load Google's script. The frame has no buttons
        // over the map; pinching zooms.
        AppMap(
          center: modiinCenter,
          zoom: 15,
          minZoom: 12,
          maxZoom: 18,
          selectedId: _selectedPoi == null ? null : _markerId(_selectedPoi!),
          onSelect: (id) => setState(() {
            _selectedPoi = id == null
                ? null
                : pois.where((p) => _markerId(p) == id).firstOrNull;
          }),
          // The card sits at the foot of the screen; this keeps Google's
          // required attribution above it rather than behind it.
          bottomPadding: _selectedPoi == null ? 0 : 250,
          pins: [
            for (final poi in pois)
              AppMapPin(
                id: _markerId(poi),
                position: poi.position,
                asset: _lookOf(poi.layer).pin,
              ),
          ],
        ),

        // ── Search bar + layer chips ──
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SearchBar(
                  hint: L.of(context).mapSearchHint,
                  onChanged: (val) => setState(() {
                    _mapSearchQuery = val.trim();
                    _selectedPoi = null;
                  }),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                // Room for the chips' shadow, which a list clips at its edge.
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  itemCount: _phoneLayers.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final layer = _phoneLayers[index].layer;
                    // The layer key a pin carries stays English in the data
                    // and is translated only where it is drawn.
                    return _LayerChip(
                      label: _layerLabel(context, layer),
                      isOn: _activeLayers.contains(layer),
                      onTap: () => _toggleLayer(layer),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        
        // ── Selected pin's card ──
        if (_selectedPoi != null)
          Positioned(
            bottom: 16,
            left: 12,
            right: 12,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 369),
                child: _PoiCard(
                  poi: _selectedPoi!,
                  onClose: _clearSelection,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// Search bar
// ═══════════════════════════════════════════════
class _SearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: _kBorder),
        boxShadow: _kShadow,
      ),
      child: Row(
        children: [
          const Icon(
            IconsaxPlusLinear.search_normal_1,
            size: 18,
            color: _kHint,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                color: _kNavy,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: _kHint,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Layer chip — the frame's checkbox button
// ═══════════════════════════════════════════════
class _LayerChip extends StatelessWidget {
  final String label;
  final bool isOn;
  final VoidCallback onTap;

  const _LayerChip({
    required this.label,
    required this.isOn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder),
          boxShadow: _kShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The frame draws only the ticked box; unticked is the same
            // square, outlined.
            if (isOn)
              SvgPicture.asset(
                'assets/icons/m_map_checkbox_on.svg',
                width: 18,
                height: 18,
              )
            else
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFBDBDBD), width: 1.5),
                ),
              ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _kNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Selected pin's card — the frame's "Map Card Overlay", per layer
// ═══════════════════════════════════════════════
class _PoiCard extends StatelessWidget {
  final MapPoi poi;
  final VoidCallback onClose;

  const _PoiCard({required this.poi, required this.onClose});

  bool get _isParking => poi.layer == 'Parkings';

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final look = _lookOf(poi.layer);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _kShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                height: 140,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: NetworkPhoto(
                        url: poi.photos.isEmpty ? null : poi.photos.first,
                        width: 120,
                        height: 140,
                        radius: BorderRadius.circular(8),
                        gradient: [
                          look.color.withValues(alpha: 0.16),
                          look.color.withValues(alpha: 0.08),
                        ],
                        icon: poi.icon,
                        iconSize: 40,
                        iconColor: look.color,
                      ),
                    ),
                    // Not in the frame, but a card over a map needs a way off
                    // it besides guessing to tap the map; the restaurants map
                    // and the website's card have the same one.
                    PositionedDirectional(
                      end: 4,
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
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: _kBodyText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 140,
                  child: switch (poi.layer) {
                    'Real Estate' => _realEstateDetails(l),
                    'Events' => _eventDetails(l),
                    'Parkings' => _parkingDetails(context, l),
                    _ => _businessDetails(),
                  },
                ),
              ),
            ],
          ),
          if (_isParking || poi.route != null) ...[
            const SizedBox(height: 12),
            _isParking
                ? _CardButton(
                    label: l.getDirections,
                    // As the business page does: Waze, which people here
                    // drive with, from the lot's own coordinates.
                    onTap: () => launchUrl(
                      Uri.parse(
                        'https://waze.com/ul?ll=${poi.position.latitude},'
                        '${poi.position.longitude}&navigate=yes',
                      ),
                    ),
                  )
                : _CardButton(
                    label: l.viewFullDetails,
                    onTap: () => context.push(poi.route!),
                  ),
          ],
        ],
      ),
    );
  }

  // ── Business — as "Map Card Overlay 3 Restaurant" ──
  Widget _businessDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(poi.name),
        const SizedBox(height: 8),
        _subtitle(poi.category),
        if (poi.address != null) ...[
          const SizedBox(height: 11),
          _infoRow(IconsaxPlusBold.location, poi.address!),
        ],
        const Spacer(),
        // Only where reviews have earned one; the provider leaves it null
        // otherwise.
        if (poi.rating != null)
          Row(
            children: [
              const Icon(
                IconsaxPlusBold.star_1,
                size: 16,
                color: Color(0xFFFFC107),
              ),
              const SizedBox(width: 8),
              Text(
                poi.rating!.toStringAsFixed(1),
                style: _inter(14, weight: FontWeight.w500, color: Colors.black),
              ),
              const SizedBox(width: 8),
              Text('(${poi.reviewCount ?? 0})', style: _inter(14, color: _kHint)),
            ],
          ),
      ],
    );
  }

  // ── Property — as "Map Card Overlay" ──
  Widget _realEstateDetails(L l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (poi.saleTag != null) ...[
          Text(
            (poi.saleTag == 'FOR RENT' ? l.forRent : l.forSale).toUpperCase(),
            style: _inter(12, weight: FontWeight.w500, color: _kTurquoise),
          ),
          const SizedBox(height: 8),
        ],
        _title(poi.price ?? poi.name),
        if (poi.address != null) ...[
          const SizedBox(height: 11),
          _infoRow(IconsaxPlusBold.location, poi.address!),
        ],
        const SizedBox(height: 11),
        // Worded here from the figures, not from the pin's `area`/`rooms`/
        // `floor`: those are English, and in Hebrew "7 Rooms" read back to
        // front as "Rooms 7".
        Row(
          children: [
            if (poi.sqm != null) ...[
              _stat(
                'assets/icons/m_map_card_area.svg',
                '${poi.sqm} ${l.sqmUnit}',
              ),
              const SizedBox(width: 16),
            ],
            if (poi.roomCount != null)
              _stat('assets/icons/m_map_card_rooms.svg', _roomsText(l)),
          ],
        ),
        if (poi.floorNumber != null) ...[
          const SizedBox(height: 16),
          _stat(
            'assets/icons/m_map_card_floor.svg',
            l.floorLabel('${poi.floorNumber}'),
          ),
        ],
      ],
    );
  }

  /// "3.5 rooms" / "3.5 חדרים". Half rooms are normal here, and the string
  /// takes a whole number, so a half is put in place of its figure.
  String _roomsText(L l) {
    final rooms = poi.roomCount!;
    if (rooms == rooms.roundToDouble()) return l.rooms(rooms.toInt());
    return l.rooms(0).replaceFirst('0', '$rooms');
  }

  // ── Event — as "Map Card Overlay 3 Event" ──
  Widget _eventDetails(L l) {
    final interested = poi.interestedCount ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(poi.name),
        const SizedBox(height: 8),
        _subtitle(l.event),
        if (poi.time != null) ...[
          const SizedBox(height: 11),
          _infoRow(IconsaxPlusBold.clock, poi.time!),
        ],
        if (poi.venue != null) ...[
          const SizedBox(height: 11),
          _infoRow(IconsaxPlusBold.location, poi.venue!),
        ],
        const Spacer(),
        Row(
          children: [
            if (poi.eventFree || poi.eventPrice != null)
              Expanded(
                child: Text(
                  poi.eventFree ? l.free : poi.eventPrice!,
                  style: _display(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              const Spacer(),
            // Counted from RSVPs; nobody yet is left unsaid rather than
            // printed as "0 interested".
            if (interested > 0) ...[
              const Icon(IconsaxPlusBold.star_1, size: 16, color: _kTurquoise),
              const SizedBox(width: 4),
              Text(
                l.eventInterestedCount(interested),
                style: _inter(12, weight: FontWeight.w500, color: _kBodyText),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ── Parking — no frame of its own; the business card's layout, with the
  // lot's price and spaces where a rating would be. Each line only where the
  // client filled it in ──
  Widget _parkingDetails(BuildContext context, L l) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final lot = parkingLotOfPoi[poi];
    // "Free" only when he ticked it; a lot he said nothing about gets no
    // price at all rather than a guess.
    final price = lot?.isFree == true ? l.free : lot?.priceNote;
    final capacity = lot?.capacity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(lot?.displayName(english: english) ?? poi.name),
        if (poi.address != null) ...[
          const SizedBox(height: 11),
          _infoRow(IconsaxPlusBold.location, poi.address!),
        ],
        if (lot?.hours != null) ...[
          const SizedBox(height: 8),
          _infoRow(IconsaxPlusBold.clock, lot!.hours!),
        ],
        if (poi.description != null) ...[
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              poi.description!,
              style: _inter(12, color: _kGrey, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        const Spacer(),
        Row(
          children: [
            if (price != null)
              Expanded(
                child: Text(
                  price,
                  style: _inter(14, weight: FontWeight.w600, color: _kNavy),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              const Spacer(),
            if (capacity != null) ...[
              const SizedBox(width: 8),
              const Icon(IconsaxPlusBold.car, size: 14, color: _kTurquoise),
              const SizedBox(width: 4),
              Text(
                l.parkingSpaces(capacity),
                style: _inter(12, weight: FontWeight.w500, color: _kBodyText),
              ),
            ],
          ],
        ),
      ],
    );
  }

  static TextStyle _inter(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = _kGrey,
    double? height,
  }) => TextStyle(
    fontFamily: AppFonts.inter,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );

  /// "Avenir Next Rounded Pro Demi" in the frames, which the app does not
  /// ship; Nunito stands in, as on the restaurants map.
  static TextStyle _display() => TextStyle(
    fontFamily: AppFonts.nunito,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 25 / 20,
    color: _kNavy,
  );

  Widget _title(String text) =>
      Text(text, style: _display(), maxLines: 1, overflow: TextOverflow.ellipsis);

  Widget _subtitle(String text) => Text(
    text,
    style: _inter(14),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _kTurquoise),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: _inter(12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _stat(String asset, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(asset, width: 14, height: 14),
        const SizedBox(width: 8),
        Text(text, style: _inter(12, color: _kBodyText)),
      ],
    );
  }
}

class _CardButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CardButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.midBlue,
          borderRadius: BorderRadius.circular(60),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            // The frame's arrow — the same file the events map's card uses —
            // pointing forward: → in English, ← in Hebrew.
            Transform.flip(
              flipX: Directionality.of(context) == TextDirection.rtl,
              child: SvgPicture.asset(
                'assets/icons/m_events_arrow.svg',
                width: 16,
                height: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
