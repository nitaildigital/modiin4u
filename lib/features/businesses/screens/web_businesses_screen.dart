import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/wp_content.dart';
import '../../../shared/widgets/web_chrome.dart';

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
const _kDeliveryBg = Color(0xFFF0F7FD);

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

  /// The real directory, exported from the site. Empty until the asset
  /// loads and empty forever if it fails — both fall through to the demo
  /// listings below, so the page always renders.
  List<WpBusiness> _wp = const [];

  @override
  void initState() {
    super.initState();
    loadWpBusinesses().then((items) {
      if (mounted) setState(() => _wp = items);
    });
    loadWpProfessionals().then((items) {
      if (mounted) setState(() => _wpPros = items);
    });
  }

  List<WpProfessional> _wpPros = const [];

  /// How many listings the results grid shows. 200 at once makes a page so
  /// long that the sections under it are unreachable, so it grows on demand.
  static const _pageSize = 24;
  int _shown = _pageSize;

  /// The site lists six providers and records no ratings for them, so the
  /// cards show the provider's own blurb where a rating would sit.
  List<_Professional> get _professionals {
    if (_wpPros.isEmpty) return _professionalsDemo;
    final palette = _categoryPalette;
    return [
      for (var i = 0; i < _wpPros.length; i++)
        _Professional(
          name: _wpPros[i].title,
          profession: _wpPros[i].profession,
          rating: 0,
          reviews: 0,
          avatarBg: palette[i % palette.length].$2,
          verified: true,
          imageUrl: _wpPros[i].image,
          phone: _wpPros[i].phone,
          description: _wpPros[i].description,
          isLive: true,
        ),
    ];
  }

  bool get _live => _wp.isNotEmpty;

  /// The eight busiest categories in the directory. The site's term list is
  /// long and uneven — it carries one-off campaign tags alongside real
  /// categories — so the cards are derived from what businesses actually use
  /// rather than hard-coded.
  List<_Category> get _liveCategories {
    final counts = <String, int>{};
    for (final b in _wp) {
      for (final t in b.terms) {
        // The site tags businesses that stayed open during each war. Those
        // are campaign lists, not categories, and they out-count real ones.
        if (t.contains('מלחמת')) continue;
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final palette = _categoryPalette;
    return [
      for (var i = 0; i < top.length && i < 8; i++)
        _Category(
          name: top[i].key,
          count: top[i].value,
          icon: _iconForTerm(top[i].key),
          start: palette[i % palette.length].$1,
          end: palette[i % palette.length].$2,
        ),
    ];
  }

  static const _categoryPalette = <(Color, Color)>[
    (Color(0xFF1B3A2D), Color(0xFF2E5A47)),
    (Color(0xFF3E2723), Color(0xFF5D4037)),
    (Color(0xFF2D1B4E), Color(0xFF4A2D6E)),
    (Color(0xFF4E1B3A), Color(0xFF6E2D54)),
    (Color(0xFF1A237E), Color(0xFF283593)),
    (Color(0xFF4E342E), Color(0xFF6D4C41)),
    (Color(0xFF263238), Color(0xFF37474F)),
    (Color(0xFF1B5E20), Color(0xFF2E7D32)),
  ];

  static IconData _iconForTerm(String term) {
    bool has(List<String> words) => words.any(term.contains);
    if (has(['מסעד', 'גריל', 'פיצ', 'סושי', 'המבורגר', 'איטלקי', 'אסיאתי'])) {
      return IconsaxPlusBold.reserve;
    }
    if (has(['קפה', 'ארוחת בוקר', 'גלידות', 'קונדיטור'])) return IconsaxPlusBold.coffee;
    if (has(['בר', 'אלכוהול', 'קריוקי'])) return IconsaxPlusBold.cup;
    if (has(['אסתטיק', 'טיפוח', 'יופי', 'ספא', 'מספר'])) return IconsaxPlusBold.brush_1;
    if (has(['ספורט', 'כושר'])) return IconsaxPlusBold.weight;
    if (has(['דלק', 'רכב', 'פנצ'])) return IconsaxPlusBold.car;
    if (has(['לימוד', 'חוג', 'גן'])) return IconsaxPlusBold.book_1;
    if (has(['בריאות', 'רופא', 'מרפא'])) return IconsaxPlusBold.health;
    return IconsaxPlusBold.shop;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _featured.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  // ── Nav links ──
  // ── Categories — 8 gradient cards, 4 per row ──
  List<_Category> get _categoriesDemo => [
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
  List<String> get _filtersDemo => [
    _t('Open Now', 'פתוח עכשיו'),
    _t('Top Rated', 'המדורגים ביותר'),
    _t('New on Modiin4u', 'חדש במודיעין4u'),
    _t('Home Service', 'שירות עד הבית'),
  ];

  // ── Directory ──
  List<_Business> get _businessesDemo => [
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

  // ═══════════════════════════════════════════════
  // LIVE DIRECTORY — real listings first, demo as the fallback
  // ═══════════════════════════════════════════════

  List<_Category> get _categories => _live ? _liveCategories : _categoriesDemo;

  /// Real listings carry kosher/delivery/rating flags, so the pills filter on
  /// those rather than on the demo data's invented "open now" state.
  List<String> get _filters => _live
      ? [
          _t('Kosher', 'כשר'),
          _t('Delivery', 'משלוחים'),
          _t('Rated', 'מדורגים'),
          _t('Open on Shabbat', 'פתוח בשבת'),
        ]
      : _filtersDemo;

  List<_Business> get _businesses {
    if (!_live) return _businessesDemo;
    final cats = _liveCategories;
    final palette = _categoryPalette;
    return [
      for (final b in _wp)
        _Business(
          name: b.title,
          category: b.primaryTerm,
          categoryIndex: cats.indexWhere((c) => b.terms.contains(c.name)),
          area: b.shortAddress,
          rating: b.rating ?? 0,
          reviews: b.views,
          isOpen: true,
          tags: const {},
          imageBg: palette[b.id % palette.length].$1,
          logoBg: palette[(b.id + 3) % palette.length].$2,
          imageUrl: b.image,
          logoUrl: b.logo,
          phone: b.phone,
          hours: b.hours,
          kosher: b.kosher,
          delivery: b.delivery,
          views: b.views,
          terms: b.terms,
          isLive: true,
        ),
    ];
  }

  bool _matchesFilter(_Business b, int filter) {
    if (!_live) return b.tags.contains(filter);
    switch (filter) {
      case 0:
        return b.kosher;
      case 1:
        return b.delivery;
      case 2:
        return b.hasRating;
      case 3:
        return b.terms.any((t) => t.contains('פתוח בשבת'));
      default:
        return true;
    }
  }

  List<_Business> get _visibleBusinesses {
    final q = _query.toLowerCase();
    return _businesses.where((b) {
      if (_selectedCategory >= 0) {
        final name = _categories[_selectedCategory].name;
        final inCategory = _live ? b.terms.contains(name) : b.categoryIndex == _selectedCategory;
        if (!inCategory) return false;
      }
      if (_selectedFilter >= 0 && !_matchesFilter(b, _selectedFilter)) return false;
      if (q.isEmpty) return true;
      return b.name.toLowerCase().contains(q) ||
          b.category.toLowerCase().contains(q) ||
          b.area.toLowerCase().contains(q) ||
          b.terms.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  // ── Featured professionals ──
  List<_Professional> get _professionalsDemo => [
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
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: 'businesses',
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
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
  // STICKY NAVBAR — 1920 × 80
  // ─────────────────────────────────────────────
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
              onChanged: (v) => setState(() {
                _query = v.trim();
                _shown = _pageSize;
              }),
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
                          setState(() {
                            _selectedCategory = _selectedCategory == i ? -1 : i;
                            _shown = _pageSize;
                          });
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
                    viewsLabel: _t('views', 'צפיות'),
                    kosherLabel: _t('Kosher', 'כשר'),
                    deliveryLabel: _t('Delivery', 'משלוחים'),
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
                  onTap: () => setState(() {
                    _selectedFilter = _selectedFilter == i ? -1 : i;
                    _shown = _pageSize;
                  }),
                );
              }),
            ),
            const SizedBox(height: 32),
            if (results.isEmpty)
              _buildEmptyResults()
            else ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 20.0;
                  const perRow = 4;
                  final cardWidth = (constraints.maxWidth - gap * (perRow - 1)) / perRow;
                  final visible = results.take(_shown).toList();
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: List.generate(visible.length, (i) {
                      return SizedBox(
                        width: cardWidth,
                        height: 372,
                        child: _BusinessCard(
                          business: visible[i],
                          openLabel: _t('Open Now', 'פתוח עכשיו'),
                          closedLabel: _t('Closed', 'סגור'),
                          reviewsLabel: _t('reviews', 'ביקורות'),
                          viewsLabel: _t('views', 'צפיות'),
                          kosherLabel: _t('Kosher', 'כשר'),
                          deliveryLabel: _t('Delivery', 'משלוחים'),
                          viewLabel: _t('View Business', 'לעמוד העסק'),
                          onTap: () => context.push('/business/demo_$i'),
                        ),
                      );
                    }),
                  );
                },
              ),
              if (results.length > _shown) ...[
                const SizedBox(height: 32),
                Center(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _shown = (_shown + _pageSize).clamp(0, results.length)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.midBlue),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          _t('Show more (${results.length - _shown} left)',
                              'הצג עוד (נותרו ${results.length - _shown})'),
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.midBlue),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
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
}

// ═══════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════

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

  // ── Populated only for real listings from the WordPress export ──
  final String imageUrl, logoUrl, phone, hours;
  final bool kosher, delivery;
  /// Real listings have a view count but often no rating, so [rating] is 0
  /// for them and this carries the popularity signal the site does keep.
  final int views;
  final List<String> terms;
  /// Set for listings built from the export. Inferring this from whether a
  /// field is filled misreads the real listings that have no categories and
  /// no phone — they exist, and they were showing demo badges.
  final bool isLive;

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
    this.imageUrl = '',
    this.logoUrl = '',
    this.phone = '',
    this.hours = '',
    this.kosher = false,
    this.delivery = false,
    this.views = 0,
    this.terms = const [],
    this.isLive = false,
  });

  bool get hasRating => rating > 0;
}

class _Professional {
  final String name, profession;
  final double rating;
  final int reviews;
  final Color avatarBg;
  final bool verified;

  // ── Real providers from the WordPress export ──
  final String imageUrl, phone, description;
  final bool isLive;

  const _Professional({
    required this.name,
    required this.profession,
    required this.rating,
    required this.reviews,
    required this.avatarBg,
    required this.verified,
    this.imageUrl = '',
    this.phone = '',
    this.description = '',
    this.isLive = false,
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

/// Real photo when the listing has one, gradient stand-in otherwise.
///
/// `webHtmlElementStrategy` matters: the WordPress uploads are served with
/// no CORS headers, so CanvasKit cannot decode them and has to hand the URL
/// to a plain <img> element.
Widget _remoteImage(String url, Color base,
    {double? width, double? height, BorderRadius? radius, double glyph = 28}) {
  final fallback = _imagePlaceholder(base, width: width, height: height, radius: radius, glyph: glyph);
  if (url.isEmpty) return fallback;
  return ClipRRect(
    borderRadius: radius ?? BorderRadius.circular(999),
    child: Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
    ),
  );
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
  final String kosherLabel, deliveryLabel, viewsLabel;
  final VoidCallback onTap;
  const _BusinessCard({
    required this.business,
    required this.openLabel,
    required this.closedLabel,
    required this.reviewsLabel,
    required this.viewLabel,
    required this.kosherLabel,
    required this.deliveryLabel,
    required this.viewsLabel,
    required this.onTap,
  });

  @override
  State<_BusinessCard> createState() => _BusinessCardState();
}

class _BusinessCardState extends State<_BusinessCard> {
  bool _hovered = false;

  Widget _chip(String label, Color bg, Color fg, {bool dot = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: fg),
            ),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }

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
                    _remoteImage(b.imageUrl, b.imageBg,
                        width: double.infinity,
                        height: 168,
                        radius: const BorderRadius.vertical(top: Radius.circular(11)),
                        glyph: 30),
                    PositionedDirectional(
                      start: 12,
                      top: 12,
                      child: Row(
                        children: [
                          // Real listings say what the site actually records —
                          // kosher and delivery — instead of a live open/closed
                          // state nothing in the export can back up.
                          if (b.isLive) ...[
                            if (b.kosher)
                              _chip(widget.kosherLabel, _kOpenBg, _kOpenText),
                            if (b.kosher && b.delivery) const SizedBox(width: 6),
                            if (b.delivery)
                              _chip(widget.deliveryLabel, _kDeliveryBg, AppColors.midBlue),
                          ] else
                            _chip(
                              b.isOpen ? widget.openLabel : widget.closedLabel,
                              b.isOpen ? _kOpenBg : _kClosedBg,
                              b.isOpen ? _kOpenText : _kClosedText,
                              dot: true,
                            ),
                        ],
                      ),
                    ),
                    if (b.hasRating)
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
                        child: _remoteImage(b.logoUrl, b.logoBg, radius: BorderRadius.circular(9), glyph: 18),
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
                      Text(
                          b.isLive
                              ? '${b.views} ${widget.viewsLabel}'
                              : '${b.reviews} ${widget.reviewsLabel}',
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
                          // Dials the real number; inert on demo listings,
                          // which have none.
                          MouseRegion(
                            cursor: b.phone.isEmpty
                                ? SystemMouseCursors.basic
                                : SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: b.phone.isEmpty
                                  ? null
                                  : () => launchUrl(Uri.parse('tel:${b.phone}')),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  border: Border.all(color: _kBorder),
                                  borderRadius: BorderRadius.circular(60),
                                ),
                                child: Icon(IconsaxPlusLinear.call,
                                    size: 18,
                                    color: b.phone.isEmpty ? _kIconGrey : AppColors.midBlue),
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
                    _remoteImage(p.imageUrl, p.avatarBg, width: 88, height: 88, glyph: 24),
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
              // The site records no ratings for providers, so a real card shows
              // the provider's own blurb where the stars would be.
              if (p.isLive)
                SizedBox(
                  height: 32,
                  child: Text(
                    p.description,
                    style: GoogleFonts.inter(fontSize: 12, color: _kGreyText, height: 1.35),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
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
              GestureDetector(
                onTap: p.phone.isEmpty ? null : () => launchUrl(Uri.parse('tel:${p.phone}')),
                child: Container(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
