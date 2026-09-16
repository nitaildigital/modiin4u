import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
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

class WebRestaurantsMapContent extends StatefulWidget {
  const WebRestaurantsMapContent({super.key});

  @override
  State<WebRestaurantsMapContent> createState() =>
      _WebRestaurantsMapContentState();
}

class _WebRestaurantsMapContentState extends State<WebRestaurantsMapContent> {
  bool _isHebrew = false;
  final _searchController = TextEditingController();
  final _listController = ScrollController();
  final _mapController = MapController();

  String _query = '';
  // Empty set ⇒ "All Cuisines" is checked.
  final Set<String> _cuisines = {};
  String _kosher = 'all'; // all | kosher | not
  int _minRating = 0; // 0 ⇒ "All"
  final Set<String> _dining = {'dine_in'};
  int? _selectedPin;

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
    _NavItem(label: _t('Professionals', 'בעלי מקצוע'), route: '/businesses', hasDropdown: true),
    _NavItem(label: _t('Modiin News', 'חדשות מודיעין'), route: '/news', hasDropdown: true),
    _NavItem(label: _t('Events', 'אירועים'), route: '/events'),
    _NavItem(label: _t('Deals', 'מבצעים'), route: '/deals'),
    _NavItem(label: _t('Real Estate in Modiin', 'נדל"ן במודיעין'), route: '/realestate'),
    _NavItem(label: _t('Restaurants in Modiin', 'מסעדות במודיעין'), route: '/restaurants', isActive: true),
    _NavItem(label: _t('Businesses in Modiin', 'עסקים במודיעין'), route: '/businesses', hasDropdown: true),
  ];

  // ── Filter definitions ──
  List<_Option> get _cuisineOptions => [
    _Option('asian', _t('Asian', 'אסייתי')),
    _Option('italian', _t('Italian', 'איטלקי')),
    _Option('middle_eastern', _t('Middle Eastern', 'מזרח תיכוני')),
    _Option('seafood', _t('Seafood', 'פירות ים')),
    _Option('steak', _t('Steak House', 'מסעדת בשרים')),
  ];

  List<_Option> get _diningOptions => [
    _Option('dine_in', _t('Dine In', 'ישיבה במקום')),
    _Option('take_away', _t('Take Away', 'טייק אווי')),
    _Option('delivery', _t('Delivery', 'משלוחים')),
  ];

  // ── Listings ──
  List<_Listing> get _allListings => [
    _Listing(
      name: _t('Zalman Shazar, Modiin', 'זלמן שזר, מודיעין'),
      subtitle: _t('Wok and Sushi | Asian Restaurant', 'ווק וסושי | מסעדה אסייתית'),
      address: _t("HaMaccabim, Modi'in-Maccabim-Re'ut, Israel", 'המכבים, מודיעין-מכבים-רעות'),
      rating: 4.8, reviews: 512,
      cuisine: 'asian', isKosher: true,
      tags: [_t('Asian', 'אסייתי')],
      dining: const {'dine_in', 'take_away', 'delivery'},
      position: const LatLng(31.8968, 35.0072),
      imageBg: const Color(0xFFE3CFC4),
    ),
    _Listing(
      name: _t('AKA AKA - Modiin', 'אקה אקה - מודיעין'),
      subtitle: _t('Asian Restaurant & Sushi Bar', 'מסעדה אסייתית וסושי בר'),
      address: _t('Nahal Zohar 22, Modiin Maccabim Reut, Israel', 'נחל זוהר 22, מודיעין מכבים רעות'),
      rating: 4.5, reviews: 128,
      cuisine: 'asian', isKosher: true,
      tags: [_t('Asian', 'אסייתי')],
      dining: const {'dine_in', 'take_away'},
      position: const LatLng(31.8942, 35.0158),
      imageBg: const Color(0xFFC9D8E0),
    ),
    _Listing(
      name: _t('Pasta Basta Modiin', 'פסטה בסטה מודיעין'),
      subtitle: _t('Italian Restaurant', 'מסעדה איטלקית'),
      address: _t('HaNasi St 8, Modiin Maccabim Reut', 'הנשיא 8, מודיעין מכבים רעות'),
      rating: 4.0, reviews: 278,
      cuisine: 'italian', isKosher: true,
      tags: [_t('Mediterranean', 'ים תיכוני')],
      dining: const {'dine_in', 'delivery'},
      position: const LatLng(31.8905, 35.0126),
      imageBg: const Color(0xFFDCE0C4),
    ),
    _Listing(
      name: _t('Olive & Fire', 'אוליב אנד פייר'),
      subtitle: _t('Mediterranean Restaurant', 'מסעדה ים תיכונית'),
      address: _t('HaMaccabim Blvd 14, Modiin Maccabim Reut', 'שדרות המכבים 14, מודיעין מכבים רעות'),
      rating: 4.8, reviews: 128,
      cuisine: 'middle_eastern', isKosher: true,
      tags: [_t('Asian', 'אסייתי')],
      dining: const {'dine_in', 'take_away'},
      position: const LatLng(31.8892, 35.0058),
      imageBg: const Color(0xFFD5DFD0),
    ),
    _Listing(
      name: _t('Zalman Shazar, Modiin', 'זלמן שזר, מודיעין'),
      subtitle: _t('Wok and Sushi | Asian Restaurant', 'ווק וסושי | מסעדה אסייתית'),
      address: _t("HaMaccabim, Modi'in-Maccabim-Re'ut, Israel", 'המכבים, מודיעין-מכבים-רעות'),
      rating: 4.8, reviews: 512,
      cuisine: 'asian', isKosher: true,
      tags: [_t('Asian', 'אסייתי')],
      dining: const {'dine_in', 'delivery'},
      position: const LatLng(31.8978, 35.0190),
      imageBg: const Color(0xFFE8D5D0),
    ),
    _Listing(
      name: _t('AKA AKA - Modiin', 'אקה אקה - מודיעין'),
      subtitle: _t('Asian Restaurant & Sushi Bar', 'מסעדה אסייתית וסושי בר'),
      address: _t('Nahal Zohar 22, Modiin Maccabim Reut, Israel', 'נחל זוהר 22, מודיעין מכבים רעות'),
      rating: 4.5, reviews: 128,
      cuisine: 'asian', isKosher: true,
      tags: [_t('Asian', 'אסייתי')],
      dining: const {'dine_in', 'take_away', 'delivery'},
      position: const LatLng(31.8872, 35.0142),
      imageBg: const Color(0xFFD9E8D5),
    ),
    _Listing(
      name: _t('The Red Sea Star', 'רד סי סטאר'),
      subtitle: _t('Seafood Restaurant', 'מסעדת פירות ים'),
      address: _t('Emek Ayalon 3, Modiin Maccabim Reut', 'עמק איילון 3, מודיעין מכבים רעות'),
      rating: 4.7, reviews: 342,
      cuisine: 'seafood', isKosher: false,
      tags: [_t('Seafood', 'פירות ים')],
      dining: const {'dine_in'},
      position: const LatLng(31.8925, 35.0035),
      imageBg: const Color(0xFFD0DFE8),
    ),
    _Listing(
      name: _t('Meat Bar Modiin', 'מיט בר מודיעין'),
      subtitle: _t('Steak House & Grill', 'מסעדת בשרים ועל האש'),
      address: _t('Yigal Alon St 5, Modiin Maccabim Reut', 'יגאל אלון 5, מודיעין מכבים רעות'),
      rating: 4.3, reviews: 196,
      cuisine: 'steak', isKosher: true,
      tags: [_t('Steak House', 'מסעדת בשרים')],
      dining: const {'dine_in', 'take_away'},
      position: const LatLng(31.8952, 35.0208),
      imageBg: const Color(0xFFE8DCD0),
    ),
  ];

  List<_Listing> get _listings {
    final q = _query.toLowerCase();
    return _allListings.where((l) {
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
  }

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
                colorFilter:
                    const ColorFilter.mode(AppColors.midBlue, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Row(
              children: _navItems
                  .map((item) => Expanded(
                        child: _NavLinkButton(
                          label: item.label,
                          isActive: item.isActive,
                          hasDropdown: item.hasDropdown,
                          onTap: () => context.go(item.route),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(width: 20),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _isHebrew = !_isHebrew),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsetsDirectional.only(end: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(IconsaxPlusLinear.global,
                        size: 18, color: AppColors.midBlue),
                    const SizedBox(width: 6),
                    Text(_isHebrew ? 'עב | EN' : 'EN | עב',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.midBlue)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.midBlue,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Text(_t('Contact Us', 'צור קשר'),
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white)),
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
                ..._cuisineOptions.map((o) => _checkboxRow(
                      label: o.label,
                      checked: _cuisines.contains(o.key),
                      onTap: () => setState(() {
                        if (!_cuisines.remove(o.key)) _cuisines.add(o.key);
                      }),
                    )),
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
                        Text('$stars',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: _kTextDark)),
                        const SizedBox(width: 4),
                        const Icon(IconsaxPlusBold.star_1,
                            size: 14, color: _kGold),
                        const SizedBox(width: 4),
                        Text(_t('& up', 'ומעלה'),
                            style: GoogleFonts.inter(
                                fontSize: 13, color: _kTextDark)),
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
                  .map((o) => _checkboxRow(
                        label: o.label,
                        checked: _dining.contains(o.key),
                        onTap: () => setState(() {
                          if (!_dining.remove(o.key)) _dining.add(o.key);
                        }),
                      ))
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
          const Icon(IconsaxPlusLinear.search_normal_1,
              size: 16, color: AppColors.midBlue),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.navy),
              decoration: InputDecoration(
                hintText: _t('Search restaurant or cuisine...',
                    'חיפוש מסעדה או סוג מטבח...'),
                hintStyle:
                    GoogleFonts.inter(fontSize: 14, color: _kTextGrey),
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

  Widget _buildFilterGroup(
      {required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.navy)),
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
                Text(label ?? '',
                    style:
                        GoogleFonts.inter(fontSize: 13, color: _kTextDark)),
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
                style: GoogleFonts.nunito(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    height: 34 / 28,
                    color: AppColors.midBlue),
              ),
              const SizedBox(height: 8),
              Text(
                _t('in Modiin Maccabim Reut', 'במודיעין מכבים רעות'),
                style: GoogleFonts.inter(fontSize: 14, color: _kSubtitle),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _buildSortBox(),
      ],
    );
  }

  Widget _buildSortBox() {
    return Container(
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
              _t('Sort by: Newest', 'מיון: חדש ביותר'),
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down,
              size: 20, color: Color(0xFF4F4F4F)),
        ],
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
            Icon(IconsaxPlusLinear.search_status,
                size: 48, color: _kCheckBorder.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              _t('No restaurants match your filters',
                  'אין מסעדות שתואמות את הסינון'),
              style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _t('Try clearing a filter or searching for something else.',
                  'נסו להסיר סינון או לחפש משהו אחר.'),
              style: GoogleFonts.inter(fontSize: 14, color: _kSubtitle),
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
      selected: _selectedPin == index,
      onTap: () => context.push('/restaurant/1'),
      onHover: (hovering) => setState(() {
        if (hovering) {
          _selectedPin = index;
        } else if (_selectedPin == index) {
          _selectedPin = null;
        }
      }),
    );
  }

  // ─────────────────────────────────────────────
  // MAP PANEL — 726px
  // ─────────────────────────────────────────────
  Widget _buildMapPanel() {
    final listings = _listings;
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 14.2,
        onTap: (_, _) => setState(() => _selectedPin = null),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.modiin4u.app',
        ),
        MarkerLayer(
          markers: List.generate(listings.length, (i) {
            final l = listings[i];
            final selected = _selectedPin == i;
            return Marker(
              point: l.position,
              width: 40,
              height: 44,
              alignment: Alignment.topCenter,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _selectedPin = i),
                onExit: (_) => setState(() {
                  if (_selectedPin == i) _selectedPin = null;
                }),
                child: GestureDetector(
                  onTap: () => context.push('/restaurant/1'),
                  child: _MapPin(selected: selected),
                ),
              ),
            );
          }),
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
                bottom: BorderSide(color: _kBorder)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail 261 × 162
              Container(
                width: 261,
                height: 162,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [l.imageBg, l.imageBg.withValues(alpha: 0.7)],
                  ),
                ),
                child: Center(
                  child: Icon(IconsaxPlusLinear.image,
                      size: 40, color: Colors.black.withValues(alpha: 0.15)),
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
                                  style: GoogleFonts.nunito(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      height: 22 / 18,
                                      color: AppColors.navy),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l.subtitle,
                                  style: GoogleFonts.inter(
                                      fontSize: 14, color: _kSubtitle),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(IconsaxPlusBold.star_1,
                                        size: 16, color: _kGold),
                                    const SizedBox(width: 8),
                                    Text(
                                      l.rating.toStringAsFixed(1),
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('(${l.reviews})',
                                        style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: _kTextGrey)),
                                  ],
                                ),
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
                          const Icon(IconsaxPlusLinear.location,
                              size: 16, color: AppColors.turquoise),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l.address,
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: _kSubtitle),
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
                            ...l.tags.expand((tag) => [
                                  _badge(tag),
                                  const SizedBox(width: 8),
                                ]),
                            const Spacer(),
                            _contactButton(),
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
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 15 / 12,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _contactButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
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
              const Icon(IconsaxPlusLinear.call,
                  size: 16, color: AppColors.midBlue),
              const SizedBox(width: 8),
              Text(_t('Contact', 'צור קשר'),
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.midBlue)),
            ],
          ),
        ),
      ),
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
                  child: Icon(IconsaxPlusLinear.reserve,
                      size: 12, color: Colors.white),
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
  const _NavItem(
      {required this.label,
      required this.route,
      this.hasDropdown = false,
      this.isActive = false});
}

class _Option {
  final String key, label;
  const _Option(this.key, this.label);
}

class _Listing {
  final String name, subtitle, address, cuisine;
  final double rating;
  final int reviews;
  final bool isKosher;
  final List<String> tags;
  final Set<String> dining;
  final LatLng position;
  final Color imageBg;
  const _Listing({
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
  });
}

// ═══════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════

class _NavLinkButton extends StatefulWidget {
  final String label;
  final bool isActive, hasDropdown;
  final VoidCallback onTap;
  const _NavLinkButton(
      {required this.label,
      this.isActive = false,
      this.hasDropdown = false,
      required this.onTap});

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
                color:
                    widget.isActive ? AppColors.midBlue : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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
                      style: GoogleFonts.inter(
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
                    const Icon(Icons.keyboard_arrow_down,
                        size: 18, color: Color(0xFF21272A)),
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
