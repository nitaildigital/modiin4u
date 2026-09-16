import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// Web Businesses — full desktop layout
// Business & professionals directory (1920 grid, 1600 content)
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF5F5E5A);
const _kHeading = Color(0xFF1C1C1E);
const _kBodyText = Color(0xFF3D3D3D);
const _kIconGrey = Color(0xFF6D6D6D);
const _kPillBorder = Color(0xFFD1D1D1);
const _kOpenBg = Color(0xFFE6F7EE);
const _kOpenText = Color(0xFF12855A);
const _kClosedBg = Color(0xFFFDECEC);
const _kClosedText = Color(0xFFD64545);

class WebBusinessesContent extends StatefulWidget {
  const WebBusinessesContent({super.key});

  @override
  State<WebBusinessesContent> createState() => _WebBusinessesContentState();
}

class _WebBusinessesContentState extends State<WebBusinessesContent> {
  bool _isHebrew = false;
  int _selectedCategory = -1; // -1 = all categories
  int _selectedFilter = -1; // -1 = no pill selected
  String _query = '';

  final _searchCtrl = TextEditingController();
  final _featured = ScrollController();
  final _resultsKey = GlobalKey();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _featured.dispose();
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
    _NavItem(label: _t('Restaurants in Modiin', 'מסעדות במודיעין'), route: '/restaurants'),
    _NavItem(label: _t('Businesses in Modiin', 'עסקים במודיעין'), route: '/businesses', hasDropdown: true, isActive: true),
  ];

  // ── Categories — 8 gradient cards, 4 per row ──
  List<_Category> get _categories => [
    _Category(name: _t('Restaurants', 'מסעדות'), count: 126, icon: IconsaxPlusBold.reserve,
        start: const Color(0xFF1B3A2D), end: const Color(0xFF2E5A47)),
    _Category(name: _t('Coffee Shops', 'בתי קפה'), count: 38, icon: IconsaxPlusBold.coffee,
        start: const Color(0xFF3E2723), end: const Color(0xFF5D4037)),
    _Category(name: _t('Bars & Nightlife', 'ברים וחיי לילה'), count: 24, icon: IconsaxPlusBold.cup,
        start: const Color(0xFF2D1B4E), end: const Color(0xFF4A2D6E)),
    _Category(name: _t('Beauty & Grooming', 'יופי וטיפוח'), count: 42, icon: IconsaxPlusBold.brush_1,
        start: const Color(0xFF4E1B3A), end: const Color(0xFF6E2D54)),
    _Category(name: _t('Sports & Fitness', 'ספורט וכושר'), count: 31, icon: IconsaxPlusBold.weight,
        start: const Color(0xFF1A237E), end: const Color(0xFF283593)),
    _Category(name: _t('Hairdressers', 'מספרות'), count: 27, icon: IconsaxPlusBold.scissor,
        start: const Color(0xFF4E342E), end: const Color(0xFF6D4C41)),
    _Category(name: _t('Home Services', 'שירותים לבית'), count: 51, icon: IconsaxPlusBold.setting_2,
        start: const Color(0xFF263238), end: const Color(0xFF37474F)),
    _Category(name: _t('Education', 'חינוך והעשרה'), count: 19, icon: IconsaxPlusBold.book_1,
        start: const Color(0xFF1B5E20), end: const Color(0xFF2E7D32)),
  ];

  // ── Filter pills — index matches _Business.tags ──
  List<String> get _filters => [
    _t('Open Now', 'פתוח עכשיו'),
    _t('Top Rated', 'המדורגים ביותר'),
    _t('New on Modiin4u', 'חדש במודיעין4u'),
    _t('Home Service', 'שירות עד הבית'),
  ];

  // ── Directory ──
  List<_Business> get _businesses => [
    _Business(
      name: _t('Urban Plate Kitchen & Bar', 'אורבן פלייט קיטשן & בר'),
      categoryIndex: 0, category: _t('Restaurants', 'מסעדות'),
      area: _t('Hatikva Quarter', 'רובע התקווה'),
      rating: 4.8, reviews: 214, isOpen: true, tags: {0, 1},
      imageBg: const Color(0xFFDDD0C2), logoBg: const Color(0xFFE0CDBE),
    ),
    _Business(
      name: _t('Cafe Anava', 'קפה ענבה'),
      categoryIndex: 1, category: _t('Coffee Shops', 'בתי קפה'),
      area: _t('Anava Park', 'פארק ענבה'),
      rating: 4.6, reviews: 158, isOpen: true, tags: {0, 1},
      imageBg: const Color(0xFFE2D4C4), logoBg: const Color(0xFFD8C7B8),
    ),
    _Business(
      name: _t('The Copper Room', 'החדר הנחושת'),
      categoryIndex: 2, category: _t('Bars & Nightlife', 'ברים וחיי לילה'),
      area: _t('Modiin City Center', 'מרכז העיר מודיעין'),
      rating: 4.4, reviews: 92, isOpen: false, tags: {2},
      imageBg: const Color(0xFFD2C6DE), logoBg: const Color(0xFFD9C8DE),
    ),
    _Business(
      name: _t('Soleil Spa & Beauty', 'ספא סוליי'),
      categoryIndex: 3, category: _t('Beauty & Grooming', 'יופי וטיפוח'),
      area: _t('Hatikva Quarter', 'רובע התקווה'),
      rating: 4.9, reviews: 301, isOpen: true, tags: {0, 1, 3},
      imageBg: const Color(0xFFD6C6DE), logoBg: const Color(0xFFDCE2C6),
    ),
    _Business(
      name: _t('Modiin Fit Studio', 'סטודיו מודיעין פיט'),
      categoryIndex: 4, category: _t('Sports & Fitness', 'ספורט וכושר'),
      area: _t('Modiin Mall', 'קניון מודיעין'),
      rating: 4.7, reviews: 176, isOpen: true, tags: {0, 1},
      imageBg: const Color(0xFFC6D6E4), logoBg: const Color(0xFFCBD4DE),
    ),
    _Business(
      name: _t('Studio Bella', 'סטודיו בלה'),
      categoryIndex: 5, category: _t('Hairdressers', 'מספרות'),
      area: _t('Modiin City Center', 'מרכז העיר מודיעין'),
      rating: 4.5, reviews: 128, isOpen: true, tags: {0, 3},
      imageBg: const Color(0xFFDCE2C6), logoBg: const Color(0xFFCADEC9),
    ),
    _Business(
      name: _t('FixIt Modiin', 'פיקסאיט מודיעין'),
      categoryIndex: 6, category: _t('Home Services', 'שירותים לבית'),
      area: _t('Anava Park', 'פארק ענבה'),
      rating: 4.3, reviews: 64, isOpen: false, tags: {2, 3},
      imageBg: const Color(0xFFC8DDD8), logoBg: const Color(0xFFC6DAD8),
    ),
    _Business(
      name: _t('Anava Learning Center', 'מרכז הלמידה ענבה'),
      categoryIndex: 7, category: _t('Education', 'חינוך והעשרה'),
      area: _t('Anava Park', 'פארק ענבה'),
      rating: 4.8, reviews: 143, isOpen: true, tags: {0, 1},
      imageBg: const Color(0xFFD6E2C6), logoBg: const Color(0xFFDCE2C6),
    ),
    _Business(
      name: _t('Pizza Moretti', 'פיצה מורטי'),
      categoryIndex: 0, category: _t('Restaurants', 'מסעדות'),
      area: _t('Modiin Mall', 'קניון מודיעין'),
      rating: 4.2, reviews: 388, isOpen: true, tags: {0, 3},
      imageBg: const Color(0xFFE0CDBE), logoBg: const Color(0xFFDDD0C2),
    ),
    _Business(
      name: _t('Roasters Corner', 'פינת הקלייה'),
      categoryIndex: 1, category: _t('Coffee Shops', 'בתי קפה'),
      area: _t('Modiin City Center', 'מרכז העיר מודיעין'),
      rating: 4.7, reviews: 97, isOpen: true, tags: {0, 1, 2},
      imageBg: const Color(0xFFCBD4DE), logoBg: const Color(0xFFC6D6E4),
    ),
    _Business(
      name: _t('Glow Nail Bar', 'גלואו נייל בר'),
      categoryIndex: 3, category: _t('Beauty & Grooming', 'יופי וטיפוח'),
      area: _t('Modiin Mall', 'קניון מודיעין'),
      rating: 4.6, reviews: 205, isOpen: false, tags: {1, 3},
      imageBg: const Color(0xFFD9C8DE), logoBg: const Color(0xFFD6C6DE),
    ),
    _Business(
      name: _t('Modiin Home Electric', 'מודיעין חשמל לבית'),
      categoryIndex: 6, category: _t('Home Services', 'שירותים לבית'),
      area: _t('Hatikva Quarter', 'רובע התקווה'),
      rating: 4.4, reviews: 51, isOpen: true, tags: {0, 2, 3},
      imageBg: const Color(0xFFCADEC9), logoBg: const Color(0xFFC8DDD8),
    ),
  ];

  List<_Business> get _visibleBusinesses {
    final q = _query.toLowerCase();
    return _businesses.where((b) {
      if (_selectedCategory >= 0 && b.categoryIndex != _selectedCategory) return false;
      if (_selectedFilter >= 0 && !b.tags.contains(_selectedFilter)) return false;
      if (q.isEmpty) return true;
      return b.name.toLowerCase().contains(q) ||
          b.category.toLowerCase().contains(q) ||
          b.area.toLowerCase().contains(q);
    }).toList();
  }

  // ── Featured professionals ──
  List<_Professional> get _professionals => [
    _Professional(name: _t('Adi Ben-Ami', 'עדי בן-עמי'), profession: _t('Interior Designer', 'מעצבת פנים'),
        rating: 4.9, reviews: 87, avatarBg: const Color(0xFFE0CDBE), verified: true),
    _Professional(name: _t('Yaron Cohen', 'ירון כהן'), profession: _t('Electrician', 'חשמלאי'),
        rating: 4.8, reviews: 132, avatarBg: const Color(0xFFC6D6E4), verified: true),
    _Professional(name: _t('Maya Levi', 'מאיה לוי'), profession: _t('Personal Trainer', 'מאמנת אישית'),
        rating: 4.9, reviews: 64, avatarBg: const Color(0xFFD9C8DE), verified: false),
    _Professional(name: _t('Ronen Shapira', 'רונן שפירא'), profession: _t('Plumber', 'אינסטלטור'),
        rating: 4.6, reviews: 158, avatarBg: const Color(0xFFDCE2C6), verified: true),
    _Professional(name: _t('Noa Barak', 'נועה ברק'), profession: _t('Private Tutor', 'מורה פרטית'),
        rating: 5.0, reviews: 43, avatarBg: const Color(0xFFC8DDD8), verified: false),
    _Professional(name: _t('Eitan Mor', 'איתן מור'), profession: _t('Handyman', 'הנדימן'),
        rating: 4.5, reviews: 211, avatarBg: const Color(0xFFD8C7B8), verified: true),
  ];

  void _scrollToResults() {
    final ctx = _resultsKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 400), curve: Curves.easeOut, alignment: 0.05);
  }

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
                    _buildFeaturedSection(),
                    _buildResultsSection(),
                    _buildProfessionalsSection(),
                    _buildListBusinessCta(),
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
  // HERO — title, subtitle, search bar
  // ─────────────────────────────────────────────
  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          Text(_t('Businesses & Professionals in Modiin', 'עסקים ובעלי מקצוע במודיעין'),
              style: GoogleFonts.nunito(fontSize: 44, fontWeight: FontWeight.w600, color: Colors.black, height: 1.23),
              textAlign: TextAlign.center),
          const SizedBox(height: 14),
          Text(
              _t('Find trusted local businesses, service providers and professionals — all in one place.',
                  'מצאו עסקים מקומיים, נותני שירות ובעלי מקצוע מומלצים – הכל במקום אחד.'),
              style: GoogleFonts.inter(fontSize: 16, color: _kIconGrey, height: 1.19),
              textAlign: TextAlign.center),
          const SizedBox(height: 40),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildSearchBar(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 24),
          const Icon(IconsaxPlusLinear.search_normal_1, size: 20, color: _kIconGrey),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              onSubmitted: (_) => _scrollToResults(),
              style: GoogleFonts.inter(fontSize: 16, color: _kHeading),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: _t('Search businesses, services or professionals in Modiin...',
                    'חפשו עסקים, שירותים או בעלי מקצוע במודיעין...'),
                hintStyle: GoogleFonts.inter(fontSize: 16, color: _kIconGrey),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(IconsaxPlusLinear.close_circle, size: 20, color: _kIconGrey),
                ),
              ),
            ),
          const SizedBox(width: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _scrollToResults,
              child: Container(
                height: 48,
                margin: const EdgeInsetsDirectional.only(end: 8),
                padding: const EdgeInsets.symmetric(horizontal: 32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.midBlue,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(_t('Search', 'חיפוש'),
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BROWSE BY CATEGORY — 8 gradient cards, 4 per row
  // ─────────────────────────────────────────────
  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: _Section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(_t('Browse by Category', 'עיון לפי קטגוריה'),
                      style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
                ),
                if (_selectedCategory >= 0)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = -1),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(IconsaxPlusLinear.close_circle, size: 18, color: AppColors.midBlue),
                          const SizedBox(width: 6),
                          Text(_t('Clear category', 'נקה קטגוריה'),
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.midBlue)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 25.0;
                const perRow = 4;
                final cardWidth = (constraints.maxWidth - gap * (perRow - 1)) / perRow;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: List.generate(_categories.length, (i) {
                    return SizedBox(
                      width: cardWidth,
                      child: _CategoryCard(
                        category: _categories[i],
                        businessesLabel: _t('businesses', 'עסקים'),
                        isSelected: _selectedCategory == i,
                        onTap: () {
                          setState(() => _selectedCategory = _selectedCategory == i ? -1 : i);
                          _scrollToResults();
                        },
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FEATURED BUSINESSES — 400-wide card carousel
  // ─────────────────────────────────────────────
  Widget _buildFeaturedSection() {
    final featured = _businesses.where((b) => b.rating >= 4.6).toList();
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
                      Text(_t('Featured in Modiin', 'מומלצים במודיעין'),
                          style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
                      const SizedBox(height: 8),
                      Text(_t('Highest rated businesses by Modiin residents', 'העסקים המדורגים ביותר על ידי תושבי מודיעין'),
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
                      _carouselArrow(controller: _featured, step: 420, isNext: false),
                      const SizedBox(width: 12),
                      _carouselArrow(controller: _featured, step: 420, isNext: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 23),
            SizedBox(
              height: 372,
              child: ListView.separated(
                controller: _featured,
                scrollDirection: Axis.horizontal,
                itemCount: featured.length,
                separatorBuilder: (_, _) => const SizedBox(width: 20),
                itemBuilder: (context, i) => SizedBox(
                  width: 400,
                  child: _BusinessCard(
                    business: featured[i],
                    openLabel: _t('Open Now', 'פתוח עכשיו'),
                    closedLabel: _t('Closed', 'סגור'),
                    reviewsLabel: _t('reviews', 'ביקורות'),
                    viewLabel: _t('View Business', 'לעמוד העסק'),
                    onTap: () => context.push('/business/demo_$i'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // RESULTS — filter pills, live count, 4-up grid
  // ─────────────────────────────────────────────
  Widget _buildResultsSection() {
    final results = _visibleBusinesses;
    final categoryName = _selectedCategory >= 0 ? _categories[_selectedCategory].name : null;

    return Padding(
      key: _resultsKey,
      padding: const EdgeInsets.only(top: 80),
      child: _Section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              categoryName == null
                  ? _t('All Businesses in Modiin', 'כל העסקים במודיעין')
                  : _t('$categoryName in Modiin', '$categoryName במודיעין'),
              style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.midBlue),
            ),
            const SizedBox(height: 8),
            Text(
              results.length == 1
                  ? _t('1 business found', 'נמצא עסק אחד')
                  : _t('${results.length} businesses found', 'נמצאו ${results.length} עסקים'),
              style: GoogleFonts.inter(fontSize: 14, color: _kGreyText, height: 1.21),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(_filters.length, (i) {
                return _FilterPill(
                  label: _filters[i],
                  isSelected: _selectedFilter == i,
                  onTap: () => setState(() => _selectedFilter = _selectedFilter == i ? -1 : i),
                );
              }),
            ),
            const SizedBox(height: 32),
            if (results.isEmpty)
              _buildEmptyResults()
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 20.0;
                  const perRow = 4;
                  final cardWidth = (constraints.maxWidth - gap * (perRow - 1)) / perRow;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: List.generate(results.length, (i) {
                      return SizedBox(
                        width: cardWidth,
                        height: 372,
                        child: _BusinessCard(
                          business: results[i],
                          openLabel: _t('Open Now', 'פתוח עכשיו'),
                          closedLabel: _t('Closed', 'סגור'),
                          reviewsLabel: _t('reviews', 'ביקורות'),
                          viewLabel: _t('View Business', 'לעמוד העסק'),
                          onTap: () => context.push('/business/demo_$i'),
                        ),
                      );
                    }),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyResults() {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(IconsaxPlusLinear.shop, size: 44, color: _kGreyText.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(_t('No businesses match your search', 'לא נמצאו עסקים שתואמים לחיפוש'),
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: _kHeading)),
          const SizedBox(height: 8),
          Text(_t('Try a different category, filter or search term.', 'נסו קטגוריה, סינון או מילת חיפוש אחרים.'),
              style: GoogleFonts.inter(fontSize: 14, color: _kGreyText)),
          const SizedBox(height: 20),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() {
                  _query = '';
                  _selectedCategory = -1;
                  _selectedFilter = -1;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.midBlue,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(_t('Reset filters', 'איפוס סינון'),
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TOP PROFESSIONALS — 6 cards, 6 per row
  // ─────────────────────────────────────────────
  Widget _buildProfessionalsSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: _Section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('Top Professionals', 'בעלי המקצוע המובילים'),
                style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
            const SizedBox(height: 8),
            Text(_t('Verified service providers, rated by your neighbours', 'נותני שירות מאומתים, מדורגים על ידי השכנים שלכם'),
                style: GoogleFonts.inter(fontSize: 14, color: _kGreyText, height: 1.21)),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 20.0;
                const perRow = 6;
                final cardWidth = (constraints.maxWidth - gap * (perRow - 1)) / perRow;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: List.generate(_professionals.length, (i) {
                    return SizedBox(
                      width: cardWidth,
                      child: _ProfessionalCard(
                        professional: _professionals[i],
                        reviewsLabel: _t('reviews', 'ביקורות'),
                        verifiedLabel: _t('Verified', 'מאומת'),
                        contactLabel: _t('Contact', 'צרו קשר'),
                        onTap: () => context.push('/professional/demo_$i'),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CTA BAND — list your business
  // ─────────────────────────────────────────────
  Widget _buildListBusinessCta() {
    return Padding(
      padding: const EdgeInsets.only(top: 100, bottom: 100),
      child: _Section(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_t('Own a business in Modiin?', 'יש לכם עסק במודיעין?'),
                        style: GoogleFonts.nunito(
                            fontSize: 32, fontWeight: FontWeight.w600, color: Colors.white, height: 1.25)),
                    const SizedBox(height: 12),
                    Text(
                        _t('List it on Modiin4u and get discovered by thousands of local residents every month.',
                            'הוסיפו אותו למודיעין4u ותתגלו על ידי אלפי תושבים מקומיים מדי חודש.'),
                        style: GoogleFonts.inter(
                            fontSize: 16, color: Colors.white.withValues(alpha: 0.9), height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Text(_t('Add Your Business', 'הוסיפו את העסק שלכם'),
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
                  ),
                ),
              ),
            ],
          ),
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
  final IconData icon;
  final Color start, end;
  const _Category({
    required this.name,
    required this.count,
    required this.icon,
    required this.start,
    required this.end,
  });
}

class _Business {
  final String name, category, area;
  final int categoryIndex, reviews;
  final double rating;
  final bool isOpen;
  final Set<int> tags;
  final Color imageBg, logoBg;
  const _Business({
    required this.name,
    required this.category,
    required this.categoryIndex,
    required this.area,
    required this.rating,
    required this.reviews,
    required this.isOpen,
    required this.tags,
    required this.imageBg,
    required this.logoBg,
  });
}

class _Professional {
  final String name, profession;
  final double rating;
  final int reviews;
  final Color avatarBg;
  final bool verified;
  const _Professional({
    required this.name,
    required this.profession,
    required this.rating,
    required this.reviews,
    required this.avatarBg,
    required this.verified,
  });
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
// CATEGORY CARD — 200px gradient tile
// ─────────────────────────────────────────────
class _CategoryCard extends StatefulWidget {
  final _Category category;
  final String businessesLabel;
  final bool isSelected;
  final VoidCallback onTap;
  const _CategoryCard({
    required this.category,
    required this.businessesLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.end, c.start],
            ),
            border: Border.all(
              color: widget.isSelected ? AppColors.turquoise : Colors.transparent,
              width: 3,
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 8))]
                : null,
          ),
          child: Stack(
            children: [
              // Dark bottom scrim so the label always reads
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.5235, 1.0],
                      colors: [Colors.transparent, Color(0xBB000000)],
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                top: 20,
                end: 20,
                child: Icon(c.icon, size: 48, color: Colors.white.withValues(alpha: 0.15)),
              ),
              if (widget.isSelected)
                PositionedDirectional(
                  top: 20,
                  start: 20,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.turquoise),
                    child: const Icon(Icons.check, size: 16, color: Colors.white),
                  ),
                ),
              PositionedDirectional(
                start: 20,
                end: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      c.name,
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white, height: 1.22),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text('${c.count} ${widget.businessesLabel}',
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.9))),
                  ],
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
// FILTER PILL — 56px tall, radius 50
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
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 28),
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
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : _kBodyText,
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
// BUSINESS CARD — 400 × 372
// ─────────────────────────────────────────────
class _BusinessCard extends StatefulWidget {
  final _Business business;
  final String openLabel, closedLabel, reviewsLabel, viewLabel;
  final VoidCallback onTap;
  const _BusinessCard({
    required this.business,
    required this.openLabel,
    required this.closedLabel,
    required this.reviewsLabel,
    required this.viewLabel,
    required this.onTap,
  });

  @override
  State<_BusinessCard> createState() => _BusinessCardState();
}

class _BusinessCardState extends State<_BusinessCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.business;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _hovered ? AppColors.midBlue : _kBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo + status badge + rating pill
              SizedBox(
                height: 168,
                child: Stack(
                  // The logo chip hangs 20px below the photo — without this the
                  // Stack's default hardEdge clip cuts it in half.
                  clipBehavior: Clip.none,
                  children: [
                    _imagePlaceholder(b.imageBg,
                        width: double.infinity,
                        height: 168,
                        radius: const BorderRadius.vertical(top: Radius.circular(11)),
                        glyph: 30),
                    PositionedDirectional(
                      start: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: b.isOpen ? _kOpenBg : _kClosedBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: b.isOpen ? _kOpenText : _kClosedText,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(b.isOpen ? widget.openLabel : widget.closedLabel,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: b.isOpen ? _kOpenText : _kClosedText)),
                          ],
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      end: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(IconsaxPlusBold.star_1, size: 13, color: AppColors.gold),
                            const SizedBox(width: 4),
                            Text(b.rating.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                    fontSize: 12, fontWeight: FontWeight.w600, color: _kHeading)),
                          ],
                        ),
                      ),
                    ),
                    // Logo chip straddling the photo edge
                    PositionedDirectional(
                      start: 16,
                      bottom: -20,
                      child: Container(
                        width: 56,
                        height: 56,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _imagePlaceholder(b.logoBg, radius: BorderRadius.circular(9), glyph: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.name,
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: _kHeading, height: 1.22),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(b.category,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.midBlue)),
                          const SizedBox(width: 6),
                          const Text('•', style: TextStyle(color: _kGreyText, fontSize: 13)),
                          const SizedBox(width: 6),
                          const Icon(IconsaxPlusLinear.location, size: 13, color: _kIconGrey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(b.area,
                                style: GoogleFonts.inter(fontSize: 13, color: _kGreyText),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${b.reviews} ${widget.reviewsLabel}',
                          style: GoogleFonts.inter(fontSize: 12, color: _kGreyText)),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _hovered ? AppColors.midBlue : Colors.white,
                                border: Border.all(color: AppColors.midBlue),
                                borderRadius: BorderRadius.circular(60),
                              ),
                              child: Text(widget.viewLabel,
                                  style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: _hovered ? Colors.white : AppColors.midBlue)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              border: Border.all(color: _kBorder),
                              borderRadius: BorderRadius.circular(60),
                            ),
                            child: const Icon(IconsaxPlusLinear.call, size: 18, color: AppColors.midBlue),
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
}

// ─────────────────────────────────────────────
// PROFESSIONAL CARD — avatar, name, rating, CTA
// ─────────────────────────────────────────────
class _ProfessionalCard extends StatefulWidget {
  final _Professional professional;
  final String reviewsLabel, verifiedLabel, contactLabel;
  final VoidCallback onTap;
  const _ProfessionalCard({
    required this.professional,
    required this.reviewsLabel,
    required this.verifiedLabel,
    required this.contactLabel,
    required this.onTap,
  });

  @override
  State<_ProfessionalCard> createState() => _ProfessionalCardState();
}

class _ProfessionalCardState extends State<_ProfessionalCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.professional;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _hovered ? AppColors.midBlue : _kBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _imagePlaceholder(p.avatarBg, width: 88, height: 88, glyph: 24),
                    if (p.verified)
                      PositionedDirectional(
                        end: 0,
                        bottom: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.turquoise,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.check, size: 14, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                p.name,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: _kHeading),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                p.profession,
                style: GoogleFonts.inter(fontSize: 13, color: _kGreyText),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(IconsaxPlusBold.star_1, size: 14, color: AppColors.gold),
                  const SizedBox(width: 4),
                  Text(p.rating.toStringAsFixed(1),
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _kHeading)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text('(${p.reviews})',
                        style: GoogleFonts.inter(fontSize: 12, color: _kGreyText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _hovered ? AppColors.midBlue : Colors.white,
                  border: Border.all(color: AppColors.midBlue),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Text(widget.contactLabel,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _hovered ? Colors.white : AppColors.midBlue)),
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
