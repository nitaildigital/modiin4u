import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/web_chrome.dart';

// ═══════════════════════════════════════════════════════════
// Web Neighborhood Detail — full desktop layout from Figma
// Page: "Neighborhood" (single neighborhood detail)
// ═══════════════════════════════════════════════════════════

class WebNeighborhoodDetailContent extends StatefulWidget {
  final String neighborhoodId;
  const WebNeighborhoodDetailContent({super.key, required this.neighborhoodId});

  @override
  State<WebNeighborhoodDetailContent> createState() => _WebNeighborhoodDetailContentState();
}

class _WebNeighborhoodDetailContentState extends State<WebNeighborhoodDetailContent> {
  bool _isHebrew = false;
  bool _aboutExpanded = false;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
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

  // ── Mock data ──
  String get _name => _t('Moriah', 'מוריה');
  String get _city => _t('Modiin', 'מודיעין');

  String get _description => _t(
    'Moriah is one of the southernmost neighborhoods of Modi\'in-Maccabim-Re\'ut. Formerly known as Buchman South, the neighborhood began to be populated in 2007 and is characterized primarily by private homes and semi-detached houses.',
    'מוריה היא אחת השכונות הדרומיות ביותר של מודיעין-מכבים-רעות. הידועה בעבר כבוכמן דרום, השכונה החלה להתאכלס ב-2007 ומאופיינת בעיקר בבתים פרטיים וצמודי קרקע.',
  );

  List<_NeighStat> get _stats => [
    _NeighStat(value: '12', label: _t('Properties for Sale', 'נכסים למכירה'), icon: IconsaxPlusBold.home_2),
    _NeighStat(value: '18', label: _t('Businesses in Area', 'עסקים באזור'), icon: IconsaxPlusBold.shop),
    _NeighStat(value: '6', label: _t('Parks & Playgrounds', 'פארקים וגנים'), icon: IconsaxPlusBold.tree),
    _NeighStat(value: '7', label: _t('Schools & Kindergardens', 'בתי ספר וגנים'), icon: IconsaxPlusBold.teacher),
  ];

  String get _aboutParagraph1 => _t(
    'Moriah is one of the southernmost neighborhoods of Modi\'in-Maccabim-Re\'ut. Formerly known as Buchman South, the neighborhood began to be populated in 2007 and is characterized primarily by private homes and semi-detached houses.',
    'מוריה היא אחת השכונות הדרומיות ביותר של מודיעין-מכבים-רעות. הידועה בעבר כבוכמן דרום, השכונה החלה להתאכלס ב-2007 ומאופיינת בעיקר בבתים פרטיים וצמודי קרקע.',
  );

  String get _aboutParagraph2 => _t(
    'The neighborhood takes its name from women from ancient Jewish history, including the four matriarchs and biblical heroines, which is also reflected in many of the street names throughout the neighborhood.',
    'השכונה קרויה על שם נשים מההיסטוריה היהודית העתיקה, כולל ארבע האמהות וגיבורות מקראיות, מה שבא לידי ביטוי גם בשמות הרחובות.',
  );

  String get _aboutParagraph3 => _t(
    'Today, Moriah combines residential living with parks, recreation, education and neighborhood shopping. Its southern location also places residents close to major roads and the city\'s southern open spaces.',
    'כיום מוריה משלבת מגורים עם פארקים, פנאי, חינוך וקניות שכונתיות. מיקומה הדרומי מציב את התושבים בקרבת כבישים ראשיים ושטחים פתוחים.',
  );

  List<_HighlightItem> get _highlights => [
    _HighlightItem(text: _t('Close to main highways and public transport', 'קרוב לכבישים ראשיים ותחבורה ציבורית')),
    _HighlightItem(text: _t('Excellent schools and kindergartens', 'בתי ספר וגנים מצוינים')),
    _HighlightItem(text: _t('Surrounded by parks and open spaces', 'מוקף פארקים ושטחים פתוחים')),
    _HighlightItem(text: _t('Active neighborhood commercial center', 'מרכז מסחרי שכונתי פעיל')),
  ];

  // ── Sale listings ──
  List<_PropertyCard> get _saleListings => [
    _PropertyCard(
      price: '₪3,650,000', tag: _t('FOR SALE', 'למכירה'),
      address: _t('3 Yona Hanavi Street, Modiin', 'רח׳ יונה הנביא 3, מודיעין'),
      area: '140 m²', rooms: _t('6 Rooms', '6 חדרים'), floor: _t('Floor 3', 'קומה 3'),
      isNew: true, viaBroker: true, imageBg: const Color(0xFFE0D4C8),
    ),
    _PropertyCard(
      price: '₪3,790,000', tag: _t('FOR SALE', 'למכירה'),
      address: _t('84 Menachem Begin Road', 'דרך מנחם בגין 84'),
      area: '133 m²', rooms: _t('4 Rooms', '4 חדרים'), floor: _t('Floor 2', 'קומה 2'),
      isNew: true, viaBroker: false, imageBg: const Color(0xFFD4E4F7),
    ),
    _PropertyCard(
      price: '₪5,690,000', tag: _t('FOR SALE', 'למכירה'),
      address: _t('12 HaShvatim St, Modiin', 'רח׳ השבטים 12, מודיעין'),
      area: '180 m²', rooms: _t('7 Rooms', '7 חדרים'), floor: _t('Floor 5', 'קומה 5'),
      isNew: false, viaBroker: true, imageBg: const Color(0xFFC8D8E0),
    ),
    _PropertyCard(
      price: '₪4,350,000', tag: _t('FOR SALE', 'למכירה'),
      address: _t('7 Devora Street, Modiin', 'רח׳ דבורה 7, מודיעין'),
      area: '140 m²', rooms: _t('6 Rooms', '6 חדרים'), floor: _t('Floor 4', 'קומה 4'),
      isNew: true, viaBroker: false, imageBg: const Color(0xFFD8E8D4),
    ),
  ];

  // ── Rent listings ──
  List<_PropertyCard> get _rentListings => [
    _PropertyCard(
      price: '₪7,500', perMonth: _t('/ In the month', '/ לחודש'), tag: _t('FOR RENT', 'להשכרה'),
      address: _t('Weizmann Street Heritage Modiin', 'רח׳ ויצמן מורשת מודיעין'),
      area: '140 m²', rooms: _t('6 Rooms', '6 חדרים'), floor: _t('Floor 3', 'קומה 3'),
      isNew: true, viaBroker: true, imageBg: const Color(0xFFE0D4C8),
    ),
    _PropertyCard(
      price: '₪12,000', perMonth: _t('/ In the month', '/ לחודש'), tag: _t('FOR RENT', 'להשכרה'),
      address: _t('12 Yitzhak Shamir Street, Modiin', 'רח׳ יצחק שמיר 12, מודיעין'),
      area: '122 m²', rooms: _t('4 Rooms', '4 חדרים'), floor: _t('Floor 2', 'קומה 2'),
      isNew: false, viaBroker: false, imageBg: const Color(0xFFD4E4F7),
    ),
    _PropertyCard(
      price: '₪9,500', perMonth: _t('/ In the month', '/ לחודש'), tag: _t('FOR RENT', 'להשכרה'),
      address: _t('5 Ruth Street, Modiin', 'רח׳ רות 5, מודיעין'),
      area: '155 m²', rooms: _t('5 Rooms', '5 חדרים'), floor: _t('Floor 1', 'קומה 1'),
      isNew: true, viaBroker: true, imageBg: const Color(0xFFC8D8E0),
    ),
    _PropertyCard(
      price: '₪8,200', perMonth: _t('/ In the month', '/ לחודש'), tag: _t('FOR RENT', 'להשכרה'),
      address: _t('22 Esther Street, Modiin', 'רח׳ אסתר 22, מודיעין'),
      area: '130 m²', rooms: _t('5 Rooms', '5 חדרים'), floor: _t('Floor 3', 'קומה 3'),
      isNew: false, viaBroker: false, imageBg: const Color(0xFFD8E8D4),
    ),
  ];

  // ── Businesses ──
  List<_BusinessData> get _businesses => [
    _BusinessData(
      name: _t('Dr. Sarah Cohen', 'ד"ר שרה כהן'),
      category: _t('Dentist', 'רופאת שיניים'),
      location: _t('Moriah, Modiin', 'מוריה, מודיעין'),
      rating: 4.8, reviews: 127, imageBg: const Color(0xFFE8D4B8),
    ),
    _BusinessData(
      name: _t('Café Moriah', 'קפה מוריה'),
      category: _t('Coffee Shop', 'בית קפה'),
      location: _t('Moriah, Modiin', 'מוריה, מודיעין'),
      rating: 4.6, reviews: 89, imageBg: const Color(0xFFD4E4F7),
    ),
    _BusinessData(
      name: _t('Super Pharm Moriah', 'סופר פארם מוריה'),
      category: _t('Pharmacy', 'בית מרקחת'),
      location: _t('Moriah, Modiin', 'מוריה, מודיעין'),
      rating: 4.3, reviews: 64, imageBg: const Color(0xFFC8D8E0),
    ),
    _BusinessData(
      name: _t('Moriah Mini Market', 'מיני מרקט מוריה'),
      category: _t('Grocery', 'מכולת'),
      location: _t('Moriah, Modiin', 'מוריה, מודיעין'),
      rating: 4.1, reviews: 52, imageBg: const Color(0xFFD8E8D4),
    ),
    _BusinessData(
      name: _t('Hair by Noa', 'שיער בעיצוב נועה'),
      category: _t('Hair Salon', 'מספרה'),
      location: _t('Moriah, Modiin', 'מוריה, מודיעין'),
      rating: 4.9, reviews: 143, imageBg: const Color(0xFFE8E0D4),
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
                    const SizedBox(height: 48),
                    _buildHeroSection(),
                    const SizedBox(height: 64),
                    _buildAboutSection(),
                    const SizedBox(height: 64),
                    _buildSaleSection(),
                    const SizedBox(height: 64),
                    _buildRentSection(),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                decoration: BoxDecoration(color: AppColors.midBlue, borderRadius: BorderRadius.circular(60)),
                child: Text(_t('Contact Us', 'צרו קשר'), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
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
  // HERO SECTION — two columns
  // Left: back arrow, title, location, description, stats
  // Right: photo gallery (3 images)
  // ─────────────────────────────────────────────
  Widget _buildHeroSection() {
    return _Section(
      maxWidth: 1600,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT COLUMN — info
          Expanded(
            flex: 592,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back arrow
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.canPop() ? context.pop() : context.go('/realestate'),
                    child: const Icon(IconsaxPlusLinear.arrow_left, size: 24, color: AppColors.navy),
                  ),
                ),
                const SizedBox(height: 20),
                // Neighborhood name
                Text(_name, style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 36, fontWeight: FontWeight.w600, color: AppColors.navy)),
                const SizedBox(height: 12),
                // Location
                Row(
                  children: [
                    const Icon(IconsaxPlusBold.location, size: 16, color: AppColors.turquoise),
                    const SizedBox(width: 8),
                    Text(_city, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: const Color(0xFF6D6D6D))),
                  ],
                ),
                const SizedBox(height: 24),
                // Description
                SizedBox(
                  width: 540,
                  child: Text(_description,
                      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: const Color(0xFF3D3D3D), height: 1.6)),
                ),
                const SizedBox(height: 32),
                // Stats bar
                Container(
                  width: 541,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE7E7E7)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: _stats.asMap().entries.map((entry) {
                      final stat = entry.value;
                      final isLast = entry.key == _stats.length - 1;
                      return Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: isLast ? null : Border(
                              right: BorderSide(color: const Color(0xFFE7E7E7).withValues(alpha: 0.6)),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(stat.icon, size: 28, color: AppColors.midBlue),
                              const SizedBox(height: 10),
                              Text(stat.value, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.navy)),
                              const SizedBox(height: 4),
                              Text(stat.label,
                                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: const Color(0xFF6D6D6D)),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          // RIGHT COLUMN — photo gallery (3 images)
          Expanded(
            flex: 942,
            child: SizedBox(
              height: 425,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    // Large image
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [Color(0xFF0058B5), Color(0xFF010A36)],
                          ),
                        ),
                        child: Center(child: Icon(IconsaxPlusBold.buildings_2, size: 80, color: Colors.white.withValues(alpha: 0.15))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Two stacked images
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              color: const Color(0xFFD4E4F7),
                              child: Center(child: Icon(IconsaxPlusLinear.image, size: 32, color: Colors.black.withValues(alpha: 0.15))),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Container(
                              color: const Color(0xFFE0D4C8),
                              child: Center(child: Icon(IconsaxPlusLinear.image, size: 32, color: Colors.black.withValues(alpha: 0.15))),
                            ),
                          ),
                        ],
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
  // ABOUT SECTION — two columns
  // Left: heading + 3 paragraphs with fade/Read More
  // Right: 4 highlight items
  // ─────────────────────────────────────────────
  Widget _buildAboutSection() {
    return _Section(
      maxWidth: 1600,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT — About text
          Expanded(
            flex: 931,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_t('About Moriah', 'על שכונת מוריה'),
                    style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
                const SizedBox(height: 24),
                Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_aboutParagraph1,
                            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: const Color(0xFF3D3D3D), height: 1.6)),
                        const SizedBox(height: 16),
                        Text(_aboutParagraph2,
                            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: const Color(0xFF3D3D3D), height: 1.6)),
                        if (_aboutExpanded) ...[
                          const SizedBox(height: 16),
                          Text(_aboutParagraph3,
                              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: const Color(0xFF3D3D3D), height: 1.6)),
                        ],
                        if (!_aboutExpanded) const SizedBox(height: 80),
                      ],
                    ),
                    // Gradient fade when collapsed
                    if (!_aboutExpanded)
                      Positioned(
                        left: 0, right: 0, bottom: 0,
                        height: 180,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              colors: [Color(0x00FFFFFF), Colors.white],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Read More button
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setState(() => _aboutExpanded = !_aboutExpanded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.midBlue),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Text(
                        _aboutExpanded ? _t('Show Less', 'הצג פחות') : _t('Read More', 'קרא עוד'),
                        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.midBlue),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 64),
          // RIGHT — Highlights
          SizedBox(
            width: 465,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_t('Neighborhood Highlights', 'דגשי השכונה'),
                    style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
                const SizedBox(height: 24),
                ..._highlights.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.turquoise.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(IconsaxPlusBold.tick_circle, size: 18, color: AppColors.turquoise),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(h.text,
                              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: const Color(0xFF3D3D3D), height: 1.5)),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // APARTMENTS FOR SALE — horizontal carousel
  // ─────────────────────────────────────────────
  Widget _buildSaleSection() {
    return _buildPropertyCarousel(
      title: _t('Apartments for Sale in Moriah', 'דירות למכירה במוריה'),
      listings: _saleListings,
    );
  }

  // ─────────────────────────────────────────────
  // APARTMENTS FOR RENT — horizontal carousel
  // ─────────────────────────────────────────────
  Widget _buildRentSection() {
    return _buildPropertyCarousel(
      title: _t('Apartments for Rent in Moriah', 'דירות להשכרה במוריה'),
      listings: _rentListings,
    );
  }

  Widget _buildPropertyCarousel({required String title, required List<_PropertyCard> listings}) {
    final controller = ScrollController();
    return _Section(
      maxWidth: 1600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with "View All" link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go('/realestate'),
                  child: Text(_t('View All', 'הצג הכל'),
                      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.turquoise)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 321,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ListView.separated(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  itemCount: listings.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 20),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 382,
                      child: _PropertyCardWidget(data: listings[index], isHebrew: _isHebrew),
                    );
                  },
                ),
                // Left arrow
                Positioned(
                  left: -20, top: 0, bottom: 0,
                  child: Center(
                    child: _CarouselArrow(
                      isLeft: true,
                      onTap: () => controller.animateTo(
                        controller.offset - 402,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
                ),
                // Right arrow
                Positioned(
                  right: -20, top: 0, bottom: 0,
                  child: Center(
                    child: _CarouselArrow(
                      isLeft: false,
                      onTap: () => controller.animateTo(
                        controller.offset + 402,
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
      maxWidth: 1600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_t('Businesses in Moriah', 'עסקים במוריה'),
                  style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go('/businesses'),
                  child: Text(_t('View All', 'הצג הכל'),
                      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.turquoise)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 348,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ListView.separated(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  itemCount: _businesses.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 20),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 301,
                      child: _BusinessCardWidget(data: _businesses[index], isHebrew: _isHebrew),
                    );
                  },
                ),
                // Left arrow
                Positioned(
                  left: -20, top: 0, bottom: 0,
                  child: Center(
                    child: _CarouselArrow(
                      isLeft: true,
                      onTap: () => controller.animateTo(
                        controller.offset - 321,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
                ),
                // Right arrow
                Positioned(
                  right: -20, top: 0, bottom: 0,
                  child: Center(
                    child: _CarouselArrow(
                      isLeft: false,
                      onTap: () => controller.animateTo(
                        controller.offset + 321,
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
  const _NavItem({required this.label, required this.route, this.hasDropdown = false, this.isActive = false});
}

class _NeighStat {
  final String value, label;
  final IconData icon;
  const _NeighStat({required this.value, required this.label, required this.icon});
}

class _HighlightItem {
  final String text;
  const _HighlightItem({required this.text});
}

class _PropertyCard {
  final String price, tag, address, area, rooms, floor;
  final String? perMonth;
  final bool isNew, viaBroker;
  final Color imageBg;
  const _PropertyCard({
    required this.price, required this.tag, required this.address,
    required this.area, required this.rooms, required this.floor,
    this.perMonth, this.isNew = false, this.viaBroker = false,
    this.imageBg = const Color(0xFFE8EEF4),
  });
}

class _BusinessData {
  final String name, category, location;
  final double rating;
  final int reviews;
  final Color imageBg;
  const _BusinessData({
    required this.name, required this.category, required this.location,
    required this.rating, required this.reviews, this.imageBg = const Color(0xFFE8EEF4),
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
  const _NavLinkButton({required this.label, this.isActive = false, this.hasDropdown = false, required this.onTap});

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
                color: widget.isActive ? AppColors.turquoise : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(fontFamily: AppFonts.inter, 
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: widget.isActive
                      ? AppColors.turquoise
                      : (_hovered ? AppColors.midBlue : const Color(0xFF0F161E)),
                ),
              ),
              if (widget.hasDropdown) ...[
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 18, color: const Color(0xFF21272A)),
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
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFF8F8F8) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF6F6F6)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
          ),
          child: Icon(
            widget.isLeft ? IconsaxPlusLinear.arrow_left_2 : IconsaxPlusLinear.arrow_right_3,
            size: 20, color: AppColors.midBlue,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// PROPERTY CARD — used in sale & rent carousels
// ═══════════════════════════════════════════════

class _PropertyCardWidget extends StatefulWidget {
  final _PropertyCard data;
  final bool isHebrew;
  const _PropertyCardWidget({required this.data, required this.isHebrew});

  @override
  State<_PropertyCardWidget> createState() => _PropertyCardWidgetState();
}

class _PropertyCardWidgetState extends State<_PropertyCardWidget> {
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
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE7E7E7)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _hovered
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        transform: _hovered ? Matrix4.translationValues(0, -2, 0) : Matrix4.identity(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Stack(
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: d.imageBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Center(child: Icon(IconsaxPlusLinear.image, size: 32, color: Colors.black.withValues(alpha: 0.15))),
                ),
                // Heart button
                Positioned(
                  right: 12, top: 12,
                  child: Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(IconsaxPlusLinear.heart, size: 18, color: AppColors.midBlue),
                  ),
                ),
                // Badges row
                Positioned(
                  left: 12, bottom: 12, right: 50,
                  child: Row(
                    children: [
                      if (d.viaBroker)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCCD6EE),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(widget.isHebrew ? 'דרך מתווך' : 'Via Broker',
                              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF0033AC))),
                        ),
                      if (d.viaBroker && d.isNew) const SizedBox(width: 8),
                      if (d.isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.turquoise,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(widget.isHebrew ? 'חדש' : 'New',
                              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              Text(d.price, style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.navy)),
                              if (d.perMonth != null) ...[
                                const SizedBox(width: 6),
                                Flexible(child: Text(d.perMonth!, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: const Color(0xFF5F5E5A)), overflow: TextOverflow.ellipsis)),
                              ],
                            ],
                          ),
                        ),
                        Text(d.tag, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.turquoise)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Address
                    Row(
                      children: [
                        const Icon(IconsaxPlusBold.location, size: 14, color: AppColors.turquoise),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(d.address,
                              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: const Color(0xFF5F5E5A)),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Stats row
                    Row(
                      children: [
                        _miniStat(IconsaxPlusLinear.maximize_3, d.area),
                        const SizedBox(width: 24),
                        _miniStat(IconsaxPlusLinear.building_3, d.rooms),
                        const SizedBox(width: 24),
                        _miniStat(IconsaxPlusLinear.building_4, d.floor),
                      ],
                    ),
                  ],
                ),
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
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: const Color(0xFF3D3D3D))),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// BUSINESS CARD — used in businesses carousel
// ═══════════════════════════════════════════════

class _BusinessCardWidget extends StatefulWidget {
  final _BusinessData data;
  final bool isHebrew;
  const _BusinessCardWidget({required this.data, required this.isHebrew});

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
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE7E7E7)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _hovered
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        transform: _hovered ? Matrix4.translationValues(0, -2, 0) : Matrix4.identity(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Stack(
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: d.imageBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Center(child: Icon(IconsaxPlusLinear.image, size: 32, color: Colors.black.withValues(alpha: 0.15))),
                ),
                // Category badge
                Positioned(
                  left: 12, top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(d.category, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.navy)),
                  ),
                ),
              ],
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.name, style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.navy)),
                    const SizedBox(height: 8),
                    // Rating row
                    Row(
                      children: [
                        const Icon(IconsaxPlusBold.star_1, size: 14, color: Color(0xFFFFC107)),
                        const SizedBox(width: 4),
                        Text(d.rating.toString(), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.navy)),
                        const SizedBox(width: 6),
                        Text('(${d.reviews})', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: const Color(0xFF6D6D6D))),
                      ],
                    ),
                    const Spacer(),
                    // Location
                    Row(
                      children: [
                        const Icon(IconsaxPlusBold.location, size: 14, color: AppColors.turquoise),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(d.location,
                              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: const Color(0xFF5F5E5A)),
                              overflow: TextOverflow.ellipsis),
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
    );
  }
}

// ═══════════════════════════════════════════════
// FOOTER WIDGETS
// ═══════════════════════════════════════════════
