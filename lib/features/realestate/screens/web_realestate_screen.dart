import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// Web Real Estate — full desktop layout from Figma
// ═══════════════════════════════════════════════════════════

class WebRealEstateContent extends StatefulWidget {
  const WebRealEstateContent({super.key});

  @override
  State<WebRealEstateContent> createState() => _WebRealEstateContentState();
}

class _WebRealEstateContentState extends State<WebRealEstateContent> {
  int _selectedType = -1;
  int _neighborhoodTab = 0; // 0 = For Rent, 1 = For Sale
  int _searchMode = 0; // 0 = Buy, 1 = Rent
  bool _isHebrew = false;
  final _locationController = TextEditingController();
  final _locationFocus = FocusNode();

  @override
  void dispose() {
    _locationController.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  // ── Nav links ──
  List<_NavItem> get _navItems => [
    _NavItem(label: _t('Professionals', 'בעלי מקצוע'), route: '/businesses', hasDropdown: true),
    _NavItem(label: _t('Modiin News', 'חדשות מודיעין'), route: '/news', hasDropdown: true),
    _NavItem(label: _t('Events', 'אירועים'), route: '/events'),
    _NavItem(label: _t('Deals', 'מבצעים'), route: '/deals'),
    _NavItem(label: _t('Real Estate in Modiin', 'נדל"ן במודיעין'), route: '/realestate', isActive: true),
    _NavItem(label: _t('Restaurants in Modiin', 'מסעדות במודיעין'), route: '/restaurants'),
    _NavItem(label: _t('Businesses in Modiin', 'עסקים במודיעין'), route: '/businesses', hasDropdown: true),
  ];

  // ── Property types ──
  List<_PropType> get _propertyTypes => [
    _PropType(name: _t('Apartment', 'דירה'), count: 32, icon: IconsaxPlusBold.building_4),
    _PropType(name: _t('Penthouse', 'פנטהאוז'), count: 24, icon: IconsaxPlusBold.building_3),
    _PropType(name: _t('Garden Apartment', 'דירת גן'), count: 20, icon: IconsaxPlusBold.house),
    _PropType(name: _t('Duplex', 'דופלקס'), count: 15, icon: IconsaxPlusBold.building),
    _PropType(name: _t('Villa', 'וילה'), count: 13, icon: IconsaxPlusBold.house_2),
    _PropType(name: _t('Studio', 'סטודיו'), count: 8, icon: IconsaxPlusBold.lamp),
  ];

  // ── Sale listings ──
  List<_Listing> get _saleListings => [
    _Listing(price: '₪3,650,000', saleTag: _t('FOR SALE', 'למכירה'),
        address: _t('3 Yona Hanavi Street, Modiin', 'רח׳ יונה הנביא 3, מודיעין'),
        area: '140 m²', rooms: _t('6 Rooms', '6 חדרים'), floor: _t('Floor 3', 'קומה 3'),
        isNew: true, newBadge: _t('New', 'חדש'), viaBroker: true, brokerBadge: _t('Via Broker', 'דרך מתווך'), imageBg: const Color(0xFFD4E4F7)),
    _Listing(price: '₪3,790,000', saleTag: _t('FOR SALE', 'למכירה'),
        address: _t('84 Menachem Begin Road', 'שד׳ מנחם בגין 84'),
        area: '133 m²', rooms: _t('4 Rooms', '4 חדרים'), floor: _t('Floor 2', 'קומה 2'),
        isNew: true, newBadge: _t('New', 'חדש'), imageBg: const Color(0xFFE0D4C8)),
    _Listing(price: '₪5,690,000', saleTag: _t('FOR SALE', 'למכירה'),
        address: _t('73 Sarah Amano Street', 'רח׳ שרה אמנו 73'),
        area: '145 m²', rooms: _t('4 Rooms', '4 חדרים'), floor: _t('Floor 3', 'קומה 3'),
        viaBroker: true, brokerBadge: _t('Via Broker', 'דרך מתווך'), imageBg: const Color(0xFFC8D8E0)),
    _Listing(price: '₪3,050,000', saleTag: _t('FOR SALE', 'למכירה'),
        address: _t('37 Ella Valley Street, Modiin', 'רח׳ עמק האלה 37, מודיעין'),
        area: '140 m²', rooms: _t('6 Rooms', '6 חדרים'), floor: _t('Floor 3', 'קומה 3'),
        isNew: true, newBadge: _t('New', 'חדש'), imageBg: const Color(0xFFD8E8D4)),
  ];

  // ── Rent listings ──
  List<_Listing> get _rentListings => [
    _Listing(price: '₪7,500', perMonth: _t('/ In the month', '/ לחודש'), saleTag: _t('FOR RENT', 'להשכרה'),
        address: _t('Weizmann Street Heritage Modiin', 'רח׳ ויצמן מורשת מודיעין'),
        area: '140 m²', rooms: _t('6 Rooms', '6 חדרים'), floor: _t('Floor 3', 'קומה 3'),
        isNew: true, newBadge: _t('New', 'חדש'), imageBg: const Color(0xFFE4D8F0)),
    _Listing(price: '₪12,000', perMonth: _t('/ In the month', '/ לחודש'), saleTag: _t('FOR RENT', 'להשכרה'),
        address: _t('12 Yitzhak Shamir Street, Modiin (Legacy)', 'רח׳ יצחק שמיר 12, מודיעין (מורשת)'),
        area: '122 m²', rooms: _t('4 Rooms', '4 חדרים'), floor: _t('Floor 2', 'קומה 2'),
        isNew: true, newBadge: _t('New', 'חדש'), viaBroker: true, brokerBadge: _t('Via Broker', 'דרך מתווך'), imageBg: const Color(0xFFD4E0F0)),
    _Listing(price: '₪6,500', perMonth: _t('/ In the month', '/ לחודש'), saleTag: _t('FOR RENT', 'להשכרה'),
        address: _t('Yitzhak Rabin Modiin Street', 'רח׳ יצחק רבין מודיעין'),
        area: '85 m²', rooms: _t('4 Rooms', '4 חדרים'), floor: _t('Floor 3', 'קומה 3'),
        imageBg: const Color(0xFFF0E4D4)),
    _Listing(price: '₪8,500', perMonth: _t('/ In the month', '/ לחודש'), saleTag: _t('FOR RENT', 'להשכרה'),
        address: _t('37 Ella Valley Street, Modiin', 'רח׳ עמק האלה 37, מודיעין'),
        area: '140 m²', rooms: _t('6 Rooms', '6 חדרים'), floor: _t('Floor 3', 'קומה 3'),
        viaBroker: true, brokerBadge: _t('Via Broker', 'דרך מתווך'), imageBg: const Color(0xFFE8E0D8)),
  ];

  // ── Neighborhoods ──
  List<_Neighborhood> get _neighborhoods => [
    _Neighborhood(name: _t('HaNahalim', 'הנחלים'), imageBg: const Color(0xFFB8D0C8)),
    _Neighborhood(name: _t('Avni Chen / Kaiser', 'אבני חן / קייזר'), imageBg: const Color(0xFFD0C8B8)),
    _Neighborhood(name: _t('Keremim', 'כרמים'), imageBg: const Color(0xFFC8B8D0)),
    _Neighborhood(name: _t('The Birds', 'הציפורים'), imageBg: const Color(0xFFB8C8D0)),
    _Neighborhood(name: _t('Haganim', 'הגנים'), imageBg: const Color(0xFFD0D0B8)),
    _Neighborhood(name: _t('The Prophets', 'הנביאים'), imageBg: const Color(0xFFC8D0B8)),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _buildStickyNavbar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeroSection(),
                    _buildBrowseTypes(),
                    _buildListingsSection(
                      title: _t('Apartments for Sale in Modiin', 'דירות למכירה במודיעין'),
                      subtitle: _t('Explore the latest apartments and homes available for sale across Modiin.',
                          'גלו את הדירות והבתים העדכניים ביותר למכירה ברחבי מודיעין.'),
                      listings: _saleListings,
                    ),
                    _buildListingsSection(
                      title: _t('Apartments for Rent in Modiin', 'דירות להשכרה במודיעין'),
                      subtitle: _t('Discover apartments and homes available for rent in the best neighborhoods across Modiin.',
                          'גלו דירות ובתים להשכרה בשכונות הטובות ביותר ברחבי מודיעין.'),
                      listings: _rentListings,
                    ),
                    _buildWhatWeProvide(),
                    _buildNeighborhoods(),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STICKY NAVBAR — flat with bottom border
  // ─────────────────────────────────────────────
  Widget _buildStickyNavbar() {
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
              colorFilter: const ColorFilter.mode(AppColors.midBlue, BlendMode.srcIn),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(IconsaxPlusLinear.global, size: 18, color: AppColors.midBlue),
                    const SizedBox(width: 6),
                    Text(_isHebrew ? 'עב | EN' : 'EN | עב',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.midBlue)),
                  ],
                ),
              ),
            ),
          ),
          // CTA
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.midBlue,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Text(_t('Contact Us', 'צור קשר'),
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HERO — large image with gradient + search
  // ─────────────────────────────────────────────
  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      height: 662,
      color: Colors.white,
      child: Stack(
        children: [
          // Hero image card
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              margin: const EdgeInsets.only(top: 48),
              height: 551,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF80B2DF), Color(0xFF4A8BC4), Color(0xFF2D6A9F)],
                ),
              ),
              child: Stack(
                children: [
                  // Top gradient overlay
                  Positioned(
                    top: 0, left: 0, right: 0, height: 428,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [const Color(0xFF80B2DF).withValues(alpha: 0.6), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 112),
                        Text(
                          _t('Find Your Perfect Home in Modiin', 'מצאו את הבית המושלם במודיעין'),
                          style: GoogleFonts.nunito(fontSize: 44, fontWeight: FontWeight.w600, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _t('Discover apartments and homes available for sale and rent.',
                              'גלו דירות ובתים למכירה ולהשכרה.'),
                          style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        // Search bar
                        _buildSearchBar(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSearch() {
    final query = _locationController.text.trim();
    final path = _searchMode == 0 ? '/apartments-sale' : '/apartments-rent';
    context.push(Uri(
      path: path,
      queryParameters: query.isEmpty ? null : {'q': query},
    ).toString());
  }

  Widget _buildSearchBar() {
    final searchModes = [
      _t('Buy', 'לקנות'),
      _t('Rent', 'לשכור'),
    ];

    return Container(
      constraints: const BoxConstraints(maxWidth: 848),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16)],
      ),
      child: Row(
        children: [
          // "I'm looking to" dropdown
          _SearchDropdown(
            label: _t("I'm looking to", 'אני מחפש'),
            value: searchModes[_searchMode],
            items: searchModes,
            onChanged: (idx) => setState(() => _searchMode = idx),
          ),
          const SizedBox(width: 47),
          // Vertical divider
          Container(width: 1, height: 36, color: const Color(0xFFE0E0E0)),
          const SizedBox(width: 24),
          // Location text field
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_t('Location / Neighborhood', 'מיקום / שכונה'),
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5F5E5A))),
                const SizedBox(height: 6),
                TextField(
                  controller: _locationController,
                  focusNode: _locationFocus,
                  style: GoogleFonts.inter(fontSize: 16, color: Colors.black),
                  decoration: InputDecoration(
                    hintText: _t('Enter an address, neighborhood or area.', 'הזינו כתובת, שכונה או אזור.'),
                    hintStyle: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF4F4F4F)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    isCollapsed: true,
                  ),
                  onSubmitted: (_) => _onSearch(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Search button
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _onSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.midBlue,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(IconsaxPlusLinear.search_normal_1, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(_t('Search', 'חיפוש'), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BROWSE BY TYPE — 6 property type cards
  // ─────────────────────────────────────────────
  Widget _buildBrowseTypes() {
    return _Section(
      maxWidth: 1200,
      child: Column(
        children: [
          const SizedBox(height: 48),
          Text(_t('Browse Real Estate', 'חפשו נדל"ן'), style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 900 ? 6 : 3;
              final gap = 16.0;
              final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                alignment: WrapAlignment.center,
                children: List.generate(_propertyTypes.length, (i) {
                  final type = _propertyTypes[i];
                  final selected = _selectedType == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = selected ? -1 : i),
                    child: Container(
                      width: cardWidth,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: selected ? AppColors.midBlue : const Color(0xFFE7E7E7), width: selected ? 2 : 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(type.icon, size: 32, color: AppColors.midBlue),
                          const SizedBox(height: 19),
                          Text(type.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black), textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          Text(_t('${type.count} Properties', '${type.count} נכסים'),
                              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6D6D6D)), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LISTINGS SECTION — sale or rent
  // ─────────────────────────────────────────────
  Widget _buildListingsSection({required String title, required String subtitle, required List<_Listing> listings}) {
    return _Section(
      child: Column(
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
                    const SizedBox(height: 10),
                    Text(subtitle, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5F5E5A))),
                  ],
                ),
              ),
              _ViewAllButton(label: _t('View all properties', 'ראה את כל הנכסים'), onTap: () {}),
            ],
          ),
          const SizedBox(height: 24),
          // Cards grid — 4 in a row
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1);
              final gap = 22.0;
              final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: listings.map((l) => SizedBox(
                  width: cardWidth,
                  child: _ListingCard(listing: l),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 56),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // WHAT WE ARE PROVIDING — 3 service cards
  // ─────────────────────────────────────────────
  Widget _buildWhatWeProvide() {
    return _Section(
      child: Column(
        children: [
          Text(_t('What We Are Providing', 'מה אנחנו מציעים'),
              style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.midBlue),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 900 ? 3 : 1;
              final gap = 21.0;
              final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _ServiceCard(
                    width: cardWidth,
                    icon: IconsaxPlusBold.house,
                    title: _t('Find Your Next Rental', 'מצאו את השכירות הבאה'),
                    subtitle: _t('Browse apartments and homes available for rent across Modiin.',
                        'חפשו דירות ובתים להשכרה ברחבי מודיעין.'),
                    isHighlighted: true,
                  ),
                  _ServiceCard(
                    width: cardWidth,
                    icon: IconsaxPlusLinear.document_upload,
                    title: _t('Sell a Property', 'מכרו נכס'),
                    subtitle: _t('List your property and connect with people looking to buy in Modiin.',
                        'פרסמו את הנכס שלכם והתחברו עם אנשים שמחפשים לקנות במודיעין.'),
                  ),
                  _ServiceCard(
                    width: cardWidth,
                    icon: IconsaxPlusLinear.chart_2,
                    title: _t('Buy a Property', 'קנו נכס'),
                    subtitle: _t('Explore apartments and homes for sale in Modiin. Compare properties, neighborhoods, prices.',
                        'גלו דירות ובתים למכירה במודיעין. השוו נכסים, שכונות, מחירים.'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 56),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // NEIGHBORHOODS
  // ─────────────────────────────────────────────
  Widget _buildNeighborhoods() {
    return _Section(
      child: Column(
        children: [
          Text(_t('Apartments by Neighborhoods', 'דירות לפי שכונות'),
              style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.midBlue),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          // For Rent / For Sale toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() => _neighborhoodTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: _neighborhoodTab == 0 ? AppColors.midBlue : Colors.transparent,
                    border: _neighborhoodTab == 0 ? null : Border.all(color: AppColors.midBlue, width: 2),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(60)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(IconsaxPlusLinear.key, size: 18, color: _neighborhoodTab == 0 ? Colors.white : AppColors.midBlue),
                      const SizedBox(width: 8),
                      Text(_t('For Rent', 'להשכרה'), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: _neighborhoodTab == 0 ? Colors.white : AppColors.midBlue)),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _neighborhoodTab = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: _neighborhoodTab == 1 ? AppColors.midBlue : Colors.transparent,
                    border: _neighborhoodTab == 1 ? null : Border.all(color: AppColors.midBlue, width: 2),
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(60)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(IconsaxPlusLinear.home_hashtag, size: 18, color: _neighborhoodTab == 1 ? Colors.white : AppColors.midBlue),
                      const SizedBox(width: 8),
                      Text(_t('For Sale', 'למכירה'), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: _neighborhoodTab == 1 ? Colors.white : AppColors.midBlue)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Neighborhood cards — scrollable row
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 1200 ? 6 : (constraints.maxWidth > 800 ? 4 : 2);
              final gap = 16.0;
              final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: _neighborhoods.map((n) => SizedBox(
                  width: cardWidth,
                  child: _NeighborhoodCard(data: n, subtitle: _t('Neighborhood, Modiin', 'שכונה, מודיעין'),
                      location: _t('Modiin, Israel', 'מודיעין, ישראל')),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 56),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FOOTER — reuse from homepage pattern
  // ─────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: AppColors.midBlue,
      padding: const EdgeInsets.only(top: 64),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1600),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildFooterContact()),
                        const SizedBox(width: 40),
                        Expanded(flex: 2, child: _buildFooterLinks(_t('Modiin4u', 'מודיעין4u'), [_t('Home', 'בית'), _t('About Us', 'אודותינו'), _t('Contact Us', 'צור קשר'), _t('Privacy Policy', 'מדיניות פרטיות'), _t('Terms of Use', 'תנאי שימוש'), _t('Accessibility Statement', 'הצהרת נגישות')])),
                        const SizedBox(width: 40),
                        Expanded(flex: 2, child: _buildFooterLinks(_t('Explore Modiin', 'גלו את מודיעין'), [_t('News', 'חדשות'), _t('Events', 'אירועים'), _t('Businesses', 'עסקים'), _t('Professionals', 'בעלי מקצוע'), _t('Real Estate', 'נדל"ן'), _t('Map', 'מפה'), _t('Restaurants', 'מסעדות'), _t('Deals', 'מבצעים')])),
                        const SizedBox(width: 40),
                        Expanded(flex: 2, child: _buildFooterLinks(_t('Popular Categories', 'קטגוריות פופולריות'), [_t('Restaurants', 'מסעדות'), _t('Coffee Shops', 'בתי קפה'), _t('Bars', 'ברים'), _t('Professionals', 'בעלי מקצוע'), _t('Real Estate', 'נדל"ן'), _t('Local Businesses', 'עסקים מקומיים'), _t('Events', 'אירועים'), _t('News', 'חדשות')])),
                        const SizedBox(width: 40),
                        Expanded(flex: 3, child: _buildFooterAbout()),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFooterContact(),
                      const SizedBox(height: 40),
                      _buildFooterAbout(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
              // Bottom bar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white24))),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_t('All Rights Reserved to modiin4u.co.il, 2026', 'כל הזכויות שמורות ל-modiin4u.co.il, 2026'),
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFE7E7E7))),
                        Row(
                          children: [
                            Text(_t('Terms of Use', 'תנאי שימוש'), style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFE7E7E7))),
                            const SizedBox(width: 4),
                            const Text('|', style: TextStyle(color: Color(0xFFE7E7E7))),
                            const SizedBox(width: 4),
                            Text(_t('Privacy Policy', 'מדיניות פרטיות'), style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFE7E7E7))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => launchUrl(Uri.parse('https://personaai.me/')),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Powered by ', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                                ).createShader(bounds),
                                child: Text('PersonaAI', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildFooterContact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('We are here for\nany questions.', 'אנחנו כאן\nלכל שאלה.'),
            style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w500, color: Colors.white, height: 1.22)),
        const SizedBox(height: 40),
        _FooterContactRow(icon: IconsaxPlusLinear.call, label: _t('Phone', 'טלפון'), value: '058-4770195'),
        _FooterContactRow(icon: IconsaxPlusLinear.sms, label: _t('Email', 'אימייל'), value: 'modiin4uoffice@gmail.com'),
        _FooterContactRow(icon: IconsaxPlusLinear.message, label: _t('WhatsApp', 'וואטסאפ'), value: '058-4770195'),
        const SizedBox(height: 16),
        Text(_t('Our Socials', 'הרשתות שלנו'), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 19),
        Row(
          children: [
            _socialIcon(child: Text('f', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
            _socialIcon(child: Text('X', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
            _socialIcon(child: Text('in', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))),
            _socialIcon(child: const Icon(IconsaxPlusLinear.instagram, size: 18, color: Colors.white)),
            _socialIcon(child: const Icon(IconsaxPlusLinear.music, size: 18, color: Colors.white)),
          ],
        ),
      ],
    );
  }

  Widget _socialIcon({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(right: 9),
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white38)),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildFooterLinks(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 24),
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(link, style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.9))),
        )),
      ],
    );
  }

  Widget _buildFooterAbout() {
    final alignment = _isHebrew ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final textAlign = _isHebrew ? TextAlign.start : TextAlign.end;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        SvgPicture.asset('assets/images/logo_white.svg', width: 164, height: 88),
        const SizedBox(height: 24),
        Text(_t('Modiin for You', 'מודיעין בשבילך'), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white), textAlign: textAlign),
        const SizedBox(height: 16),
        Text(
          _t('We are not just a news site – we are the beating heart of Modiin! A local media and public relations organization that lives and breathes our city.',
             'אנחנו לא סתם אתר חדשות – אנחנו הלב הפועם של מודיעין! ארגון מדיה ויחסי ציבור מקומי שחי ונושם את העיר שלנו.'),
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.85), height: 1.4),
          textAlign: textAlign,
        ),
        const SizedBox(height: 24),
        Text(_t('Download Our App', 'הורידו את האפליקציה'), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white), textAlign: textAlign),
        const SizedBox(height: 16),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Wrap(
            spacing: 12, runSpacing: 8, alignment: WrapAlignment.end,
            children: [
              _AppStoreBtn(store: 'App Store', label: 'Download on the', svgAsset: 'assets/images/apple_logo.svg', isApple: true),
              _AppStoreBtn(store: 'Google Play', label: 'GET IT ON', svgAsset: 'assets/images/google_play.svg'),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════

class _NavItem {
  final String label, route;
  final bool hasDropdown, isActive;
  const _NavItem({required this.label, required this.route, this.hasDropdown = false, this.isActive = false});
}

class _PropType {
  final String name;
  final int count;
  final IconData icon;
  const _PropType({required this.name, required this.count, required this.icon});
}

class _Listing {
  final String price, saleTag, address, area, rooms, floor;
  final String? perMonth, newBadge, brokerBadge;
  final bool isNew, viaBroker;
  final Color imageBg;
  const _Listing({required this.price, required this.saleTag, required this.address,
    required this.area, required this.rooms, required this.floor,
    this.perMonth, this.newBadge, this.brokerBadge, this.isNew = false, this.viaBroker = false, this.imageBg = const Color(0xFFE8EEF4)});
}

class _Neighborhood {
  final String name;
  final Color imageBg;
  const _Neighborhood({required this.name, required this.imageBg});
}

// ═══════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════

class _SearchDropdown extends StatefulWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<int> onChanged;
  const _SearchDropdown({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  State<_SearchDropdown> createState() => _SearchDropdownState();
}

class _SearchDropdownState extends State<_SearchDropdown> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Tap-away backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          // Dropdown menu
          Positioned(
            width: size.width + 24,
            child: CompositedTransformFollower(
              link: _layerLink,
              offset: Offset(-12, size.height + 8),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(widget.items.length, (i) {
                      final selected = widget.items[i] == widget.value;
                      return InkWell(
                        onTap: () {
                          widget.onChanged(i);
                          _closeDropdown();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          color: selected ? const Color(0xFFF0F4FA) : Colors.transparent,
                          child: Text(
                            widget.items[i],
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              color: selected ? AppColors.midBlue : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _toggleDropdown,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5F5E5A))),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF4F4F4F)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const _Section({required this.child, this.maxWidth = 1600});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class _NavLinkButton extends StatefulWidget {
  final String label;
  final bool isActive, hasDropdown;
  final VoidCallback onTap;
  const _NavLinkButton({required this.label, this.isActive = false, this.hasDropdown = false, required this.onTap});

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
            border: Border(bottom: BorderSide(
              color: widget.isActive ? AppColors.midBlue : Colors.transparent,
              width: 3,
            )),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              decoration: BoxDecoration(
                color: _hovered && !widget.isActive ? Colors.black.withValues(alpha: 0.04) : Colors.transparent,
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
                        fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                        color: widget.isActive ? AppColors.midBlue : const Color(0xFF0F161E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.hasDropdown) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF21272A)),
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

class _ViewAllButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ViewAllButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.midBlue,
          borderRadius: BorderRadius.circular(60),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _ListingCard extends StatefulWidget {
  final _Listing listing;
  const _ListingCard({required this.listing});

  @override
  State<_ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<_ListingCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE7E7E7)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _hovered ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 6))] : [],
        ),
        transform: _hovered ? Matrix4.translationValues(0, -2, 0) : Matrix4.identity(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: l.imageBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Center(child: Icon(IconsaxPlusLinear.image, size: 40, color: Colors.black.withValues(alpha: 0.15))),
                ),
                // Favorite
                Positioned(
                  top: 12, left: 12,
                  child: Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Center(child: Icon(IconsaxPlusLinear.heart, size: 20, color: AppColors.midBlue)),
                  ),
                ),
                // New badge
                if (l.isNew) Positioned(
                  top: 15, right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.turquoise, borderRadius: BorderRadius.circular(50)),
                    child: Text(l.newBadge ?? 'New', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
                  ),
                ),
                // Via Broker
                if (l.viaBroker) Positioned(
                  bottom: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFCCD6EE), borderRadius: BorderRadius.circular(50)),
                    child: Text(l.brokerBadge ?? 'Via Broker', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF0033AC))),
                  ),
                ),
              ],
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price + tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(l.price, style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.navy)),
                          if (l.perMonth != null) ...[
                            const SizedBox(width: 8),
                            Text(l.perMonth!, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5F5E5A))),
                          ],
                        ],
                      ),
                      Text(l.saleTag, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.turquoise)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Address
                  Row(
                    children: [
                      const Icon(IconsaxPlusBold.location, size: 16, color: AppColors.turquoise),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l.address, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5F5E5A)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Details: area, rooms, floor
                  Row(
                    children: [
                      const Icon(IconsaxPlusLinear.ruler, size: 14, color: Color(0xFF6D6D6D)),
                      const SizedBox(width: 8),
                      Text(l.area, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF3D3D3D))),
                      const SizedBox(width: 31),
                      const Icon(IconsaxPlusLinear.house, size: 14, color: Color(0xFF6D6D6D)),
                      const SizedBox(width: 8),
                      Text(l.rooms, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF3D3D3D))),
                      const SizedBox(width: 31),
                      const Icon(IconsaxPlusLinear.building_4, size: 14, color: Color(0xFF6D6D6D)),
                      const SizedBox(width: 8),
                      Text(l.floor, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF3D3D3D))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String title, subtitle;
  final bool isHighlighted;
  const _ServiceCard({required this.width, required this.icon, required this.title, required this.subtitle, this.isHighlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(10),
        boxShadow: isHighlighted ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 1))] : [],
      ),
      child: Column(
        children: [
          Icon(icon, size: 56, color: isHighlighted ? AppColors.midBlue : const Color(0xFF6D6D6D)),
          const SizedBox(height: 20),
          Text(title, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: isHighlighted ? AppColors.midBlue : Colors.black), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF5F5E5A), height: 1.6), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _NeighborhoodCard extends StatefulWidget {
  final _Neighborhood data;
  final String subtitle, location;
  const _NeighborhoodCard({required this.data, required this.subtitle, required this.location});

  @override
  State<_NeighborhoodCard> createState() => _NeighborhoodCardState();
}

class _NeighborhoodCardState extends State<_NeighborhoodCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE7E7E7)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _hovered ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        transform: _hovered ? Matrix4.translationValues(0, -2, 0) : Matrix4.identity(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: widget.data.imageBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Center(child: Icon(IconsaxPlusLinear.image, size: 32, color: Colors.black.withValues(alpha: 0.15))),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.data.name, style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.navy)),
                  const SizedBox(height: 4),
                  Text(widget.subtitle, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5F5E5A))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(IconsaxPlusBold.location, size: 16, color: AppColors.turquoise),
                      const SizedBox(width: 6),
                      Text(widget.location, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5F5E5A))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterContactRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _FooterContactRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 34),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white38)),
            child: Center(child: Icon(icon, size: 16, color: Colors.white)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9))),
              const SizedBox(height: 4),
              Text(value, style: GoogleFonts.inter(fontSize: 16, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppStoreBtn extends StatelessWidget {
  final String store, label, svgAsset;
  final bool isApple;
  const _AppStoreBtn({required this.store, required this.label, required this.svgAsset, this.isApple = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(svgAsset, width: 24, height: 24,
              colorFilter: isApple ? const ColorFilter.mode(Colors.white, BlendMode.srcIn) : null),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.8))),
              const SizedBox(height: 1),
              Text(store, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}
