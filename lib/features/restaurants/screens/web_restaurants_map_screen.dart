import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../providers/restaurant_providers.dart';
import '../widgets/restaurant_place_card.dart' show kHeartRed;

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
const _kGold = Color(0xFFFFC107);
const _kCheckBorder = Color(0xFF7B899A);
const _kPinBlue = Color(0xFF006BF6);

class WebRestaurantsMapContent extends ConsumerStatefulWidget {
  const WebRestaurantsMapContent({super.key});

  @override
  ConsumerState<WebRestaurantsMapContent> createState() =>
      _WebRestaurantsMapContentState();
}

class _WebRestaurantsMapContentState
    extends ConsumerState<WebRestaurantsMapContent> {
  bool _isHebrew = false;
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

  /// The hovered or selected place, by id rather than by index: the map draws
  /// only the places that have coordinates, so an index into the pins is not
  /// an index into the list.
  String? _selectedId;

  static const _center = LatLng(31.8928, 35.0104);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _query = _searchController.text.trim()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listController.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  // ── Nav links ──
  List<_NavItem> get _navItems => [
    _NavItem(
      label: _t('Professionals', 'בעלי מקצוע'),
      route: '/businesses',
      hasDropdown: true,
    ),
    _NavItem(
      label: _t('Modiin News', 'חדשות מודיעין'),
      route: '/news',
      hasDropdown: true,
    ),
    _NavItem(label: _t('Events', 'אירועים'), route: '/events'),
    _NavItem(label: _t('Deals', 'מבצעים'), route: '/deals'),
    _NavItem(
      label: _t('Real Estate in Modiin', 'נדל"ן במודיעין'),
      route: '/realestate',
    ),
    _NavItem(
      label: _t('Restaurants in Modiin', 'מסעדות במודיעין'),
      route: '/restaurants',
      isActive: true,
    ),
    _NavItem(
      label: _t('Businesses in Modiin', 'עסקים במודיעין'),
      route: '/businesses',
      hasDropdown: true,
    ),
  ];

  // ── Filter definitions ──
  //
  // The cuisines are the sub-categories of "restaurants" as the admin panel
  // holds them, so adding one there adds it here. They used to be five keys
  // written into this screen — italian, seafood and steak among them — none of
  // which is a category in the database, so three of the five could never
  // match anything.
  List<_Option> get _cuisineOptions =>
      (ref.watch(cuisineCategoriesProvider).valueOrNull ?? const [])
          .map((c) => _Option(c.slug, c.name))
          .toList();

  /// Only delivery. `has_takeaway` is false on every row, and there is no
  /// column at all for dine-in, so those two checkboxes could only ever
  /// mislead: one would empty the list, the other would narrow nothing.
  List<_Option> get _diningOptions => [
    _Option('delivery', _t('Delivery', 'משלוחים')),
  ];

  // ── Listings ──
  //
  // Eight places written into this screen before, with ratings and review
  // counts nobody had earned, and every row and pin pushing `/restaurant/1`,
  // which matches no row.
  List<_Listing> get _allListings {
    final places =
        ref.watch(foodMapPlacesProvider).valueOrNull ?? const <FoodPlace>[];
    return [
      for (final (i, place) in places.indexed)
        _Listing.of(
          place,
          _isHebrew,
          _kPlaceholders[i % _kPlaceholders.length],
        ),
    ];
  }

  List<_Listing> get _listings {
    final q = _query.toLowerCase();
    final rows = _allListings.where((l) {
      if (q.isNotEmpty &&
          !l.name.toLowerCase().contains(q) &&
          !l.subtitle.toLowerCase().contains(q) &&
          !l.address.toLowerCase().contains(q)) {
        return false;
      }
      if (_cuisines.isNotEmpty && !_cuisines.contains(l.cuisine)) return false;
      if (_kosher == 'kosher' && !l.isKosher) return false;
      if (_kosher == 'not' && l.isKosher) return false;
      if (_minRating > 0 && l.rating < _minRating) return false;
      if (_dining.isNotEmpty && !_dining.any(l.dining.contains)) return false;
      return true;
    }).toList();

    // `_allListings` already arrives newest first, and `List.sort` is not
    // stable — a comparator returning 0 would be free to shuffle the rows.
    return switch (_sort) {
      _Sort.newest => rows,
      _Sort.rating => rows..sort((a, b) => b.rating.compareTo(a.rating)),
      _Sort.name => rows..sort((a, b) => a.name.compareTo(b.name)),
    };
  }

  String _sortLabel(_Sort sort) => switch (sort) {
    _Sort.newest => _t('Newest', 'חדש ביותר'),
    _Sort.rating => _t('Rating', 'דירוג'),
    _Sort.name => _t('Name', 'שם'),
  };

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _buildNavbar(),
            Expanded(
              child: Row(
                children: [
                  _buildFilterSidebar(),
                  Expanded(flex: 900, child: _buildListingsPanel()),
                  Expanded(flex: 726, child: _buildMapPanel()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // NAVBAR
  // ─────────────────────────────────────────────
  Widget _buildNavbar() {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 160),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: SvgPicture.asset(
                'assets/images/logo_white.svg',
                width: 90,
                height: 48,
                colorFilter: const ColorFilter.mode(
                  AppColors.midBlue,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Row(
              children: _navItems
                  .map(
                    (item) => Expanded(
                      child: _NavLinkButton(
                        label: item.label,
                        isActive: item.isActive,
                        hasDropdown: item.hasDropdown,
                        onTap: () => context.go(item.route),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(width: 20),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _isHebrew = !_isHebrew),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                margin: const EdgeInsetsDirectional.only(end: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      IconsaxPlusLinear.global,
                      size: 18,
                      color: AppColors.midBlue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isHebrew ? 'עב | EN' : 'EN | עב',
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.midBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: AppColors.midBlue,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Text(
                  _t('Contact Us', 'צור קשר'),
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
                        Text(
                          '$stars',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 13,
                            color: _kTextDark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          IconsaxPlusBold.star_1,
                          size: 14,
                          color: _kGold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _t('& up', 'ומעלה'),
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 13,
                            color: _kTextDark,
                          ),
                        ),
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
          const Icon(
            IconsaxPlusLinear.search_normal_1,
            size: 16,
            color: AppColors.midBlue,
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
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: checked ? AppColors.midBlue : Colors.white,
                border: Border.all(
                  color: checked ? AppColors.midBlue : _kCheckBorder,
                  width: checked ? 1 : 0.89,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            labelWidget ??
                Text(
                  label ?? '',
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 13,
                    color: _kTextDark,
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
  Widget _buildListingsPanel() {
    final listings = _listings;
    return Container(
      decoration: const BoxDecoration(
        border: BorderDirectional(end: BorderSide(color: _kBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _buildListingsHeader(listings.length),
          ),
          const SizedBox(height: 26),
          Expanded(
            child: listings.isEmpty
                ? _buildEmptyState()
                : Scrollbar(
                    controller: _listController,
                    child: ListView.builder(
                      controller: _listController,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: listings.length,
                      itemBuilder: (context, i) =>
                          _buildListingRow(listings[i], i),
                    ),
                  ),
          ),
        ],
      ),
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
                  color: _kSubtitle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _buildSortBox(),
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
        width: 166,
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _t('Sort by: ', 'מיון: ') + _sortLabel(_sort),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: Color(0xFF4F4F4F),
            ),
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

  Widget _buildListingRow(_Listing l, int index) {
    return _ListingRow(
      listing: l,
      isHebrew: _isHebrew,
      selected: _selectedId == l.id,
      onTap: () => context.push('/business/${l.id}'),
      onHover: (hovering) => setState(() {
        if (hovering) {
          _selectedId = l.id;
        } else if (_selectedId == l.id) {
          _selectedId = null;
        }
      }),
    );
  }

  // ─────────────────────────────────────────────
  // MAP PANEL — 726px
  // ─────────────────────────────────────────────
  Widget _buildMapPanel() {
    // Only the places that have coordinates; the rest stay in the list.
    final pinned = _listings.where((l) => l.position != null).toList();
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 14.2,
        onTap: (_, _) => setState(() => _selectedId = null),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.modiin4u.app',
        ),
        MarkerLayer(
          markers: [
            for (final l in pinned)
              Marker(
                point: l.position!,
                width: 40,
                height: 44,
                alignment: Alignment.topCenter,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _selectedId = l.id),
                  onExit: (_) => setState(() {
                    if (_selectedId == l.id) _selectedId = null;
                  }),
                  child: GestureDetector(
                    onTap: () => context.push('/business/${l.id}'),
                    child: _MapPin(selected: _selectedId == l.id),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// LISTING ROW
// ═══════════════════════════════════════════════
class _ListingRow extends StatefulWidget {
  final _Listing listing;
  final bool isHebrew, selected;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;
  const _ListingRow({
    required this.listing,
    required this.isHebrew,
    required this.selected,
    required this.onTap,
    required this.onHover,
  });

  @override
  State<_ListingRow> createState() => _ListingRowState();
}

class _ListingRowState extends State<_ListingRow> {
  bool _saved = false;

  String _t(String en, String he) => widget.isHebrew ? he : en;

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => widget.onHover(true),
      onExit: (_) => widget.onHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: widget.selected
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
              // Content
              Expanded(
                child: SizedBox(
                  height: 162,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title + rating + save
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.name,
                                  style: TextStyle(
                                    fontFamily: AppFonts.nunito,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    height: 22 / 18,
                                    color: AppColors.navy,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l.subtitle,
                                  style: TextStyle(
                                    fontFamily: AppFonts.inter,
                                    fontSize: 14,
                                    color: _kSubtitle,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // Only where reviews have earned one. Every
                                // row carried a score before, copied between
                                // them.
                                if (l.rating > 0) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        IconsaxPlusBold.star_1,
                                        size: 16,
                                        color: _kGold,
                                      ),
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
                                        style: TextStyle(
                                          fontFamily: AppFonts.inter,
                                          fontSize: 14,
                                          color: _kTextGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 22),
                          // Save circle
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => setState(() => _saved = !_saved),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF2F3F8),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    _saved
                                        ? IconsaxPlusBold.heart
                                        : IconsaxPlusLinear.heart,
                                    size: 20,
                                    color: _saved
                                        ? kHeartRed
                                        : AppColors.midBlue,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Address
                      Row(
                        children: [
                          const Icon(
                            IconsaxPlusLinear.location,
                            size: 16,
                            color: AppColors.turquoise,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l.address,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
                                color: _kSubtitle,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // Badges + Contact
                      SizedBox(
                        height: 40,
                        child: Row(
                          children: [
                            if (l.isKosher) ...[
                              _badge(_t('Kosher', 'כשר'), withIcon: true),
                              const SizedBox(width: 8),
                            ],
                            ...l.tags.expand(
                              (tag) => [_badge(tag), const SizedBox(width: 8)],
                            ),
                            const Spacer(),
                            if (l.phone != null && l.phone!.isNotEmpty)
                              _contactButton(l.phone!),
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

  Widget _badge(String label, {bool withIcon = false}) {
    return Container(
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
            const Icon(IconsaxPlusLinear.verify, size: 14, color: Colors.white),
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
    );
  }

  /// Dials the business. The button had an empty handler before, so it looked
  /// like a way to reach the place and was not one.
  Widget _contactButton(String phone) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => launchUrl(Uri(scheme: 'tel', path: phone)),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.midBlue),
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
              const SizedBox(width: 8),
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
    );
  }
}

/// The cover photo, or a flat placeholder where the business has none — which
/// is most of them.
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
      src,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _fallback,
    );
  }
}

// ═══════════════════════════════════════════════
// MAP PIN — white teardrop with blue disc
// ═══════════════════════════════════════════════
class _MapPin extends StatelessWidget {
  final bool selected;
  const _MapPin({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 150),
      scale: selected ? 1.15 : 1.0,
      child: SizedBox(
        width: 40,
        height: 44,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            const Icon(
              IconsaxPlusBold.location,
              size: 40,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Color(0x40000000),
                  blurRadius: 2.29,
                  offset: Offset(0, 2.29),
                ),
              ],
            ),
            Positioned(
              top: 5.8,
              child: Container(
                width: 21.4,
                height: 21.4,
                decoration: const BoxDecoration(
                  color: _kPinBlue,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    IconsaxPlusLinear.reserve,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════

class _NavItem {
  final String label, route;
  final bool hasDropdown, isActive;
  const _NavItem({
    required this.label,
    required this.route,
    this.hasDropdown = false,
    this.isActive = false,
  });
}

class _Option {
  final String key, label;
  const _Option(this.key, this.label);
}

class _Listing {
  /// The business row's id, so a click opens the place it names.
  final String id;
  final String name, subtitle, address, cuisine;
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

  /// Behind the thumbnail. Not a photo and not claiming to be one; it varies
  /// down the list so the rows stay tellable apart.
  final Color imageBg;

  const _Listing({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.address,
    required this.rating,
    required this.reviews,
    required this.cuisine,
    required this.isKosher,
    required this.tags,
    required this.dining,
    required this.position,
    required this.imageBg,
    this.imageUrl,
    this.phone,
  });

  factory _Listing.of(FoodPlace place, bool isHebrew, Color placeholder) {
    final b = place.business;
    return _Listing(
      id: b.id,
      name: b.name,
      // Its own description where it has one, otherwise the category it sits
      // in. Nothing is composed out of the two.
      subtitle: (b.description?.trim().isNotEmpty ?? false)
          ? b.description!.trim()
          : place.categoryName,
      address: b.address,
      rating: b.rating,
      reviews: b.reviewCount,
      cuisine: place.categorySlug,
      // `kosher_level` is 'none' for a place with no certification, and the
      // model already maps that to null.
      isKosher: b.kosherStatus != null,
      tags: [place.categoryName],
      dining: {if (b.hasDelivery) 'delivery'},
      position: place.hasLocation ? LatLng(b.latitude, b.longitude) : null,
      imageUrl: b.imageUrl,
      phone: b.phone,
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

// ═══════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════

class _NavLinkButton extends StatefulWidget {
  final String label;
  final bool isActive, hasDropdown;
  final VoidCallback onTap;
  const _NavLinkButton({
    required this.label,
    this.isActive = false,
    this.hasDropdown = false,
    required this.onTap,
  });

  @override
  State<_NavLinkButton> createState() => _NavLinkButtonState();
}

class _NavLinkButtonState extends State<_NavLinkButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: widget.isActive ? AppColors.midBlue : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              decoration: BoxDecoration(
                color: _hovered && !widget.isActive
                    ? Colors.black.withValues(alpha: 0.04)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 15,
                        fontWeight: widget.isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: widget.isActive
                            ? AppColors.midBlue
                            : const Color(0xFF0F161E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.hasDropdown) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: Color(0xFF21272A),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
