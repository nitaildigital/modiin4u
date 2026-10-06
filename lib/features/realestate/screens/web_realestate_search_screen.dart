import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../models/listing.dart';
import '../providers/listing_providers.dart';
import '../../../shared/widgets/web_map_tiles.dart';
import 'my_apartments_screen.dart' show formatShekels;
import '../../../shared/widgets/web_contact_menu.dart';

// ═══════════════════════════════════════════════════════════
// Web Real Estate Search — /apartments-sale and /apartments-rent
// Left: filters | Centre: results | Right: map
//
// Drawn to the Figma frames "Appartments For Sale" and "Appartments For
// Rent" (1920 × 960): a 294 sidebar, a 900 column of results and the map in
// the remaining 726.
//
// The three panels all stood on invented material, which lived in a file of
// its own: sixteen flats, eight for sale and eight to let, the same addresses
// in both lists at different prices, a mini penthouse in Avni Hen at the head
// of each. Every card opened /listing/1. The neighbourhood dropdown offered
// four names — Maccabim Reut, HaNahalim, Buchman, Kaiser — of which only two
// are rows in `neighborhoods`. The price slider ran between bounds chosen to
// suit the demo prices. "Sort by: Newest" had no handler. The map on the right
// was a CustomPainter drawing roads, blocks and two green rectangles for parks,
// with eight pins at fixed fractions of the panel.
// ═══════════════════════════════════════════════════════════

const _kAssets = 'assets/web/realestate';
const _kBorder = Color(0xFFE7E7E7);
const _kGrey = Color(0xFF5F5E5A);
const _kGrey500 = Color(0xFF6D6D6D);
const _kGrey900 = Color(0xFF3D3D3D);

enum _Sort { newest, priceLow, priceHigh }

/// Which floors a bucket covers. A listing whose floor is not recorded cannot
/// be known to sit in any of them, so it is left out once a bucket is chosen.
enum _FloorBucket {
  any(null, null),
  low(1, 3),
  mid(4, 7),
  high(8, null);

  const _FloorBucket(this.from, this.to);
  final int? from;
  final int? to;

  bool matches(int? floor) {
    if (from == null) return true;
    if (floor == null) return false;
    if (floor < from!) return false;
    return to == null || floor <= to!;
  }
}

class WebRealEstateSearchContent extends ConsumerStatefulWidget {
  final String listingType; // 'sale' or 'rent'
  final String initialQuery;
  const WebRealEstateSearchContent({
    super.key,
    required this.listingType,
    this.initialQuery = '',
  });

  @override
  ConsumerState<WebRealEstateSearchContent> createState() =>
      _WebRealEstateSearchContentState();
}

class _WebRealEstateSearchContentState extends ConsumerState<WebRealEstateSearchContent>
    with WebLanguageState<WebRealEstateSearchContent> {
  bool get _isHebrew => webIsHebrew.value;
  final _scrollController = ScrollController();
  late final TextEditingController _searchController;

  String _query = '';
  final _types = <PropertyType>{};
  final _rooms = <int>{}; // 5 means "5 or more"
  _FloorBucket _floor = _FloorBucket.any;
  String? _neighborhoodId;
  bool _readRoute = false;
  _Sort _sort = _Sort.newest;

  /// The row under the pointer, whose pin the map lifts.
  String? _hoveredId;

  /// Null until the reader moves the slider, which is what keeps a listing
  /// with no price in the results while the range is untouched.
  RangeValues? _priceRange;

  ListingKind get _kind =>
      widget.listingType == 'rent' ? ListingKind.rent : ListingKind.sale;

  bool get _isRent => _kind == ListingKind.rent;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _searchController = TextEditingController(text: widget.initialQuery);
    _searchController.addListener(
      () => setState(() => _query = _searchController.text),
    );
  }

  /// The Real Estate page's neighbourhood cards open this page with
  /// `?neighborhood=<id>`, so the reader lands on that neighbourhood's flats.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_readRoute) return;
    _readRoute = true;
    try {
      final params = GoRouterState.of(context).uri.queryParameters;
      final id = params['neighborhood'];
      if (id != null && id.isNotEmpty) _neighborhoodId = id;
      // "View all properties" on the Real Estate page carries the type
      // picked there.
      final type = PropertyType.values.where((t) => t.name == params['type']).firstOrNull;
      if (type != null) _types.add(type);
    } catch (_) {
      // Not under a route (a test harness); nothing to read.
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  String _typeLabel(PropertyType t) => switch (t) {
    PropertyType.apartment => _t('Apartment', 'דירה'),
    PropertyType.penthouse => _t('Penthouse', 'פנטהאוז'),
    PropertyType.garden => _t('Garden Apartment', 'דירת גן'),
    PropertyType.duplex => _t('Duplex', 'דופלקס'),
    PropertyType.villa => _t('Villa', 'וילה'),
    PropertyType.studio => _t('Studio', 'סטודיו'),
    PropertyType.other => _t('Other', 'אחר'),
  };

  /// The type as the result rows print it, where a plain flat is a
  /// "Standard Apartment" to set it apart from a garden one.
  String _rowTypeLabel(PropertyType t) => t == PropertyType.apartment
      ? _t('Standard Apartment', 'דירה רגילה')
      : _typeLabel(t);

  String _floorLabel(_FloorBucket b) => switch (b) {
    _FloorBucket.any => _t('Any', 'הכל'),
    _FloorBucket.low => '1-3',
    _FloorBucket.mid => '4-7',
    _FloorBucket.high => '8+',
  };

  String _sortLabel(_Sort s) => switch (s) {
    _Sort.newest => _t('Sort by: Newest', 'מיון: החדשים ביותר'),
    _Sort.priceLow => _t('Sort by: Lowest price', 'מיון: המחיר הנמוך'),
    _Sort.priceHigh => _t('Sort by: Highest price', 'מיון: המחיר הגבוה'),
  };

  // ─────────────────────────────────────────────
  // FILTERING
  // ─────────────────────────────────────────────
  /// The bounds the price slider can run between, or null when the listings
  /// on file do not give two different prices to slide between — a slider whose
  /// ends meet is a control that cannot be used.
  ({double min, double max})? _priceBounds(List<Listing> listings) {
    final prices =
        listings.map((l) => l.effectivePrice).whereType<int>().toList()..sort();
    if (prices.length < 2 || prices.first == prices.last) return null;
    return (min: prices.first.toDouble(), max: prices.last.toDouble());
  }

  int get _activeFilterCount =>
      (_types.isEmpty ? 0 : 1) +
      (_rooms.isEmpty ? 0 : 1) +
      (_priceRange == null ? 0 : 1) +
      (_floor == _FloorBucket.any ? 0 : 1) +
      (_neighborhoodId == null ? 0 : 1);

  List<Listing> _apply(List<Listing> listings) {
    final q = _query.trim().toLowerCase();
    final range = _priceRange;

    final out = listings.where((l) {
      if (q.isNotEmpty &&
          !l.title.toLowerCase().contains(q) &&
          !(l.address ?? '').toLowerCase().contains(q) &&
          !(l.neighborhoodName ?? '').toLowerCase().contains(q)) {
        return false;
      }
      if (_types.isNotEmpty && !_types.contains(l.propertyType)) return false;
      if (_rooms.isNotEmpty) {
        final rooms = l.rooms;
        if (rooms == null) return false;
        final bucket = rooms >= 5 ? 5 : rooms.floor();
        if (!_rooms.contains(bucket)) return false;
      }
      if (range != null) {
        final price = l.effectivePrice;
        if (price == null) return false;
        if (price < range.start || price > range.end) return false;
      }
      if (!_floor.matches(l.floor)) return false;
      if (_neighborhoodId != null && l.neighborhoodId != _neighborhoodId) {
        return false;
      }
      return true;
    }).toList();

    // A listing with no price sorts last either way, rather than as if it were
    // the cheapest on the page.
    switch (_sort) {
      case _Sort.newest:
        out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _Sort.priceLow:
        out.sort(_byPrice(ascending: true));
      case _Sort.priceHigh:
        out.sort(_byPrice(ascending: false));
    }
    return out;
  }

  static int Function(Listing, Listing) _byPrice({required bool ascending}) =>
      (a, b) {
        final pa = a.effectivePrice;
        final pb = b.effectivePrice;
        if (pa == null && pb == null) return 0;
        if (pa == null) return 1;
        if (pb == null) return -1;
        return ascending ? pa.compareTo(pb) : pb.compareTo(pa);
      };

  void _clearFilters() {
    setState(() {
      _types.clear();
      _rooms.clear();
      _priceRange = null;
      _floor = _FloorBucket.any;
      _neighborhoodId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // One fetch for both pages, narrowed to this page's kind here.
    final async = ref
        .watch(allActiveListingsProvider)
        .whenData((rows) => rows.where((l) => l.kind == _kind).toList());
    final all = async.valueOrNull ?? const <Listing>[];
    final results = _apply(all);

    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: 'realestate',
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFilterSidebar(all),
                  Expanded(
                    flex: 900,
                    child: _buildListingsPanel(async, all, results),
                  ),
                  Expanded(flex: 726, child: _buildMapPanel(results)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FILTER SIDEBAR — 294 wide
  // ─────────────────────────────────────────────
  Widget _buildFilterSidebar(List<Listing> all) {
    final bounds = _priceBounds(all);

    return Container(
      width: 294,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FA),
        border: BorderDirectional(end: BorderSide(color: _kBorder)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchInput(),
            const SizedBox(height: 16),
            _buildFilterSection(
              title: _t('Property Type', 'סוג נכס'),
              gap: 17,
              child: _checkboxList([
                for (final t in const [
                  PropertyType.apartment,
                  PropertyType.penthouse,
                  PropertyType.garden,
                  PropertyType.duplex,
                  PropertyType.villa,
                  PropertyType.studio,
                ])
                  (
                    label: _typeLabel(t),
                    checked: _types.contains(t),
                    onTap: () => setState(
                      () =>
                          _types.contains(t) ? _types.remove(t) : _types.add(t),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 24),
            // Only when there are two different prices to slide between. The
            // slider used to run between bounds written into the demo file —
            // ₪1m to ₪10m for a sale, ₪2,000 to ₪25,000 a month for a let.
            if (bounds != null) ...[
              _buildFilterSection(
                title: _t('Price Range', 'טווח מחירים'),
                gap: 14,
                child: _buildPriceRange(bounds),
              ),
              const SizedBox(height: 24),
            ],
            _buildFilterSection(
              title: _t('Rooms', 'חדרים'),
              gap: 17,
              child: _checkboxList([
                for (var n = 1; n <= 5; n++)
                  (
                    label: n == 5
                        ? _t('5+ Rooms', '5+ חדרים')
                        : n == 1
                        ? _t('1 Room', 'חדר 1')
                        : _t('$n Rooms', '$n חדרים'),
                    checked: _rooms.contains(n),
                    onTap: () => setState(
                      () =>
                          _rooms.contains(n) ? _rooms.remove(n) : _rooms.add(n),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 24),
            _buildFilterSection(
              title: _t('Floor', 'קומה'),
              gap: 12,
              child: _buildDropdown(
                value: _floorLabel(_floor),
                options: _FloorBucket.values.map(_floorLabel).toList(),
                onSelected: (i) =>
                    setState(() => _floor = _FloorBucket.values[i]),
              ),
            ),
            const SizedBox(height: 24),
            _buildNeighborhoodFilter(),
            if (_activeFilterCount > 0) ...[
              const SizedBox(height: 24),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _clearFilters,
                    child: Text(
                      _t('Clear all filters', 'נקה את כל הסינונים'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 13,
                        height: 16 / 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.midBlue,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.midBlue,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The city's real neighbourhoods, in the order the admin set.
  Widget _buildNeighborhoodFilter() {
    final hoods = ref.watch(listingNeighborhoodsProvider).valueOrNull;

    return _buildFilterSection(
      title: _t('Neighborhood', 'שכונה'),
      gap: 12,
      child: hoods == null
          // The list is still coming, or could not be fetched; an empty
          // dropdown would be a control that cannot be used.
          ? Text(
              _t('Loading neighbourhoods…', 'טוען שכונות…'),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 13,
                height: 16 / 13,
                color: _kGrey500,
              ),
            )
          : _buildDropdown(
              value: _neighborhoodId == null
                  ? _t('Any', 'הכל')
                  : hoods
                        .firstWhere(
                          (h) => h.id == _neighborhoodId,
                          orElse: () => (id: '', name: _t('Any', 'הכל')),
                        )
                        .name,
              options: [_t('Any', 'הכל'), ...hoods.map((h) => h.name)],
              onSelected: (i) => setState(
                () => _neighborhoodId = i == 0 ? null : hoods[i - 1].id,
              ),
            ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SvgPicture.asset('$_kAssets/search_pin.svg', width: 16, height: 16),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                height: 17 / 14,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: _t('Search by location...', 'חיפוש לפי מיקום...'),
                hintStyle: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  height: 17 / 14,
                  color: _kGrey500,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                // The app theme fills every field with a grey pill, which
                // would draw a second box inside this one.
                filled: false,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required double gap,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            height: 17 / 14,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
        SizedBox(height: gap),
        child,
      ],
    );
  }

  Widget _checkboxList(
    List<({String label, bool checked, VoidCallback onTap})> rows,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: rows[i].onTap,
              child: Row(
                children: [
                  SvgPicture.asset(
                    '$_kAssets/${rows[i].checked ? 'checkbox_on' : 'checkbox_off'}.svg',
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rows[i].label,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 13,
                        height: 16 / 13,
                        color: _kGrey900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceRange(({double min, double max}) bounds) {
    // Clamped because the bounds move with the listings on file, and a stored
    // range from a moment ago may now sit outside them.
    final range = RangeValues(
      (_priceRange?.start ?? bounds.min).clamp(bounds.min, bounds.max),
      (_priceRange?.end ?? bounds.max).clamp(bounds.min, bounds.max),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${formatShekels(range.start.round())} – '
          '${formatShekels(range.end.round())}',
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 16 / 13,
            color: _kGrey900,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 19,
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.midBlue,
              inactiveTrackColor: _kBorder,
              trackHeight: 3,
              overlayShape: SliderComponentShape.noOverlay,
              rangeThumbShape: const _RingThumb(),
              rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
              padding: EdgeInsets.zero,
            ),
            child: RangeSlider(
              values: range,
              min: bounds.min,
              max: bounds.max,
              onChanged: (values) => setState(() => _priceRange = values),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> options,
    required ValueChanged<int> onSelected,
    double? width,
  }) {
    return PopupMenuButton<int>(
      tooltip: '',
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 166),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _kBorder),
      ),
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (var i = 0; i < options.length; i++)
          PopupMenuItem(
            value: i,
            height: 40,
            child: Text(
              options[i],
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                height: 17 / 14,
                fontWeight: options[i] == value
                    ? FontWeight.w500
                    : FontWeight.w400,
                color: options[i] == value ? AppColors.midBlue : _kGrey900,
              ),
            ),
          ),
      ],
      child: Container(
        height: 42,
        // The sort box is 166 wide as drawn, and grows rather than cutting
        // off a longer choice.
        constraints: width == null ? null : BoxConstraints(minWidth: width),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: width == null ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (width == null)
              Expanded(child: _dropdownText(value))
            else
              _dropdownText(value),
            const SizedBox(width: 13),
            SvgPicture.asset(
              '$_kAssets/chevron_down20.svg',
              width: 20,
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownText(String value) => Text(
    value,
    style: TextStyle(
      fontFamily: AppFonts.inter,
      fontSize: 14,
      height: 17 / 14,
      color: Colors.black,
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );

  // ─────────────────────────────────────────────
  // RESULTS PANEL
  // ─────────────────────────────────────────────
  Widget _buildListingsPanel(
    AsyncValue<List<Listing>> async,
    List<Listing> all,
    List<Listing> results,
  ) {
    return Container(
      decoration: const BoxDecoration(
        border: BorderDirectional(end: BorderSide(color: _kBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
            child: _buildListingsHeader(async, results),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _buildNotice(
                icon: IconsaxPlusLinear.wifi_square,
                title: _t(
                  'Properties could not be loaded',
                  'לא ניתן לטעון את הנכסים',
                ),
                body: _t(
                  'Check your connection and try again.',
                  'בדקו את החיבור לאינטרנט ונסו שוב.',
                ),
                actionLabel: _t('Try again', 'נסו שוב'),
                onAction: () => ref.invalidate(allActiveListingsProvider),
              ),
              data: (_) {
                if (all.isEmpty) {
                  // Nothing has been published at all, which is not the same
                  // as nothing matching the filters, and must not read as if
                  // the reader had narrowed something too far.
                  return _buildNotice(
                    icon: IconsaxPlusLinear.home_2,
                    title: _isRent
                        ? _t(
                            'No apartments to let yet',
                            'אין כרגע דירות להשכרה',
                          )
                        : _t(
                            'No apartments for sale yet',
                            'אין כרגע דירות למכירה',
                          ),
                    body: _t(
                      'Properties will appear here as they are published.',
                      'נכסים יופיעו כאן עם פרסומם.',
                    ),
                  );
                }
                if (results.isEmpty) {
                  return _buildNotice(
                    icon: IconsaxPlusLinear.search_status,
                    title: _t(
                      'No apartments match your filters',
                      'אין דירות שתואמות את הסינון',
                    ),
                    body: _t(
                      'Try widening the price range or clearing a filter.',
                      'נסו להרחיב את טווח המחירים או להסיר סינון.',
                    ),
                    actionLabel: _activeFilterCount > 0
                        ? _t('Clear all filters', 'נקה את כל הסינונים')
                        : null,
                    onAction: _activeFilterCount > 0 ? _clearFilters : null,
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: results.length,
                  itemBuilder: (context, index) =>
                      _buildListingRow(results[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingsHeader(
    AsyncValue<List<Listing>> async,
    List<Listing> results,
  ) {
    // The count is a real one now, so it is only claimed once the query has
    // come back — a heading reading "0 Apartments found" while the fetch is in
    // flight is a figure the page does not yet have.
    final n = results.length;
    final heading = async.isLoading
        ? _t('Searching…', 'מחפשים…')
        : _isRent
        ? (n == 1
              ? _t('1 Apartment found for rent', 'נמצאה דירה אחת להשכרה')
              : _t('$n Apartments found for rent', '$n דירות נמצאו להשכרה'))
        : (n == 1
              ? _t('1 Apartment found for sale', 'נמצאה דירה אחת למכירה')
              : _t('$n Apartments found for sale', '$n דירות נמצאו למכירה'));

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                heading,
                style: TextStyle(
                  fontFamily: AppFonts.nunito,
                  fontSize: 28,
                  height: 34 / 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.midBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _t('in Modiin Maccabim Reut', 'במודיעין מכבים רעות'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  height: 17 / 14,
                  color: _kGrey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // It was a box with a chevron and no handler at all.
        _buildDropdown(
          value: _sortLabel(_sort),
          options: _Sort.values.map(_sortLabel).toList(),
          onSelected: (i) => setState(() => _sort = _Sort.values[i]),
          width: 166,
        ),
      ],
    );
  }

  Widget _buildNotice({
    required IconData icon,
    required String title,
    required String body,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: const Color(0xFF7B899A).withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppFonts.nunito,
                fontSize: 20,
                height: 25 / 20,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                height: 17 / 14,
                color: _kGrey,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onAction,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: AppColors.midBlue,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      actionLabel,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        height: 19 / 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Half rooms are normal here, so 3.5 must not print as 3.
  static String _roomsText(double rooms) =>
      rooms == rooms.roundToDouble() ? '${rooms.toInt()}' : '$rooms';

  /// One result: the photograph, then the title, where it is, its figures,
  /// and the price with a way to call.
  Widget _buildListingRow(Listing l) {
    final price = l.effectivePrice;
    final phone = l.contactDisplayPhone;
    final place = l.neighborhoodName ?? l.address;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredId = l.id),
      onExit: (_) => setState(() {
        if (_hoveredId == l.id) _hoveredId = null;
      }),
      child: GestureDetector(
        // Every card in this list pushed /listing/1, an id that matches no row.
        onTap: () => context.push('/listing/${l.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _kBorder)),
          ),
          child: SizedBox(
            height: 162,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 261,
                  child: NetworkPhoto(
                    url: l.coverUrl,
                    radius: BorderRadius.circular(12),
                    icon: IconsaxPlusBold.home_2,
                    iconSize: 40,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // The design puts a heart at the end of this line;
                          // it saves to an account, and accounts are the
                          // app's alone.
                          Text(
                            l.title,
                            style: TextStyle(
                              fontFamily: AppFonts.nunito,
                              fontSize: 18,
                              height: 22 / 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (place != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              place,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
                                height: 17 / 14,
                                color: _kGrey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 22),
                          // Each figure only where the row carries it. The
                          // row used to print area, rooms, floor and
                          // "Standard Apartment" whatever the listing was.
                          // Closer together where the column is narrower
                          // than the design's, so the four stay on one line.
                          LayoutBuilder(
                            builder: (context, c) => Wrap(
                              spacing: c.maxWidth >= 520 ? 31 : 16,
                              runSpacing: 8,
                              children: [
                                if (l.sqm != null)
                                  _specItem(
                                    'spec_sqm.svg',
                                    _t('${l.sqm} m²', '${l.sqm} מ״ר'),
                                  ),
                                if (l.rooms != null)
                                  _specItem(
                                    'spec_rooms.svg',
                                    (l.rooms == 1
                                        ? _t('1 Room', 'חדר 1')
                                        : _t(
                                            '${_roomsText(l.rooms!)} Rooms',
                                            '${_roomsText(l.rooms!)} חדרים',
                                          )),
                                  ),
                                if (l.floor != null)
                                  _specItem(
                                    'spec_floor.svg',
                                    (l.floor == 0
                                        ? _t('Ground Floor', 'קומת קרקע')
                                        : _t(
                                            'Floor ${l.floor}',
                                            'קומה ${l.floor}',
                                          )),
                                  ),
                                _specItem(
                                  'spec_type.svg',
                                  _rowTypeLabel(l.propertyType),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // A listing with no price is not a free one.
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    price == null
                                        ? _t(
                                            'Price on request',
                                            'מחיר לפי בקשה',
                                          )
                                        : formatShekels(price),
                                    style: TextStyle(
                                      fontFamily: AppFonts.nunito,
                                      fontSize: price == null ? 16 : 22,
                                      height: price == null ? 20 / 16 : 27 / 22,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.midBlue,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (price != null && _isRent) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    _t('/ month', '/ לחודש'),
                                    style: TextStyle(
                                      fontFamily: AppFonts.inter,
                                      fontSize: 14,
                                      height: 17 / 14,
                                      color: _kGrey,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // A listing can carry no telephone number at all,
                          // so the button is drawn only when there is a
                          // number to dial.
                          if (phone != null) _contactButton(phone),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The contact menu under the button: the number, Call, and WhatsApp —
  /// a listing's number is the advertiser's mobile, as on the listing page.
  Widget _contactButton(String phone) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Builder(builder: (anchor) => GestureDetector(
        onTap: () => showWebContactMenu(anchor, isHebrew: _isHebrew, phone: phone, whatsapp: phone),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.midBlue),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset('$_kAssets/call16.svg', width: 16, height: 16),
              const SizedBox(width: 8),
              Text(
                _t('Contact', 'צור קשר'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 24 / 14,
                  color: AppColors.midBlue,
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  Widget _specItem(String icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset('$_kAssets/$icon', width: 14, height: 14),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 12,
            height: 15 / 12,
            color: _kGrey900,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // MAP PANEL
  // ─────────────────────────────────────────────
  /// Modiin, at the centre of the map.
  static const _center = LatLng(31.8928, 35.0104);

  /// The results that carry coordinates. The rest stay in the list beside it.
  ///
  /// This panel used to be a painting: roads at fixed fractions of its height,
  /// rectangles standing in for buildings and two green ones for parks, with
  /// eight pins placed by hand and none of them tied to a listing.
  Widget _buildMapPanel(List<Listing> results) {
    final pinned = results
        .where((l) => l.latitude != null && l.longitude != null)
        .toList();
    final points = [for (final l in pinned) LatLng(l.latitude!, l.longitude!)];

    return FlutterMap(
      // Keyed to the pins, so a change of filter frames the new set rather
      // than leaving the camera where the old one was.
      key: ValueKey(Object.hashAll(pinned.map((l) => l.id))),
      options: MapOptions(
        initialCenter: points.length == 1 ? points.first : _center,
        initialZoom: 13.2,
        initialCameraFit: points.length > 1
            ? CameraFit.coordinates(
                coordinates: points,
                padding: const EdgeInsets.all(64),
                maxZoom: 15,
              )
            : null,
      ),
      children: [
        const WebMapTiles(),
        MarkerLayer(
          markers: [
            for (final l in pinned)
              Marker(
                point: LatLng(l.latitude!, l.longitude!),
                width: 40,
                height: 44,
                // The pin's point, not its middle, sits on the address.
                alignment: Alignment.topCenter,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _hoveredId = l.id),
                  onExit: (_) => setState(() {
                    if (_hoveredId == l.id) _hoveredId = null;
                  }),
                  child: GestureDetector(
                    onTap: () => context.push('/listing/${l.id}'),
                    child: AnimatedScale(
                      scale: _hoveredId == l.id ? 1.2 : 1,
                      alignment: Alignment.bottomCenter,
                      duration: const Duration(milliseconds: 150),
                      child: const ListingMapPin(),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const WebMapCredit(),
      ],
    );
  }
}

/// The design's blue house pin, with its drop shadow.
///
/// The SVG carries the shadow as a filter, which flutter_svg does not draw,
/// so the same shape is laid underneath, darkened and blurred.
class ListingMapPin extends StatelessWidget {
  const ListingMapPin({super.key});

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
              imageFilter: _pinShadowBlur,
              child: SvgPicture.asset(
                '$_kAssets/listing_pin.svg',
                width: 40,
                colorFilter: const ColorFilter.mode(
                  Color(0x40000000),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          SvgPicture.asset('$_kAssets/listing_pin.svg', width: 40),
        ],
      ),
    );
  }
}

final _pinShadowBlur = ImageFilter.blur(sigmaX: 1.1, sigmaY: 1.1);

/// The price slider's handle: a filled blue disc with a white ring, 19 across.
class _RingThumb extends RangeSliderThumbShape {
  const _RingThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(9.5);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    TextDirection? textDirection,
    required SliderThemeData sliderTheme,
    Thumb? thumb,
    bool? isPressed,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(center, 9.5, Paint()..color = Colors.white);
    canvas.drawCircle(center, 7.5, Paint()..color = AppColors.midBlue);
  }
}
