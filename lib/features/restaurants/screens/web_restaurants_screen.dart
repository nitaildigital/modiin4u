import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../businesses/models/business.dart';
import '../../businesses/providers/business_providers.dart';
import '../providers/restaurant_providers.dart';
import '../widgets/restaurant_place_card.dart';
import '../../../shared/widgets/web_chrome.dart';

// ═══════════════════════════════════════════════════════════
// Web Restaurants — full desktop layout from Figma
// (Restaurants in Modiin — 1920 × 5047)
// ═══════════════════════════════════════════════════════════


class WebRestaurantsContent extends ConsumerStatefulWidget {
  const WebRestaurantsContent({super.key});

  @override
  ConsumerState<WebRestaurantsContent> createState() => _WebRestaurantsContentState();
}

class _WebRestaurantsContentState extends ConsumerState<WebRestaurantsContent> {
  bool _isHebrew = false;
  int _categoryPage = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  // ═══════════════════════════════════════════════
  // LIVE CONTENT — the food categories and the businesses in them
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

  /// The food categories as the admin panel holds them: "restaurants", its
  /// sub-categories, and the top-level "cafe-bakery".
  ///
  /// Nine cuisines used to be written into this screen — Japanese, Italian,
  /// Vegan and Desserts among them, each with a count beside it — and not one
  /// of them is a category in the database, so no card could be acted on and
  /// no count came from anywhere. Busiest first, from the real links.
  List<_Category> get _categories {
    final all = ref.watch(categoriesBySlugProvider).valueOrNull;
    if (all == null) return const [];
    final counts = ref.watch(businessCountsByCategoryProvider).valueOrNull ?? const {};

    final parent = all['restaurants'];
    final food = [
      for (final c in all.values)
        if (c.slug == 'cafe-bakery' ||
            c.slug == 'restaurants' ||
            (parent != null && c.parentId == parent.id))
          c,
    ]..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));

    return [
      for (final (i, c) in food.indexed)
        _Category(
          id: c.id,
          name: c.name,
          count: counts[c.id] ?? 0,
          imageBg: _categoryPalette[i % _categoryPalette.length],
        ),
    ];
  }

  List<Business> _inCategory(String slug) =>
      ref.watch(businessesBySlugProvider(slug)).valueOrNull ?? const [];

  List<FoodPlace> get _foodPlaces =>
      ref.watch(foodMapPlacesProvider).valueOrNull ?? const [];

  /// Food businesses the directory records a delivery service for. 66 of the
  /// 219 rows say so, and `has_takeaway` is false on every one of them, so
  /// this is the only serving option the page can claim.
  ///
  /// It used to be "Lunch Nearby", five invented places addressed on Abylai
  /// Khan Avenue and Dostyk Street in Almaty, each promising a delivery window
  /// — 30–40 min, 25–35 min — that no column holds.
  List<_Entry> get _delivery => [
    for (final (i, p) in _foodPlaces.where((p) => p.business.hasDelivery).take(10).indexed)
      _placeOf(p, AppColors.turquoise, i),
  ];

  /// The best-rated places. `reviews` is empty, so every row's rating is 0 and
  /// this list is too — the section is left out of the page rather than
  /// printing five places at "4.8" that nobody has rated.
  List<_Entry> get _mostLoved {
    final rated = _foodPlaces.where((p) => p.business.rating > 0).toList()
      ..sort((a, b) {
        final byRating = b.business.rating.compareTo(a.business.rating);
        return byRating != 0
            ? byRating
            : b.business.reviewCount.compareTo(a.business.reviewCount);
      });
    return [
      for (final (i, p) in rated.take(10).indexed) _placeOf(p, kHeartRed, i),
    ];
  }

  _Entry _placeOf(FoodPlace place, Color marker, int index) =>
      _place(place.business, place.categoryName, marker, index);

  _Entry _place(Business b, String categoryName, Color marker, int index) {
    final description = b.description?.trim() ?? '';
    return _Entry(
      b.id,
      RestaurantPlace(
        name: b.name,
        // Its own blurb where the row has one, the category it sits in
        // otherwise. Nothing is composed out of the two.
        type: description.isNotEmpty ? description : categoryName,
        address: b.address,
        rating: b.rating,
        reviews: b.reviewCount,
        // Null for a place the directory records no delivery for, which the
        // card now simply omits. It used to fall back to a view count there,
        // and `businesses` has no such column.
        deliveryTime: b.hasDelivery ? _t('Delivery', 'משלוחים') : null,
        // The badge would otherwise repeat the line underneath it.
        category: description.isNotEmpty ? categoryName : null,
        // `kosher_level` is 'none' for a place with no certification, and the
        // model maps that to null.
        isKosher: b.kosherStatus != null,
        marker: marker,
        imageBg: _placePalette[index % _placePalette.length],
        imageUrl: b.imageUrl ?? '',
        phone: b.phone ?? '',
      ),
    );
  }

  List<_Entry> _places(List<Business> items, String categoryName, Color marker) => [
    for (final (i, b) in items.take(8).indexed) _place(b, categoryName, marker, i),
  ];

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    final restaurants = _places(
      _inCategory('restaurants'),
      _t('Restaurant', 'מסעדה'),
      kRestaurantGreen,
    );
    final cafes = _places(
      _inCategory('cafe-bakery'),
      _t('Cafe & Bakery', 'קפה ומאפה'),
      kCafeBlue,
    );
    final mostLoved = _mostLoved;
    final delivery = _delivery;

    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: 'restaurants',
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeroSection(),
                    // Each section is left out until its rows arrive: a heading
                    // over an empty row reads as a section that lost its
                    // contents.
                    if (categories.isNotEmpty) _buildCategoriesSection(categories),
                    if (restaurants.isNotEmpty)
                      _buildPlacesSection(
                        icon: IconsaxPlusLinear.reserve,
                        accent: kRestaurantGreen,
                        title: _t('Restaurants in Modiin', 'מסעדות במודיעין'),
                        subtitle: _t('The newest additions to the restaurants category.',
                            'התוספות החדשות לקטגוריית המסעדות.'),
                        places: restaurants,
                      ),
                    if (cafes.isNotEmpty)
                      _buildPlacesSection(
                        icon: IconsaxPlusLinear.coffee,
                        accent: kCafeBlue,
                        title: _t('Cafes & Bakeries in Modiin', 'קפה ומאפה במודיעין'),
                        subtitle: _t('Places for coffee, breakfast and something baked.',
                            'מקומות לקפה, ארוחת בוקר ומשהו מהתנור.'),
                        places: cafes,
                      ),
                    if (mostLoved.isNotEmpty)
                      _buildPlacesSection(
                        icon: IconsaxPlusLinear.heart,
                        accent: kHeartRed,
                        title: _t('Most Loved in Modiin', 'האהובים ביותר במודיעין'),
                        subtitle: _t('The best rated places in the directory.',
                            'המקומות המדורגים ביותר במדריך.'),
                        places: mostLoved,
                        compact: true,
                      ),
                    if (delivery.isNotEmpty)
                      _buildPlacesSection(
                        icon: IconsaxPlusLinear.truck_fast,
                        accent: AppColors.turquoise,
                        title: _t('Delivery in Modiin', 'משלוחים במודיעין'),
                        subtitle: _t('Places that deliver around Modiin.',
                            'מקומות שמציעים משלוחים במודיעין.'),
                        places: delivery,
                        compact: true,
                      ),
                    const SizedBox(height: 24),
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
  Widget _buildHeroSection() {
    return SizedBox(
      width: double.infinity,
      height: 560,
      child: Stack(
        children: [
          // Soft background wash behind the hero card
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0x14BFE7F6), Color(0x00C4C4C4)],
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              margin: const EdgeInsets.symmetric(horizontal: 40).copyWith(top: 48),
              height: 450,
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
                  Positioned(
                    top: 0, left: 0, right: 0, height: 350,
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
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 96),
                        Text(
                          _t('Restaurants in Modiin', 'מסעדות במודיעין'),
                          style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 44, fontWeight: FontWeight.w600, color: Colors.white, height: 1.23),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          // The line named bars too. There is no bar category
                          // in the directory, so the page has none to show.
                          _t('Discover the restaurants, cafes and bakeries of Modiin',
                              'גלו את המסעדות, בתי הקפה והמאפיות של מודיעין'),
                          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 43),
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
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    context.push(Uri(path: '/search', queryParameters: {'q': query}).toString());
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16)],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_t('What are you looking for?', 'מה אתם מחפשים?'),
                      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: const Color(0xFF3D3D3D))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: _t('Restaurants, cuisines, dish or name...', 'מסעדות, מטבחים, מנה או שם...'),
                      hintStyle: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: kRGreyText),
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
                      const Icon(IconsaxPlusLinear.search_normal_1, size: 18, color: Colors.white),
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
      child: _Section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('Explore Categories', 'גלו קטגוריות'),
                style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
            const SizedBox(height: 10),
            Text(_t('Discover restaurants by the food you love.', 'גלו מסעדות לפי האוכל שאתם אוהבים.'),
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: kRGreyText)),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 18.0;
                final cols = constraints.maxWidth > 1400 ? 7 : (constraints.maxWidth > 1000 ? 5 : 3);
                final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
                final pages = (categories.length / cols).ceil();
                final start = (_categoryPage * cols) % categories.length;
                final visible = List.generate(cols, (i) => categories[(start + i) % categories.length]);

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
                              // The card was drawn with a pointer cursor and no
                              // handler at all. This opens the listing for the
                              // category it names.
                              onTap: () => context.push(
                                Uri(
                                  path: '/businesses/category/${visible[i].id}',
                                  queryParameters: {'title': visible[i].name},
                                ).toString(),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Only worth drawing when there is more than one page.
                    if (pages > 1) ...[
                      Positioned(
                        left: -19, top: 90,
                        child: _CarouselArrow(
                          icon: IconsaxPlusLinear.arrow_left_2,
                          onTap: () => setState(() => _categoryPage = (_categoryPage - 1 + pages) % pages),
                        ),
                      ),
                      Positioned(
                        right: -19, top: 90,
                        child: _CarouselArrow(
                          icon: IconsaxPlusLinear.arrow_right_3,
                          onTap: () => setState(() => _categoryPage = (_categoryPage + 1) % pages),
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
  // PLACES SECTION — header + card row
  // ─────────────────────────────────────────────
  Widget _buildPlacesSection({
    required IconData icon,
    required Color accent,
    required String title,
    required String subtitle,
    required List<_Entry> places,
    bool compact = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: _Section(
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.4),
                  ),
                  child: Center(child: Icon(icon, size: 26, color: accent)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
                      const SizedBox(height: 10),
                      Text(subtitle, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: kRGreyText)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Every section's button read "View all …" and did nothing.
                // The search page beside the map is where all of the places
                // are, cuisine by cuisine.
                _ViewAllButton(
                  label: _t('Search all places', 'חיפוש כל המקומות'),
                  onTap: () => context.push('/restaurants-map'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 24.0;
                final maxCols = compact ? 5 : 4;
                final cols = constraints.maxWidth > 1400
                    ? maxCols
                    : (constraints.maxWidth > 1000 ? 3 : 2);
                final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: places
                      .map((entry) => SizedBox(
                            width: cardWidth,
                            child: RestaurantCard(
                              place: entry.place,
                              compact: compact,
                              isHebrew: _isHebrew,
                              // Each card used to push `/restaurant/1`, which
                              // matches no row. Restaurants are businesses, and
                              // this opens the one the card names.
                              onTap: () => context.push('/business/${entry.id}'),
                            ),
                          ))
                      .toList(),
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
  /// The `categories` row id, so a card can open that category's listing.
  final String id;
  final String name;
  final int count;
  final Color imageBg;
  const _Category({required this.id, required this.name, required this.count, required this.imageBg});
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

class _ViewAllButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ViewAllButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
              Text(label, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CarouselArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 1))],
          ),
          child: Center(child: Icon(icon, size: 20, color: AppColors.midBlue)),
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
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [c.imageBg, Color.lerp(c.imageBg, Colors.black, 0.18)!],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.navy),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Text('${c.count} ${_placesLabel(context)}',
                        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: kRGreyText),
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

  String _placesLabel(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl ? 'מקומות' : 'places';
}
