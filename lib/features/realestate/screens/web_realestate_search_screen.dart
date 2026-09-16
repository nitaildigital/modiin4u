import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import 'realestate_search_data.dart';

// ═══════════════════════════════════════════════════════════
// Web Real Estate Search — three-panel layout from Figma
// Left: Filter sidebar | Center: Listings | Right: Map
// ═══════════════════════════════════════════════════════════

class WebRealEstateSearchContent extends StatefulWidget {
  final String listingType; // 'sale' or 'rent'
  final String initialQuery;
  const WebRealEstateSearchContent({
    super.key,
    required this.listingType,
    this.initialQuery = '',
  });

  @override
  State<WebRealEstateSearchContent> createState() =>
      _WebRealEstateSearchContentState();
}

class _WebRealEstateSearchContentState
    extends State<WebRealEstateSearchContent> {
  bool _isHebrew = false;
  final _scrollController = ScrollController();
  late final TextEditingController _searchController;

  late SearchFilters _filters;

  bool get _isRent => widget.listingType == 'rent';
  RangeValues get _fullRange => fullPriceRange(isRent: _isRent);
  double get _priceMin => _fullRange.start;
  double get _priceMax => _fullRange.end;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _filters = SearchFilters(
      priceRange: _fullRange,
      query: widget.initialQuery,
    );
    _searchController.addListener(
      () => setState(
        () => _filters = _filters.copyWith(query: _searchController.text),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  // ── Nav items ──
  List<_NavItem> get _navItems => [
        _NavItem(
            label: _t('Professionals', 'בעלי מקצוע'),
            route: '/businesses',
            hasDropdown: true),
        _NavItem(
            label: _t('Modiin News', 'חדשות מודיעין'),
            route: '/news',
            hasDropdown: true),
        _NavItem(label: _t('Events', 'אירועים'), route: '/events'),
        _NavItem(label: _t('Deals', 'מבצעים'), route: '/deals'),
        _NavItem(
            label: _t('Real Estate in Modiin', 'נדל"ן במודיעין'),
            route: '/realestate',
            isActive: true),
        _NavItem(
            label: _t('Restaurants in Modiin', 'מסעדות במודיעין'),
            route: '/restaurants'),
        _NavItem(
            label: _t('Businesses in Modiin', 'עסקים במודיעין'),
            route: '/businesses',
            hasDropdown: true),
      ];

  // ── Listing data ──
  List<SearchListing> get _allListings =>
      searchListings(isRent: _isRent, isHebrew: _isHebrew);

  List<SearchListing> get _listings => applyFilters(_allListings, _filters);

  // ── Map pin positions (relative to map area, % of width/height) ──
  static const _mapPins = [
    Offset(0.25, 0.30),
    Offset(0.45, 0.20),
    Offset(0.60, 0.45),
    Offset(0.35, 0.55),
    Offset(0.70, 0.30),
    Offset(0.50, 0.65),
    Offset(0.20, 0.70),
    Offset(0.80, 0.55),
  ];

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
                  // LEFT: Filter sidebar (fixed 294px)
                  _buildFilterSidebar(),
                  // CENTER: Listings panel
                  Expanded(flex: 5, child: _buildListingsPanel()),
                  // RIGHT: Map panel
                  Expanded(flex: 4, child: _buildMapPanel()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // NAVBAR — same as other web pages
  // ─────────────────────────────────────────────
  Widget _buildNavbar() {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 160),
      child: Row(
        children: [
          // Logo
          GestureDetector(
            onTap: () => context.go('/'),
            child: SvgPicture.asset(
              'assets/images/logo_white.svg',
              width: 90,
              height: 48,
              colorFilter:
                  const ColorFilter.mode(AppColors.midBlue, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 20),
          // Nav links
          Expanded(
            child: Row(
              children: _navItems.map((item) {
                return Expanded(
                  child: _NavLinkButton(
                    label: item.label,
                    isActive: item.isActive,
                    hasDropdown: item.hasDropdown,
                    onTap: () => context.go(item.route),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 20),
          // Language toggle
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _isHebrew = !_isHebrew),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(right: 12),
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
          // CTA
          GestureDetector(
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
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FILTER SIDEBAR — 294px wide
  // ─────────────────────────────────────────────
  Widget _buildFilterSidebar() {
    return Container(
      width: 294,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FA),
        border: Border(right: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search input
            _buildSearchInput(),
            const SizedBox(height: 16),
            // Property Type
            _buildFilterSection(
              title: _t('Property Type', 'סוג נכס'),
              child: Column(
                children: [
                  _buildTypeCheckbox('apartment', _t('Apartment', 'דירה')),
                  _buildTypeCheckbox('penthouse', _t('Penthouse', 'פנטהאוז')),
                  _buildTypeCheckbox(
                      'garden', _t('Garden Apartment', 'דירת גן')),
                  _buildTypeCheckbox('duplex', _t('Duplex', 'דופלקס')),
                  _buildTypeCheckbox('villa', _t('Villa', 'וילה')),
                  _buildTypeCheckbox('studio', _t('Studio', 'סטודיו')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Price Range
            _buildFilterSection(
              title: _t('Price Range', 'טווח מחירים'),
              child: _buildPriceRange(),
            ),
            const SizedBox(height: 16),
            // Rooms
            _buildFilterSection(
              title: _t('Rooms', 'חדרים'),
              child: Column(
                children: [
                  _buildRoomCheckbox(1, _t('1 Room', 'חדר 1')),
                  _buildRoomCheckbox(2, _t('2 Rooms', '2 חדרים')),
                  _buildRoomCheckbox(3, _t('3 Rooms', '3 חדרים')),
                  _buildRoomCheckbox(4, _t('4 Rooms', '4 חדרים')),
                  _buildRoomCheckbox(5, _t('5+ Rooms', '5+ חדרים')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Floor dropdown
            _buildFilterSection(
              title: _t('Floor', 'קומה'),
              child: _buildDropdown(
                value: floorLabel(_isHebrew, _filters.floor),
                options: floorOptions
                    .map((f) => floorLabel(_isHebrew, f))
                    .toList(),
                onSelected: (i) => setState(
                    () => _filters = _filters.copyWith(floor: floorOptions[i])),
              ),
            ),
            const SizedBox(height: 16),
            // Neighborhood dropdown
            _buildFilterSection(
              title: _t('Neighborhood', 'שכונה'),
              child: _buildDropdown(
                value: _filters.neighborhood == 'any'
                    ? _t('Any', 'הכל')
                    : _filters.neighborhood,
                options: [
                  _t('Any', 'הכל'),
                  ...neighborhoodOptions(_isHebrew),
                ],
                onSelected: (i) => setState(() {
                  _filters = _filters.copyWith(
                    neighborhood:
                        i == 0 ? 'any' : neighborhoodOptions(_isHebrew)[i - 1],
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            // Clear all
            if (_filters.activeCount(_fullRange) > 0)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() {
                    _filters = SearchFilters(
                      priceRange: _fullRange,
                      query: _searchController.text,
                    );
                  }),
                  child: Text(
                    _t('Clear all filters', 'נקה את כל הסינונים'),
                    style: GoogleFonts.inter(
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
          const Icon(IconsaxPlusLinear.search_normal_1,
              size: 16, color: Color(0xFF6D6D6D)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.navy),
              decoration: InputDecoration(
                hintText: _t(
                    'Search by location...', 'חיפוש לפי מיקום...'),
                hintStyle: GoogleFonts.inter(
                    fontSize: 14, color: const Color(0xFF6D6D6D)),
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

  Widget _buildFilterSection(
      {required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.navy)),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildTypeCheckbox(String key, String label) {
    final checked = _filters.propertyTypes.contains(key);
    return _checkboxRow(
      label: label,
      checked: checked,
      onTap: () => setState(() {
        final next = Set<String>.from(_filters.propertyTypes);
        checked ? next.remove(key) : next.add(key);
        _filters = _filters.copyWith(propertyTypes: next);
      }),
    );
  }

  Widget _buildRoomCheckbox(int rooms, String label) {
    final checked = _filters.rooms.contains(rooms);
    return _checkboxRow(
      label: label,
      checked: checked,
      onTap: () => setState(() {
        final next = Set<int>.from(_filters.rooms);
        checked ? next.remove(rooms) : next.add(rooms);
        _filters = _filters.copyWith(rooms: next);
      }),
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
                    ? const Icon(Icons.check,
                        size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF3D3D3D))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRange() {
    final range = _filters.priceRange;
    final startFormatted = formatPrice(range.start.round());
    final endFormatted = range.end >= _priceMax
        ? '${formatPrice(_priceMax.round())}+'
        : formatPrice(range.end.round());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$startFormatted – $endFormatted',
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF3D3D3D))),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.midBlue,
            inactiveTrackColor: const Color(0xFFE7E7E7),
            thumbColor: AppColors.midBlue,
            overlayColor: AppColors.midBlue.withValues(alpha: 0.1),
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 9.5),
            trackHeight: 3,
            rangeThumbShape:
                const RoundRangeSliderThumbShape(enabledThumbRadius: 9.5),
          ),
          child: RangeSlider(
            values: range,
            min: _priceMin,
            max: _priceMax,
            divisions: 90,
            onChanged: (values) => setState(
                () => _filters = _filters.copyWith(priceRange: values)),
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
            child: Text(options[i],
                style: GoogleFonts.inter(
                    fontSize: 14,
                    color: options[i] == value
                        ? AppColors.midBlue
                        : const Color(0xFF3D3D3D))),
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
              child: Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF3D3D3D))),
            ),
            const Icon(Icons.keyboard_arrow_down,
                size: 18, color: Color(0xFF7B899A)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LISTINGS PANEL — center, scrollable
  // ─────────────────────────────────────────────
  Widget _buildListingsPanel() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildListingsHeader(),
          // Scrollable list
          Expanded(
            child: _listings.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _listings.length,
                    itemBuilder: (context, index) =>
                        _buildListingCard(_listings[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingsHeader() {
    final typeText = _isRent
        ? _t('for rent', 'להשכרה')
        : _t('for sale', 'למכירה');
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
                      _t('${_listings.length} Apartments found $typeText',
                          '${_listings.length} דירות נמצאו $typeText'),
                      style: GoogleFonts.nunito(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AppColors.midBlue),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _t('in Modiin Maccabim Reut',
                          'במודיעין מכבים רעות'),
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF5F5E5A)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Sort dropdown
              _buildSortDropdown(),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      width: 166,
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
              _t('Sort by: Newest', 'מיון: חדש ביותר'),
              style: GoogleFonts.inter(
                  fontSize: 14, color: const Color(0xFF3D3D3D)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down,
              size: 18, color: Color(0xFF7B899A)),
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
                size: 48, color: const Color(0xFF7B899A).withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              _t('No apartments match your filters',
                  'אין דירות שתואמות את הסינון'),
              style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _t('Try widening the price range or clearing a filter.',
                  'נסו להרחיב את טווח המחירים או להסיר סינון.'),
              style: GoogleFonts.inter(
                  fontSize: 14, color: const Color(0xFF5F5E5A)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingCard(SearchListing listing) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.push('/listing/1'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Container(
                width: 261,
                height: 162,
                decoration: BoxDecoration(
                  color: listing.imageBg,
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      listing.imageBg,
                      listing.imageBg.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(IconsaxPlusLinear.image,
                      size: 40,
                      color: Colors.black.withValues(alpha: 0.15)),
                ),
              ),
              const SizedBox(width: 20),
              // Content
              Expanded(
                child: SizedBox(
                  height: 162,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row + heart
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  listing.title,
                                  style: GoogleFonts.nunito(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.navy),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  listing.neighborhood,
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color:
                                          const Color(0xFF5F5E5A)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Heart button
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF2F3F8),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(IconsaxPlusLinear.heart,
                                  size: 20,
                                  color: AppColors.midBlue),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Specs row
                      Row(
                        children: [
                          _specItem(IconsaxPlusLinear.ruler,
                              '${listing.area} m²'),
                          const SizedBox(width: 31),
                          _specItem(IconsaxPlusLinear.house,
                              '${listing.rooms} ${_t('Rooms', 'חדרים')}'),
                          const SizedBox(width: 31),
                          _specItem(IconsaxPlusLinear.building_4,
                              '${_t('Floor', 'קומה')} ${listing.floor}'),
                          const SizedBox(width: 31),
                          _specItem(IconsaxPlusLinear.category,
                              listing.type),
                        ],
                      ),
                      const Spacer(),
                      // Price row + Contact button
                      Row(
                        children: [
                          Text(listing.price,
                              style: GoogleFonts.nunito(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.midBlue)),
                          if (listing.perMonth != null) ...[
                            const SizedBox(width: 6),
                            Text(listing.perMonth!,
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color:
                                        const Color(0xFF5F5E5A))),
                          ],
                          const Spacer(),
                          // Contact button
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.midBlue),
                                borderRadius:
                                    BorderRadius.circular(60),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                      IconsaxPlusLinear.call,
                                      size: 16,
                                      color: AppColors.midBlue),
                                  const SizedBox(width: 6),
                                  Text(
                                    _t('Contact', 'צור קשר'),
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.midBlue),
                                  ),
                                ],
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

  Widget _specItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6D6D6D)),
        const SizedBox(width: 6),
        Text(text,
            style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF3D3D3D))),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // MAP PANEL — right side
  // ─────────────────────────────────────────────
  Widget _buildMapPanel() {
    return Container(
      color: const Color(0xFFE8E0D0),
      child: Stack(
        children: [
          // Map background with subtle pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _MapBackgroundPainter(),
            ),
          ),
          // Location pins using Align with fractional positioning
          ..._mapPins.map((offset) => Align(
                alignment: Alignment(
                  offset.dx * 2 - 1, // Convert 0..1 to -1..1
                  offset.dy * 2 - 1,
                ),
                child: _buildMapPin(),
              )),
        ],
      ),
    );
  }

  Widget _buildMapPin() {
    return Container(
      width: 40,
      height: 40,
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
        child: Icon(IconsaxPlusBold.location,
            size: 20, color: Color(0xFF006BF6)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// MAP BACKGROUND PAINTER
// ═══════════════════════════════════════════════
class _MapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base color
    final bgPaint = Paint()..color = const Color(0xFFE8E0D0);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Draw some road-like lines
    final roadPaint = Paint()
      ..color = const Color(0xFFD4CDB8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Horizontal roads
    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.15 + i * 0.18);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }

    // Vertical roads
    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.2 + i * 0.2);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }

    // Some block fills to simulate buildings/areas
    final blockPaint = Paint()..color = const Color(0xFFD9D1BF);
    final blocks = [
      Rect.fromLTWH(
          size.width * 0.05, size.height * 0.05, size.width * 0.12, size.height * 0.08),
      Rect.fromLTWH(
          size.width * 0.25, size.height * 0.2, size.width * 0.15, size.height * 0.1),
      Rect.fromLTWH(
          size.width * 0.55, size.height * 0.35, size.width * 0.1, size.height * 0.12),
      Rect.fromLTWH(
          size.width * 0.7, size.height * 0.1, size.width * 0.15, size.height * 0.08),
      Rect.fromLTWH(
          size.width * 0.1, size.height * 0.55, size.width * 0.12, size.height * 0.1),
      Rect.fromLTWH(
          size.width * 0.45, size.height * 0.6, size.width * 0.18, size.height * 0.08),
      Rect.fromLTWH(
          size.width * 0.75, size.height * 0.7, size.width * 0.12, size.height * 0.1),
    ];
    for (final block in blocks) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(block, const Radius.circular(4)),
          blockPaint);
    }

    // Green areas (parks)
    final greenPaint = Paint()..color = const Color(0xFFC8D8B8);
    final parks = [
      Rect.fromLTWH(
          size.width * 0.35, size.height * 0.4, size.width * 0.08, size.height * 0.06),
      Rect.fromLTWH(
          size.width * 0.6, size.height * 0.15, size.width * 0.06, size.height * 0.06),
    ];
    for (final park in parks) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(park, const Radius.circular(8)),
          greenPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: widget.isActive
                    ? AppColors.midBlue
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 16),
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
