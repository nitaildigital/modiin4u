import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/web_chrome.dart';

// ═══════════════════════════════════════════════════════════
// Web Listing Detail — full desktop layout from Figma
// Page: "Appartments" (single property detail)
// ═══════════════════════════════════════════════════════════

class WebListingDetailContent extends StatefulWidget {
  final String listingId;
  const WebListingDetailContent({super.key, required this.listingId});

  @override
  State<WebListingDetailContent> createState() =>
      _WebListingDetailContentState();
}

class _WebListingDetailContentState extends State<WebListingDetailContent> {
  bool _isHebrew = false;
  bool _aboutExpanded = false;
  bool _isFavorited = false;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
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
      isActive: true,
    ),
    _NavItem(
      label: _t('Restaurants in Modiin', 'מסעדות במודיעין'),
      route: '/restaurants',
    ),
    _NavItem(
      label: _t('Businesses in Modiin', 'עסקים במודיעין'),
      route: '/businesses',
      hasDropdown: true,
    ),
  ];

  // ── Mock data ──
  String get _title => _t(
    'Mini Penthouse 6 Rooms – Moriah Neighborhood',
    'מיני פנטהאוז 6 חדרים – שכונת מוריה',
  );
  String get _address => _t('HaShvatim St 7, Modiin', 'רח׳ השבטים 7, מודיעין');
  String get _price => '₪4,350,000';
  String get _saleTag => _t('For Sale', 'למכירה');

  List<_Highlight> get _highlights => [
    _Highlight(
      label: _t('Bedrooms', 'חדרי שינה'),
      value: '4',
      icon: IconsaxPlusLinear.building_3,
    ),
    _Highlight(
      label: _t('Bathrooms', 'חדרי אמבטיה'),
      value: '2',
      icon: IconsaxPlusLinear.courthouse,
    ),
    _Highlight(
      label: _t('Built-up Area', 'שטח בנוי'),
      value: '140 m²',
      icon: IconsaxPlusLinear.maximize_3,
    ),
    _Highlight(
      label: _t('Floor', 'קומה'),
      value: _t('4 Floor', 'קומה 4'),
      icon: IconsaxPlusLinear.building_4,
    ),
  ];

  String get _aboutProperty => _t(
    'New directly from the contractor, mini penthouse 6 rooms, excellent location in Avni Chen neighborhood, back apartment!! Occupancy 4 months from signing the contract, built 140 m², balcony 18 m². Payment schedule 20/80 without attachments.',
    'חדש ישירות מהקבלן, מיני פנטהאוז 6 חדרים, מיקום מעולה בשכונת אבני חן, דירה אחורית!! אכלוס 4 חודשים מחתימת החוזה, בנוי 140 מ"ר, מרפסת 18 מ"ר. לוח תשלומים 20/80 ללא הצמדות.',
  );

  List<_SpecItem> get _specs => [
    _SpecItem(
      label: _t('Balcony', 'מרפסת'),
      value: _t('Yes', 'כן'),
      icon: IconsaxPlusLinear.element_3,
    ),
    _SpecItem(
      label: _t('Parking', 'חניה'),
      value: _t('Yes', 'כן'),
      icon: IconsaxPlusLinear.car,
    ),
    _SpecItem(
      label: _t('Elevator', 'מעלית'),
      value: _t('Yes', 'כן'),
      icon: IconsaxPlusLinear.arrow_3,
    ),
    _SpecItem(
      label: _t('Protected Space', 'ממ"ד'),
      value: _t('Yes', 'כן'),
      icon: IconsaxPlusLinear.shield_tick,
    ),
  ];

  String get _aboutNeighborhood1 => _t(
    'Moriah is one of the southernmost neighborhoods of Modi\'in-Maccabim-Re\'ut. Formerly known as Buchman South, the neighborhood began to be populated in 2007 and is characterized primarily by private homes and semi-detached houses.',
    'מוריה היא אחת השכונות הדרומיות ביותר של מודיעין-מכבים-רעות. הידועה בעבר כבוכמן דרום, השכונה החלה להתאכלס ב-2007 ומאופיינת בעיקר בבתים פרטיים וצמודי קרקע.',
  );

  String get _aboutNeighborhood2 => _t(
    'The neighborhood takes its name from women from ancient Jewish history, including the four matriarchs and biblical heroines, which is also reflected in many of the street names throughout the neighborhood. Today, Moriah combines residential living with parks, recreation, education and neighborhood shopping. Its southern location also places residents close to major roads and the city\'s southern open spaces.',
    'השכונה קרויה על שם נשים מההיסטוריה היהודית העתיקה, כולל ארבע האמהות וגיבורות מקראיות, מה שבא לידי ביטוי גם בשמות הרחובות. כיום מוריה משלבת מגורים עם פארקים, פנאי, חינוך וקניות שכונתיות. מיקומה הדרומי מציב את התושבים בקרבת כבישים ראשיים ושטחים פתוחים.',
  );

  // ── Nearby properties in Moriah ──
  List<_NearbyProperty> get _nearbyProperties => [
    _NearbyProperty(
      price: '₪7,500',
      perMonth: _t('/ In the month', '/ לחודש'),
      tag: _t('FOR Rent', 'להשכרה'),
      area: '140 m²',
      rooms: _t('6 Rooms', '6 חדרים'),
      floor: _t('Floor 3', 'קומה 3'),
      location: _t('Moriah, Modiin', 'מוריה, מודיעין'),
      imageBg: const Color(0xFFE0D4C8),
    ),
    _NearbyProperty(
      price: '₪3,790,000',
      tag: _t('FOR SALE', 'למכירה'),
      area: '140 m²',
      rooms: _t('6 Rooms', '6 חדרים'),
      floor: _t('Floor 3', 'קומה 3'),
      location: _t('Moriah, Modiin', 'מוריה, מודיעין'),
      imageBg: const Color(0xFFD4E4F7),
    ),
    _NearbyProperty(
      price: '₪5,690,000',
      tag: _t('FOR SALE', 'למכירה'),
      area: '140 m²',
      rooms: _t('6 Rooms', '6 חדרים'),
      floor: _t('Floor 3', 'קומה 3'),
      location: _t('Moriah, Modiin', 'מוריה, מודיעין'),
      imageBg: const Color(0xFFC8D8E0),
    ),
    _NearbyProperty(
      price: '₪7,500',
      perMonth: _t('/ In the month', '/ לחודש'),
      tag: _t('FOR Rent', 'להשכרה'),
      area: '140 m²',
      rooms: _t('6 Rooms', '6 חדרים'),
      floor: _t('Floor 3', 'קומה 3'),
      location: _t('Moriah, Modiin', 'מוריה, מודיעין'),
      imageBg: const Color(0xFFD8E8D4),
    ),
  ];

  // ── Businesses in Moriah ──
  List<_BusinessCard> get _businesses => [
    _BusinessCard(
      name: 'HaNahalım',
      subtitle: _t('Neighborhood, Modiin', 'שכונה, מודיעין'),
      location: _t('Modiin, Israel', 'מודיעין, ישראל'),
      imageBg: const Color(0xFFE8D4B8),
    ),
    _BusinessCard(
      name: _t('Avni Chen / Kaiser', 'אבני חן / קייזר'),
      subtitle: _t('Neighborhood, Modiin', 'שכונה, מודיעין'),
      location: _t('Modiin, Israel', 'מודיעין, ישראל'),
      imageBg: const Color(0xFFD4E4F7),
    ),
    _BusinessCard(
      name: _t('Keremim', 'כרמים'),
      subtitle: _t('Neighborhood, Modiin', 'שכונה, מודיעין'),
      location: _t('Modiin, Israel', 'מודיעין, ישראל'),
      imageBg: const Color(0xFFC8D8E0),
    ),
    _BusinessCard(
      name: _t('The Birds', 'הציפורים'),
      subtitle: _t('Neighborhood, Modiin', 'שכונה, מודיעין'),
      location: _t('Modiin, Israel', 'מודיעין, ישראל'),
      imageBg: const Color(0xFFD8E8D4),
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
            _buildNavbar(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    _buildBreadcrumb(),
                    const SizedBox(height: 32),
                    _buildPhotoGallery(),
                    const SizedBox(height: 28),
                    _buildMainContent(),
                    const SizedBox(height: 64),
                    _buildNearbySection(),
                    const SizedBox(height: 64),
                    _buildBusinessesSection(),
                    const SizedBox(height: 64),
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
  // NAVBAR (80px, identical to other web pages)
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
          // Contact Us button
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
                  _t('Contact Us', 'צרו קשר'),
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
          const SizedBox(width: 20),
          // Nav links
          Expanded(
            child: Row(
              children: _navItems.map((item) {
                return _NavLinkButton(
                  label: item.label,
                  isActive: item.isActive,
                  hasDropdown: item.hasDropdown,
                  onTap: () => context.go(item.route),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 20),
          // Logo
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/'),
              child: SvgPicture.asset('assets/images/logo.svg', height: 48),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BREADCRUMB — back arrow + title + heart + location + badge
  // ─────────────────────────────────────────────
  Widget _buildBreadcrumb() {
    return _Section(
      maxWidth: 1200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: back + title + heart
          Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.canPop()
                      ? context.pop()
                      : context.go('/realestate'),
                  child: const Icon(
                    IconsaxPlusLinear.arrow_left,
                    size: 24,
                    color: AppColors.navy,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _title,
                  style: TextStyle(
                    fontFamily: AppFonts.nunito,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => _isFavorited = !_isFavorited),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF2F3F8),
                    ),
                    child: Icon(
                      _isFavorited
                          ? IconsaxPlusBold.heart
                          : IconsaxPlusLinear.heart,
                      size: 20,
                      color: AppColors.midBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: location + "For Sale" badge
          Row(
            children: [
              const Icon(
                IconsaxPlusBold.location,
                size: 16,
                color: AppColors.turquoise,
              ),
              const SizedBox(width: 8),
              Text(
                _address,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0033AC).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  _saleTag,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0033AC),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PHOTO GALLERY — 1200x514, 4 images grid
  // ─────────────────────────────────────────────
  Widget _buildPhotoGallery() {
    return _Section(
      maxWidth: 1200,
      child: SizedBox(
        height: 514,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Row(
                children: [
                  // Large image left
                  Expanded(
                    flex: 595,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0058B5), Color(0xFF010A36)],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          IconsaxPlusBold.home_2,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Right side — 3 images
                  Expanded(
                    flex: 595,
                    child: Column(
                      children: [
                        // Top image
                        Expanded(
                          flex: 252,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4E4F7),
                              borderRadius: BorderRadius.circular(0),
                            ),
                            child: Center(
                              child: Icon(
                                IconsaxPlusLinear.image,
                                size: 32,
                                color: Colors.black.withValues(alpha: 0.15),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Bottom two images
                        Expanded(
                          flex: 252,
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  color: const Color(0xFFE0D4C8),
                                  child: Center(
                                    child: Icon(
                                      IconsaxPlusLinear.image,
                                      size: 32,
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  color: const Color(0xFFC8D8E0),
                                  child: Center(
                                    child: Icon(
                                      IconsaxPlusLinear.image,
                                      size: 32,
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
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
                ],
              ),
              // "Show all photos" button — bottom right
              Positioned(
                right: 16,
                bottom: 16,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Text(
                      _t('Show all photos', 'הצג את כל התמונות'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MAIN CONTENT — two-column layout
  // Left: price, highlights, about, specs, map, neighborhood
  // Right: contact card (sticky)
  // ─────────────────────────────────────────────
  Widget _buildMainContent() {
    return _Section(
      maxWidth: 1200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT COLUMN — 720px max
          SizedBox(
            width: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPrice(),
                const SizedBox(height: 48),
                _buildHighlights(),
                const SizedBox(height: 63),
                _buildAboutProperty(),
                const SizedBox(height: 63),
                _buildPropertySpecs(),
                const SizedBox(height: 63),
                _buildWhereYoullBe(),
                const SizedBox(height: 64),
                _buildAboutNeighborhood(),
              ],
            ),
          ),
          const Spacer(),
          // RIGHT COLUMN — contact card
          _buildContactCard(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PRICE + ADDRESS
  // ─────────────────────────────────────────────
  Widget _buildPrice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _price,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(
              IconsaxPlusBold.location,
              size: 16,
              color: AppColors.turquoise,
            ),
            const SizedBox(width: 8),
            Text(
              _address,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // HIGHLIGHTS — 2x2 grid
  // ─────────────────────────────────────────────
  Widget _buildHighlights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Highlights', 'דגשים'),
          style: TextStyle(
            fontFamily: AppFonts.nunito,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.midBlue,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: 683,
          child: Column(
            children: [
              Row(
                children: [
                  _buildHighlightItem(_highlights[0]),
                  const SizedBox(width: 20),
                  _buildHighlightItem(_highlights[1]),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  _buildHighlightItem(_highlights[2]),
                  const SizedBox(width: 20),
                  _buildHighlightItem(_highlights[3]),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightItem(_Highlight h) {
    return Expanded(
      child: Row(
        children: [
          Icon(h.icon, size: 32, color: const Color(0xFF5D5D5D)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                h.label,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 12,
                  color: const Color(0xFF5F5E5A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                h.value,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ABOUT THIS PROPERTY
  // ─────────────────────────────────────────────
  Widget _buildAboutProperty() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('About This Property', 'על הנכס'),
          style: TextStyle(
            fontFamily: AppFonts.nunito,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.midBlue,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 620,
          child: Text(
            _aboutProperty,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              color: const Color(0xFF3D3D3D),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // PROPERTY SPECIFICATIONS — 4 cards in a row
  // ─────────────────────────────────────────────
  Widget _buildPropertySpecs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Property Specifications', 'מפרט הנכס'),
          style: TextStyle(
            fontFamily: AppFonts.nunito,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.midBlue,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 721,
          child: Row(
            children: _specs.map((spec) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: spec == _specs.last ? 0 : 16),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 132),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE7E7E7)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(spec.icon, size: 32, color: AppColors.midBlue),
                        const SizedBox(height: 16),
                        Text(
                          spec.label,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          spec.value,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // WHERE YOU'LL BE — map placeholder
  // ─────────────────────────────────────────────
  Widget _buildWhereYoullBe() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Where You\'ll Be', 'היכן תהיו'),
          style: TextStyle(
            fontFamily: AppFonts.nunito,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.midBlue,
          ),
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 720,
            height: 320,
            child: Stack(
              children: [
                Container(
                  color: const Color(0xFFE8F0F8),
                  child: Center(
                    child: Icon(
                      IconsaxPlusBold.map_1,
                      size: 60,
                      color: AppColors.midBlue.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                // Map pin
                Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 2.74,
                          offset: const Offset(0, 2.74),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Color(0xFF006BF6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          IconsaxPlusLinear.user,
                          size: 12,
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
      ],
    );
  }

  // ─────────────────────────────────────────────
  // ABOUT NEIGHBORHOOD — with fade + Read More
  // ─────────────────────────────────────────────
  Widget _buildAboutNeighborhood() {
    return SizedBox(
      width: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('About Moriah', 'על שכונת מוריה'),
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.midBlue,
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _aboutNeighborhood1,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      color: const Color(0xFF3D3D3D),
                      height: 1.6,
                    ),
                  ),
                  if (_aboutExpanded) ...[
                    const SizedBox(height: 16),
                    Text(
                      _aboutNeighborhood2,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        color: const Color(0xFF3D3D3D),
                        height: 1.6,
                      ),
                    ),
                  ],
                  if (!_aboutExpanded) const SizedBox(height: 100),
                ],
              ),
              // White gradient overlay when collapsed
              if (!_aboutExpanded)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 222,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00FFFFFF), Colors.white],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Read More button
          Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _aboutExpanded = !_aboutExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.midBlue),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Text(
                    _aboutExpanded
                        ? _t('Show Less', 'הצג פחות')
                        : _t('Read More', 'קרא עוד'),
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.midBlue,
                    ),
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
  // CONTACT CARD — right sidebar
  // ─────────────────────────────────────────────
  Widget _buildContactCard() {
    return Container(
      width: 374,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('Contact This Property', 'צור קשר עם הנכס'),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t(
              'Get in touch with our real estate expert',
              'צור קשר עם המומחה לנדל"ן שלנו',
            ),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: const Color(0xFF3D3D3D),
            ),
          ),
          const SizedBox(height: 25),
          // Agent row
          Row(
            children: [
              // Avatar placeholder
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD0D0D0),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: const Icon(
                  IconsaxPlusBold.user,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zeev Schumacher',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t('RGF Properties, Modiin', 'RGF נכסים, מודיעין'),
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 12,
                      color: const Color(0xFF6D6D6D),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 26),
          // Contact button
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.midBlue,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Center(
                  child: Text(
                    _t('Contact', 'צור קשר'),
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
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PROPERTIES IN MORIAH — horizontal carousel
  // ─────────────────────────────────────────────
  Widget _buildNearbySection() {
    final controller = ScrollController();
    return _Section(
      maxWidth: 1200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('Properties in Moriah', 'נכסים במוריה'),
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.midBlue,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 275,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ListView.separated(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  itemCount: _nearbyProperties.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 288,
                      child: _NearbyPropertyCard(
                        data: _nearbyProperties[index],
                        isHebrew: _isHebrew,
                      ),
                    );
                  },
                ),
                // Left arrow
                Positioned(
                  left: -20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _CarouselArrow(
                      isLeft: true,
                      onTap: () => controller.animateTo(
                        controller.offset - 304,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
                ),
                // Right arrow
                Positioned(
                  right: -20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _CarouselArrow(
                      isLeft: false,
                      onTap: () => controller.animateTo(
                        controller.offset + 304,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUSINESSES IN MORIAH — horizontal carousel
  // ─────────────────────────────────────────────
  Widget _buildBusinessesSection() {
    final controller = ScrollController();
    return _Section(
      maxWidth: 1200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('Businesses in Moriah', 'עסקים במוריה'),
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.midBlue,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 262,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ListView.separated(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  itemCount: _businesses.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 287.75,
                      child: _BusinessCardWidget(data: _businesses[index]),
                    );
                  },
                ),
                // Left arrow
                Positioned(
                  left: -20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _CarouselArrow(
                      isLeft: true,
                      onTap: () => controller.animateTo(
                        controller.offset - 304,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
                ),
                // Right arrow
                Positioned(
                  right: -20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _CarouselArrow(
                      isLeft: false,
                      onTap: () => controller.animateTo(
                        controller.offset + 304,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FOOTER — reuse from homepage/realestate pattern
  // ─────────────────────────────────────────────
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

class _Highlight {
  final String label, value;
  final IconData icon;
  const _Highlight({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _SpecItem {
  final String label, value;
  final IconData icon;
  const _SpecItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _NearbyProperty {
  final String price, tag, area, rooms, floor, location;
  final String? perMonth;
  final Color imageBg;
  const _NearbyProperty({
    required this.price,
    required this.tag,
    required this.area,
    required this.rooms,
    required this.floor,
    required this.location,
    this.perMonth,
    this.imageBg = const Color(0xFFE8EEF4),
  });
}

class _BusinessCard {
  final String name, subtitle, location;
  final Color imageBg;
  const _BusinessCard({
    required this.name,
    required this.subtitle,
    required this.location,
    this.imageBg = const Color(0xFFE8EEF4),
  });
}

// ═══════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════

class _Section extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const _Section({required this.child, this.maxWidth = 1600});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: child,
        ),
      ),
    );
  }
}

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
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: widget.isActive
                    ? AppColors.turquoise
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: widget.isActive
                      ? AppColors.turquoise
                      : (_hovered
                            ? AppColors.midBlue
                            : const Color(0xFF0F161E)),
                ),
              ),
              if (widget.hasDropdown) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: const Color(0xFF21272A),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CarouselArrow extends StatefulWidget {
  final bool isLeft;
  final VoidCallback onTap;
  const _CarouselArrow({required this.isLeft, required this.onTap});

  @override
  State<_CarouselArrow> createState() => _CarouselArrowState();
}

class _CarouselArrowState extends State<_CarouselArrow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFF8F8F8) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF6F6F6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Icon(
            widget.isLeft
                ? IconsaxPlusLinear.arrow_left_2
                : IconsaxPlusLinear.arrow_right_3,
            size: 20,
            color: AppColors.midBlue,
          ),
        ),
      ),
    );
  }
}

class _NearbyPropertyCard extends StatefulWidget {
  final _NearbyProperty data;
  final bool isHebrew;
  const _NearbyPropertyCard({required this.data, required this.isHebrew});

  @override
  State<_NearbyPropertyCard> createState() => _NearbyPropertyCardState();
}

class _NearbyPropertyCardState extends State<_NearbyPropertyCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
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
            Stack(
              children: [
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: d.imageBg,
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
                // Heart button
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      IconsaxPlusLinear.heart,
                      size: 20,
                      color: AppColors.midBlue,
                    ),
                  ),
                ),
              ],
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            d.price,
                            style: TextStyle(
                              fontFamily: AppFonts.nunito,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
                            ),
                          ),
                          if (d.perMonth != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              d.perMonth!,
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
                        d.tag,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.turquoise,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Stats row: area + rooms + floor
                  Row(
                    children: [
                      _miniStat(IconsaxPlusLinear.maximize_3, d.area),
                      const SizedBox(width: 31),
                      _miniStat(IconsaxPlusLinear.building_3, d.rooms),
                      const SizedBox(width: 31),
                      _miniStat(IconsaxPlusLinear.building_4, d.floor),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Location
                  Row(
                    children: [
                      const Icon(
                        IconsaxPlusBold.location,
                        size: 16,
                        color: AppColors.turquoise,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        d.location,
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

  Widget _miniStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6D6D6D)),
        const SizedBox(width: 8),
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
}

class _BusinessCardWidget extends StatefulWidget {
  final _BusinessCard data;
  const _BusinessCardWidget({required this.data});

  @override
  State<_BusinessCardWidget> createState() => _BusinessCardWidgetState();
}

class _BusinessCardWidgetState extends State<_BusinessCardWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
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
                color: d.imageBg,
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
            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.name,
                    style: TextStyle(
                      fontFamily: AppFonts.nunito,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    d.subtitle,
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
                        d.location,
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
