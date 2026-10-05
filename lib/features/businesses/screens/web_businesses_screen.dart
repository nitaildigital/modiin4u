import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../restaurants/providers/restaurant_providers.dart' show categoriesBySlugProvider;
import '../models/business.dart';
import '../providers/business_providers.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../../shared/widgets/network_photo.dart' show NetworkPhoto, photoTargetWidth, sizedPhotoUrl;
import '../../../shared/widgets/web_contact_menu.dart';

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

/// Which categories each business is filed under, keyed by business id.
///
/// The `businesses` table has no category column of its own — the links live
/// in `entity_categories` — so the card's category line, the category grid and
/// the professionals row all come from one read of those 210 links rather than
/// from a query per category.
final _categoryLinksProvider = FutureProvider<Map<String, List<String>>>((ref) async {
  final links = await ref.watch(businessRepositoryProvider).fetchCategoryLinks();
  final byBusiness = <String, List<String>>{};
  for (final link in links) {
    byBusiness
        .putIfAbsent(link['entity_id'] as String, () => [])
        .add(link['category_id'] as String);
  }
  return byBusiness;
});

class WebBusinessesContent extends ConsumerStatefulWidget {
  const WebBusinessesContent({super.key});

  @override
  ConsumerState<WebBusinessesContent> createState() => _WebBusinessesContentState();
}

class _WebBusinessesContentState extends ConsumerState<WebBusinessesContent>
    with WebLanguageState<WebBusinessesContent> {
  bool get _isHebrew => webIsHebrew.value;
  String? _selectedCategory; // null = all categories
  int _selectedFilter = -1; // -1 = no pill selected
  String _query = '';

  final _searchCtrl = TextEditingController();
  final _resultsKey = GlobalKey();

  /// How many listings the results grid shows. All 219 at once makes a page so
  /// long that the sections under it are unreachable, so it grows on demand.
  static const _pageSize = 24;
  int _shown = _pageSize;

  /// Whether the category grid is expanded past the first eight.
  bool _allCategories = false;

  /// The categories a service provider is filed under. A "professional" is not
  /// a separate kind of record here — there is no such table — it is a
  /// business in one of these categories.
  static const _serviceSlugs = {
    'services',
    'health',
    'beauty',
    'automotive',
    'education',
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

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

  static IconData _iconForSlug(String slug) => switch (slug) {
    'restaurants' || 'meat' || 'fish' || 'mediterranean' || 'asian' => IconsaxPlusBold.reserve,
    'pizza' => IconsaxPlusBold.cake,
    'cafe-bakery' => IconsaxPlusBold.coffee,
    'beauty' => IconsaxPlusBold.brush_1,
    'sports-fitness' => IconsaxPlusBold.weight,
    'automotive' => IconsaxPlusBold.car,
    'education' => IconsaxPlusBold.book_1,
    'health' => IconsaxPlusBold.health,
    'shopping' => IconsaxPlusBold.bag_2,
    'entertainment' => IconsaxPlusBold.ticket,
    'services' => IconsaxPlusBold.setting_2,
    _ => IconsaxPlusBold.shop,
  };

  // ═══════════════════════════════════════════════
  // LIVE DIRECTORY
  //
  // Eight categories with counts like "126 restaurants", twelve businesses
  // with names, neighbourhoods, open/closed states and ratings up to 4.9, and
  // six named professionals with review counts were all written into this
  // screen. None of it came from anywhere, and every card pushed
  // `/business/demo_<index>`, which matches no row and so opened nothing.
  // ═══════════════════════════════════════════════

  Map<String, BusinessCategory> get _categoriesById {
    final bySlug = ref.watch(categoriesBySlugProvider).valueOrNull ?? const {};
    return {for (final c in bySlug.values) c.id: c};
  }

  Map<String, List<String>> get _links =>
      ref.watch(_categoryLinksProvider).valueOrNull ?? const {};

  /// The directory's categories, busiest first, with the number of businesses
  /// actually linked to each: the main ones, or every one once expanded.
  ///
  /// Before the old site's 63 categories came back (5 Oct) the eight cards
  /// were all categories; now sub-categories such as "מסעדות כשרות" (38)
  /// would push the main ones off the first row, so they wait for "All
  /// categories". Lists kept out of the menus are never cards.
  List<_Category> get _categories {
    final counts = ref.watch(businessCountsByCategoryProvider).valueOrNull ?? const {};
    final all = _categoriesById.values
        .where((c) => c.inMenus && (_allCategories || c.parentId == null))
        .toList()
      ..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
    return [
      for (final (i, c) in all.indexed)
        _Category(
          id: c.id,
          name: c.name,
          count: counts[c.id] ?? 0,
          icon: _iconForSlug(c.slug),
          start: _categoryPalette[i % _categoryPalette.length].$1,
          end: _categoryPalette[i % _categoryPalette.length].$2,
        ),
    ];
  }

  /// How many cards "All categories" opens to: every category in the menus.
  int get _allCategoryCount =>
      _categoriesById.values.where((c) => c.inMenus).length;

  /// The eight cards above the fold, or all of them once expanded.
  List<_Category> get _visibleCategories {
    final all = _categories;
    return _allCategories ? all : all.take(8).toList();
  }

  /// Filter pills that a column can answer. "Open Now" needs opening hours and
  /// `business_hours` is empty; "Top Rated" and "Rated" need reviews and there
  /// are none; "Open on Shabbat" and "Home Service" name flags that are false
  /// on all 219 rows. Each of those could only ever empty the grid.
  List<String> get _filters => [
    _t('Kosher', 'כשר'),
    _t('Delivery', 'משלוחים'),
  ];

  bool _matchesFilter(_Business b, int filter) => switch (filter) {
    0 => b.kosher,
    1 => b.delivery,
    _ => true,
  };

  List<_Business> get _businesses {
    final rows = ref.watch(businessesProvider).valueOrNull ?? const <Business>[];
    final byId = _categoriesById;
    final links = _links;
    return [
      for (final (i, b) in rows.indexed)
        _Business.of(
          b,
          categories: [
            for (final id in links[b.id] ?? const <String>[])
              if (byId[id] != null) byId[id]!,
          ],
          imageBg: _categoryPalette[i % _categoryPalette.length].$1,
          logoBg: _categoryPalette[(i + 3) % _categoryPalette.length].$2,
          unlistedCategory: _t('Business', 'עסק'),
        ),
    ];
  }

  List<_Business> get _visibleBusinesses {
    final q = _query.toLowerCase();
    return _businesses.where((b) {
      if (_selectedCategory != null && !b.categoryIds.contains(_selectedCategory)) {
        return false;
      }
      if (_selectedFilter >= 0 && !_matchesFilter(b, _selectedFilter)) return false;
      if (q.isEmpty) return true;
      return b.name.toLowerCase().contains(q) ||
          b.category.toLowerCase().contains(q) ||
          b.area.toLowerCase().contains(q);
    }).toList();
  }

  /// The service providers under the grid: businesses in the service
  /// categories, newest first.
  List<_Business> get _professionals {
    final serviceIds = {
      for (final c in _categoriesById.values)
        if (_serviceSlugs.contains(c.slug)) c.id,
    };
    if (serviceIds.isEmpty) return const [];
    return _businesses
        .where((b) => b.categoryIds.any(serviceIds.contains))
        .take(6)
        .toList();
  }

  void _scrollToResults() {
    final ctx = _resultsKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      alignment: 0.05,
    );
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
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeroSection(),
                    _buildCategoriesSection(),
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
  // HERO — title, subtitle, search bar
  // ─────────────────────────────────────────────
  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          Text(
            _t(
              'Businesses & Professionals in Modiin',
              'עסקים ובעלי מקצוע במודיעין',
            ),
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 44,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              height: 1.23,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            _t(
              'Find trusted local businesses, service providers and professionals — all in one place.',
              'מצאו עסקים מקומיים, נותני שירות ובעלי מקצוע מומלצים – הכל במקום אחד.',
            ),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              color: _kIconGrey,
              height: 1.19,
            ),
            textAlign: TextAlign.center,
          ),
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 24),
          const Icon(
            IconsaxPlusLinear.search_normal_1,
            size: 20,
            color: _kIconGrey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() {
                _query = v.trim();
                _shown = _pageSize;
              }),
              onSubmitted: (_) => _scrollToResults(),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 16,
                color: _kHeading,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: _t(
                  'Search businesses, services or professionals in Modiin...',
                  'חפשו עסקים, שירותים או בעלי מקצוע במודיעין...',
                ),
                hintStyle: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  color: _kIconGrey,
                ),
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
                  child: Icon(
                    IconsaxPlusLinear.close_circle,
                    size: 20,
                    color: _kIconGrey,
                  ),
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
                child: Text(
                  _t('Search', 'חיפוש'),
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
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BROWSE BY CATEGORY — gradient cards, 4 per row
  // ─────────────────────────────────────────────
  Widget _buildCategoriesSection() {
    final all = _categories;
    // Nothing to browse until the categories arrive; a grid of empty tiles
    // would only look like a page that had lost its content.
    if (all.isEmpty) return const SizedBox.shrink();
    final visible = _visibleCategories;

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
                  child: Text(
                    _t('Browse by Category', 'עיון לפי קטגוריה'),
                    style: TextStyle(
                      fontFamily: AppFonts.nunito,
                      fontSize: 28,
                      height: 34 / 28,
                      fontWeight: FontWeight.w600,
                      color: AppColors.midBlue,
                    ),
                  ),
                ),
                if (_allCategoryCount > 8) ...[
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _allCategories = !_allCategories),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _allCategories
                                ? IconsaxPlusLinear.arrow_up_2
                                : IconsaxPlusLinear.arrow_down_1,
                            size: 18,
                            color: AppColors.midBlue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _allCategories
                                ? _t('Show fewer', 'הצג פחות')
                                : _t(
                                    'All $_allCategoryCount categories',
                                    'כל $_allCategoryCount הקטגוריות',
                                  ),
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.midBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
                if (_selectedCategory != null)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = null),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            IconsaxPlusLinear.close_circle,
                            size: 18,
                            color: AppColors.midBlue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _t('Clear category', 'נקה קטגוריה'),
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.midBlue,
                            ),
                          ),
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
                final cardWidth =
                    (constraints.maxWidth - gap * (perRow - 1)) / perRow;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: List.generate(visible.length, (i) {
                    final category = visible[i];
                    return SizedBox(
                      width: cardWidth,
                      child: _CategoryCard(
                        category: category,
                        businessesLabel: _t('businesses', 'עסקים'),
                        isSelected: _selectedCategory == category.id,
                        onTap: () {
                          setState(() {
                            _selectedCategory =
                                _selectedCategory == category.id ? null : category.id;
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
  // RESULTS — filter pills, live count, 4-up grid
  // ─────────────────────────────────────────────
  Widget _buildResultsSection() {
    final request = ref.watch(businessesProvider);
    final results = _visibleBusinesses;
    final categoryName = _selectedCategory == null
        ? null
        : _categoriesById[_selectedCategory]?.name;

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
              style: TextStyle(
                fontFamily: AppFonts.nunito,
                fontSize: 28,
                height: 34 / 28,
                fontWeight: FontWeight.w600,
                color: AppColors.midBlue,
              ),
            ),
            const SizedBox(height: 10),
            // The count is only the truth once the rows are in; while the
            // request is in flight it would read "0 businesses found".
            Text(
              switch (request) {
                AsyncLoading() => _t('Loading the directory…', 'טוען את המדריך…'),
                AsyncError() => _t(
                    'The directory could not be loaded.',
                    'לא ניתן לטעון את המדריך.',
                  ),
                _ => results.length == 1
                    ? _t('1 business found', 'נמצא עסק אחד')
                    : _t(
                        '${results.length} businesses found',
                        'נמצאו ${results.length} עסקים',
                      ),
              },
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                color: _kGreyText,
                height: 1.21,
              ),
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
            if (request.isLoading)
              const SizedBox(
                height: 320,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (results.isEmpty)
              _buildEmptyResults()
            else ...[
              WebBusinessGrid(
                businesses: [for (final b in results.take(_shown)) b.source],
                isHebrew: _isHebrew,
              ),
              if (results.length > _shown) ...[
                const SizedBox(height: 32),
                Center(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(
                        () => _shown = (_shown + _pageSize).clamp(
                          0,
                          results.length,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.midBlue),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          _t(
                            'Show more (${results.length - _shown} left)',
                            'הצג עוד (נותרו ${results.length - _shown})',
                          ),
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
          Icon(
            IconsaxPlusLinear.shop,
            size: 44,
            color: _kGreyText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _t(
              'No businesses match your search',
              'לא נמצאו עסקים שתואמים לחיפוש',
            ),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _kHeading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t(
              'Try a different category, filter or search term.',
              'נסו קטגוריה, סינון או מילת חיפוש אחרים.',
            ),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: _kGreyText,
            ),
          ),
          const SizedBox(height: 20),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() {
                  _query = '';
                  _selectedCategory = null;
                  _selectedFilter = -1;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.midBlue,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  _t('Reset filters', 'איפוס סינון'),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
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
  // SERVICE PROVIDERS — 6 cards, 6 per row
  // ─────────────────────────────────────────────
  Widget _buildProfessionalsSection() {
    final professionals = _professionals;
    // Six named providers with ratings and review counts used to stand here,
    // and each opened a detail page describing the same invented plumber. A
    // provider is a business in one of the service categories, so the row is
    // drawn from those rows or not at all.
    if (professionals.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: _Section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('Professionals & Services', 'בעלי מקצוע ושירותים'),
              style: TextStyle(
                fontFamily: AppFonts.nunito,
                fontSize: 28,
                height: 34 / 28,
                fontWeight: FontWeight.w600,
                color: AppColors.midBlue,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _t(
                'Service providers listed in the Modiin directory',
                'נותני שירות הרשומים במדריך מודיעין',
              ),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                color: _kGreyText,
                height: 1.21,
              ),
            ),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 20.0;
                const perRow = 6;
                final cardWidth =
                    (constraints.maxWidth - gap * (perRow - 1)) / perRow;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: List.generate(professionals.length, (i) {
                    return SizedBox(
                      width: cardWidth,
                      child: _ProfessionalCard(
                        business: professionals[i],
                        contactLabel: _t('Contact', 'צרו קשר'),
                        onTap: () =>
                            context.push('/business/${professionals[i].id}'),
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
                    Text(
                      _t('Own a business in Modiin?', 'יש לכם עסק במודיעין?'),
                      style: TextStyle(
                        fontFamily: AppFonts.nunito,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _t(
                        'Write to us and we will add it to the Modiin4u directory.',
                        'כתבו לנו ונוסיף אותו למדריך מודיעין4u.',
                      ),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  // There is no self-service listing form, and the button had
                  // an empty handler. It opens the office mailbox the rest of
                  // the site's chrome uses.
                  onTap: () => launchUrl(
                    Uri(
                      scheme: 'mailto',
                      path: kContactEmail,
                      queryParameters: {
                        'subject': _t(
                          'Adding my business to Modiin4u',
                          'הוספת העסק שלי למודיעין4u',
                        ),
                      },
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Text(
                      _t('Add Your Business', 'הוסיפו את העסק שלכם'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.midBlue,
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
}

// ═══════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════

class _Category {
  /// The `categories` row id, which is also what the grid filters on.
  final String id;
  final String name;
  final int count;
  final IconData icon;
  final Color start, end;
  const _Category({
    required this.id,
    required this.name,
    required this.count,
    required this.icon,
    required this.start,
    required this.end,
  });
}

class _Business {
  /// The row itself, which the design's card draws from.
  final Business source;

  /// The row's id, so a card opens the business it names.
  final String id;
  final String name, category, area, description;
  final double rating;
  final int reviewCount;
  final bool kosher, delivery;
  final String imageUrl, logoUrl, phone;
  final Color imageBg, logoBg;

  /// Every category this business is linked to, for the grid's filter.
  final Set<String> categoryIds;

  const _Business({
    required this.source,
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.description,
    required this.rating,
    required this.reviewCount,
    required this.kosher,
    required this.delivery,
    required this.imageUrl,
    required this.logoUrl,
    required this.phone,
    required this.imageBg,
    required this.logoBg,
    required this.categoryIds,
  });

  factory _Business.of(
    Business b, {
    required List<BusinessCategory> categories,
    required Color imageBg,
    required Color logoBg,
    required String unlistedCategory,
  }) {
    return _Business(
      source: b,
      id: b.id,
      name: b.name,
      // 63 of the rows are in no category at all; those say "Business" rather
      // than borrowing the name of one they are not in. A pizzeria is linked
      // both to "restaurants" and to "pizza", and the child is the truer label.
      category: categories.isEmpty
          ? unlistedCategory
          : categories
                .firstWhere(
                  (c) => c.parentId != null,
                  orElse: () => categories.first,
                )
                .name,
      // The neighbourhood where the row is filed under one — only 19 are — and
      // the street address otherwise.
      area: b.neighborhood.isNotEmpty ? b.neighborhood : b.address,
      description: b.description?.trim() ?? '',
      rating: b.rating,
      reviewCount: b.reviewCount,
      kosher: b.kosherStatus != null,
      delivery: b.hasDelivery,
      imageUrl: b.imageUrl ?? '',
      logoUrl: b.logoUrl ?? '',
      phone: b.phone ?? '',
      imageBg: imageBg,
      logoBg: logoBg,
      categoryIds: {for (final c in categories) c.id},
    );
  }

  bool get hasRating => rating > 0;
}

// ═══════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════

class _Section extends StatelessWidget {
  final Widget child;
  const _Section({required this.child});

  @override
  Widget build(BuildContext context) {
    return WebSection(child: child);
  }
}

/// The row's photo, falling back to a gradient stand-in where it has none —
/// 90 of the 219 businesses have no cover image.
Widget _remoteImage(
  String url,
  Color base, {
  double? width,
  double? height,
  BorderRadius? radius,
  double glyph = 28,
}) {
  final fallback = _imagePlaceholder(
    base,
    width: width,
    height: height,
    radius: radius,
    glyph: glyph,
  );
  if (url.isEmpty) return fallback;
  return ClipRRect(
    borderRadius: radius ?? BorderRadius.circular(999),
    child: Image.network(
      sizedPhotoUrl(url, photoTargetWidth(width, height), 2),
      width: width,
      height: height,
      fit: BoxFit.cover,
      // Rendered by the browser's own <img> element rather than decoded into
      // the CanvasKit surface, which is how these covers have always loaded
      // here.
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : fallback,
    ),
  );
}

/// Gradient stand-in for a photo that has no asset yet.
Widget _imagePlaceholder(
  Color base, {
  double? width,
  double? height,
  BorderRadius? radius,
  double glyph = 28,
}) {
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
      child: Icon(
        IconsaxPlusLinear.image,
        size: glyph,
        color: Colors.white.withValues(alpha: 0.35),
      ),
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
              color: widget.isSelected
                  ? AppColors.turquoise
                  : Colors.transparent,
              width: 3,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
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
                child: Icon(
                  c.icon,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              if (widget.isSelected)
                PositionedDirectional(
                  top: 20,
                  start: 20,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.turquoise,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
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
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.22,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${c.count} ${widget.businessesLabel}',
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
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
}

// ─────────────────────────────────────────────
// FILTER PILL — 56px tall, radius 50
// ─────────────────────────────────────────────
class _FilterPill extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

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
            border: Border.all(
              color: selected
                  ? AppColors.midBlue
                  : (_hovered ? AppColors.turquoise : _kPillBorder),
            ),
            borderRadius: BorderRadius.circular(50),
          ),
          // mainAxisSize.min keeps the pill hugging its label — a Container
          // `alignment` here would stretch it to the full row width.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
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
// PROVIDER CARD — logo, name, category, contact
// ─────────────────────────────────────────────
class _ProfessionalCard extends StatefulWidget {
  final _Business business;
  final String contactLabel;
  final VoidCallback onTap;
  const _ProfessionalCard({
    required this.business,
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
    final b = widget.business;
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
              // A turquoise "Verified" tick sat on this avatar. `is_verified`
              // is false on every row, so nothing here is verified.
              _remoteImage(
                b.logoUrl.isNotEmpty ? b.logoUrl : b.imageUrl,
                b.logoBg,
                width: 88,
                height: 88,
                glyph: 24,
              ),
              const SizedBox(height: 16),
              Text(
                b.name,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kHeading,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                b.category,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 13,
                  color: _kGreyText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              // The provider's own blurb where the row has one, in the space a
              // star rating used to fill with a score nobody had given.
              SizedBox(
                height: 32,
                child: Text(
                  b.description,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 12,
                    color: _kGreyText,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              if (b.phone.isNotEmpty)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Builder(builder: (anchor) => GestureDetector(
                    onTap: () => showWebContactMenu(anchor, isHebrew: webIsHebrew.value, phone: b.phone, whatsapp: b.source.whatsapp, email: b.source.email),
                    child: Container(
                      width: double.infinity,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _hovered ? AppColors.midBlue : Colors.white,
                        border: Border.all(color: AppColors.midBlue),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Text(
                        widget.contactLabel,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _hovered ? Colors.white : AppColors.midBlue,
                        ),
                      ),
                    ),
                  )),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// THE DESIGN'S BUSINESS CARD — Homepage 17:1463, 385 × 404
// ═══════════════════════════════════════════════

const _kCardAsset = 'assets/web/home';
const _kCardInk = Color(0xFF0A1230);
const _kCardPill = Color(0xFF0033AC);
final _hebrewText = RegExp(r'[֐-׿]');

/// One business in the directory, drawn as the design's card: 200 of
/// photograph with the category in a pill at the top and the kosher
/// certificate at the bottom, the round café or restaurant badge on the
/// photograph's edge, then name, kind, address, rating and Contact.
///
/// It prints what the row carries and nothing else:
///
/// * the rating only once reviews have earned one — a gold star over
///   "0.0 (0)" reads as a bad score, not as no score;
/// * no view count: `businesses` has no such column, so the design's
///   "187 Views" has no source;
/// * no heart: saving belongs to an account, and accounts to the app;
/// * Contact only where there is a number to dial. The card keeps its 404
///   either way so a row of cards lines up.
///
/// The directory, a category page and the whole list all use it, so a
/// business looks the same wherever it is listed.
class WebBusinessCard extends StatefulWidget {
  final Business business;

  /// The most specific category the business is filed under, and the slug at
  /// the top of its branch — which decides the badge.
  final ({BusinessCategory category, String rootSlug})? kind;
  final bool isHebrew;
  const WebBusinessCard({super.key, required this.business, required this.kind, required this.isHebrew});

  @override
  State<WebBusinessCard> createState() => _WebBusinessCardState();
}

class _WebBusinessCardState extends State<WebBusinessCard> {
  bool _hovered = false;

  String _t(String en, String he) => widget.isHebrew ? he : en;

  /// Directory text reads in its own direction but lines up with the card:
  /// a Hebrew address on the English page still starts beside its pin.
  Widget _text(String s, TextStyle style) => Text(
        s,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textDirection: _hebrewText.hasMatch(s) ? TextDirection.rtl : TextDirection.ltr,
        textAlign: Directionality.of(context) == TextDirection.rtl ? TextAlign.right : TextAlign.left,
      );

  TextStyle _inter(double size, {FontWeight weight = FontWeight.w400, Color color = Colors.black}) =>
      TextStyle(fontFamily: AppFonts.inter, fontSize: size, fontWeight: weight, color: color, height: 1.21);

  Widget _pill(String label, {Widget? icon}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(color: _kCardPill, borderRadius: BorderRadius.circular(50)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon, const SizedBox(width: 6)],
            _text(label, _inter(12, weight: FontWeight.w500, color: Colors.white)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final b = widget.business;
    final categoryName = widget.kind?.category.name ?? '';
    final description = (b.description ?? '').trim();
    final subtitle = description.isNotEmpty ? description : categoryName;
    final address = b.address.isNotEmpty ? b.address : b.neighborhood;
    final phone = (b.phone ?? '').trim();
    final badge = switch (widget.kind?.rootSlug) {
      'cafe-bakery' => ('card_badge_ring.svg', 'card_badge_cafe.svg'),
      'restaurants' => ('card_badge_ring_green.svg', 'card_badge_restaurant.svg'),
      _ => null,
    };

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push('/business/${b.id}'),
        child: Container(
          height: 404,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: NetworkPhoto(url: b.imageUrl ?? b.logoUrl, icon: IconsaxPlusLinear.shop, iconSize: 40),
                    ),
                    if (categoryName.isNotEmpty)
                      PositionedDirectional(top: 15, end: 14, child: _pill(categoryName)),
                    if (b.kosherLabel != null)
                      PositionedDirectional(
                        top: 161,
                        start: 12,
                        child: _pill(
                          widget.isHebrew ? b.kosherLabel! : 'Kosher',
                          icon: SvgPicture.asset('$_kCardAsset/card_kosher.svg', width: 14, height: 14),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 50,
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _text(b.name, TextStyle(fontFamily: AppFonts.nunito, fontSize: 20, fontWeight: FontWeight.w600, color: _kCardInk, height: 1.25)),
                                if (subtitle.isNotEmpty) ...[const SizedBox(height: 8), _text(subtitle, _inter(14, color: _kGreyText))],
                              ],
                            ),
                          ),
                          if (address.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: Center(child: SvgPicture.asset('$_kCardAsset/card_pin.svg', width: 12, height: 16)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: _text(address, _inter(14, color: _kGreyText))),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (b.reviewCount == 0)
                            Text(_t('Not rated yet', 'אין דירוג עדיין'), style: _inter(14, color: _kIconGrey))
                          else
                            Row(
                              children: [
                                SvgPicture.asset('$_kCardAsset/card_star.svg', width: 16, height: 16),
                                const SizedBox(width: 8),
                                Text(b.rating.toStringAsFixed(1), style: _inter(14, weight: FontWeight.w500)),
                                const SizedBox(width: 8),
                                Text('(${b.reviewCount})', style: _inter(14, color: _kIconGrey)),
                              ],
                            ),
                          if (phone.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            // Outlined, filled while the card is under the
                            // pointer, as the design draws both states.
                            Builder(builder: (anchor) => GestureDetector(
                              onTap: () => showWebContactMenu(anchor, isHebrew: widget.isHebrew, phone: phone, whatsapp: b.whatsapp, email: b.email),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _hovered ? AppColors.midBlue : Colors.transparent,
                                  border: Border.all(color: AppColors.midBlue),
                                  borderRadius: BorderRadius.circular(60),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.asset(_hovered ? '$_kCardAsset/card_phone_white.svg' : '$_kCardAsset/card_phone.svg', width: 16, height: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      _t('Contact', 'צור קשר'),
                                      style: TextStyle(
                                        fontFamily: AppFonts.inter,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        height: 24 / 14,
                                        color: _hovered ? Colors.white : AppColors.midBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                          ],
                        ],
                      ),
                    ),
                    // The round badge sits on the photograph's edge, 44 across
                    // with its white ring, half over the picture.
                    if (badge != null)
                      PositionedDirectional(
                        top: -22,
                        end: 15,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SvgPicture.asset('$_kCardAsset/${badge.$1}', width: 44, height: 44),
                              SvgPicture.asset('$_kCardAsset/${badge.$2}', width: 20, height: 20),
                            ],
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
}

/// The grid of [WebBusinessCard]s both listing pages draw: four across at the
/// design's width, 24 apart, three on a narrower window.
class WebBusinessGrid extends ConsumerWidget {
  final List<Business> businesses;
  final bool isHebrew;
  const WebBusinessGrid({super.key, required this.businesses, required this.isHebrew});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kinds = ref.watch(businessPrimaryCategoryProvider).valueOrNull ?? const {};
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 24.0;
        final perRow = c.maxWidth >= 1250 ? 4 : 3;
        final w = (c.maxWidth - gap * (perRow - 1)) / perRow;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final b in businesses)
              SizedBox(width: w, child: WebBusinessCard(business: b, kind: kinds[b.id], isHebrew: isHebrew)),
          ],
        );
      },
    );
  }
}
