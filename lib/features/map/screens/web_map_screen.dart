import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../data/map_pois.dart';
import '../../../shared/widgets/web_chrome.dart';

const _kBorder = Color(0xFFE7E7E7);
const _kGrey = Color(0xFF5F5E5A);
const _kBodyText = Color(0xFF3D3D3D);
const _kIconGrey = Color(0xFF6D6D6D);
const _kPlaceholder = Color(0xFF4F4F4F);

/// Desktop map page (1920 × 950) — full-bleed OSM map under the 80px header,
/// with the "Explore Modiin" layer card, a centred search pill and a
/// detail slide-over for the selected pin.
class WebMapContent extends StatefulWidget {
  const WebMapContent({super.key});

  @override
  State<WebMapContent> createState() => _WebMapContentState();
}

class _WebMapContentState extends State<WebMapContent> {
  bool _isHebrew = false;
  final _mapController = MapController();
  final _searchController = TextEditingController();

  final _activeLayers = <String>{
    'Businesses',
    'Events',
    'Parkings',
    'Real Estate',
  };
  MapPoi? _selectedPoi;
  String _query = '';
  int _slideIndex = 0;

  /// Real business pins from the WordPress export. Empty until the asset
  /// loads and empty if it fails, in which case the demo pins stand in.
  List<MapPoi> _businessPois = const [];

  @override
  void initState() {
    super.initState();
    loadBusinessPois().then((pois) {
      if (mounted) setState(() => _businessPois = pois);
    });
  }

  /// Real listings replace the demo pins on the Businesses layer only —
  /// events, parking and real estate have no exported source yet.
  List<MapPoi> get _allPois => _businessPois.isEmpty
      ? mapPois
      : [
          ..._businessPois,
          ...mapPois.where((p) => p.layer != 'Businesses'),
        ];

  String _t(String en, String he) => _isHebrew ? he : en;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Nav links ──
  String _layerLabel(String layer) => switch (layer) {
    'Businesses' => _t('Businesses', 'עסקים'),
    'Events' => _t('Events', 'אירועים'),
    'Parkings' => _t('Parkings', 'חניונים'),
    _ => _t('Real Estate', 'נדל"ן'),
  };

  List<MapPoi> get _visiblePois {
    var pois = _allPois.where((p) => _activeLayers.contains(p.layer));
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      pois = pois.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          (p.address ?? '').toLowerCase().contains(q));
    }
    return pois.toList();
  }

  void _selectPoi(MapPoi poi) {
    setState(() {
      _selectedPoi = poi;
      _slideIndex = 0;
    });
    _mapController.move(poi.position, _mapController.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
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
                  PositionedDirectional(
                    end: 16,
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
                  if (_selectedPoi != null)
                    PositionedDirectional(
                      end: 16,
                      top: 16,
                      bottom: 16,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 832),
                          child: _buildSlideCard(_selectedPoi!),
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
  // HEADER — 1920 × 80
  // ─────────────────────────────────────────────
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
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.modiin4u.app',
          maxZoom: 19,
        ),
        MarkerLayer(
          markers: _visiblePois.map((poi) {
            return Marker(
              point: poi.position,
              width: 40,
              height: 40,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _selectPoi(poi),
                  child: _MapPin(
                    color: poi.color,
                    icon: poi.icon,
                    isSelected: _selectedPoi == poi,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // FILTER CARD — 275 × 345
  // ─────────────────────────────────────────────
  Widget _buildFilterCard() {
    return Container(
      width: 275,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 8),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('Explore Modiin', 'גלו את מודיעין'),
            style: TextStyle(fontFamily: AppFonts.nunito, 
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 30 / 24,
              color: AppColors.midBlue,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _t(
              'Discover businesses, events and place around the city.',
              'גלו עסקים, אירועים ומקומות ברחבי העיר.',
            ),
            style: TextStyle(fontFamily: AppFonts.inter, 
              fontSize: 14,
              fontWeight: FontWeight.w400,
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

  Widget _buildLayerRow((String, IconData, Color) layer, {required bool isLast}) {
    final (name, icon, color) = layer;
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
          width: 235,
          padding: EdgeInsets.only(top: 16, bottom: isLast ? 0 : 16),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(bottom: BorderSide(color: _kBorder)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 20, color: color),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _layerLabel(name),
                        style: TextStyle(fontFamily: AppFonts.inter, 
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 17 / 14,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          const Icon(IconsaxPlusLinear.search_normal_1, size: 20, color: _kIconGrey),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() {
                _query = v;
                if (_selectedPoi != null && !_visiblePois.contains(_selectedPoi)) {
                  _selectedPoi = null;
                }
              }),
              style: TextStyle(fontFamily: AppFonts.inter, 
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 19 / 16,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: _t(
                  'Search for places, businesses, or events',
                  'חיפוש מקומות, עסקים או אירועים',
                ),
                hintStyle: TextStyle(fontFamily: AppFonts.inter, 
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
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
                child: const Icon(IconsaxPlusLinear.close_circle,
                    size: 20, color: _kIconGrey),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SLIDE-OVER CARD — 356 wide
  // ─────────────────────────────────────────────
  Widget _buildSlideCard(MapPoi poi) {
    return Container(
      width: 356,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 8),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gallery + header ──
            _buildGallery(poi),
            const SizedBox(height: 12),
            _buildTypeBadge(poi),
            const SizedBox(height: 16),
            _buildHeaderBlock(poi),
            const SizedBox(height: 24),

            // ── About ──
            _sectionTitle(_aboutTitle(poi)),
            const SizedBox(height: 12),
            Text(
              _aboutText(poi),
              style: TextStyle(fontFamily: AppFonts.inter, 
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.6,
                color: _kBodyText,
              ),
            ),
            const SizedBox(height: 12),
            _buildThumbnails(poi),
            const SizedBox(height: 24),

            // ── More details ──
            _sectionTitle(_t('More Details', 'פרטים נוספים')),
            const SizedBox(height: 12),
            ..._detailRows(poi),
            const SizedBox(height: 24),

            // ── CTA ──
            _buildCta(poi),
          ],
        ),
      ),
    );
  }

  Widget _buildGallery(MapPoi poi) {
    final colors = _galleryColors(poi);
    final photos = poi.photos;
    // Demo POIs have no photos and kept a hard-coded 18-slide counter.
    final slideCount = photos.isEmpty ? 18 : photos.length;
    return SizedBox(
      width: 324,
      height: 190,
      child: Stack(
        children: [
          Positioned.fill(
            child: photos.isEmpty
                ? _imagePlaceholder(colors[_slideIndex % colors.length], radius: 12, glyphSize: 44)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      photos[_slideIndex % photos.length],
                      fit: BoxFit.cover,
                      width: 324,
                      height: 190,
                      // WordPress serves uploads without CORS headers, so
                      // CanvasKit has to hand these to a plain <img>.
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      errorBuilder: (_, _, _) => _imagePlaceholder(
                          colors[_slideIndex % colors.length], radius: 12, glyphSize: 44),
                    ),
                  ),
          ),
          // Slide counter
          Positioned(
            left: 258,
            top: 151,
            child: Container(
              height: 27,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xB3000000),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Text(
                '${_slideIndex % slideCount + 1} / $slideCount',
                style: TextStyle(fontFamily: AppFonts.inter, 
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 15 / 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Prev / next arrows
          Positioned(
            left: 10,
            top: 79,
            child: _GalleryArrow(
              icon: Icons.chevron_left,
              onTap: () => setState(() => _slideIndex = (_slideIndex + slideCount - 1) % slideCount),
            ),
          ),
          Positioned(
            left: 280,
            top: 79,
            child: _GalleryArrow(
              icon: Icons.chevron_right,
              onTap: () => setState(() => _slideIndex = (_slideIndex + 1) % slideCount),
            ),
          ),
          // Close
          Positioned(
            right: 10,
            top: 10,
            child: _GalleryArrow(
              icon: Icons.close,
              onTap: () => setState(() => _selectedPoi = null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(MapPoi poi) {
    final label = switch (poi.layer) {
      'Real Estate' => _t('Apartment', 'דירה'),
      'Events' => _t('Event', 'אירוע'),
      'Parkings' => _t('Parking', 'חניון'),
      _ => poi.category,
    };
    return Container(
      height: 27,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: poi.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(poi.icon, size: 14, color: poi.color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontFamily: AppFonts.inter, 
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 15 / 12,
              color: poi.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBlock(MapPoi poi) {
    final facts = _facts(poi);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                poi.price ?? poi.name,
                style: TextStyle(fontFamily: AppFonts.nunito, 
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 25 / 20,
                  color: AppColors.navy,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_tag(poi) != null) ...[
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _tag(poi)!,
                  style: TextStyle(fontFamily: AppFonts.inter, 
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 15 / 12,
                    color: AppColors.turquoise,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (facts.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < facts.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Text(
                  facts[i],
                  style: TextStyle(fontFamily: AppFonts.inter, 
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 15 / 12,
                    color: _kBodyText,
                  ),
                ),
              ],
            ],
          ),
        ],
        if (poi.address != null || poi.venue != null) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(IconsaxPlusLinear.location, size: 14, color: Color(0xFF454545)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  poi.address ?? poi.venue!,
                  style: TextStyle(fontFamily: AppFonts.inter, 
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 15 / 12,
                    color: _kBodyText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildThumbnails(MapPoi poi) {
    final colors = _galleryColors(poi);
    final photos = poi.photos;
    // Demo POIs kept a hard-coded "+14"; real ones count what they actually have.
    final extra = photos.isEmpty ? 14 : photos.length - 4;
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _slideIndex = i + 1),
              child: SizedBox(
                width: 75,
                height: 75,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: i + 1 < photos.length
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(7.2),
                              child: Image.network(
                                photos[i + 1],
                                fit: BoxFit.cover,
                                width: 75,
                                height: 75,
                                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                                errorBuilder: (_, _, _) => _imagePlaceholder(
                                    colors[(i + 1) % colors.length], radius: 7.2, glyphSize: 20),
                              ),
                            )
                          : _imagePlaceholder(
                              colors[(i + 1) % colors.length],
                              radius: 7.2,
                              glyphSize: 20,
                            ),
                    ),
                    if (i == 3 && extra > 0)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0x80000000),
                            borderRadius: BorderRadius.circular(7.2),
                          ),
                          child: Center(
                            child: Text(
                              '+$extra',
                              style: TextStyle(fontFamily: AppFonts.inter, 
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 19 / 16,
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

  List<Widget> _detailRows(MapPoi poi) {
    final rows = <(String, String)>[];
    switch (poi.layer) {
      case 'Real Estate':
        rows.addAll([
          (_t('Property Type', 'סוג נכס'), _t('Apartment', 'דירה')),
          (_t('Rooms', 'חדרים'), poi.rooms ?? '—'),
          (_t('Floor', 'קומה'), poi.floor ?? '—'),
          (_t('Size', 'שטח'), poi.area ?? '—'),
        ]);
      case 'Events':
        rows.addAll([
          (_t('Category', 'קטגוריה'), poi.category),
          (_t('Venue', 'מיקום'), poi.venue ?? '—'),
          (_t('Time', 'שעה'), poi.time ?? '—'),
          (_t('Price', 'מחיר'), poi.eventPrice ?? '—'),
        ]);
      case 'Parkings':
        rows.addAll([
          (_t('Type', 'סוג'), poi.category),
          (_t('Address', 'כתובת'), poi.address ?? '—'),
          (_t('Access', 'גישה'), _t('24/7', '24/7')),
          (_t('Payment', 'תשלום'), _t('Pango / Cellopark', 'פנגו / סלופארק')),
        ]);
      default:
        rows.addAll([
          (_t('Category', 'קטגוריה'), poi.category),
          // Real listings have a rating for only some entries and no review
          // count at all, so both rows appear only when there is something
          // behind them — "Reviews 0" reads as a fact the site never claimed.
          if (poi.rating != null) (_t('Rating', 'דירוג'), poi.rating!.toStringAsFixed(1)),
          if (poi.reviewCount != null)
            (_t('Reviews', 'ביקורות'), '${poi.reviewCount}'),
          if (poi.viewCount != null) (_t('Views', 'צפיות'), '${poi.viewCount}'),
        ]);
    }

    final style = TextStyle(fontFamily: AppFonts.inter, 
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 15 / 12,
      color: _kBodyText,
    );

    return [
      for (var i = 0; i < rows.length; i++) ...[
        if (i > 0) const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 120, child: Text(rows[i].$1, style: style)),
            Expanded(child: Text(rows[i].$2, style: style)),
          ],
        ),
      ],
    ];
  }

  Widget _buildCta(MapPoi poi) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (poi.route != null) context.push(poi.route!);
        },
        child: Container(
          width: 324,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.midBlue,
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _t('View Full Details', 'לפרטים המלאים'),
                style: TextStyle(fontFamily: AppFonts.inter, 
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 24 / 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Transform.flip(
                flipX: _isHebrew,
                child: const Icon(Icons.arrow_forward,
                    size: 20, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Slide-card helpers ──
  Widget _sectionTitle(String label) => Text(
    label,
    style: TextStyle(fontFamily: AppFonts.inter, 
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 17 / 14,
      color: Colors.black,
    ),
  );

  String _aboutTitle(MapPoi poi) => switch (poi.layer) {
    'Real Estate' => _t('About This Property', 'על הנכס'),
    'Events' => _t('About This Event', 'על האירוע'),
    'Parkings' => _t('About This Parking', 'על החניון'),
    _ => _t('About This Business', 'על העסק'),
  };

  /// Real listings carry the site's own blurb; demo POIs fall back to a
  /// sentence generated from whatever fields they have.
  String _aboutText(MapPoi poi) => poi.description ?? _generatedAboutText(poi);

  String _generatedAboutText(MapPoi poi) => switch (poi.layer) {
    'Real Estate' => _t(
      'New directly from the contractor, mini penthouse 6 rooms, excellent '
      'location in Avni Chen neighborhood, back apartment!! Occupancy 4 months '
      'from signing the contract, built 140 m², balcony 18 m². Payment '
      'schedule 20/80 without attachments.',
      'חדשה ישירות מהקבלן, מיני פנטהאוז 6 חדרים, מיקום מעולה בשכונת אבני חן, '
      'דירה אחורית!! אכלוס 4 חודשים ממועד חתימת החוזה, בנוי 140 מ"ר, '
      'מרפסת 18 מ"ר. לוח תשלומים 20/80 ללא צמודים.',
    ),
    'Events' => _t(
      '${poi.name} takes place at ${poi.venue ?? 'Modiin'} starting '
      '${poi.time ?? 'this week'}. A local ${poi.category.toLowerCase()} event '
      'open to residents and visitors — save your spot and see the full '
      'schedule on the event page.',
      '${poi.name} מתקיים ב${poi.venue ?? 'מודיעין'} בשעה ${poi.time ?? 'הקרובה'}. '
      'אירוע ${poi.category} מקומי הפתוח לתושבים ולמבקרים — שמרו מקום וצפו '
      'בלוח הזמנים המלא בעמוד האירוע.',
    ),
    'Parkings' => _t(
      '${poi.name} is a public parking facility at ${poi.address ?? 'Modiin'}, '
      'a short walk from the city center. Entry is available around the clock '
      'and payment is supported through the usual parking apps.',
      '${poi.name} הוא חניון ציבורי ב${poi.address ?? 'מודיעין'}, מרחק הליכה '
      'קצר ממרכז העיר. הכניסה זמינה מסביב לשעון והתשלום נתמך באפליקציות '
      'החניה המוכרות.',
    ),
    _ => _t(
      '${poi.name} is a local ${poi.category.toLowerCase()} in Modiin, rated '
      '${poi.rating ?? '-'} by ${poi.reviewCount ?? 0} residents. Find opening '
      'hours, contact details and reviews on the business page.',
      '${poi.name} הוא ${poi.category} מקומי במודיעין, בדירוג ${poi.rating ?? '-'} '
      'מתוך ${poi.reviewCount ?? 0} ביקורות של תושבים. שעות פתיחה, פרטי קשר '
      'וביקורות בעמוד העסק.',
    ),
  };

  String? _tag(MapPoi poi) => switch (poi.layer) {
    'Real Estate' => _t(poi.saleTag ?? 'FOR SALE', 'למכירה'),
    'Events' => poi.eventPrice,
    'Parkings' => null,
    _ => poi.rating == null ? null : '★ ${poi.rating}',
  };

  List<String> _facts(MapPoi poi) => switch (poi.layer) {
    'Real Estate' => [
      if (poi.rooms != null) poi.rooms!,
      if (poi.area != null) poi.area!,
      if (poi.floor != null) poi.floor!,
    ],
    'Events' => [
      poi.category,
      if (poi.time != null) poi.time!,
      if (poi.interestedCount != null)
        _t('${poi.interestedCount} interested', '${poi.interestedCount} מתעניינים'),
    ],
    'Parkings' => [poi.category],
    _ => [
      poi.category,
      if (poi.reviewCount != null)
        _t('${poi.reviewCount} reviews', '${poi.reviewCount} ביקורות'),
      if (poi.viewCount != null)
        _t('${poi.viewCount} views', '${poi.viewCount} צפיות'),
    ],
  };

  List<List<Color>> _galleryColors(MapPoi poi) {
    final base = poi.color;
    return [
      [Color.lerp(base, Colors.white, 0.35)!, Color.lerp(base, Colors.black, 0.55)!],
      [const Color(0xFFE0D4C8), const Color(0xFFC0A891)],
      [const Color(0xFF26607F), const Color(0xFF081428)],
      [const Color(0xFF3B5B3A), const Color(0xFF0B1A16)],
    ];
  }
}

// ═══════════════════════════════════════════════
// Shared bits
// ═══════════════════════════════════════════════
Widget _imagePlaceholder(List<Color> colors,
    {double radius = 12, double glyphSize = 40}) {
  return DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
    ),
    child: Center(
      child: Icon(
        IconsaxPlusLinear.image,
        size: glyphSize,
        color: Colors.white.withValues(alpha: 0.12),
      ),
    ),
  );
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
      alignment: isOn ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        color: isOn ? AppColors.midBlue : const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }
}

/// 32 × 32 white round-rect gallery control.
class _GalleryArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GalleryArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 16, color: AppColors.midBlue),
        ),
      ),
    );
  }
}

/// 40 × 40 map marker — white teardrop with a coloured glyph circle.
class _MapPin extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool isSelected;
  const _MapPin({required this.color, required this.icon, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: isSelected ? 40 : 36,
        height: isSelected ? 40 : 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: color, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: const Color(0x40000000),
              blurRadius: isSelected ? 6 : 2.29,
              offset: const Offset(0, 2.29),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 13, color: Colors.white),
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
              BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: Icon(icon, size: 22, color: AppColors.midBlue),
        ),
      ),
    );
  }
}
