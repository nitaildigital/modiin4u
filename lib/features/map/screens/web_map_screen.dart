import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../realestate/models/listing.dart';
import '../../realestate/providers/listing_providers.dart';
import '../../realestate/screens/my_apartments_screen.dart' show formatShekels;
import '../data/map_pois.dart';
import '../providers/map_providers.dart';
import '../../../shared/widgets/web_map_tiles.dart';
import '../../../shared/widgets/network_photo.dart' show sizedPhotoUrl;

const _kAssets = 'assets/web/map';
const _kBorder = Color(0xFFE7E7E7);
const _kGrey = Color(0xFF5F5E5A);
const _kBodyText = Color(0xFF3D3D3D);
const _kIconGrey = Color(0xFF6D6D6D);
const _kPlaceholder = Color(0xFF4F4F4F);

/// How the Figma frame "Map" draws each layer: its line icon in the card, its
/// pin on the map and its colour.
///
/// `mapLayers` keeps the app's own colours, which the phone's map uses; the
/// website follows the design — blue businesses, purple events, green
/// property. The design's fourth layer, Parkings, has no table behind it; see
/// `mapLayers`.
const _layerLook = {
  'Businesses': (
    icon: 'layer_biz.svg',
    pin: 'pin_biz.svg',
    color: Color(0xFF006BF6),
  ),
  'Events': (
    icon: 'layer_events.svg',
    pin: 'pin_events.svg',
    color: Color(0xFF9032E1),
  ),
  'Real Estate': (
    icon: 'layer_re.svg',
    pin: 'pin_re.svg',
    color: Color(0xFF31AC4E),
  ),
};

/// Desktop map page (1920 × 950) — full-bleed OSM map under the 80px header,
/// with the "Explore Modiin" layer card, a centred search pill and a
/// detail slide-over for the selected pin.
class WebMapContent extends ConsumerStatefulWidget {
  const WebMapContent({super.key});

  @override
  ConsumerState<WebMapContent> createState() => _WebMapContentState();
}

class _WebMapContentState extends ConsumerState<WebMapContent>
    with WebLanguageState<WebMapContent> {
  bool get _isHebrew => webIsHebrew.value;
  final _mapController = MapController();
  final _searchController = TextEditingController();

  final _activeLayers = <String>{'Businesses', 'Events', 'Real Estate'};
  MapPoi? _selectedPoi;
  String _query = '';

  /// The same pins the mobile map draws, from the same provider.
  ///
  /// This page used to read a frozen WordPress export and, when that was
  /// empty, fall back to pins written into the source — "Cafe Greg",
  /// "Pizza Prego", "Summer Music Night", four car parks and three
  /// apartments, each with a rating and a review count nobody had given,
  /// and each routing to `/business/demo_2` or `/listing/demo_0`, which
  /// match no row. The events, parking and property layers came from that
  /// list *always*, even when the export had loaded.
  List<MapPoi> get _allPois =>
      ref.watch(mapPoisProvider).valueOrNull ?? const <MapPoi>[];

  String _t(String en, String he) => _isHebrew ? he : en;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _layerLabel(String layer) => switch (layer) {
    'Businesses' => _t('Businesses', 'עסקים'),
    'Events' => _t('Events', 'אירועים'),
    _ => _t('Real Estate', 'נדל״ן'),
  };

  List<MapPoi> get _visiblePois {
    var pois = _allPois.where((p) => _activeLayers.contains(p.layer));
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      pois = pois.where(
        (p) =>
            p.name.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            (p.address ?? '').toLowerCase().contains(q),
      );
    }
    return pois.toList();
  }

  void _selectPoi(MapPoi poi) {
    setState(() => _selectedPoi = poi);
    _mapController.move(poi.position, _mapController.camera.zoom);
  }

  /// The listing behind a property pin, for the fields the pin does not
  /// carry — its type, its storeys, its whole gallery.
  Listing? _listingFor(MapPoi poi) {
    final route = poi.route;
    if (poi.layer != 'Real Estate' || route == null) return null;
    final id = route.split('/').last;
    final rows = ref.watch(allActiveListingsProvider).valueOrNull;
    if (rows == null) return null;
    for (final l in rows) {
      if (l.id == id) return l;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedPoi;
    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
            ),
            Expanded(
              child: Stack(
                children: [
                  _buildMap(),

                  // ── Layer / filter card ──
                  PositionedDirectional(
                    start: 16,
                    top: 16,
                    child: _buildFilterCard(),
                  ),

                  // ── Search pill ──
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(child: _buildSearchBar()),
                  ),

                  // ── Zoom / locate controls ──
                  // Beside the slide while one is open, rather than under it.
                  PositionedDirectional(
                    end: selected == null ? 16 : 16 + 356 + 16,
                    bottom: 24,
                    child: Column(
                      children: [
                        _MapFab(
                          icon: IconsaxPlusLinear.gps,
                          onTap: () => _mapController.move(modiinCenter, 15),
                        ),
                        const SizedBox(height: 12),
                        _MapFab(
                          icon: IconsaxPlusLinear.add,
                          onTap: () => _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom + 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _MapFab(
                          icon: IconsaxPlusLinear.minus,
                          onTap: () => _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom - 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Detail slide-over ──
                  if (selected != null)
                    PositionedDirectional(
                      end: 16,
                      top: 16,
                      bottom: 16,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 832),
                          child: WebMapSlide(
                            // A new pin starts its gallery at the first photo.
                            key: ValueKey(selected),
                            data: _slideData(selected),
                            isHebrew: _isHebrew,
                            onClose: () => setState(() => _selectedPoi = null),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MAP
  // ─────────────────────────────────────────────
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: modiinCenter,
        initialZoom: 15,
        minZoom: 12,
        maxZoom: 18,
        backgroundColor: const Color(0xFFF9F5ED),
        onTap: (_, _) => setState(() => _selectedPoi = null),
      ),
      children: [
        const WebMapTiles(),
        MarkerLayer(
          markers: _visiblePois.map((poi) {
            final look = _layerLook[poi.layer];
            return Marker(
              point: poi.position,
              width: 40,
              height: 44,
              // The pin's point, not its middle, sits on the address.
              alignment: Alignment.topCenter,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _selectPoi(poi),
                  child: AnimatedScale(
                    scale: _selectedPoi == poi ? 1.2 : 1,
                    alignment: Alignment.bottomCenter,
                    duration: const Duration(milliseconds: 150),
                    child: look == null
                        ? Icon(poi.icon, color: poi.color)
                        : WebMapPin(asset: '$_kAssets/${look.pin}'),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const WebMapCredit(),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // FILTER CARD — 275 wide
  // ─────────────────────────────────────────────
  Widget _buildFilterCard() {
    return Container(
      width: 275,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _t('Explore Modiin', 'גלו את מודיעין'),
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 24,
              height: 30 / 24,
              fontWeight: FontWeight.w600,
              color: AppColors.midBlue,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _t(
              'Discover businesses, events and place around the city.',
              'גלו עסקים, אירועים ומקומות ברחבי העיר.',
            ),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              height: 17 / 14,
              color: _kGrey,
            ),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < mapLayers.length; i++)
            _buildLayerRow(mapLayers[i], isLast: i == mapLayers.length - 1),
        ],
      ),
    );
  }

  Widget _buildLayerRow(
    (String, IconData, Color) layer, {
    required bool isLast,
  }) {
    final (name, icon, color) = layer;
    final look = _layerLook[name];
    final isOn = _activeLayers.contains(name);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() {
          if (isOn) {
            _activeLayers.remove(name);
            if (_selectedPoi?.layer == name) _selectedPoi = null;
          } else {
            _activeLayers.add(name);
          }
        }),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.only(top: 16, bottom: isLast ? 0 : 16),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(bottom: BorderSide(color: _kBorder)),
          ),
          child: Row(
            children: [
              if (look != null)
                SvgPicture.asset(
                  '$_kAssets/${look.icon}',
                  width: 20,
                  height: 20,
                )
              else
                Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _layerLabel(name),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    height: 17 / 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              _LayerSwitch(isOn: isOn),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SEARCH PILL — 573 × 52
  // ─────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      width: 573,
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
      ),
      child: Row(
        children: [
          SvgPicture.asset('$_kAssets/search20.svg', width: 20, height: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() {
                _query = v;
                if (_selectedPoi != null &&
                    !_visiblePois.contains(_selectedPoi)) {
                  _selectedPoi = null;
                }
              }),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 16,
                height: 19 / 16,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                // The app theme pads every field; the pill already has its own.
                contentPadding: EdgeInsets.zero,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: _t(
                  'Search for places, businesses, or events',
                  'חיפוש מקומות, עסקים או אירועים',
                ),
                hintStyle: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  height: 19 / 16,
                  color: _kPlaceholder,
                ),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                child: const Icon(
                  IconsaxPlusLinear.close_circle,
                  size: 20,
                  color: _kIconGrey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SLIDE-OVER — what the selected pin says about itself
  // ─────────────────────────────────────────────
  /// The design's "Apartment Slide", filled from whichever row the pin stands
  /// for. A business or an event gets the same card with its own fields.
  WebMapSlideData _slideData(MapPoi poi) {
    final look = _layerLook[poi.layer];
    final color = look?.color ?? poi.color;
    final badgeIcon = look == null ? null : '$_kAssets/${look.icon}';

    final l = _listingFor(poi);
    if (l != null) return webListingSlideData(l, isHebrew: _isHebrew);

    final eventPrice = poi.eventFree ? _t('Free', 'חינם') : poi.eventPrice;

    final rows = switch (poi.layer) {
      // "Property Type: Apartment" was printed for every pin, whatever the
      // listing actually is. Without the listing's row the type is not known,
      // so the line is left out rather than guessed.
      'Real Estate' => [
        if (poi.rooms != null) (_t('Rooms', 'חדרים'), poi.rooms!),
        if (poi.floor != null) (_t('Floor', 'קומה'), poi.floor!),
        if (poi.area != null) (_t('Size', 'שטח'), poi.area!),
      ],
      'Events' => [
        (_t('Category', 'קטגוריה'), _t('Event', 'אירוע')),
        if (poi.venue != null) (_t('Venue', 'מיקום'), poi.venue!),
        if (poi.time != null) (_t('Time', 'שעה'), poi.time!),
        if (eventPrice != null) (_t('Price', 'מחיר'), eventPrice),
      ],
      _ => [
        (_t('Category', 'קטגוריה'), poi.category),
        // Real listings have a rating for only some entries and no review
        // count at all, so both rows appear only when there is something
        // behind them — "Reviews 0" reads as a fact the site never claimed.
        if (poi.rating != null)
          (_t('Rating', 'דירוג'), poi.rating!.toStringAsFixed(1)),
        if (poi.reviewCount != null)
          (_t('Reviews', 'ביקורות'), '${poi.reviewCount}'),
        if (poi.viewCount != null) (_t('Views', 'צפיות'), '${poi.viewCount}'),
      ],
    };

    final facts = switch (poi.layer) {
      'Real Estate' => [?poi.rooms, ?poi.area, ?poi.floor],
      'Events' => [
        _t('Event', 'אירוע'),
        ?poi.time,
        if (poi.interestedCount != null)
          _t(
            '${poi.interestedCount} interested',
            '${poi.interestedCount} מתעניינים',
          ),
      ],
      _ => [
        poi.category,
        if (poi.reviewCount != null)
          _t('${poi.reviewCount} reviews', '${poi.reviewCount} ביקורות'),
      ],
    };

    return WebMapSlideData(
      photos: poi.photos,
      badge: switch (poi.layer) {
        'Real Estate' => _t('Property', 'נכס'),
        'Events' => _t('Event', 'אירוע'),
        _ => poi.category,
      },
      badgeColor: color,
      badgeIcon: badgeIcon,
      headline: poi.price ?? poi.name,
      tag: switch (poi.layer) {
        // Not "FOR SALE" by default — a listing that is let is not for sale.
        'Real Estate' =>
          poi.saleTag == null
              ? null
              : _t(
                  poi.saleTag!,
                  poi.saleTag == 'FOR RENT' ? 'להשכרה' : 'למכירה',
                ),
        'Events' => eventPrice,
        _ => poi.rating == null ? null : '★ ${poi.rating}',
      },
      facts: facts,
      address: poi.address ?? poi.venue,
      aboutTitle: switch (poi.layer) {
        'Real Estate' => _t('About This Property', 'על הנכס'),
        'Events' => _t('About This Event', 'על האירוע'),
        _ => _t('About This Business', 'על העסק'),
      },
      // Only where the row carries a description. It used to compose one
      // when it did not: any property with no text of its own got a
      // paragraph about a "mini penthouse 6 rooms in Avni Chen, 140 m²,
      // balcony 18 m², payment schedule 20/80", every car park was declared
      // open around the clock, and a business with no reviews was described
      // as "rated - by 0 residents".
      about: poi.description,
      details: rows,
      route: poi.route,
    );
  }
}

// ═══════════════════════════════════════════════
// THE SLIDE — the Figma component "Apartment Slide", 356 wide
// ═══════════════════════════════════════════════

/// What the slide shows, whatever kind of row it came from.
class WebMapSlideData {
  final List<String> photos;
  final String badge;
  final Color badgeColor;
  final String? badgeIcon;
  final String headline;
  final String? perMonth;
  final String? tag;
  final List<String> facts;
  final String? address;
  final String aboutTitle;
  final String? about;
  final List<(String, String)> details;
  final String? route;

  const WebMapSlideData({
    required this.photos,
    required this.badge,
    required this.badgeColor,
    required this.badgeIcon,
    required this.headline,
    this.perMonth,
    required this.tag,
    required this.facts,
    required this.address,
    required this.aboutTitle,
    required this.about,
    required this.details,
    required this.route,
  });
}

/// The slide for one listing, from its own row.
WebMapSlideData webListingSlideData(Listing l, {required bool isHebrew}) {
  String t(String en, String he) => isHebrew ? he : en;
  String rooms(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  final type = switch (l.propertyType) {
    PropertyType.apartment => t('Apartment', 'דירה'),
    PropertyType.penthouse => t('Penthouse', 'פנטהאוז'),
    PropertyType.garden => t('Garden Apartment', 'דירת גן'),
    PropertyType.duplex => t('Duplex', 'דופלקס'),
    PropertyType.villa => t('Villa', 'וילה'),
    PropertyType.studio => t('Studio', 'סטודיו'),
    PropertyType.other => t('Property', 'נכס'),
  };
  final price = l.effectivePrice;
  final isRent = l.kind == ListingKind.rent;
  // "2 / 6" where the building's height is on file, "2" where it is not.
  final storey = l.floor == 0 ? t('Ground', 'קרקע') : '${l.floor}';
  final floor = l.floor == null
      ? null
      : (l.totalFloors == null ? storey : '$storey / ${l.totalFloors}');

  return WebMapSlideData(
    photos: [?l.coverUrl, ...l.gallery.where((g) => g != l.coverUrl)],
    badge: type,
    badgeColor: const Color(0xFF31AC4E),
    badgeIcon: '$_kAssets/slide_badge.svg',
    // A listing with no price is not a free one.
    headline: price == null
        ? t('Price on request', 'מחיר לפי בקשה')
        : formatShekels(price),
    perMonth: price != null && isRent ? t('/ In the month', '/ לחודש') : null,
    tag: isRent ? t('FOR RENT', 'להשכרה') : t('FOR SALE', 'למכירה'),
    facts: [
      if (l.rooms != null)
        l.rooms == 1
            ? t('1 Room', 'חדר 1')
            : t('${rooms(l.rooms!)} Rooms', '${rooms(l.rooms!)} חדרים'),
      if (l.sqm != null) t('${l.sqm} m²', '${l.sqm} מ״ר'),
      if (l.floor != null)
        (l.floor == 0
            ? t('Ground Floor', 'קומת קרקע')
            : t('Floor ${l.floor}', 'קומה ${l.floor}')),
    ],
    address: l.address ?? l.neighborhoodName,
    aboutTitle: t('About This Property', 'על הנכס'),
    about: l.description,
    details: [
      (t('Property Type', 'סוג נכס'), type),
      if (l.rooms != null) (t('Rooms', 'חדרים'), rooms(l.rooms!)),
      if (floor != null) (t('Floor', 'קומה'), floor),
      if (l.sqm != null) (t('Size', 'שטח'), t('${l.sqm} m²', '${l.sqm} מ״ר')),
    ],
    route: '/listing/${l.id}',
  );
}

class WebMapSlide extends StatefulWidget {
  final WebMapSlideData data;
  final bool isHebrew;

  /// Draws a × in the card's corner. The card could only be closed by
  /// clicking the map beside it, which nobody guesses.
  final VoidCallback? onClose;
  const WebMapSlide({super.key, required this.data, required this.isHebrew, this.onClose});

  @override
  State<WebMapSlide> createState() => _WebMapSlideState();
}

class _WebMapSlideState extends State<WebMapSlide> {
  int _index = 0;

  String _t(String en, String he) => widget.isHebrew ? he : en;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final card = Container(
      width: 356,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGallery(d.photos),
            const SizedBox(height: 12),
            _buildBadge(d),
            const SizedBox(height: 16),
            _buildHeader(d),
            const SizedBox(height: 24),
            if ((d.about ?? '').isNotEmpty || d.photos.length > 1) ...[
              if ((d.about ?? '').isNotEmpty) ...[
                _sectionTitle(d.aboutTitle),
                const SizedBox(height: 12),
                Text(
                  d.about!,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 12,
                    height: 1.6,
                    color: _kBodyText,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _buildThumbnails(d.photos),
              const SizedBox(height: 24),
            ],
            if (d.details.isNotEmpty) ...[
              _sectionTitle(_t('More Details', 'פרטים נוספים')),
              const SizedBox(height: 12),
              for (var i = 0; i < d.details.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(d.details[i].$1, style: _body),
                    ),
                    Expanded(child: Text(d.details[i].$2, style: _body)),
                  ],
                ),
              ],
              const SizedBox(height: 24),
            ],
            _buildCta(d),
          ],
        ),
      ),
    );
    if (widget.onClose == null) return card;
    return Stack(
      children: [
        card,
        PositionedDirectional(
          top: 24,
          end: 24,
          child: Tooltip(
            message: _t('Close', 'סגירה'),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
                  ),
                  child: const Icon(Icons.close_rounded, size: 18, color: Colors.black87),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  TextStyle get _body => TextStyle(
    fontFamily: AppFonts.inter,
    fontSize: 12,
    height: 15 / 12,
    color: _kBodyText,
  );

  Widget _sectionTitle(String label) => Text(
    label,
    style: TextStyle(
      fontFamily: AppFonts.inter,
      fontSize: 14,
      height: 17 / 14,
      fontWeight: FontWeight.w500,
      color: Colors.black,
    ),
  );

  Widget _photo(String url, double w, double h, double radius) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        sizedPhotoUrl(url, w, 2),
        fit: BoxFit.cover,
        width: w,
        height: h,
        // WordPress serves uploads without CORS headers, so CanvasKit has to
        // hand these to a plain <img>.
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (_, _, _) => _placeholder(w, h, radius),
      ),
    );
  }

  Widget _placeholder(double w, double h, double radius) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0058B5), Color(0xFF010A36)],
      ),
    ),
    child: Icon(
      IconsaxPlusLinear.image,
      size: h / 4,
      color: Colors.white.withValues(alpha: 0.12),
    ),
  );

  /// 324 × 190, with the arrows and the "1 / 18" counter only where there is
  /// more than one photograph to step through. It used to count eighteen
  /// slides for a pin that had none.
  Widget _buildGallery(List<String> photos) {
    final count = photos.length;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(
      width: 324,
      height: 190,
      child: Stack(
        children: [
          Positioned.fill(
            child: count == 0
                ? _placeholder(324, 190, 12)
                : _photo(photos[_index % count], 324, 190, 12),
          ),
          if (count > 1) ...[
            PositionedDirectional(
              end: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xB3000000),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Text(
                  '${_index % count + 1} / $count',
                  // "1 / 18" in either language; a right-to-left run would
                  // print it as "18 / 1".
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 12,
                    height: 15 / 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              start: 10,
              top: 79,
              child: _GalleryArrow(
                // The drawing points forward; back is its mirror image, and
                // in Hebrew forward is to the left.
                flip: !rtl,
                onTap: () =>
                    setState(() => _index = (_index + count - 1) % count),
              ),
            ),
            PositionedDirectional(
              end: 12,
              top: 79,
              child: _GalleryArrow(
                flip: rtl,
                onTap: () => setState(() => _index = (_index + 1) % count),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(WebMapSlideData d) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: d.badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (d.badgeIcon != null) ...[
            SvgPicture.asset(
              d.badgeIcon!,
              width: 14,
              height: 14,
              colorFilter: ColorFilter.mode(d.badgeColor, BlendMode.srcIn),
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              d.badge,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 12,
                height: 15 / 12,
                fontWeight: FontWeight.w500,
                color: d.badgeColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(WebMapSlideData d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                d.headline,
                style: TextStyle(
                  fontFamily: AppFonts.nunito,
                  fontSize: 20,
                  height: 25 / 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (d.perMonth != null) ...[
              const SizedBox(width: 8),
              Text(
                d.perMonth!,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  height: 17 / 14,
                  color: _kGrey,
                ),
              ),
            ],
            const Spacer(),
            if (d.tag != null) ...[
              const SizedBox(width: 12),
              Text(
                d.tag!,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 12,
                  height: 15 / 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.turquoise,
                ),
              ),
            ],
          ],
        ),
        if (d.facts.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 30,
            runSpacing: 6,
            children: [for (final f in d.facts) Text(f, style: _body)],
          ),
        ],
        if (d.address != null && d.address!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                '$_kAssets/slide_pin.svg',
                width: 14,
                height: 14,
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(d.address!, style: _body)),
            ],
          ),
        ],
      ],
    );
  }

  /// Up to four more photographs, the last carrying how many are left. Only
  /// the ones there are: the row used to be filled out with coloured panels
  /// and a "+14" that counted nothing.
  Widget _buildThumbnails(List<String> photos) {
    final thumbs = photos.skip(1).take(4).toList();
    if (thumbs.isEmpty) return const SizedBox.shrink();
    final hidden = photos.length - 1 - thumbs.length;
    return Row(
      children: [
        for (var i = 0; i < thumbs.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _index = i + 1),
              child: SizedBox(
                width: 75,
                height: 75,
                child: Stack(
                  children: [
                    Positioned.fill(child: _photo(thumbs[i], 75, 75, 7.2)),
                    if (i == thumbs.length - 1 && hidden > 0)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0x80000000),
                            borderRadius: BorderRadius.circular(7.2),
                          ),
                          child: Center(
                            child: Text(
                              '+${hidden + 1}',
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 16,
                                height: 19 / 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
        ],
      ],
    );
  }

  Widget _buildCta(WebMapSlideData d) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (d.route != null) context.push(d.route!);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.midBlue,
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _t('View Full Details', 'לפרטים המלאים'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 24 / 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Transform.flip(
                flipX: rtl,
                child: SvgPicture.asset(
                  '$_kAssets/slide_cta.svg',
                  width: 20,
                  height: 20,
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
// Shared bits
// ═══════════════════════════════════════════════

/// One of the design's teardrop pins, with its drop shadow.
///
/// The SVG carries the shadow as a filter, which flutter_svg does not draw,
/// so the same shape is laid underneath, darkened and blurred.
class WebMapPin extends StatelessWidget {
  final String asset;
  const WebMapPin({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 44,
      child: Stack(
        children: [
          Transform.translate(
            offset: const Offset(0, 2.3),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 1.1, sigmaY: 1.1),
              child: SvgPicture.asset(
                asset,
                width: 40,
                colorFilter: const ColorFilter.mode(
                  Color(0x40000000),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          SvgPicture.asset(asset, width: 40),
        ],
      ),
    );
  }
}

/// 44 × 24 pill switch used by the layer rows.
class _LayerSwitch extends StatelessWidget {
  final bool isOn;
  const _LayerSwitch({required this.isOn});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 44,
      height: 24,
      padding: const EdgeInsets.all(2),
      alignment: isOn
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        color: isOn ? AppColors.midBlue : const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// The white rounded square over the gallery, 32 across, with the design's
/// arrow in it.
class _GalleryArrow extends StatelessWidget {
  final bool flip;
  final VoidCallback onTap;
  const _GalleryArrow({required this.flip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Transform.flip(
            flipX: flip,
            child: SvgPicture.asset(
              '$_kAssets/slide_arrow.svg',
              width: 16,
              height: 16,
            ),
          ),
        ),
      ),
    );
  }
}

/// 44 × 44 white map control button.
class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapFab({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
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
          child: Icon(icon, size: 22, color: AppColors.midBlue),
        ),
      ),
    );
  }
}
