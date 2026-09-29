import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/widgets/web_chrome.dart' show WebLanguageState, WebNavbar, webIsHebrew;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../providers/restaurant_providers.dart';
import '../../../shared/widgets/web_map_tiles.dart';
import '../widgets/restaurant_place_card.dart';
import '../../../shared/widgets/network_photo.dart' show sizedPhotoUrl;
import '../../../shared/widgets/web_contact_menu.dart';

// ═══════════════════════════════════════════════════════════
// Web Restaurants Search — three-panel layout from Figma
// (Restaurants — 1920 × 960)
// Left: filter sidebar 294 | Center: listings 900 | Right: map 726
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kSidebarBg = Color(0xFFF7F8FA);
const _kTextDark = Color(0xFF3D3D3D);
const _kTextGrey = Color(0xFF6D6D6D);
const _kSubtitle = Color(0xFF5F5E5A);
const _kBadgeBlue = Color(0xFF0033AC);
const _kCheckBorder = Color(0xFF7B899A);

const _kAsset = 'assets/web/restaurants';
const _kCardAsset = 'assets/web/home';

class WebRestaurantsMapContent extends ConsumerStatefulWidget {
  const WebRestaurantsMapContent({super.key});

  @override
  ConsumerState<WebRestaurantsMapContent> createState() =>
      _WebRestaurantsMapContentState();
}

class _WebRestaurantsMapContentState extends ConsumerState<WebRestaurantsMapContent>
    with WebLanguageState<WebRestaurantsMapContent> {
  bool get _isHebrew => webIsHebrew.value;
  final _searchController = TextEditingController();
  final _listController = ScrollController();
  final _mapController = MapController();

  String _query = '';
  // Empty set ⇒ "All Cuisines" is checked.
  final Set<String> _cuisines = {};
  String _kosher = 'all'; // all | kosher | not
  int _minRating = 0; // 0 ⇒ "All"

  /// Empty ⇒ no narrowing. It used to default to `{'dine_in'}`, a filter no
  /// column can answer.
  final Set<String> _dining = {};

  _Sort _sort = _Sort.newest;

  /// The place under the pointer, in the list or on the map, by id rather
  /// than by index: the map draws only the places that have coordinates, so
  /// an index into the pins is not an index into the list.
  String? _hoveredId;

  /// The pin that was clicked, whose card sits over the map.
  String? _selectedId;

  bool _readLink = false;

  static const _center = LatLng(31.8928, 35.0104);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _query = _searchController.text.trim()),
    );
  }

  /// The Restaurants page opens this list already narrowed: its search,
  /// quick picks, category cards and "View all" buttons say how in the link
  /// (`?q=`, `?cuisine=pizza`, `?dining=delivery`, `?sort=rating`).
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_readLink) return;
    _readLink = true;
    final Map<String, String> params;
    try {
      params = GoRouterState.of(context).uri.queryParameters;
    } catch (_) {
      return;
    }
    final q = params['q']?.trim() ?? '';
    if (q.isNotEmpty) {
      _searchController.text = q;
      _query = q;
    }
    _cuisines.addAll((params['cuisine'] ?? '').split(',').where((s) => s.isNotEmpty));
    _dining.addAll((params['dining'] ?? '').split(',').where((s) => s.isNotEmpty));
    if (params['sort'] == 'rating') _sort = _Sort.rating;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listController.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  // ── Filter definitions ──
  //
  // The cuisines are the food categories as the admin panel holds them —
  // "מסעדות", its sub-categories and "קפה ומאפה" — so adding one there adds it
  // here. They used to be five keys written into this screen, italian,
  // seafood and steak among them, none of which is a category in the
  // database, so three of the five could never match anything. Bars have no
  // category; they are the places whose own description says bar or pub
  // (see `describesABar`), under the one label written here.
  List<_Option> get _cuisineOptions {
    final all = ref.watch(categoriesBySlugProvider).valueOrNull ?? const {};
    final parent = all['restaurants'];
    final cafe = all['cafe-bakery'];
    final hasBars = _places.any((p) => p.kind == FoodKind.bar);
    return [
      if (parent != null) _Option(parent.slug, parent.name),
      for (final c in ref.watch(cuisineCategoriesProvider).valueOrNull ?? const [])
        _Option(c.slug, c.name),
      if (cafe != null) _Option(cafe.slug, cafe.name),
      if (hasBars) _Option(kBarsKey, _t('Bars', 'ברים')),
    ];
  }

  /// Take Away and Delivery, each only while some place offers it. There is
  /// no column at all for the design's "Dine In", so that box could only
  /// mislead: checked, it would narrow nothing.
  List<_Option> get _diningOptions => [
    if (_takeaway.isNotEmpty) _Option('takeaway', _t('Take Away', 'טייק אווי')),
    _Option('delivery', _t('Delivery', 'משלוחים')),
  ];

  // ── Listings ──
  //
  // Eight places written into this screen before, with ratings and review
  // counts nobody had earned, and every row and pin pushing `/restaurant/1`,
  // which matches no row.
  List<FoodPlace> get _places =>
      ref.watch(webFoodPlacesProvider).valueOrNull ?? const <FoodPlace>[];

  Set<String> get _takeaway =>
      ref.watch(takeawayBusinessIdsProvider).valueOrNull ?? const {};

  List<_Listing> get _allListings {
    final takeaway = _takeaway;
    return [
      for (final (i, place) in _places.indexed)
        _Listing.of(
          place,
          _kPlaceholders[i % _kPlaceholders.length],
          takeaway: takeaway.contains(place.business.id),
        ),
    ];
  }

  List<_Listing> get _listings {
    final q = _query.toLowerCase();
    final rows = _allListings.where((l) {
      if (q.isNotEmpty &&
          !l.name.toLowerCase().contains(q) &&
          !l.subtitle.toLowerCase().contains(q) &&
          !l.address.toLowerCase().contains(q) &&
          !l.tags.any((t) => t.toLowerCase().contains(q))) {
        return false;
      }
      if (_cuisines.isNotEmpty && !_cuisines.any(l.slugs.contains)) return false;
      if (_kosher == 'kosher' && !l.isKosher) return false;
      if (_kosher == 'not' && l.isKosher) return false;
      if (_minRating > 0 && l.rating < _minRating) return false;
      if (_dining.isNotEmpty && !_dining.any(l.dining.contains)) return false;
      return true;
    }).toList();

    // `_allListings` already arrives newest first. `List.sort` is not stable,
    // so ties keep that order through the original position.
    int keep(_Listing a, _Listing b) => rows.indexOf(a).compareTo(rows.indexOf(b));
    return switch (_sort) {
      _Sort.newest => rows,
      _Sort.rating => [...rows]..sort((a, b) {
        final byRating = b.rating.compareTo(a.rating);
        if (byRating != 0) return byRating;
        final byCount = b.reviews.compareTo(a.reviews);
        return byCount != 0 ? byCount : keep(a, b);
      }),
      _Sort.name => [...rows]..sort((a, b) => a.name.compareTo(b.name)),
    };
  }

  String _sortLabel(_Sort sort) => switch (sort) {
    _Sort.newest => _t('Newest', 'חדש ביותר'),
    _Sort.rating => _t('Rating', 'דירוג'),
    _Sort.name => _t('Name', 'שם'),
  };

  @override
  Widget build(BuildContext context) {
    final listings = _listings;
    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // The site's own bar, with its menus and the language switch. This
            // page used to carry a copy of it whose links opened no menus.
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: 'restaurants',
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFilterSidebar(),
                  Expanded(flex: 900, child: _buildListingsPanel(listings)),
                  Expanded(flex: 726, child: _buildMapPanel(listings)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FILTER SIDEBAR — 294px
  // ─────────────────────────────────────────────
  Widget _buildFilterSidebar() {
    return Container(
      width: 294,
      decoration: const BoxDecoration(
        color: _kSidebarBg,
        border: BorderDirectional(end: BorderSide(color: _kBorder)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBox(),
            const SizedBox(height: 16),
            // ── Cuisine ──
            _buildFilterGroup(
              title: _t('Cuisine', 'סוג מטבח'),
              items: [
                _checkboxRow(
                  label: _t('All Cuisines', 'כל סוגי המטבח'),
                  checked: _cuisines.isEmpty,
                  onTap: () => setState(_cuisines.clear),
                ),
                ..._cuisineOptions.map(
                  (o) => _checkboxRow(
                    label: o.label,
                    checked: _cuisines.contains(o.key),
                    onTap: () => setState(() {
                      if (!_cuisines.remove(o.key)) _cuisines.add(o.key);
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // ── Kosher ──
            _buildFilterGroup(
              title: _t('Kosher', 'כשרות'),
              items: [
                _checkboxRow(
                  label: _t('All', 'הכל'),
                  checked: _kosher == 'all',
                  onTap: () => setState(() => _kosher = 'all'),
                ),
                _checkboxRow(
                  label: _t('Kosher', 'כשר'),
                  checked: _kosher == 'kosher',
                  onTap: () => setState(() => _kosher = 'kosher'),
                ),
                _checkboxRow(
                  label: _t('Not Kosher', 'לא כשר'),
                  checked: _kosher == 'not',
                  onTap: () => setState(() => _kosher = 'not'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // ── Rating ──
            _buildFilterGroup(
              title: _t('Rating', 'דירוג'),
              items: [
                _checkboxRow(
                  label: _t('All', 'הכל'),
                  checked: _minRating == 0,
                  onTap: () => setState(() => _minRating = 0),
                ),
                for (final stars in [4, 3, 2, 1])
                  _checkboxRow(
                    checked: _minRating == stars,
                    onTap: () => setState(() => _minRating = stars),
                    labelWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$stars', style: _checkLabelStyle),
                        const SizedBox(width: 4),
                        SvgPicture.asset('$_kAsset/star14.svg', width: 14, height: 14),
                        const SizedBox(width: 4),
                        Text(_t('& up', 'ומעלה'), style: _checkLabelStyle),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            // ── Dining Options ──
            _buildFilterGroup(
              title: _t('Dining Options', 'אפשרויות הגשה'),
              items: _diningOptions
                  .map(
                    (o) => _checkboxRow(
                      label: o.label,
                      checked: _dining.contains(o.key),
                      onTap: () => setState(() {
                        if (!_dining.remove(o.key)) _dining.add(o.key);
                      }),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _checkLabelStyle => TextStyle(
    fontFamily: AppFonts.inter,
    fontSize: 13,
    height: 16 / 13,
    color: _kTextDark,
  );

  Widget _buildSearchBox() {
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
          SvgPicture.asset('$_kAsset/search16.svg', width: 16, height: 16),
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
                // The app theme fills its fields and rounds them to 50px,
                // which drew a second pill inside this one.
                filled: false,
                hintText: _t(
                  'Search restaurant or cuisine...',
                  'חיפוש מסעדה או סוג מטבח...',
                ),
                hintStyle: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: _kTextGrey,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterGroup({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 17),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          items[i],
        ],
      ],
    );
  }

  Widget _checkboxRow({
    String? label,
    Widget? labelWidget,
    required bool checked,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            SvgPicture.asset(
              checked ? '$_kAsset/check_on.svg' : '$_kAsset/check_off.svg',
              width: 16,
              height: 16,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: labelWidget ??
                  Text(
                    label ?? '',
                    style: _checkLabelStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LISTINGS PANEL — 900px
  // ─────────────────────────────────────────────
  Widget _buildListingsPanel(List<_Listing> listings) {
    final loading = ref.watch(webFoodPlacesProvider).isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _buildListingsHeader(listings.length),
        ),
        const SizedBox(height: 26),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.midBlue, strokeWidth: 2))
              : listings.isEmpty
              ? _buildEmptyState()
              : Scrollbar(
                  controller: _listController,
                  child: ListView.builder(
                    controller: _listController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: listings.length,
                    itemBuilder: (context, i) => _buildListingRow(listings[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildListingsHeader(int count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('$count Restaurant Listings', '$count מסעדות'),
                style: TextStyle(
                  fontFamily: AppFonts.nunito,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  height: 34 / 28,
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
                  color: _kSubtitle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.only(top: 8.5),
          child: _buildSortBox(),
        ),
      ],
    );
  }

  /// It read "Sort by: Newest" under a chevron and had no handler, so the list
  /// could not be reordered. These three are the ones the rows can answer.
  Widget _buildSortBox() {
    return PopupMenuButton<_Sort>(
      initialValue: _sort,
      tooltip: '',
      onSelected: (sort) => setState(() => _sort = sort),
      itemBuilder: (context) => [
        for (final sort in _Sort.values)
          PopupMenuItem(
            value: sort,
            child: Text(
              _sortLabel(sort),
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
            ),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(minWidth: 166),
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _t('Sort by: ', 'מיון: ') + _sortLabel(_sort),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 13),
            SvgPicture.asset('$_kAsset/chevron_down20.svg', width: 20, height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              IconsaxPlusLinear.search_status,
              size: 48,
              color: _kCheckBorder.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              _t(
                'No restaurants match your filters',
                'אין מסעדות שתואמות את הסינון',
              ),
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
              _t(
                'Try clearing a filter or searching for something else.',
                'נסו להסיר סינון או לחפש משהו אחר.',
              ),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                color: _kSubtitle,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingRow(_Listing l) {
    return _ListingRow(
      listing: l,
      isHebrew: _isHebrew,
      highlighted: _hoveredId == l.id || _selectedId == l.id,
      onTap: () => context.push('/business/${l.id}'),
      onHover: (hovering) => setState(() {
        if (hovering) {
          _hoveredId = l.id;
        } else if (_hoveredId == l.id) {
          _hoveredId = null;
        }
      }),
    );
  }

  // ─────────────────────────────────────────────
  // MAP PANEL — 726px
  // ─────────────────────────────────────────────
  Widget _buildMapPanel(List<_Listing> listings) {
    // The map waits for the places, so that it can open framed on them.
    if (ref.watch(webFoodPlacesProvider).isLoading) {
      return const ColoredBox(color: Color(0xFFF2EFE9));
    }
    // Only the places that have coordinates; the rest stay in the list.
    final pinned = listings.where((l) => l.position != null).toList();
    final selected = pinned.where((l) => l.id == _selectedId).firstOrNull;
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 14.2,
            // Framed on the places the list opened with — all of them, or
            // the bars, or the pizzerias. Changing a filter afterwards leaves
            // the map where the visitor has put it.
            initialCameraFit: _fitOf(pinned),
            onTap: (_, _) => setState(() => _selectedId = null),
          ),
          children: [
            const WebMapTiles(),
            MarkerLayer(
              markers: [
                for (final l in pinned)
                  Marker(
                    point: l.position!,
                    width: 40,
                    height: 43.24,
                    // The point of the pin, not its middle, sits on the place.
                    alignment: const Alignment(0, -0.79),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => setState(() => _hoveredId = l.id),
                      onExit: (_) => setState(() {
                        if (_hoveredId == l.id) _hoveredId = null;
                      }),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedId = l.id),
                        child: _MapPin(
                          active: _hoveredId == l.id || _selectedId == l.id,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const WebMapCredit(),
          ],
        ),
        // The clicked pin's place, as the page's compact card, over the map.
        if (selected != null)
          PositionedDirectional(
            start: 24,
            bottom: 32,
            child: _MapCard(
              listing: selected,
              isHebrew: _isHebrew,
              onOpen: () => context.push('/business/${selected.id}'),
              onClose: () => setState(() => _selectedId = null),
            ),
          ),
      ],
    );
  }
}

/// The camera framing [pinned], leaving out any place far from the rest.
///
/// One bar is recorded at Merkaz Tarsa, 12 km north-west of the city, and
/// framing it with the others shrank Modiin to a corner of the map. It keeps
/// its pin; the map simply does not open on it.
CameraFit? _fitOf(List<_Listing> pinned) {
  if (pinned.length < 2) return null;
  double median(List<double> xs) => (xs..sort())[xs.length ~/ 2];
  final middle = LatLng(
    median([for (final l in pinned) l.position!.latitude]),
    median([for (final l in pinned) l.position!.longitude]),
  );
  const distance = Distance();
  final near = [
    for (final l in pinned)
      if (distance.as(LengthUnit.Kilometer, middle, l.position!) <= 6) l.position!,
  ];
  if (near.length < 2) return null;
  return CameraFit.coordinates(
    coordinates: near,
    padding: const EdgeInsets.all(56),
    maxZoom: 16,
  );
}

// ═══════════════════════════════════════════════
// LISTING ROW
// ═══════════════════════════════════════════════
class _ListingRow extends StatelessWidget {
  final _Listing listing;
  final bool isHebrew, highlighted;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;
  const _ListingRow({
    required this.listing,
    required this.isHebrew,
    required this.highlighted,
    required this.onTap,
    required this.onHover,
  });

  String _t(String en, String he) => isHebrew ? he : en;

  @override
  Widget build(BuildContext context) {
    final l = listing;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: highlighted
                ? AppColors.midBlue.withValues(alpha: 0.03)
                : Colors.transparent,
            border: const BorderDirectional(
              bottom: BorderSide(color: _kBorder),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail 261 × 162
              SizedBox(
                width: 261,
                height: 162,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _Thumbnail(url: l.imageUrl, background: l.imageBg),
                ),
              ),
              const SizedBox(width: 24),
              // Content. The design's heart in the top corner is left off:
              // saving a place belongs to an account, and accounts are the
              // app's.
              Expanded(
                child: SizedBox(
                  height: 162,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: placeText(
                              context,
                              l.name,
                              TextStyle(
                                fontFamily: AppFonts.nunito,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                height: 22 / 18,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: placeText(
                              context,
                              l.subtitle,
                              TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
                                height: 17 / 14,
                                color: _kSubtitle,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 17,
                            child: _rating(l),
                          ),
                        ],
                      ),
                      // Address
                      Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 17,
                            child: Center(
                              child: SvgPicture.asset('$_kCardAsset/card_pin.svg', width: 12, height: 16),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: placeText(
                              context,
                              l.address,
                              TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
                                height: 17 / 14,
                                color: _kSubtitle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Badges + Contact
                      SizedBox(
                        height: 40,
                        child: Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                clipBehavior: Clip.hardEdge,
                                children: [
                                  if (l.isKosher)
                                    _badge(_t('Kosher', 'כשר'), withIcon: true),
                                  for (final tag in l.tags) _badge(tag),
                                ],
                              ),
                            ),
                            if (l.phone != null && l.phone!.isNotEmpty)
                              _ContactButton(phone: l.phone!, whatsapp: l.whatsapp, isHebrew: isHebrew),
                          ],
                        ),
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

  /// Only where reviews have earned one. Every row carried a score before,
  /// copied between them.
  Widget _rating(_Listing l) {
    if (l.rating <= 0 && l.reviews <= 0) {
      return Text(
        _t('Not rated yet', 'אין דירוג עדיין'),
        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kTextGrey),
      );
    }
    return Row(
      children: [
        SvgPicture.asset('$_kCardAsset/card_star.svg', width: 16, height: 16),
        const SizedBox(width: 8),
        Text(
          l.rating.toStringAsFixed(1),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '(${l.reviews})',
          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kTextGrey),
        ),
      ],
    );
  }

  Widget _badge(String label, {bool withIcon = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.5),
      child: Container(
        height: 27,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: _kBadgeBlue,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (withIcon) ...[
              SvgPicture.asset('$_kCardAsset/card_kosher.svg', width: 14, height: 14),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 15 / 12,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dials the business — outlined, and filled under the pointer. The button
/// had an empty handler before, so it looked like a way to reach the place
/// and was not one.
class _ContactButton extends StatefulWidget {
  final String phone;
  final String? whatsapp;
  final bool isHebrew;
  const _ContactButton({required this.phone, this.whatsapp, required this.isHebrew});

  @override
  State<_ContactButton> createState() => _ContactButtonState();
}

class _ContactButtonState extends State<_ContactButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Builder(builder: (anchor) => GestureDetector(
        onTap: () => showWebContactMenu(anchor, isHebrew: widget.isHebrew, phone: widget.phone, whatsapp: widget.whatsapp),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.midBlue : Colors.white,
            border: Border.all(color: AppColors.midBlue),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                _hovered ? '$_kCardAsset/card_phone_white.svg' : '$_kCardAsset/card_phone.svg',
                width: 16,
                height: 16,
              ),
              const SizedBox(width: 8),
              Text(
                widget.isHebrew ? 'צור קשר' : 'Contact',
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _hovered ? Colors.white : AppColors.midBlue,
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }
}

/// The cover photo, or a flat placeholder where the business has none.
class _Thumbnail extends StatelessWidget {
  final String? url;
  final Color background;

  const _Thumbnail({required this.url, required this.background});

  Widget get _fallback => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [background, background.withValues(alpha: 0.7)],
      ),
    ),
    child: Center(
      child: Icon(
        IconsaxPlusLinear.image,
        size: 40,
        color: Colors.black.withValues(alpha: 0.15),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final src = url;
    if (src == null || src.isEmpty) return _fallback;
    // A broken link should look like a place with no photo, not like an error.
    return Image.network(
      sizedPhotoUrl(src, 400, 2),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _fallback,
    );
  }
}

// ═══════════════════════════════════════════════
// MAP PIN — the design's white drop with the blue disc and the chef's hat
// ═══════════════════════════════════════════════
class _MapPin extends StatelessWidget {
  final bool active;
  const _MapPin({required this.active});

  @override
  Widget build(BuildContext context) {
    // flutter_svg ignores the drop's shadow filter, so the shadow is drawn
    // here: the same drop, black at a quarter, 2.3 lower and softened.
    return AnimatedScale(
      duration: const Duration(milliseconds: 150),
      scale: active ? 1.15 : 1.0,
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: 40,
        height: 43.24,
        child: Stack(
          children: [
            Positioned.fill(
              top: 2.29,
              child: ImageFiltered(
                imageFilter: _kPinShadowBlur,
                child: SvgPicture.asset(
                  '$_kAsset/map_pin.svg',
                  colorFilter: const ColorFilter.mode(Color(0x40000000), BlendMode.srcIn),
                ),
              ),
            ),
            Positioned.fill(child: SvgPicture.asset('$_kAsset/map_pin.svg')),
          ],
        ),
      ),
    );
  }
}

final _kPinShadowBlur = ImageFilter.blur(sigmaX: 1.14, sigmaY: 1.14);

// ═══════════════════════════════════════════════
// MAP CARD — the clicked pin's place, over the map
// ═══════════════════════════════════════════════
class _MapCard extends StatelessWidget {
  final _Listing listing;
  final bool isHebrew;
  final VoidCallback onOpen, onClose;
  const _MapCard({
    required this.listing,
    required this.isHebrew,
    required this.onOpen,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l = listing;
    final kind = switch (l.kind) {
      FoodKind.restaurant => isHebrew ? 'מסעדה' : 'Restaurant',
      FoodKind.cafe => isHebrew ? 'בית קפה' : 'Cafe',
      FoodKind.bar => isHebrew ? 'בר' : 'Bar',
    };
    return SizedBox(
      width: 301,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: RestaurantCard(
              compact: true,
              isHebrew: isHebrew,
              onTap: onOpen,
              place: RestaurantPlace(
                name: l.name,
                type: l.cuisine == null ? kind : '$kind · ${l.cuisine}',
                address: l.address,
                rating: l.rating,
                reviews: l.reviews,
                kind: l.kind,
                isKosher: l.isKosher,
                imageBg: l.imageBg,
                imageUrl: l.imageUrl ?? '',
              ),
            ),
          ),
          PositionedDirectional(
            top: 12,
            end: 12,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 5, offset: const Offset(0, 1))],
                  ),
                  child: const Icon(Icons.close, size: 18, color: AppColors.midBlue),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════

class _Option {
  final String key, label;
  const _Option(this.key, this.label);
}

class _Listing {
  /// The business row's id, so a click opens the place it names.
  final String id;
  final String name, subtitle, address;
  final FoodKind kind;

  /// The food categories it is filed under, plus `bars` for a bar — what the
  /// Cuisine boxes match on.
  final Set<String> slugs;

  /// Its sub-category of מסעדות, if any.
  final String? cuisine;
  final double rating;
  final int reviews;
  final bool isKosher;
  final List<String> tags;
  final Set<String> dining;

  /// Null where the business has no coordinates — it is then listed but not
  /// pinned.
  final LatLng? position;
  final String? imageUrl;
  final String? phone;
  final String? whatsapp;

  /// Behind the thumbnail. Not a photo and not claiming to be one; it varies
  /// down the list so the rows stay tellable apart.
  final Color imageBg;

  const _Listing({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.address,
    required this.kind,
    required this.slugs,
    required this.cuisine,
    required this.rating,
    required this.reviews,
    required this.isKosher,
    required this.tags,
    required this.dining,
    required this.position,
    required this.imageBg,
    this.imageUrl,
    this.phone,
    this.whatsapp,
  });

  factory _Listing.of(FoodPlace place, Color placeholder, {required bool takeaway}) {
    final b = place.business;
    return _Listing(
      id: b.id,
      name: b.name,
      // Its own description where it has one ("Wok and Sushi | Asian
      // Restaurant", as drawn), otherwise the category it sits in.
      subtitle: (b.description?.trim().isNotEmpty ?? false)
          ? b.description!.trim()
          : place.categoryName,
      address: b.address,
      kind: place.kind,
      slugs: place.slugs,
      cuisine: place.cuisineName,
      rating: b.rating,
      reviews: b.reviewCount,
      // `kosher_level` is 'none' for a place with no certification, and the
      // model already maps that to null.
      isKosher: b.kosherStatus != null,
      // The pill beside "Kosher" is the cuisine ("Asian"); a place with none
      // shows the category it is filed under.
      tags: [
        if ((place.cuisineName ?? place.categoryName).isNotEmpty)
          place.cuisineName ?? place.categoryName,
      ],
      dining: {if (b.hasDelivery) 'delivery', if (takeaway) 'takeaway'},
      position: place.hasLocation ? LatLng(b.latitude, b.longitude) : null,
      imageUrl: b.imageUrl,
      phone: b.phone,
      whatsapp: b.whatsapp,
      imageBg: placeholder,
    );
  }
}

enum _Sort { newest, rating, name }

/// Thumbnail backgrounds, cycled down the list.
const _kPlaceholders = [
  Color(0xFFE3CFC4),
  Color(0xFFC9D8E0),
  Color(0xFFDCE0C4),
  Color(0xFFE0D3C4),
  Color(0xFFCFD9C4),
];
