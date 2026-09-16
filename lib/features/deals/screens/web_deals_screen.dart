import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// Web Deals — full desktop layout from Figma
// (Deals — 1920 × 2876)
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF5F5E5A);
const _kHeading = Color(0xFF1C1C1E);
const _kBodyText = Color(0xFF3D3D3D);
const _kIconGrey = Color(0xFF6D6D6D);
const _kPillBorder = Color(0xFFD1D1D1);
const _kBrandStrip = Color(0xFFFFE6E6);
const _kBrandStripText = Color(0xFFE90052);

class WebDealsContent extends StatefulWidget {
  const WebDealsContent({super.key});

  @override
  State<WebDealsContent> createState() => _WebDealsContentState();
}

class _WebDealsContentState extends State<WebDealsContent> {
  bool _isHebrew = false;
  int _selectedCategory = 0;
  int _selectedFilter = -1; // -1 = no pill selected
  final _banner = ScrollController();
  final _dealsCarousel = ScrollController();

  @override
  void dispose() {
    _banner.dispose();
    _dealsCarousel.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  // ── Nav links ──
  List<_NavItem> get _navItems => [
    _NavItem(label: _t('Professionals', 'בעלי מקצוע'), route: '/businesses', hasDropdown: true),
    _NavItem(label: _t('Modiin News', 'חדשות מודיעין'), route: '/news', hasDropdown: true),
    _NavItem(label: _t('Events', 'אירועים'), route: '/events'),
    _NavItem(label: _t('Deals', 'מבצעים'), route: '/deals', isActive: true),
    _NavItem(label: _t('Real Estate in Modiin', 'נדל"ן במודיעין'), route: '/realestate'),
    _NavItem(label: _t('Restaurants in Modiin', 'מסעדות במודיעין'), route: '/restaurants'),
    _NavItem(label: _t('Businesses in Modiin', 'עסקים במודיעין'), route: '/businesses', hasDropdown: true),
  ];

  // ── Deal categories — 6 circular tiles ──
  List<_Category> get _categories => [
    _Category(name: _t('Restaurants & Nightlife', 'מסעדות וחיי לילה'), count: 62, imageBg: const Color(0xFFE0CDBE)),
    _Category(name: _t('Shopping', 'קניות'), count: 48, imageBg: const Color(0xFFC6D6E4)),
    _Category(name: _t('Beauty & Wellness', 'יופי ובריאות'), count: 31, imageBg: const Color(0xFFD9C8DE)),
    _Category(name: _t('Leisure & Culture', 'פנאי ותרבות'), count: 27, imageBg: const Color(0xFFDCE2C6)),
    _Category(name: _t('Services', 'שירותים'), count: 19, imageBg: const Color(0xFFC8DDD8)),
    _Category(name: _t('Experiences', 'חוויות'), count: 15, imageBg: const Color(0xFFD8C7B8)),
  ];

  // ── Filter pills ──
  List<String> get _filters => [
    _t('expiring soon', 'נגמר בקרוב'),
    _t('most popular', 'הכי פופולרי'),
    _t('new', 'חדש'),
    _t('Residents Only', 'לתושבים בלבד'),
  ];

  // ── Popular deals ──
  List<_Deal> get _deals => [
    _Deal(
      badge: _t('20% OFF', '20% הנחה'),
      title: _t('20% Off Your Dinner Bill', '20% הנחה על חשבון הערב'),
      merchant: _t('Urban Plate Kitchen & Bar', 'אורבן פלייט קיטשן & בר'),
      location: _t('Hatikva Quarter', 'רובע התקווה'),
      timeLeft: '2d : 14h',
      residentsOnly: true,
      tags: {0, 1},
      imageBg: const Color(0xFFDDD0C2),
      logoBg: const Color(0xFFE0CDBE),
    ),
    _Deal(
      badge: _t('FLAT ₪300 OFF', '₪300 הנחה'),
      title: _t('Flat ₪300 Off on Orders Above ₪2,999', '₪300 הנחה בקנייה מעל ₪2,999'),
      merchant: _t('Nike Store', 'חנות נייקי'),
      location: _t('Modiin City Center', 'מרכז העיר מודיעין'),
      timeLeft: '3d : 05h',
      residentsOnly: false,
      tags: {1},
      imageBg: const Color(0xFFCBD4DE),
      logoBg: const Color(0xFFC6D6E4),
    ),
    _Deal(
      badge: _t('BUY 1 GET 1', '1+1'),
      title: _t('Buy 1 Get 1 Free on All Beverages', '1+1 על כל המשקאות'),
      merchant: _t('mCaffeine', 'אמקפאין'),
      location: _t('Modiin Mall', 'קניון מודיעין'),
      timeLeft: '1d : 08h',
      residentsOnly: true,
      tags: {0, 2},
      imageBg: const Color(0xFFD2C6DE),
      logoBg: const Color(0xFFD9C8DE),
    ),
    _Deal(
      badge: _t('30% OFF', '30% הנחה'),
      title: _t('30% Off on All Spa Packages', '30% הנחה על כל חבילות הספא'),
      merchant: _t('Soleil Spa', 'ספא סוליי'),
      location: _t('Hatikva Quarter', 'רובע התקווה'),
      timeLeft: '2d : 14h',
      residentsOnly: true,
      tags: {0, 1},
      imageBg: const Color(0xFFD6C6DE),
      logoBg: const Color(0xFFDCE2C6),
    ),
    _Deal(
      badge: _t('15% OFF', '15% הנחה'),
      title: _t('15% Off on Every Family Haircut', '15% הנחה על תספורת משפחתית'),
      merchant: _t('Studio Bella', 'סטודיו בלה'),
      location: _t('Modiin City Center', 'מרכז העיר מודיעין'),
      timeLeft: '5d : 02h',
      residentsOnly: false,
      tags: {2},
      imageBg: const Color(0xFFDCE2C6),
      logoBg: const Color(0xFFCADEC9),
    ),
    _Deal(
      badge: _t('2 FOR 1', '2 ב-1'),
      title: _t('Two Cinema Tickets for the Price of One', 'שני כרטיסי קולנוע במחיר אחד'),
      merchant: _t('Modiin Cinema City', 'סינמה סיטי מודיעין'),
      location: _t('Modiin Mall', 'קניון מודיעין'),
      timeLeft: '0d : 19h',
      residentsOnly: true,
      tags: {0, 3},
      imageBg: const Color(0xFFC8DDD8),
      logoBg: const Color(0xFFC6DAD8),
    ),
    _Deal(
      badge: _t('FLAT ₪50 OFF', '₪50 הנחה'),
      title: _t('Flat ₪50 Off on Your First Home Service', '₪50 הנחה על שירות ראשון בבית'),
      merchant: _t('FixIt Modiin', 'פיקסאיט מודיעין'),
      location: _t('Anava Park', 'פארק ענבה'),
      timeLeft: '6d : 11h',
      residentsOnly: false,
      tags: {2},
      imageBg: const Color(0xFFE2D4C4),
      logoBg: const Color(0xFFD8C7B8),
    ),
    _Deal(
      badge: _t('25% OFF', '25% הנחה'),
      title: _t('25% Off All Kids Activity Classes', '25% הנחה על כל חוגי הילדים'),
      merchant: _t('Anava Community Center', 'המרכז הקהילתי ענבה'),
      location: _t('Anava Park', 'פארק ענבה'),
      timeLeft: '4d : 07h',
      residentsOnly: true,
      tags: {1, 3},
      imageBg: const Color(0xFFD6E2C6),
      logoBg: const Color(0xFFDCE2C6),
    ),
  ];

  List<_Deal> get _visibleDeals {
    if (_selectedFilter < 0) return _deals;
    return _deals.where((d) => d.tags.contains(_selectedFilter)).toList();
  }

  // ── Brand cards — 5 × 2 grid ──
  List<_Brand> get _brands => [
    _Brand(offer: _t('Upto 80% Off', 'עד 80% הנחה'), reward: _t('Upto 5% Rewards', 'עד 5% החזר'), logoBg: const Color(0xFFD6C6DE)),
    _Brand(offer: _t('50-90% Off', '50-90% הנחה'), reward: _t('Upto 5% Rewards', 'עד 5% החזר'), logoBg: const Color(0xFFC6D6E4)),
    _Brand(offer: _t('50-90% Off', '50-90% הנחה'), reward: _t('Upto 6.50% Rewards', 'עד 6.50% החזר'), logoBg: const Color(0xFFDCE2C6)),
    _Brand(offer: _t('50-90% Off', '50-90% הנחה'), reward: _t('Upto 7% Rewards', 'עד 7% החזר'), logoBg: const Color(0xFFC8DDD8)),
    _Brand(offer: _t('Upto 20% Off', 'עד 20% הנחה'), reward: _t('Upto 12% Rewards', 'עד 12% החזר'), logoBg: const Color(0xFFE4D6C2)),
    _Brand(offer: _t('Upto 80% Off', 'עד 80% הנחה'), reward: _t('Upto 5% Rewards', 'עד 5% החזר'), logoBg: const Color(0xFFDDD0C2)),
    _Brand(offer: _t('Buy 2 Get 4 Free', 'קנה 2 קבל 4'), reward: _t('Upto 6% Rewards', 'עד 6% החזר'), logoBg: const Color(0xFFD9C8DE)),
    _Brand(offer: _t('Upto 60% Off', 'עד 60% הנחה'), reward: _t('Upto 5% Rewards', 'עד 5% החזר'), logoBg: const Color(0xFFCBD4DE)),
    _Brand(offer: _t('Upto 80% Off', 'עד 80% הנחה'), reward: _t('Upto 8% Rewards', 'עד 8% החזר'), logoBg: const Color(0xFFCADEC9)),
    _Brand(offer: _t('Upto 80% Off', 'עד 80% הנחה'), reward: _t('Upto 5% Rewards', 'עד 5% החזר'), logoBg: const Color(0xFFE2D4C4)),
  ];

  // ── Hero banners — 3 × 520 + 2 × 20 gap = 1600 ──
  List<Color> get _banners => const [
    Color(0xFFD9C8DE),
    Color(0xFFC6D6E4),
    Color(0xFFE0CDBE),
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
                    _buildCategoriesSection(),
                    _buildPopularDealsSection(),
                    _buildFilterPills(),
                    _buildBrandsSection(),
                    const SizedBox(height: 146),
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
  // STICKY NAVBAR — 1920 × 80
  // ─────────────────────────────────────────────
  Widget _buildStickyNavbar() {
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
            child: SvgPicture.asset(
              'assets/images/logo_white.svg',
              width: 90,
              height: 48,
              colorFilter: const ColorFilter.mode(AppColors.midBlue, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 20),
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
                margin: const EdgeInsetsDirectional.only(end: 12),
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
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
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
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HERO — title, subtitle, 3-up banner carousel
  // ─────────────────────────────────────────────
  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          Text(_t('Best Deals & Offers in Modiin', 'המבצעים וההטבות הטובים במודיעין'),
              style: GoogleFonts.nunito(fontSize: 44, fontWeight: FontWeight.w600, color: Colors.black, height: 1.23),
              textAlign: TextAlign.center),
          const SizedBox(height: 14),
          Text(_t('Explore local deals, discounts, and limited-time offers across Modiin.',
                  'גלו מבצעים מקומיים, הנחות והטבות לזמן מוגבל בכל מודיעין.'),
              style: GoogleFonts.inter(fontSize: 16, color: _kIconGrey, height: 1.19),
              textAlign: TextAlign.center),
          const SizedBox(height: 48),
          _Section(
            child: SizedBox(
              height: 300,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ListView.separated(
                    controller: _banner,
                    scrollDirection: Axis.horizontal,
                    itemCount: _banners.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 20),
                    itemBuilder: (context, i) => _imagePlaceholder(
                      _banners[i],
                      width: 520,
                      height: 300,
                      radius: BorderRadius.circular(12),
                      glyph: 40,
                    ),
                  ),
                  PositionedDirectional(
                    start: -20,
                    top: 130,
                    child: _carouselArrow(controller: _banner, step: 540, isNext: false, shadow: true),
                  ),
                  PositionedDirectional(
                    end: -20,
                    top: 130,
                    child: _carouselArrow(controller: _banner, step: 540, isNext: true, shadow: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EXPLORE DEALS BY CATEGORY — 6 circular tiles
  // ─────────────────────────────────────────────
  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: _Section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('Explore Deals by Category', 'גלו מבצעים לפי קטגוריה'),
                style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
            const SizedBox(height: 40),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(_categories.length, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(end: i == _categories.length - 1 ? 0 : 30),
                    child: _CategoryTile(
                      category: _categories[i],
                      dealsLabel: _t('Deals', 'מבצעים'),
                      isSelected: _selectedCategory == i,
                      onTap: () => setState(() => _selectedCategory = i),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // POPULAR DEALS IN MODIIN — 480 × 353 card carousel
  // ─────────────────────────────────────────────
  Widget _buildPopularDealsSection() {
    final deals = _visibleDeals;
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: _Section(
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
                      Text(_t('Popular Deals in Modiin', 'מבצעים פופולריים במודיעין'),
                          style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
                      const SizedBox(height: 8),
                      Text(_t('Top deals handpicked for you', 'המבצעים הטובים ביותר שנבחרו עבורכם'),
                          style: GoogleFonts.inter(fontSize: 14, color: _kGreyText, height: 1.21)),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _carouselArrow(controller: _dealsCarousel, step: 500, isNext: false),
                      const SizedBox(width: 12),
                      _carouselArrow(controller: _dealsCarousel, step: 500, isNext: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 23),
            if (deals.isEmpty)
              _buildEmptyDeals()
            else
              SizedBox(
                height: 353,
                child: ListView.separated(
                  controller: _dealsCarousel,
                  scrollDirection: Axis.horizontal,
                  itemCount: deals.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 20),
                  itemBuilder: (context, i) => SizedBox(
                    width: 480,
                    child: _DealCard(
                      deal: deals[i],
                      timeLeftLabel: _t('Time Left', 'זמן שנותר'),
                      residentsLabel: _t('Residents Only', 'לתושבים בלבד'),
                      viewLabel: _t('View Deal', 'צפו במבצע'),
                      onTap: () => context.push('/deal/demo_$i'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDeals() {
    return Container(
      height: 353,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(IconsaxPlusLinear.discount_shape, size: 44, color: _kGreyText.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(_t('No deals match this filter', 'אין מבצעים שתואמים לסינון'),
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: _kHeading)),
          const SizedBox(height: 8),
          Text(_t('Try another filter to see more offers.', 'נסו סינון אחר כדי לראות עוד הטבות.'),
              style: GoogleFonts.inter(fontSize: 14, color: _kGreyText)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FILTER PILLS — 80px tall, radius 50
  // ─────────────────────────────────────────────
  Widget _buildFilterPills() {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Wrap(
          spacing: 21,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: List.generate(_filters.length, (i) {
            return _FilterPill(
              label: _filters[i],
              isSelected: _selectedFilter == i,
              onTap: () => setState(() => _selectedFilter = _selectedFilter == i ? -1 : i),
            );
          }),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MOST POPULAR BRANDS — 5 × 2 grid of 300 × 210
  // ─────────────────────────────────────────────
  Widget _buildBrandsSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 70),
      child: _Section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('Most Popular Brands', 'המותגים הפופולריים ביותר'),
                style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 25.0;
                const perRow = 5;
                final cardWidth = (constraints.maxWidth - gap * (perRow - 1)) / perRow;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: _brands.map((b) {
                    return SizedBox(
                      width: cardWidth,
                      child: _BrandCard(brand: b),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _carouselArrow({
    required ScrollController controller,
    required double step,
    required bool isNext,
    bool shadow = false,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (!controller.hasClients) return;
          final delta = step * (isNext ? 1 : -1);
          controller.animateTo(
            (controller.offset + delta).clamp(0.0, controller.position.maxScrollExtent),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
          );
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: shadow ? const Color(0xFFF6F6F6) : _kBorder),
            borderRadius: BorderRadius.circular(20),
            boxShadow: shadow
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 1))]
                : null,
          ),
          child: Icon(
            isNext ? IconsaxPlusLinear.arrow_right_3 : IconsaxPlusLinear.arrow_left_2,
            size: 20,
            color: AppColors.midBlue,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FOOTER — 1920 × 632
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
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white24))),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_t('All Rights Reserved to modiin4u.co.il, 2026', 'כל הזכויות שמורות ל-modiin4u.co.il, 2026'),
                            style: GoogleFonts.inter(fontSize: 14, color: _kBorder)),
                        Row(
                          children: [
                            Text(_t('Terms of Use', 'תנאי שימוש'), style: GoogleFonts.inter(fontSize: 14, color: _kBorder)),
                            const SizedBox(width: 4),
                            const Text('|', style: TextStyle(color: _kBorder)),
                            const SizedBox(width: 4),
                            Text(_t('Privacy Policy', 'מדיניות פרטיות'), style: GoogleFonts.inter(fontSize: 14, color: _kBorder)),
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
      padding: const EdgeInsetsDirectional.only(end: 9),
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_t('View all', 'הצג הכל'),
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.turquoise)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.turquoise),
          ],
        ),
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

class _Category {
  final String name;
  final int count;
  final Color imageBg;
  const _Category({required this.name, required this.count, required this.imageBg});
}

class _Deal {
  final String badge, title, merchant, location, timeLeft;
  final bool residentsOnly;
  final Set<int> tags;
  final Color imageBg, logoBg;
  const _Deal({
    required this.badge,
    required this.title,
    required this.merchant,
    required this.location,
    required this.timeLeft,
    required this.residentsOnly,
    required this.tags,
    required this.imageBg,
    required this.logoBg,
  });
}

class _Brand {
  final String offer, reward;
  final Color logoBg;
  const _Brand({required this.offer, required this.reward, required this.logoBg});
}

// ═══════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════

class _Section extends StatelessWidget {
  final Widget child;
  const _Section({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1648), // 1600 content + 24 padding each side
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: child,
        ),
      ),
    );
  }
}

/// Gradient stand-in for a photo that has no asset yet.
Widget _imagePlaceholder(Color base, {double? width, double? height, BorderRadius? radius, double glyph = 28}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: radius,
      shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [base, Color.lerp(base, Colors.black, 0.22)!],
      ),
    ),
    child: Center(
      child: Icon(IconsaxPlusLinear.image, size: glyph, color: Colors.white.withValues(alpha: 0.35)),
    ),
  );
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

// ─────────────────────────────────────────────
// CATEGORY TILE — 116px circle + name + "N Deals"
// ─────────────────────────────────────────────
class _CategoryTile extends StatefulWidget {
  final _Category category;
  final String dealsLabel;
  final bool isSelected;
  final VoidCallback onTap;
  const _CategoryTile({
    required this.category,
    required this.dealsLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.category;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 116,
              height: 116,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isSelected
                      ? AppColors.midBlue
                      : (_hovered ? AppColors.turquoise : Colors.transparent),
                  width: 2,
                ),
              ),
              child: _imagePlaceholder(c.imageBg, glyph: 30),
            ),
            const SizedBox(height: 20),
            // Fixed two-line box so every count in the row sits on one baseline.
            SizedBox(
              height: 44,
              child: Text(
                c.name,
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: _kHeading, height: 1.22),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${c.count} ${widget.dealsLabel}',
              style: GoogleFonts.inter(fontSize: 14, color: _kGreyText, height: 1.21),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FILTER PILL — 80px tall, radius 50
// ─────────────────────────────────────────────
class _FilterPill extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterPill({required this.label, required this.isSelected, required this.onTap});

  @override
  State<_FilterPill> createState() => _FilterPillState();
}

class _FilterPillState extends State<_FilterPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: selected ? AppColors.midBlue : Colors.white,
            border: Border.all(color: selected ? AppColors.midBlue : (_hovered ? AppColors.turquoise : _kPillBorder)),
            borderRadius: BorderRadius.circular(50),
          ),
          // mainAxisSize.min keeps the pill hugging its label — a Container
          // `alignment` here would stretch it to the full row width.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : _kBodyText,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DEAL CARD — 480 × 353
// ─────────────────────────────────────────────
class _DealCard extends StatefulWidget {
  final _Deal deal;
  final String timeLeftLabel, residentsLabel, viewLabel;
  final VoidCallback onTap;
  const _DealCard({
    required this.deal,
    required this.timeLeftLabel,
    required this.residentsLabel,
    required this.viewLabel,
    required this.onTap,
  });

  @override
  State<_DealCard> createState() => _DealCardState();
}

class _DealCardState extends State<_DealCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.deal;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _hovered ? AppColors.midBlue : _kBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo 157 × 191 + discount badge
                    SizedBox(
                      width: 157,
                      height: 191,
                      child: Stack(
                        children: [
                          _imagePlaceholder(d.imageBg,
                              width: 157, height: 191, radius: BorderRadius.circular(12), glyph: 30),
                          PositionedDirectional(
                            start: 12,
                            top: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.orange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(d.badge,
                                  style: GoogleFonts.inter(
                                      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, height: 1.21)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 17),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Merchant logo — 72px ring
                          Container(
                            width: 72,
                            height: 72,
                            padding: const EdgeInsets.all(3.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: _kBorder),
                            ),
                            child: _imagePlaceholder(d.logoBg, glyph: 20),
                          ),
                          const SizedBox(height: 13),
                          Text(
                            d.title,
                            style: GoogleFonts.inter(
                                fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.midBlue, height: 1.23),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            d.merchant,
                            style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w500, color: _kHeading, height: 1.21),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(IconsaxPlusLinear.location, size: 16, color: _kIconGrey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  d.location,
                                  style: GoogleFonts.inter(fontSize: 14, color: _kBodyText, height: 1.21),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(IconsaxPlusLinear.clock, size: 20, color: AppColors.midBlue),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(d.timeLeft,
                                        style: GoogleFonts.inter(
                                            fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.navy, height: 1.19)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(widget.timeLeftLabel,
                                      style: GoogleFonts.inter(fontSize: 12, color: _kGreyText, height: 1.25)),
                                ],
                              ),
                              if (d.residentsOnly) ...[
                                const SizedBox(width: 20),
                                const Icon(IconsaxPlusLinear.shield_tick, size: 20, color: AppColors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.residentsLabel,
                                    style: GoogleFonts.inter(
                                        fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.orange, height: 1.25),
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              // View Deal button — full width, 44px, radius 60
              Container(
                width: double.infinity,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.midBlue,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Text(widget.viewLabel,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white, height: 1.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BRAND CARD — 300 × 210
// ─────────────────────────────────────────────
class _BrandCard extends StatefulWidget {
  final _Brand brand;
  const _BrandCard({required this.brand});

  @override
  State<_BrandCard> createState() => _BrandCardState();
}

class _BrandCardState extends State<_BrandCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.brand;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 210,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _hovered ? AppColors.midBlue : _kBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Column(
            children: [
              // Offer strip — 33px
              Container(
                width: double.infinity,
                height: 33,
                alignment: Alignment.center,
                color: _kBrandStrip,
                child: Text(b.offer,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w500, color: _kBrandStripText, height: 1.21)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Expanded(
                        child: _imagePlaceholder(b.logoBg,
                            width: double.infinity, radius: BorderRadius.circular(8), glyph: 28),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.midBlue,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Text(b.reward,
                            style: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white, height: 1.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 4),
                Text(value,
                    style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
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
