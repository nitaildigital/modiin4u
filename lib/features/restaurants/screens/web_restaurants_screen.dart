import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/web_banner_row.dart';
import '../../../shared/widgets/web_dotted_band.dart';
import '../providers/restaurant_providers.dart';
import '../widgets/restaurant_place_card.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../../shared/widgets/web_hero_photo.dart';

// ═══════════════════════════════════════════════════════════
// Web Restaurants — full desktop layout from Figma
// (Restaurants in Modiin — 1920 × 5047)
// ═══════════════════════════════════════════════════════════

const _kAsset = 'assets/web/restaurants';

class WebRestaurantsContent extends ConsumerStatefulWidget {
  const WebRestaurantsContent({super.key});

  @override
  ConsumerState<WebRestaurantsContent> createState() => _WebRestaurantsContentState();
}

class _WebRestaurantsContentState extends ConsumerState<WebRestaurantsContent>
    with WebLanguageState<WebRestaurantsContent> {
  bool get _isHebrew => webIsHebrew.value;
  int _categoryStart = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  /// The listing beside the map, narrowed the way [params] say. Every
  /// "View all", quick pick and category card on this page opens it, so the
  /// whole list is one click from the row that showed four of it.
  void _openListing([Map<String, String> params = const {}]) {
    context.push(Uri(path: '/restaurants-map', queryParameters: params.isEmpty ? null : params).toString());
  }

  // ═══════════════════════════════════════════════
  // LIVE CONTENT — the food categories and the places in them
  // ═══════════════════════════════════════════════

  static const _categoryPalette = [
    Color(0xFFE8D5D0), Color(0xFFD5E3E8), Color(0xFFE8E0CE), Color(0xFFD9E8D5),
    Color(0xFFE8DCD0), Color(0xFFD0DFE8), Color(0xFFE8D0D0), Color(0xFFDCE8D0),
    Color(0xFFE8D8E4),
  ];

  static const _placePalette = [
    Color(0xFFE3CFC4), Color(0xFFDCE0C4), Color(0xFFC4D4E0), Color(0xFFE0C4D4),
    Color(0xFFC4E0D8), Color(0xFFE0DCC4), Color(0xFFD4C4E0), Color(0xFFC4C9E0),
  ];

  /// Restaurants, cafés and the bars, as the directory holds them.
  List<FoodPlace> get _places => ref.watch(webFoodPlacesProvider).valueOrNull ?? const [];

  /// The food categories as the admin panel holds them: "restaurants", its
  /// sub-categories, and the top-level "cafe-bakery".
  ///
  /// Nine cuisines used to be written into this screen — Japanese, Italian,
  /// Vegan and Desserts among them, each with a count beside it — and not one
  /// of them is a category in the database, so no card could be acted on and
  /// no count came from anywhere. Busiest first, counted from the places.
  List<_Category> get _categories {
    final all = ref.watch(categoriesBySlugProvider).valueOrNull;
    if (all == null) return const [];
    final places = _places;

    final parent = all['restaurants'];
    final food = [
      for (final c in all.values)
        if (c.slug == 'cafe-bakery' ||
            c.slug == 'restaurants' ||
            (parent != null && c.parentId == parent.id))
          c,
    ];
    final inside = {
      for (final c in food) c.slug: places.where((p) => p.slugs.contains(c.slug)).toList(),
    };
    food.sort((a, b) => inside[b.slug]!.length.compareTo(inside[a.slug]!.length));

    // The category's own picture where the admin has set one — none has yet
    // — and otherwise a photograph from a place inside it, so the tile shows
    // the food rather than a colour. A place filed under two categories gives
    // its photograph to the first of them only, so no two tiles repeat one.
    final used = <String>{};
    return [
      for (final (i, c) in food.indexed)
        _Category(
          slug: c.slug,
          name: c.name,
          count: inside[c.slug]!.length,
          imageBg: _categoryPalette[i % _categoryPalette.length],
          imageUrl: (c.imageUrl ?? '').isNotEmpty
              ? c.imageUrl
              : _firstUnused(inside[c.slug]!, used),
        ),
    ];
  }

  static String? _firstUnused(List<FoodPlace> places, Set<String> used) {
    final photos = places.map((p) => p.business.imageUrl).whereType<String>().where((u) => u.isNotEmpty);
    final pick = photos.where((u) => !used.contains(u)).firstOrNull ?? photos.firstOrNull;
    if (pick != null) used.add(pick);
    return pick;
  }

  /// Best rated first; among equals, a place with a photograph before one
  /// without, since the row is drawn as photographs; and otherwise in the
  /// order they came (newest first). `List.sort` is not stable, so the
  /// original position breaks the last tie.
  static List<FoodPlace> _ratedFirst(Iterable<FoodPlace> places) {
    int photo(FoodPlace p) => (p.business.imageUrl ?? '').isEmpty ? 1 : 0;
    final indexed = places.indexed.toList()
      ..sort((a, b) {
        final byRating = b.$2.business.rating.compareTo(a.$2.business.rating);
        if (byRating != 0) return byRating;
        final byCount = b.$2.business.reviewCount.compareTo(a.$2.business.reviewCount);
        if (byCount != 0) return byCount;
        final byPhoto = photo(a.$2).compareTo(photo(b.$2));
        return byPhoto != 0 ? byPhoto : a.$1.compareTo(b.$1);
      });
    return [for (final e in indexed) e.$2];
  }

  String _kindLabel(FoodKind kind) => switch (kind) {
    FoodKind.restaurant => _t('Restaurant', 'מסעדה'),
    FoodKind.cafe => _t('Cafe', 'בית קפה'),
    FoodKind.bar => _t('Bar', 'בר'),
  };

  /// A card for [place]. The large card names the kind of place under the
  /// name and puts the cuisine in the photograph's pill; the compact one has
  /// no pill, and joins the two on its second line ("Restaurant · Asian"), as
  /// each is drawn.
  _Entry _entry(FoodPlace place, int index, {required bool compact}) {
    final b = place.business;
    final kind = _kindLabel(place.kind);
    return _Entry(
      b.id,
      RestaurantPlace(
        name: b.name,
        type: compact && place.cuisineName != null ? '$kind · ${place.cuisineName}' : kind,
        address: b.address,
        rating: b.rating,
        reviews: b.reviewCount,
        kind: place.kind,
        pill: compact ? null : place.cuisineName,
        // `kosher_level` is 'none' for a place with no certification, and the
        // model maps that to null.
        isKosher: b.kosherStatus != null,
        delivers: b.hasDelivery,
        imageBg: _placePalette[index % _placePalette.length],
        imageUrl: b.imageUrl ?? '',
        phone: b.phone ?? '',
        whatsapp: b.whatsapp,
      ),
    );
  }

  List<_Entry> _entries(Iterable<FoodPlace> places, {required bool compact}) => [
    for (final (i, p) in places.take(5).indexed) _entry(p, i, compact: compact),
  ];

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    final places = _places;

    // "Top rated restaurants loved by locals": the restaurants, best rated
    // first.
    final popular = _ratedFirst(places.where((p) => p.kind == FoodKind.restaurant));
    final coffee = _ratedFirst(places.where((p) => p.kind == FoodKind.cafe));
    // There is no bar category; these are the places whose own description
    // opens with "bar" or "pub" (see `describesABar`).
    final bars = _ratedFirst(places.where((p) => p.kind == FoodKind.bar));
    // "The places locals love most" can only be the ones someone has rated.
    // Until a review is approved the row is left out rather than ranking
    // places nobody has scored.
    final loved = _ratedFirst(places.where((p) => p.business.rating > 0));
    // "Lunch Nearby" drew a wait of "30–40 min" under each place; no column
    // holds one. What the directory does record is who delivers, so this is
    // the restaurants that bring lunch to you — less the ones the first row
    // already shows.
    final shown = {for (final p in popular.take(4)) p.business.id};
    final lunch = _ratedFirst(places.where(
        (p) => p.kind == FoodKind.restaurant && p.business.hasDelivery && !shown.contains(p.business.id)));

    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: 'restaurants',
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeroSection(categories, bars.isNotEmpty),
                    const WebBannerRow(code: 'RESTAURANTS_TOP'),
                    // Each section is left out until its rows arrive: a heading
                    // over an empty row reads as a section that lost its
                    // contents.
                    if (categories.isNotEmpty) _buildCategoriesSection(categories),
                    if (popular.isNotEmpty)
                      _buildPlacesSection(
                        icon: 'section_restaurants.svg',
                        title: _t('Popular Restaurants in Modiin', 'מסעדות פופולריות במודיעין'),
                        subtitle: _t('Top rated restaurants loved by locals.',
                            'המסעדות המדורגות ביותר, האהובות על המקומיים.'),
                        viewAll: _t('View all restaurants', 'כל המסעדות'),
                        onViewAll: () => _openListing({'cuisine': 'restaurants'}),
                        places: _entries(popular, compact: false),
                      ),
                    if (coffee.isNotEmpty)
                      _buildPlacesSection(
                        icon: 'section_coffee.svg',
                        title: _t('Coffee Shops in Modiin', 'בתי קפה במודיעין'),
                        // The design's line reads "ozy places…", its first
                        // letter lost.
                        subtitle: _t('Cozy places for great coffee and good vibes.',
                            'מקומות נעימים לקפה טוב ואווירה טובה.'),
                        viewAll: _t('View all coffee shops', 'כל בתי הקפה'),
                        onViewAll: () => _openListing({'cuisine': 'cafe-bakery'}),
                        places: _entries(coffee, compact: false),
                      ),
                    if (bars.isNotEmpty)
                      _buildPlacesSection(
                        icon: 'section_bars.svg',
                        title: _t('Bars in Modiin', 'ברים במודיעין'),
                        // The design repeats the coffee row's line here, and
                        // its button reads "View all coffee shops"; both are
                        // the bars' own below.
                        subtitle: _t('Bars and pubs for a drink and a night out.',
                            'ברים ופאבים לדרינק ולבילוי בערב.'),
                        viewAll: _t('View all bars', 'כל הברים'),
                        onViewAll: () => _openListing({'cuisine': kBarsKey}),
                        places: _entries(bars, compact: false),
                      ),
                    if (loved.isNotEmpty)
                      _buildPlacesSection(
                        icon: 'section_loved.svg',
                        title: _t('Most Loved in Modiin', 'האהובים ביותר במודיעין'),
                        subtitle: _t('The places locals love most.', 'המקומות שהמקומיים הכי אוהבים.'),
                        viewAll: _t('View all', 'הצג הכל'),
                        onViewAll: () => _openListing({'sort': 'rating'}),
                        places: _entries(loved, compact: true),
                        compact: true,
                      ),
                    if (lunch.isNotEmpty)
                      _buildPlacesSection(
                        icon: 'section_nearby.svg',
                        title: _t('Lunch Nearby', 'ארוחת צהריים בסביבה'),
                        subtitle: _t('Find great places for lunch around Modiin.',
                            'מצאו מקומות מעולים לארוחת צהריים במודיעין.'),
                        viewAll: _t('View all', 'הצג הכל'),
                        onViewAll: () => _openListing({'dining': 'delivery'}),
                        places: _entries(lunch, compact: true),
                        compact: true,
                        showDelivery: true,
                      ),
                    const SizedBox(height: 216),
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
  // HERO
  // ─────────────────────────────────────────────
  /// The design's band: a white field with a faint grid of dots, and in it
  /// the photograph card with the title, the search and the quick picks.
  Widget _buildHeroSection(List<_Category> categories, bool hasBars) {
    return SizedBox(
      width: double.infinity,
      height: 662,
      child: Stack(
        children: [
          const Positioned.fill(child: WebDottedBand()),
          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                height: 551,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        top: 1,
                        child: WebHeroPhoto(asset: '$_kAsset/hero.webp', placeholder: Color(0xFF858882)),
                      ),
                      // The sky is washed blue from the top, multiplied over
                      // the photograph and gone by two thirds of the way down.
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 428,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            backgroundBlendMode: BlendMode.multiply,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF80B2DF), Color(0x0080B2DF)],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 112,
                        left: 0,
                        right: 0,
                        child: Text(
                          _t('Restaurants in Modiin', 'מסעדות במודיעין'),
                          style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 44, height: 54 / 44, fontWeight: FontWeight.w600, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Positioned(
                        top: 180,
                        left: 0,
                        right: 0,
                        child: Text(
                          _t('Discover the best restaurants, cafe and bars in Modiin',
                              'גלו את המסעדות, בתי הקפה והברים הטובים במודיעין'),
                          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, height: 19 / 16, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Positioned(top: 247, left: 0, right: 0, child: _buildSearchBar()),
                      Positioned(top: 356, left: 0, right: 0, child: _buildQuickPicks(categories, hasBars)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The white chips under the search: Restaurants, Coffee Shops, Bars,
  /// Takeaway and Pizza, each opening the listing narrowed to it.
  ///
  /// A chip is only drawn while something answers it. Takeaway is the one
  /// that is missing today: `has_takeaway` is false on every business, and a
  /// chip that opened an empty list would be worse than none.
  Widget _buildQuickPicks(List<_Category> categories, bool hasBars) {
    final slugs = {for (final c in categories) c.slug};
    final takeaway = (ref.watch(takeawayBusinessIdsProvider).valueOrNull ?? const {}).isNotEmpty;
    final picks = [
      if (slugs.contains('restaurants'))
        ('chip_restaurants.svg', _t('Restaurants', 'מסעדות'), {'cuisine': 'restaurants'}),
      if (slugs.contains('cafe-bakery'))
        ('chip_coffee.svg', _t('Coffee Shops', 'בתי קפה'), {'cuisine': 'cafe-bakery'}),
      if (hasBars) ('chip_bars.svg', _t('Bars', 'ברים'), {'cuisine': kBarsKey}),
      if (takeaway) ('chip_takeaway.svg', _t('Takeaway', 'טייק אווי'), {'dining': 'takeaway'}),
      if (slugs.contains('pizza')) ('chip_pizza.svg', _t('Pizza', 'פיצה'), {'cuisine': 'pizza'}),
    ];
    if (picks.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final (icon, label, params) in picks)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _openListing(params),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset('$_kAsset/$icon', width: 14, height: 14),
                    const SizedBox(width: 8),
                    Text(label, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, height: 15 / 12, color: AppColors.midBlue)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Searches the restaurants, in the listing beside the map, rather than
  /// the whole site.
  void _onSearch() {
    final query = _searchController.text.trim();
    _openListing(query.isEmpty ? const {} : {'q': query});
  }

  Widget _buildSearchBar() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 848),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_t('What are you looking for?', 'מה אתם מחפשים?'),
                      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 17 / 14, color: const Color(0xFF3D3D3D))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, height: 19 / 16, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: _t('Restaurants, cuisines, dish or name...', 'מסעדות, מטבחים, מנה או שם...'),
                      hintStyle: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, height: 19 / 16, color: kRGreyText),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      filled: false,
                      isDense: true,
                      isCollapsed: true,
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _onSearch,
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppColors.midBlue,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset('assets/web/common/search_white.svg', width: 18, height: 18),
                      const SizedBox(width: 8),
                      Text(_t('Search', 'חיפוש'),
                          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                    ],
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
  // EXPLORE CATEGORIES — cuisine cards
  // ─────────────────────────────────────────────
  Widget _buildCategoriesSection(List<_Category> categories) {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: WebSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The design spells it "Expore".
            Text(_t('Explore Categories', 'גלו קטגוריות'),
                style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 28, height: 34 / 28, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
            const SizedBox(height: 10),
            Text(_t('Discover restaurants by the food you love.', 'גלו מסעדות לפי האוכל שאתם אוהבים.'),
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 17 / 14, color: kRGreyText)),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 18.0;
                final cols = constraints.maxWidth > 1400 ? 7 : (constraints.maxWidth > 1000 ? 5 : 3);
                final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
                final count = categories.length;
                final start = _categoryStart % count;
                final visible = [
                  for (var i = 0; i < cols && i < count; i++) categories[(start + i) % count],
                ];

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < visible.length; i++) ...[
                          if (i > 0) const SizedBox(width: gap),
                          SizedBox(
                            width: cardWidth,
                            child: _CategoryCard(
                              category: visible[i],
                              onTap: () => _openListing({'cuisine': visible[i].slug}),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // The row turns by one card either way, round and round,
                    // so the arrows always move it — even when every
                    // category already fits, as all seven do at 1920.
                    if (count > 1) ...[
                      PositionedDirectional(
                        start: -19, top: 90,
                        child: _CarouselArrow(
                          back: true,
                          onTap: () => setState(() => _categoryStart = (start - 1 + count) % count),
                        ),
                      ),
                      PositionedDirectional(
                        end: -20, top: 90,
                        child: _CarouselArrow(
                          onTap: () => setState(() => _categoryStart = (start + 1) % count),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PLACES SECTION — header + one row of cards
  // ─────────────────────────────────────────────
  Widget _buildPlacesSection({
    required String icon,
    required String title,
    required String subtitle,
    required String viewAll,
    required VoidCallback onViewAll,
    required List<_Entry> places,
    bool compact = false,
    bool showDelivery = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 72),
      child: WebSection(
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // The round icon is 48 across with a 2.4 white ring drawn
                // outside it, which the SVG includes.
                SizedBox(
                  width: 48,
                  height: 48,
                  child: OverflowBox(
                    maxWidth: 52.8,
                    maxHeight: 52.8,
                    child: SvgPicture.asset('$_kAsset/$icon', width: 52.8, height: 52.8),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 28, height: 34 / 28, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
                      const SizedBox(height: 10),
                      Text(subtitle, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 17 / 14, color: kRGreyText)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _ViewAllButton(label: viewAll, onTap: onViewAll),
              ],
            ),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 24.0;
                // One row, as drawn: four large cards or five small ones at
                // the design's width, one fewer on a narrower window.
                final cols = (compact ? 5 : 4) - (constraints.maxWidth > 1400 ? 0 : 1);
                final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, entry) in places.take(cols).indexed) ...[
                      if (i > 0) const SizedBox(width: gap),
                      SizedBox(
                        width: cardWidth,
                        child: RestaurantCard(
                          place: entry.place,
                          compact: compact,
                          isHebrew: _isHebrew,
                          showDelivery: showDelivery,
                          // Restaurants are businesses; this opens the one
                          // the card names.
                          onTap: () => context.push('/business/${entry.id}'),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════

/// A card and the id of the business behind it.
///
/// The shared `RestaurantPlace` carries no id, so the two travel together and
/// a tap opens the row the card was built from.
class _Entry {
  final String id;
  final RestaurantPlace place;
  const _Entry(this.id, this.place);
}

class _Category {
  /// The `categories` row's slug, which is what the listing filters on.
  final String slug;
  final String name;
  final int count;
  final Color imageBg;
  final String? imageUrl;
  const _Category({
    required this.slug,
    required this.name,
    required this.count,
    required this.imageBg,
    this.imageUrl,
  });
}

// ═══════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════

class _ViewAllButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ViewAllButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
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
              Text(label, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 24 / 14, fontWeight: FontWeight.w500, color: Colors.white)),
              const SizedBox(width: 4),
              Transform.flip(
                flipX: rtl,
                child: SvgPicture.asset('$_kAsset/chevron_right_white.svg', width: 16, height: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The white round arrow at either end of a carousel. [back] points it the
/// other way, and the page's direction turns both round in Hebrew.
class _CarouselArrow extends StatelessWidget {
  final bool back;
  final VoidCallback onTap;
  const _CarouselArrow({this.back = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF6F6F6)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 5, offset: const Offset(0, 1))],
          ),
          child: Center(
            child: Transform.flip(
              flipX: back != rtl,
              child: SvgPicture.asset('$_kAsset/carousel_arrow.svg', width: 20, height: 20),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final _Category category;
  final VoidCallback onTap;
  const _CategoryCard({required this.category, required this.onTap});

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
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _hovered ? AppColors.midBlue : kRBorder),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                child: NetworkPhoto(
                  url: c.imageUrl,
                  height: 150,
                  width: double.infinity,
                  gradient: [c.imageBg, Color.lerp(c.imageBg, Colors.black, 0.18)!],
                  icon: null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 18, height: 22 / 18, fontWeight: FontWeight.w600, color: AppColors.navy),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${c.count} ${_placesLabel(context, c.count)}',
                        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, height: 17 / 14, color: kRGreyText),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _placesLabel(BuildContext context, int count) {
    final hebrew = Directionality.of(context) == TextDirection.rtl;
    if (count == 1) return hebrew ? 'מקום' : 'place';
    return hebrew ? 'מקומות' : 'places';
  }
}
