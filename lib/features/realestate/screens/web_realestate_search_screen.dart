import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// Web Real Estate Search — three-panel layout from Figma
// Left: Filter sidebar | Center: Listings | Right: Map
// ═══════════════════════════════════════════════════════════

class WebRealEstateSearchContent extends StatefulWidget {
  final String listingType; // 'sale' or 'rent'
  const WebRealEstateSearchContent({super.key, required this.listingType});

  @override
  State<WebRealEstateSearchContent> createState() =>
      _WebRealEstateSearchContentState();
}

class _WebRealEstateSearchContentState
    extends State<WebRealEstateSearchContent> {
  bool _isHebrew = false;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  // Filter state
  final Map<String, bool> _propertyTypeChecks = {
    'apartment': false,
    'penthouse': true,
    'garden': false,
    'duplex': true,
    'villa': false,
    'studio': false,
  };

  RangeValues _priceRange = const RangeValues(1000000, 10000000);
  static const double _priceMin = 1000000;
  static const double _priceMax = 10000000;

  final Map<String, bool> _roomChecks = {
    '1': false,
    '2': true,
    '3': false,
    '4': true,
    '5+': false,
  };

  String _selectedFloor = 'any';
  String _selectedNeighborhood = 'any';

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  bool get _isRent => widget.listingType == 'rent';

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
  List<_SearchListing> get _listings => _isRent ? _rentListings : _saleListings;

  List<_SearchListing> get _saleListings => [
        _SearchListing(
          title: _t('Mini Penthouse 6 Rooms – Avni Hen',
              'מיני פנטהאוז 6 חדרים – אבני חן'),
          neighborhood: _t('Maccabim Reut', 'מכבים רעות'),
          area: '140',
          rooms: '6',
          floor: '3',
          type: _t('Standard Apartment', 'דירה רגילה'),
          price: '₪4,350,000',
          imageBg: const Color(0xFFD4E4F7),
        ),
        _SearchListing(
          title:
              _t('Ha-Rav Kook St, Modiin', 'רח׳ הרב קוק, מודיעין'),
          neighborhood: _t('Maccabim Reut', 'מכבים רעות'),
          area: '120',
          rooms: '5',
          floor: '2',
          type: _t('Standard Apartment', 'דירה רגילה'),
          price: '₪3,600,000',
          imageBg: const Color(0xFFE0D4C8),
        ),
        _SearchListing(
          title: _t('Nachal Shilat, Modiin', 'נחל שילת, מודיעין'),
          neighborhood: _t('Maccabim Reut', 'מכבים רעות'),
          area: '163',
          rooms: '6',
          floor: '4',
          type: _t('Standard Apartment', 'דירה רגילה'),
          price: '₪4,800,000',
          imageBg: const Color(0xFFC8D8E0),
        ),
        _SearchListing(
          title: _t(
              'Sheshet HaYamim, Modiin', 'ששת הימים, מודיעין'),
          neighborhood: _t('Maccabim Reut', 'מכבים רעות'),
          area: '135',
          rooms: '4',
          floor: '1',
          type: _t('Garden Apartment', 'דירת גן'),
          price: '₪4,100,000',
          imageBg: const Color(0xFFD8E8D4),
        ),
        _SearchListing(
          title: _t('Matityahu Doron St, Modiin',
              'רח׳ מתתיהו דורון, מודיעין'),
          neighborhood: _t('Maccabim Reut', 'מכבים רעות'),
          area: '112',
          rooms: '4',
          floor: '2',
          type: _t('Standard Apartment', 'דירה רגילה'),
          price: '₪3,280,000',
          imageBg: const Color(0xFFE8EEF4),
        ),
        _SearchListing(
          title: _t('Hein St 6, Modiin', 'רח׳ חן 6, מודיעין'),
          neighborhood: _t('Maccabim Reut', 'מכבים רעות'),
          area: '112',
          rooms: '4',
          floor: '2',
          type: _t('Standard Apartment', 'דירה רגילה'),
          price: '₪3,280,000',
          imageBg: const Color(0xFFF0E4D4),
        ),
      ];

  List<_SearchListing> get _rentListings => [
        _SearchListing(
          title: _t('Mini Penthouse 6 Rooms – Avni Hen',
              'מיני פנטהאוז 6 חדרים – אבני חן'),
          neighborhood: _t('Maccabim Reut', 'מכבים רעות'),
          area: '140',
          rooms: '6',
          floor: '3',
          type: _t('Standard Apartment', 'דירה רגילה'),
          price: '₪12,500',
          perMonth: _t('/ In the month', '/ לחודש'),
          imageBg: const Color(0xFFE4D8F0),
        ),
        _SearchListing(
          title: _t(
              'Ha-Rav Kook St, Modiin', 'רח׳ הרב קוק, מודיעין'),
          neighborhood: _t('Maccabim Reut', 'מכבים רעות'),
          area: '120',
          rooms: '5',
          floor: '2',
          type: _t('Standard Apartment', 'דירה רגילה'),
          price: '₪9,800',
          perMonth: _t('/ In the month', '/ לחודש'),
          imageBg: const Color(0xFFD4E0F0),
        ),
        _SearchListing(
          title: _t('Nachal Shilat, Modiin', 'נחל שילת, מודיעין'),
          neighborhood: _t('Maccabim Reut', 'מכבים רעות'),
          area: '163',
          rooms: '6',
          floor: '4',
          type: _t('Standard Apartment', 'דירה רגילה'),
          price: '₪14,000',
          perMonth: _t('/ In the month', '/ לחודש'),
          imageBg: const Color(0xFFC8D8E0),
        ),
        _SearchListing(
          title: _t(
              'Sheshet HaYamim, Modiin', 'ששת הימים, מודיעין'),
          neighborhood: _t('Maccabim Reut', 'מכבים רעות'),
          area: '135',
          rooms: '4',
          floor: '1',
          type: _t('Garden Apartment', 'דירת גן'),
          price: '₪8,500',
          perMonth: _t('/ In the month', '/ לחודש'),
          imageBg: const Color(0xFFD8E8D4),
        ),
        _SearchListing(
          title: _t('Matityahu Doron St, Modiin',
              'רח׳ מתתיהו דורון, מודיעין'),
          neighborhood: _t('Maccabim Reut', 'מכבים רעות'),
          area: '112',
          rooms: '4',
          floor: '2',
          type: _t('Standard Apartment', 'דירה רגילה'),
          price: '₪7,200',
          perMonth: _t('/ In the month', '/ לחודש'),
          imageBg: const Color(0xFFE8EEF4),
        ),
        _SearchListing(
          title: _t('Hein St 6, Modiin', 'רח׳ חן 6, מודיעין'),
          neighborhood: _t('Maccabim Reut', 'מכבים רעות'),
          area: '112',
          rooms: '4',
          floor: '2',
          type: _t('Standard Apartment', 'דירה רגילה'),
          price: '₪6,800',
          perMonth: _t('/ In the month', '/ לחודש'),
          imageBg: const Color(0xFFF0E4D4),
        ),
      ];

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
                  _buildCheckbox('apartment',
                      _t('Apartment', 'דירה')),
                  _buildCheckbox('penthouse',
                      _t('Penthouse', 'פנטהאוז')),
                  _buildCheckbox('garden',
                      _t('Garden Apartment', 'דירת גן')),
                  _buildCheckbox(
                      'duplex', _t('Duplex', 'דופלקס')),
                  _buildCheckbox('villa', _t('Villa', 'וילה')),
                  _buildCheckbox(
                      'studio', _t('Studio', 'סטודיו')),
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
                  _buildCheckbox(
                      '1', _t('1 Room', 'חדר 1'),
                      isRoom: true),
                  _buildCheckbox(
                      '2', _t('2 Rooms', '2 חדרים'),
                      isRoom: true),
                  _buildCheckbox(
                      '3', _t('3 Rooms', '3 חדרים'),
                      isRoom: true),
                  _buildCheckbox(
                      '4', _t('4 Rooms', '4 חדרים'),
                      isRoom: true),
                  _buildCheckbox(
                      '5+', _t('5+ Rooms', '5+ חדרים'),
                      isRoom: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Floor dropdown
            _buildFilterSection(
              title: _t('Floor', 'קומה'),
              child: _buildDropdown(
                value: _selectedFloor == 'any'
                    ? _t('Any', 'הכל')
                    : _selectedFloor,
                onTap: () {
                  // Toggle through options for demo
                  setState(() {
                    _selectedFloor =
                        _selectedFloor == 'any' ? '1-3' : 'any';
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            // Neighborhood dropdown
            _buildFilterSection(
              title: _t('Neighborhood', 'שכונה'),
              child: _buildDropdown(
                value: _selectedNeighborhood == 'any'
                    ? _t('Any', 'הכל')
                    : _selectedNeighborhood,
                onTap: () {
                  setState(() {
                    _selectedNeighborhood =
                        _selectedNeighborhood == 'any'
                            ? _t('HaNahalim', 'הנחלים')
                            : 'any';
                  });
                },
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

  Widget _buildCheckbox(String key, String label,
      {bool isRoom = false}) {
    final checks = isRoom ? _roomChecks : _propertyTypeChecks;
    final checked = checks[key] ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => checks[key] = !checked),
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
    final startFormatted = _formatPrice(_priceRange.start);
    final endFormatted = _priceRange.end >= _priceMax
        ? '₪10,000,000+'
        : _formatPrice(_priceRange.end);

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
            values: _priceRange,
            min: _priceMin,
            max: _priceMax,
            divisions: 90,
            onChanged: (values) =>
                setState(() => _priceRange = values),
          ),
        ),
      ],
    );
  }

  String _formatPrice(double value) {
    final intVal = value.round();
    if (intVal >= 1000000) {
      final millions = intVal ~/ 1000000;
      final thousands = (intVal % 1000000) ~/ 1000;
      if (thousands > 0) {
        return '₪$millions,${thousands.toString().padLeft(3, '0')},000';
      }
      return '₪$millions,000,000';
    }
    return '₪${intVal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  Widget _buildDropdown(
      {required String value, required VoidCallback onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
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
            child: ListView.builder(
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
                      _t('124 Apartments found $typeText',
                          '124 דירות נמצאו $typeText'),
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

  Widget _buildListingCard(_SearchListing listing) {
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

class _SearchListing {
  final String title, neighborhood, area, rooms, floor, type, price;
  final String? perMonth;
  final Color imageBg;
  const _SearchListing({
    required this.title,
    required this.neighborhood,
    required this.area,
    required this.rooms,
    required this.floor,
    required this.type,
    required this.price,
    this.perMonth,
    this.imageBg = const Color(0xFFE8EEF4),
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
