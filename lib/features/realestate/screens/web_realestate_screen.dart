import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../../core/data/wp_content.dart';

// ═══════════════════════════════════════════════════════════
// Web Real Estate — full desktop layout from Figma
// ═══════════════════════════════════════════════════════════

class WebRealEstateContent extends StatefulWidget {
  const WebRealEstateContent({super.key});

  @override
  State<WebRealEstateContent> createState() => _WebRealEstateContentState();
}

class _WebRealEstateContentState extends State<WebRealEstateContent> {
  /// Listings from the site's apartments directory. Only four are published
  /// today and all are for sale, so the rent section keeps its demo entries.
  List<WpApartment> _apartments = const [];

  @override
  void initState() {
    super.initState();
    loadWpApartments().then((items) {
      if (mounted) setState(() => _apartments = items);
    });
  }

  static const _listingPalette = [
    Color(0xFFD4E4F7),
    Color(0xFFE0D4C8),
    Color(0xFFC8D8E0),
    Color(0xFFD8E8D4),
  ];

  _Listing _toListing(WpApartment a, int i) => _Listing(
    price: a.priceLabel,
    saleTag: a.type,
    address: '${a.shortAddress}, ${a.neighborhood}',
    area: a.meters.isEmpty ? '' : '${a.meters} מ״ר',
    rooms: a.rooms,
    floor: a.floor.isEmpty ? '' : _t('Floor ${a.floor}', 'קומה ${a.floor}'),
    viaBroker: a.byAgent,
    brokerBadge: a.byAgent ? _t('Via Broker', 'דרך מתווך') : null,
    imageBg: _listingPalette[i % _listingPalette.length],
    imageUrl: a.image,
  );

  List<_Listing> get _saleListings => _apartments.isEmpty
      ? _saleListingsDemo
      : [
          for (var i = 0; i < _apartments.length; i++)
            _toListing(_apartments[i], i),
        ];

  List<_Listing> get _rentListings => _rentListingsDemo;

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
  // ── Property types ──
  List<_PropType> get _propertyTypes => [
    _PropType(
      name: _t('Apartment', 'דירה'),
      count: 32,
      icon: IconsaxPlusBold.building_4,
    ),
    _PropType(
      name: _t('Penthouse', 'פנטהאוז'),
      count: 24,
      icon: IconsaxPlusBold.building_3,
    ),
    _PropType(
      name: _t('Garden Apartment', 'דירת גן'),
      count: 20,
      icon: IconsaxPlusBold.house,
    ),
    _PropType(
      name: _t('Duplex', 'דופלקס'),
      count: 15,
      icon: IconsaxPlusBold.building,
    ),
    _PropType(
      name: _t('Villa', 'וילה'),
      count: 13,
      icon: IconsaxPlusBold.house_2,
    ),
    _PropType(
      name: _t('Studio', 'סטודיו'),
      count: 8,
      icon: IconsaxPlusBold.lamp,
    ),
  ];

  // ── Sale listings ──
  List<_Listing> get _saleListingsDemo => [
    _Listing(
      price: '₪3,650,000',
      saleTag: _t('FOR SALE', 'למכירה'),
      address: _t('3 Yona Hanavi Street, Modiin', 'רח׳ יונה הנביא 3, מודיעין'),
      area: '140 m²',
      rooms: _t('6 Rooms', '6 חדרים'),
      floor: _t('Floor 3', 'קומה 3'),
      isNew: true,
      newBadge: _t('New', 'חדש'),
      viaBroker: true,
      brokerBadge: _t('Via Broker', 'דרך מתווך'),
      imageBg: const Color(0xFFD4E4F7),
    ),
    _Listing(
      price: '₪3,790,000',
      saleTag: _t('FOR SALE', 'למכירה'),
      address: _t('84 Menachem Begin Road', 'שד׳ מנחם בגין 84'),
      area: '133 m²',
      rooms: _t('4 Rooms', '4 חדרים'),
      floor: _t('Floor 2', 'קומה 2'),
      isNew: true,
      newBadge: _t('New', 'חדש'),
      imageBg: const Color(0xFFE0D4C8),
    ),
    _Listing(
      price: '₪5,690,000',
      saleTag: _t('FOR SALE', 'למכירה'),
      address: _t('73 Sarah Amano Street', 'רח׳ שרה אמנו 73'),
      area: '145 m²',
      rooms: _t('4 Rooms', '4 חדרים'),
      floor: _t('Floor 3', 'קומה 3'),
      viaBroker: true,
      brokerBadge: _t('Via Broker', 'דרך מתווך'),
      imageBg: const Color(0xFFC8D8E0),
    ),
    _Listing(
      price: '₪3,050,000',
      saleTag: _t('FOR SALE', 'למכירה'),
      address: _t('37 Ella Valley Street, Modiin', 'רח׳ עמק האלה 37, מודיעין'),
      area: '140 m²',
      rooms: _t('6 Rooms', '6 חדרים'),
      floor: _t('Floor 3', 'קומה 3'),
      isNew: true,
      newBadge: _t('New', 'חדש'),
      imageBg: const Color(0xFFD8E8D4),
    ),
  ];

  // ── Rent listings ──
  List<_Listing> get _rentListingsDemo => [
    _Listing(
      price: '₪7,500',
      perMonth: _t('/ In the month', '/ לחודש'),
      saleTag: _t('FOR RENT', 'להשכרה'),
      address: _t('Weizmann Street Heritage Modiin', 'רח׳ ויצמן מורשת מודיעין'),
      area: '140 m²',
      rooms: _t('6 Rooms', '6 חדרים'),
      floor: _t('Floor 3', 'קומה 3'),
      isNew: true,
      newBadge: _t('New', 'חדש'),
      imageBg: const Color(0xFFE4D8F0),
    ),
    _Listing(
      price: '₪12,000',
      perMonth: _t('/ In the month', '/ לחודש'),
      saleTag: _t('FOR RENT', 'להשכרה'),
      address: _t(
        '12 Yitzhak Shamir Street, Modiin (Legacy)',
        'רח׳ יצחק שמיר 12, מודיעין (מורשת)',
      ),
      area: '122 m²',
      rooms: _t('4 Rooms', '4 חדרים'),
      floor: _t('Floor 2', 'קומה 2'),
      isNew: true,
      newBadge: _t('New', 'חדש'),
      viaBroker: true,
      brokerBadge: _t('Via Broker', 'דרך מתווך'),
      imageBg: const Color(0xFFD4E0F0),
    ),
    _Listing(
      price: '₪6,500',
      perMonth: _t('/ In the month', '/ לחודש'),
      saleTag: _t('FOR RENT', 'להשכרה'),
      address: _t('Yitzhak Rabin Modiin Street', 'רח׳ יצחק רבין מודיעין'),
      area: '85 m²',
      rooms: _t('4 Rooms', '4 חדרים'),
      floor: _t('Floor 3', 'קומה 3'),
      imageBg: const Color(0xFFF0E4D4),
    ),
    _Listing(
      price: '₪8,500',
      perMonth: _t('/ In the month', '/ לחודש'),
      saleTag: _t('FOR RENT', 'להשכרה'),
      address: _t('37 Ella Valley Street, Modiin', 'רח׳ עמק האלה 37, מודיעין'),
      area: '140 m²',
      rooms: _t('6 Rooms', '6 חדרים'),
      floor: _t('Floor 3', 'קומה 3'),
      viaBroker: true,
      brokerBadge: _t('Via Broker', 'דרך מתווך'),
      imageBg: const Color(0xFFE8E0D8),
    ),
  ];

  // ── Neighborhoods ──
  List<_Neighborhood> get _neighborhoods => [
    _Neighborhood(
      name: _t('HaNahalim', 'הנחלים'),
      imageBg: const Color(0xFFB8D0C8),
    ),
    _Neighborhood(
      name: _t('Avni Chen / Kaiser', 'אבני חן / קייזר'),
      imageBg: const Color(0xFFD0C8B8),
    ),
    _Neighborhood(
      name: _t('Keremim', 'כרמים'),
      imageBg: const Color(0xFFC8B8D0),
    ),
    _Neighborhood(
      name: _t('The Birds', 'הציפורים'),
      imageBg: const Color(0xFFB8C8D0),
    ),
    _Neighborhood(
      name: _t('Haganim', 'הגנים'),
      imageBg: const Color(0xFFD0D0B8),
    ),
    _Neighborhood(
      name: _t('The Prophets', 'הנביאים'),
      imageBg: const Color(0xFFC8D0B8),
    ),
  ];

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
              activeId: 'realestate',
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeroSection(),
                    _buildBrowseTypes(),
                    _buildListingsSection(
                      title: _t(
                        'Apartments for Sale in Modiin',
                        'דירות למכירה במודיעין',
                      ),
                      subtitle: _t(
                        'Explore the latest apartments and homes available for sale across Modiin.',
                        'גלו את הדירות והבתים העדכניים ביותר למכירה ברחבי מודיעין.',
                      ),
                      listings: _saleListings,
                    ),
                    _buildListingsSection(
                      title: _t(
                        'Apartments for Rent in Modiin',
                        'דירות להשכרה במודיעין',
                      ),
                      subtitle: _t(
                        'Discover apartments and homes available for rent in the best neighborhoods across Modiin.',
                        'גלו דירות ובתים להשכרה בשכונות הטובות ביותר ברחבי מודיעין.',
                      ),
                      listings: _rentListings,
                    ),
                    _buildWhatWeProvide(),
                    _buildNeighborhoods(),
                    WebFooter(isHebrew: _isHebrew),
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
                  colors: [
                    Color(0xFF80B2DF),
                    Color(0xFF4A8BC4),
                    Color(0xFF2D6A9F),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Top gradient overlay
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 428,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF80B2DF).withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
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
                          _t(
                            'Find Your Perfect Home in Modiin',
                            'מצאו את הבית המושלם במודיעין',
                          ),
                          style: TextStyle(
                            fontFamily: AppFonts.nunito,
                            fontSize: 44,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _t(
                            'Discover apartments and homes available for sale and rent.',
                            'גלו דירות ובתים למכירה ולהשכרה.',
                          ),
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 16,
                            color: Colors.white,
                          ),
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
    context.push(
      Uri(
        path: path,
        queryParameters: query.isEmpty ? null : {'q': query},
      ).toString(),
    );
  }

  Widget _buildSearchBar() {
    final searchModes = [_t('Buy', 'לקנות'), _t('Rent', 'לשכור')];

    return Container(
      constraints: const BoxConstraints(maxWidth: 848),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
          ),
        ],
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
                Text(
                  _t('Location / Neighborhood', 'מיקום / שכונה'),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    color: const Color(0xFF5F5E5A),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _locationController,
                  focusNode: _locationFocus,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: _t(
                      'Enter an address, neighborhood or area.',
                      'הזינו כתובת, שכונה או אזור.',
                    ),
                    hintStyle: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      color: const Color(0xFF4F4F4F),
                    ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: AppColors.midBlue,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      IconsaxPlusLinear.search_normal_1,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _t('Search', 'חיפוש'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
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
          Text(
            _t('Browse Real Estate', 'חפשו נדל"ן'),
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.midBlue,
            ),
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 900 ? 6 : 3;
              final gap = 16.0;
              final cardWidth =
                  (constraints.maxWidth - (cols - 1) * gap) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                alignment: WrapAlignment.center,
                children: List.generate(_propertyTypes.length, (i) {
                  final type = _propertyTypes[i];
                  final selected = _selectedType == i;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedType = selected ? -1 : i),
                    child: Container(
                      width: cardWidth,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: selected
                              ? AppColors.midBlue
                              : const Color(0xFFE7E7E7),
                          width: selected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(type.icon, size: 32, color: AppColors.midBlue),
                          const SizedBox(height: 19),
                          Text(
                            type.name,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _t(
                              '${type.count} Properties',
                              '${type.count} נכסים',
                            ),
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              color: const Color(0xFF6D6D6D),
                            ),
                            textAlign: TextAlign.center,
                          ),
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
  Widget _buildListingsSection({
    required String title,
    required String subtitle,
    required List<_Listing> listings,
  }) {
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
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppFonts.nunito,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.midBlue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        color: const Color(0xFF5F5E5A),
                      ),
                    ),
                  ],
                ),
              ),
              _ViewAllButton(
                label: _t('View all properties', 'ראה את כל הנכסים'),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Cards grid — 4 in a row
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 1200
                  ? 4
                  : (constraints.maxWidth > 800 ? 2 : 1);
              final gap = 22.0;
              final cardWidth =
                  (constraints.maxWidth - (cols - 1) * gap) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: listings
                    .map(
                      (l) => SizedBox(
                        width: cardWidth,
                        child: _ListingCard(listing: l),
                      ),
                    )
                    .toList(),
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
          Text(
            _t('What We Are Providing', 'מה אנחנו מציעים'),
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.midBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 900 ? 3 : 1;
              final gap = 21.0;
              final cardWidth =
                  (constraints.maxWidth - (cols - 1) * gap) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _ServiceCard(
                    width: cardWidth,
                    icon: IconsaxPlusBold.house,
                    title: _t('Find Your Next Rental', 'מצאו את השכירות הבאה'),
                    subtitle: _t(
                      'Browse apartments and homes available for rent across Modiin.',
                      'חפשו דירות ובתים להשכרה ברחבי מודיעין.',
                    ),
                    isHighlighted: true,
                  ),
                  _ServiceCard(
                    width: cardWidth,
                    icon: IconsaxPlusLinear.document_upload,
                    title: _t('Sell a Property', 'מכרו נכס'),
                    subtitle: _t(
                      'List your property and connect with people looking to buy in Modiin.',
                      'פרסמו את הנכס שלכם והתחברו עם אנשים שמחפשים לקנות במודיעין.',
                    ),
                  ),
                  _ServiceCard(
                    width: cardWidth,
                    icon: IconsaxPlusLinear.chart_2,
                    title: _t('Buy a Property', 'קנו נכס'),
                    subtitle: _t(
                      'Explore apartments and homes for sale in Modiin. Compare properties, neighborhoods, prices.',
                      'גלו דירות ובתים למכירה במודיעין. השוו נכסים, שכונות, מחירים.',
                    ),
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
          Text(
            _t('Apartments by Neighborhoods', 'דירות לפי שכונות'),
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.midBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // For Rent / For Sale toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() => _neighborhoodTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _neighborhoodTab == 0
                        ? AppColors.midBlue
                        : Colors.transparent,
                    border: _neighborhoodTab == 0
                        ? null
                        : Border.all(color: AppColors.midBlue, width: 2),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(60),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        IconsaxPlusLinear.key,
                        size: 18,
                        color: _neighborhoodTab == 0
                            ? Colors.white
                            : AppColors.midBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _t('For Rent', 'להשכרה'),
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _neighborhoodTab == 0
                              ? Colors.white
                              : AppColors.midBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _neighborhoodTab = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _neighborhoodTab == 1
                        ? AppColors.midBlue
                        : Colors.transparent,
                    border: _neighborhoodTab == 1
                        ? null
                        : Border.all(color: AppColors.midBlue, width: 2),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(60),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        IconsaxPlusLinear.home_hashtag,
                        size: 18,
                        color: _neighborhoodTab == 1
                            ? Colors.white
                            : AppColors.midBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _t('For Sale', 'למכירה'),
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _neighborhoodTab == 1
                              ? Colors.white
                              : AppColors.midBlue,
                        ),
                      ),
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
              final cols = constraints.maxWidth > 1200
                  ? 6
                  : (constraints.maxWidth > 800 ? 4 : 2);
              final gap = 16.0;
              final cardWidth =
                  (constraints.maxWidth - (cols - 1) * gap) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: _neighborhoods
                    .map(
                      (n) => SizedBox(
                        width: cardWidth,
                        child: _NeighborhoodCard(
                          data: n,
                          subtitle: _t(
                            'Neighborhood, Modiin',
                            'שכונה, מודיעין',
                          ),
                          location: _t('Modiin, Israel', 'מודיעין, ישראל'),
                        ),
                      ),
                    )
                    .toList(),
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
}

// ═══════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════

class _PropType {
  final String name;
  final int count;
  final IconData icon;
  const _PropType({
    required this.name,
    required this.count,
    required this.icon,
  });
}

class _Listing {
  final String price, saleTag, address, area, rooms, floor;
  final String? perMonth, newBadge, brokerBadge;
  final bool isNew, viaBroker;
  final Color imageBg;

  /// Remote photo from the WordPress export; empty on demo listings.
  final String imageUrl;
  const _Listing({
    required this.price,
    required this.saleTag,
    required this.address,
    required this.area,
    required this.rooms,
    required this.floor,
    this.perMonth,
    this.newBadge,
    this.brokerBadge,
    this.isNew = false,
    this.viaBroker = false,
    this.imageBg = const Color(0xFFE8EEF4),
    this.imageUrl = '',
  });
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
  const _SearchDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: selected
                              ? const Color(0xFFF0F4FA)
                              : Colors.transparent,
                          child: Text(
                            widget.items[i],
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 16,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: selected
                                  ? AppColors.midBlue
                                  : Colors.black,
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
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: const Color(0xFF5F5E5A),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.value,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: Color(0xFF4F4F4F),
                    ),
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
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
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

Widget _listingFallback(Color base) => ColoredBox(
  color: base,
  child: Center(
    child: Icon(
      IconsaxPlusLinear.image,
      size: 40,
      color: Colors.black.withValues(alpha: 0.15),
    ),
  ),
);

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
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        transform: _hovered
            ? Matrix4.translationValues(0, -2, 0)
            : Matrix4.identity(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                // WordPress serves uploads without CORS headers, so CanvasKit
                // has to hand the URL to a plain <img>.
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: l.imageUrl.isEmpty
                        ? _listingFallback(l.imageBg)
                        : Image.network(
                            l.imageUrl,
                            fit: BoxFit.cover,
                            webHtmlElementStrategy:
                                WebHtmlElementStrategy.prefer,
                            errorBuilder: (_, _, _) =>
                                _listingFallback(l.imageBg),
                            loadingBuilder: (context, child, progress) =>
                                progress == null
                                ? child
                                : _listingFallback(l.imageBg),
                          ),
                  ),
                ),
                // Favorite
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        IconsaxPlusLinear.heart,
                        size: 20,
                        color: AppColors.midBlue,
                      ),
                    ),
                  ),
                ),
                // New badge
                if (l.isNew)
                  Positioned(
                    top: 15,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.turquoise,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        l.newBadge ?? 'New',
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // Via Broker
                if (l.viaBroker)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCD6EE),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        l.brokerBadge ?? 'Via Broker',
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0033AC),
                        ),
                      ),
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
                          Text(
                            l.price,
                            style: TextStyle(
                              fontFamily: AppFonts.nunito,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
                            ),
                          ),
                          if (l.perMonth != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              l.perMonth!,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
                                color: const Color(0xFF5F5E5A),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        l.saleTag,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.turquoise,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Address
                  Row(
                    children: [
                      const Icon(
                        IconsaxPlusBold.location,
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
                            color: const Color(0xFF5F5E5A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Details: area, rooms, floor
                  Row(
                    children: [
                      const Icon(
                        IconsaxPlusLinear.ruler,
                        size: 14,
                        color: Color(0xFF6D6D6D),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l.area,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          color: const Color(0xFF3D3D3D),
                        ),
                      ),
                      const SizedBox(width: 31),
                      const Icon(
                        IconsaxPlusLinear.house,
                        size: 14,
                        color: Color(0xFF6D6D6D),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l.rooms,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          color: const Color(0xFF3D3D3D),
                        ),
                      ),
                      const SizedBox(width: 31),
                      const Icon(
                        IconsaxPlusLinear.building_4,
                        size: 14,
                        color: Color(0xFF6D6D6D),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l.floor,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          color: const Color(0xFF3D3D3D),
                        ),
                      ),
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
  const _ServiceCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(10),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 1),
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 56,
            color: isHighlighted ? AppColors.midBlue : const Color(0xFF6D6D6D),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: isHighlighted ? AppColors.midBlue : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              color: const Color(0xFF5F5E5A),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NeighborhoodCard extends StatefulWidget {
  final _Neighborhood data;
  final String subtitle, location;
  const _NeighborhoodCard({
    required this.data,
    required this.subtitle,
    required this.location,
  });

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
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        transform: _hovered
            ? Matrix4.translationValues(0, -2, 0)
            : Matrix4.identity(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: widget.data.imageBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Icon(
                  IconsaxPlusLinear.image,
                  size: 32,
                  color: Colors.black.withValues(alpha: 0.15),
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data.name,
                    style: TextStyle(
                      fontFamily: AppFonts.nunito,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      color: const Color(0xFF5F5E5A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        IconsaxPlusBold.location,
                        size: 16,
                        color: AppColors.turquoise,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.location,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          color: const Color(0xFF5F5E5A),
                        ),
                      ),
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
