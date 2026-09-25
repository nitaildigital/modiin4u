import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../models/listing.dart';
import '../providers/listing_providers.dart';
import 'my_apartments_screen.dart' show formatShekels;

// ═══════════════════════════════════════════════════════════
// Web Real Estate Search — /apartments-sale and /apartments-rent
// Left: filters | Centre: results | Right: map
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

/// Active listings of one kind, newest first.
///
/// [listingsProvider] is keyed to the browse filter the mobile tab drives, so
/// this page fetches by kind on its own and narrows the result here: the
/// sidebar allows several property types and several room counts at once,
/// which [ListingFilter] holds one of each.
final _searchListingsProvider =
    FutureProvider.family<List<Listing>, ListingKind>(
      (ref, kind) =>
          ref.watch(listingRepositoryProvider).fetchActive(kind: kind),
    );

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

class _WebRealEstateSearchContentState
    extends ConsumerState<WebRealEstateSearchContent> {
  bool _isHebrew = false;
  final _scrollController = ScrollController();
  late final TextEditingController _searchController;

  String _query = '';
  final _types = <PropertyType>{};
  final _rooms = <int>{}; // 5 means "5 or more"
  _FloorBucket _floor = _FloorBucket.any;
  String? _neighborhoodId;
  _Sort _sort = _Sort.newest;

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

  String _floorLabel(_FloorBucket b) => switch (b) {
    _FloorBucket.any => _t('Any', 'הכל'),
    _FloorBucket.low => '1-3',
    _FloorBucket.mid => '4-7',
    _FloorBucket.high => '8+',
  };

  String _sortLabel(_Sort s) => switch (s) {
    _Sort.newest => _t('Sort by: Newest', 'מיון: חדש ביותר'),
    _Sort.priceLow => _t('Price: low to high', 'מחיר: מהנמוך לגבוה'),
    _Sort.priceHigh => _t('Price: high to low', 'מחיר: מהגבוה לנמוך'),
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
    final async = ref.watch(_searchListingsProvider(_kind));
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
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: Row(
                children: [
                  _buildFilterSidebar(all),
                  Expanded(flex: 5, child: _buildListingsPanel(async, results)),
                  Expanded(flex: 4, child: _buildMapPanel(results)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FILTER SIDEBAR
  // ─────────────────────────────────────────────
  Widget _buildFilterSidebar(List<Listing> all) {
    final bounds = _priceBounds(all);

    return Container(
      width: 294,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FA),
        border: BorderDirectional(end: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchInput(),
            const SizedBox(height: 16),
            _buildFilterSection(
              title: _t('Property Type', 'סוג נכס'),
              child: Column(
                children: [
                  for (final t in const [
                    PropertyType.apartment,
                    PropertyType.penthouse,
                    PropertyType.garden,
                    PropertyType.duplex,
                    PropertyType.villa,
                    PropertyType.studio,
                  ])
                    _checkboxRow(
                      label: _typeLabel(t),
                      checked: _types.contains(t),
                      onTap: () => setState(
                        () => _types.contains(t)
                            ? _types.remove(t)
                            : _types.add(t),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Only when there are two different prices to slide between. The
            // slider used to run between bounds written into the demo file —
            // ₪1m to ₪10m for a sale, ₪2,000 to ₪25,000 a month for a let.
            if (bounds != null) ...[
              _buildFilterSection(
                title: _t('Price Range', 'טווח מחירים'),
                child: _buildPriceRange(bounds),
              ),
              const SizedBox(height: 16),
            ],
            _buildFilterSection(
              title: _t('Rooms', 'חדרים'),
              child: Column(
                children: [
                  for (var n = 1; n <= 5; n++)
                    _checkboxRow(
                      label: n == 5
                          ? _t('5+ Rooms', '5+ חדרים')
                          : n == 1
                          ? _t('1 Room', 'חדר 1')
                          : _t('$n Rooms', '$n חדרים'),
                      checked: _rooms.contains(n),
                      onTap: () => setState(
                        () => _rooms.contains(n)
                            ? _rooms.remove(n)
                            : _rooms.add(n),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildFilterSection(
              title: _t('Floor', 'קומה'),
              child: _buildDropdown(
                value: _floorLabel(_floor),
                options: _FloorBucket.values.map(_floorLabel).toList(),
                onSelected: (i) =>
                    setState(() => _floor = _FloorBucket.values[i]),
              ),
            ),
            const SizedBox(height: 16),
            _buildNeighborhoodFilter(),
            const SizedBox(height: 20),
            if (_activeFilterCount > 0)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _clearFilters,
                  child: Text(
                    _t('Clear all filters', 'נקה את כל הסינונים'),
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.midBlue,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.midBlue,
                    ),
                  ),
                ),
              ),
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
      child: hoods == null
          // The list is still coming, or could not be fetched; an empty
          // dropdown would be a control that cannot be used.
          ? Text(
              _t('Loading neighbourhoods…', 'טוען שכונות…'),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 13,
                color: const Color(0xFF6D6D6D),
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
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(
            IconsaxPlusLinear.search_normal_1,
            size: 16,
            color: Color(0xFF6D6D6D),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                color: AppColors.navy,
              ),
              decoration: InputDecoration(
                hintText: _t('Search by location...', 'חיפוש לפי מיקום...'),
                hintStyle: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: const Color(0xFF6D6D6D),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _checkboxRow({
    required String label,
    required bool checked,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: checked ? AppColors.midBlue : Colors.white,
                  border: Border.all(
                    color: checked
                        ? AppColors.midBlue
                        : const Color(0xFF7B899A),
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: checked
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 13,
                    color: const Color(0xFF3D3D3D),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${formatShekels(range.start.round())} – '
          '${formatShekels(range.end.round())}',
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF3D3D3D),
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.midBlue,
            inactiveTrackColor: const Color(0xFFE7E7E7),
            thumbColor: AppColors.midBlue,
            overlayColor: AppColors.midBlue.withValues(alpha: 0.1),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9.5),
            trackHeight: 3,
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 9.5,
            ),
          ),
          child: RangeSlider(
            values: range,
            min: bounds.min,
            max: bounds.max,
            onChanged: (values) => setState(() => _priceRange = values),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> options,
    required ValueChanged<int> onSelected,
  }) {
    return PopupMenuButton<int>(
      tooltip: '',
      offset: const Offset(0, 46),
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 254),
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
                color: options[i] == value
                    ? AppColors.midBlue
                    : const Color(0xFF3D3D3D),
              ),
            ),
          ),
      ],
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE7E7E7)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: const Color(0xFF3D3D3D),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: Color(0xFF7B899A),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // RESULTS PANEL
  // ─────────────────────────────────────────────
  Widget _buildListingsPanel(
    AsyncValue<List<Listing>> async,
    List<Listing> results,
  ) {
    return Container(
      decoration: const BoxDecoration(
        border: BorderDirectional(end: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildListingsHeader(async, results),
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
                onAction: () => ref.invalidate(_searchListingsProvider(_kind)),
              ),
              data: (all) {
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
                      _buildListingCard(results[index]),
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
    final heading = async.isLoading
        ? _t('Searching…', 'מחפשים…')
        : _isRent
        ? _t(
            '${results.length} Apartments found for rent',
            '${results.length} דירות נמצאו להשכרה',
          )
        : _t(
            '${results.length} Apartments found for sale',
            '${results.length} דירות נמצאו למכירה',
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        fontWeight: FontWeight.w600,
                        color: AppColors.midBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _t('in Modiin Maccabim Reut', 'במודיעין מכבים רעות'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        color: const Color(0xFF5F5E5A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // It was a box with a chevron and no handler at all.
              SizedBox(
                width: 190,
                child: _buildDropdown(
                  value: _sortLabel(_sort),
                  options: _Sort.values.map(_sortLabel).toList(),
                  onSelected: (i) => setState(() => _sort = _Sort.values[i]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
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
                color: const Color(0xFF5F5E5A),
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

  Widget _buildListingCard(Listing l) {
    final price = l.effectivePrice;
    final phone = l.contactDisplayPhone;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        // Every card in this list pushed /listing/1, an id that matches no row.
        onTap: () => context.push('/listing/${l.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 261,
                height: 162,
                child: NetworkPhoto(
                  url: l.coverUrl,
                  radius: BorderRadius.circular(12),
                  icon: IconsaxPlusBold.home_2,
                  iconSize: 40,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: SizedBox(
                  height: 162,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.title,
                                  style: TextStyle(
                                    fontFamily: AppFonts.nunito,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navy,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if ((l.address ?? l.neighborhoodName) !=
                                    null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    l.address ?? l.neighborhoodName!,
                                    style: TextStyle(
                                      fontFamily: AppFonts.inter,
                                      fontSize: 14,
                                      color: const Color(0xFF5F5E5A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // A drawing of a heart with nothing behind it.
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF2F3F8),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: FavoriteButton(
                                kind: FavoriteKind.listing,
                                id: l.id,
                                iconSize: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Each figure only where the row carries it. The row used
                      // to print area, rooms, floor and "Standard Apartment"
                      // whatever the listing was.
                      Wrap(
                        spacing: 31,
                        runSpacing: 8,
                        children: [
                          if (l.sqm != null)
                            _specItem(
                              IconsaxPlusLinear.ruler,
                              _t('${l.sqm} m²', '${l.sqm} מ"ר'),
                            ),
                          if (l.rooms != null)
                            _specItem(
                              IconsaxPlusLinear.house,
                              _t(
                                '${_roomsText(l.rooms!)} Rooms',
                                '${_roomsText(l.rooms!)} חדרים',
                              ),
                            ),
                          if (l.floor != null)
                            _specItem(
                              IconsaxPlusLinear.building_4,
                              _t('Floor ${l.floor}', 'קומה ${l.floor}'),
                            ),
                          _specItem(
                            IconsaxPlusLinear.category,
                            _typeLabel(l.propertyType),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          // A listing with no price is not a free one.
                          Text(
                            price == null
                                ? _t('Price on request', 'מחיר לפי בקשה')
                                : formatShekels(price),
                            style: TextStyle(
                              fontFamily: AppFonts.nunito,
                              fontSize: price == null ? 15 : 22,
                              fontWeight: FontWeight.w600,
                              color: AppColors.midBlue,
                            ),
                          ),
                          if (price != null && _isRent) ...[
                            const SizedBox(width: 6),
                            Text(
                              _t('/ month', '/ לחודש'),
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
                                color: const Color(0xFF5F5E5A),
                              ),
                            ),
                          ],
                          const Spacer(),
                          // The button had no handler, and a listing can carry
                          // no telephone number at all, so it is drawn only
                          // when there is a number to dial.
                          if (phone != null)
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => _launchPhone(phone),
                                child: Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.midBlue,
                                    ),
                                    borderRadius: BorderRadius.circular(60),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        IconsaxPlusLinear.call,
                                        size: 16,
                                        color: AppColors.midBlue,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _t('Contact', 'צור קשר'),
                                        style: TextStyle(
                                          fontFamily: AppFonts.inter,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.midBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
        ),
      ),
    );
  }

  /// A number that cannot be dialled is left alone rather than reported, since
  /// there is nothing the reader could do about it.
  static Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Widget _specItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6D6D6D)),
        const SizedBox(width: 6),
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

    return FlutterMap(
      options: const MapOptions(initialCenter: _center, initialZoom: 13.2),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.modiin4u.app',
        ),
        MarkerLayer(
          markers: [
            for (final l in pinned)
              Marker(
                point: LatLng(l.latitude!, l.longitude!),
                width: 40,
                height: 40,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.push('/listing/${l.id}'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          IconsaxPlusBold.location,
                          size: 20,
                          color: Color(0xFF006BF6),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
