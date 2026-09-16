import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/restaurant_place_card.dart';
import '../../../shared/widgets/web_chrome.dart';

// ═══════════════════════════════════════════════════════════
// Web Restaurants — full desktop layout from Figma
// (Restaurants in Modiin — 1920 × 5047)
// ═══════════════════════════════════════════════════════════


class WebRestaurantsContent extends StatefulWidget {
  const WebRestaurantsContent({super.key});

  @override
  State<WebRestaurantsContent> createState() => _WebRestaurantsContentState();
}

class _WebRestaurantsContentState extends State<WebRestaurantsContent> {
  bool _isHebrew = false;
  int _selectedChip = -1;
  int _bannerPage = 0;
  int _categoryPage = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  // ── Nav links ──
  // ── Hero category chips ──
  List<_Chip> get _chips => [
    _Chip(label: _t('Restaurants', 'מסעדות'), icon: IconsaxPlusLinear.reserve),
    _Chip(label: _t('Coffee Shops', 'בתי קפה'), icon: IconsaxPlusLinear.coffee),
    _Chip(label: _t('Bars', 'ברים'), icon: IconsaxPlusLinear.cup),
    _Chip(label: _t('Takeaway', 'טייק אווי'), icon: IconsaxPlusLinear.shopping_bag),
    _Chip(label: _t('Pizza', 'פיצה'), icon: IconsaxPlusLinear.cake),
  ];

  // ── Banner carousel ──
  static const _banners = [
    Color(0xFFD4E4F7),
    Color(0xFFE0D4C8),
    Color(0xFFC8D8E0),
    Color(0xFFD8E8D4),
    Color(0xFFE4D8F0),
    Color(0xFFF0E4D4),
  ];

  // ── Food categories ──
  List<_Category> get _categories => [
    _Category(name: _t('Japanese', 'יפני'), count: 12, imageBg: const Color(0xFFE8D5D0)),
    _Category(name: _t('Sushi', 'סושי'), count: 10, imageBg: const Color(0xFFD5E3E8)),
    _Category(name: _t('Italian', 'איטלקי'), count: 8, imageBg: const Color(0xFFE8E0CE)),
    _Category(name: _t('Asian', 'אסייתי'), count: 9, imageBg: const Color(0xFFD9E8D5)),
    _Category(name: _t('Israeli', 'ישראלי'), count: 14, imageBg: const Color(0xFFE8DCD0)),
    _Category(name: _t('Mediterranean', 'ים תיכוני'), count: 7, imageBg: const Color(0xFFD0DFE8)),
    _Category(name: _t('Burgers', 'המבורגרים'), count: 6, imageBg: const Color(0xFFE8D0D0)),
    _Category(name: _t('Vegan', 'טבעוני'), count: 5, imageBg: const Color(0xFFDCE8D0)),
    _Category(name: _t('Desserts', 'קינוחים'), count: 9, imageBg: const Color(0xFFE8D8E4)),
  ];

  // ── Popular restaurants ──
  List<RestaurantPlace> get _popular => [
    RestaurantPlace(
      name: _t('Shipudey Hatikva', 'שיפודי התקווה'),
      type: _t('Restaurant', 'מסעדה'),
      address: _t("HaMaccabim, Modi'in-Maccabim-Re'ut, Israel", 'המכבים, מודיעין-מכבים-רעות'),
      rating: 4.8, reviews: 254, views: 428,
      isKosher: true, category: _t('Israeli Dining', 'מטבח ישראלי'),
      marker: kRestaurantGreen, imageBg: const Color(0xFFE3CFC4),
    ),
    RestaurantPlace(
      name: _t('Pasta Basta', 'פסטה בסטה'),
      type: _t('Restaurant', 'מסעדה'),
      address: _t('HaOmanut St 2, Modiin', 'האומנות 2, מודיעין'),
      rating: 4.8, reviews: 254, views: 428,
      isKosher: true, category: _t('Israeli Dining', 'מטבח ישראלי'),
      marker: kRestaurantGreen, imageBg: const Color(0xFFDCE0C4),
    ),
    RestaurantPlace(
      name: _t('Sushi Bar Modiin', 'סושי בר מודיעין'),
      type: _t('Restaurant', 'מסעדה'),
      address: _t('HaShvatim St 7, Modiin', 'השבטים 7, מודיעין'),
      rating: 4.8, reviews: 254, views: 428,
      isKosher: true, category: _t('Israeli Dining', 'מטבח ישראלי'),
      marker: kRestaurantGreen, imageBg: const Color(0xFFC9D8E0),
    ),
    RestaurantPlace(
      name: _t('Sea & Spice', 'סי אנד ספייס'),
      type: _t('Restaurant', 'מסעדה'),
      address: _t("21 Sderot Modi'in-Maccabim-Re'ut, Israel", 'שדרות מודיעין 21, מודיעין-מכבים-רעות'),
      rating: 4.5, reviews: 254, views: 428,
      category: _t('Mediterraneant', 'ים תיכוני'),
      marker: kRestaurantGreen, imageBg: const Color(0xFFD5DFD0),
    ),
  ];

  // ── Coffee shops ──
  List<RestaurantPlace> get _coffeeShops => [
    RestaurantPlace(
      name: _t('Fresh Coffee', 'פרש קופי'),
      type: _t('Cafe', 'בית קפה'),
      address: _t('HaNahalım St 8, Modiin', 'הנחלים 8, מודיעין'),
      rating: 4.8, reviews: 128, views: 187,
      isKosher: true, marker: kCafeBlue, imageBg: const Color(0xFFE0D3C4),
    ),
    RestaurantPlace(
      name: _t('3:16 John Caffe', '3:16 ג׳ון קפה'),
      type: _t('Cafe', 'בית קפה'),
      address: _t('HaShvatim St 10, Modiin', 'השבטים 10, מודיעין'),
      rating: 4.8, reviews: 128, views: 187,
      isKosher: true, category: _t('Breakfast in Modiin', 'ארוחת בוקר במודיעין'),
      marker: kCafeBlue, imageBg: const Color(0xFFD9DEE4),
    ),
    RestaurantPlace(
      name: _t('Coffee Station', 'קופי סטיישן'),
      type: _t('Cafe', 'בית קפה'),
      address: _t('HaOmanut St 3, Modiin', 'האומנות 3, מודיעין'),
      rating: 4.8, reviews: 128, views: 187,
      isKosher: true, marker: kCafeBlue, imageBg: const Color(0xFFE4DCCB),
    ),
    RestaurantPlace(
      name: _t('Landwer Café', 'קפה לנדוור'),
      type: _t('Cafe', 'בית קפה'),
      address: _t('Derech Modiin 6, Modiin', 'דרך מודיעין 6, מודיעין'),
      rating: 4.8, reviews: 128, views: 187,
      isKosher: true, category: _t('Breakfast in Modiin', 'ארוחת בוקר במודיעין'),
      marker: kCafeBlue, imageBg: const Color(0xFFCFDCD8),
    ),
  ];

  // ── Bars ──
  List<RestaurantPlace> get _bars => [
    RestaurantPlace(
      name: _t("Jim's Bar", 'הבר של ג׳ים'),
      type: _t('Bar', 'בר'),
      address: _t('HaOmanut St 5, Modiin', 'האומנות 5, מודיעין'),
      rating: 4.5, reviews: 128, views: 187,
      category: _t('Cocktails', 'קוקטיילים'),
      marker: kBarRed, imageBg: const Color(0xFFD8CFD4),
    ),
    RestaurantPlace(
      name: _t('The Duke', 'הדיוק'),
      type: _t('Bar', 'בר'),
      address: _t('Derech Modiin 8, Modiin', 'דרך מודיעין 8, מודיעין'),
      rating: 4.5, reviews: 128, views: 187,
      marker: kBarRed, imageBg: const Color(0xFFD2D6DE),
    ),
    RestaurantPlace(
      name: _t('Wine House', 'בית היין'),
      type: _t('Bar', 'בר'),
      address: _t("14 Yehuda St, Modi'in-Maccabim-Re'ut, Israel", 'יהודה 14, מודיעין-מכבים-רעות'),
      rating: 4.5, reviews: 128, views: 187,
      marker: kBarRed, imageBg: const Color(0xFFDFD3C9),
    ),
    RestaurantPlace(
      name: _t("Perry's Bar", 'הבר של פרי'),
      type: _t('Cocktail Bar', 'בר קוקטיילים'),
      address: _t("14 Yehuda St, Modi'in-Maccabim-Re'ut, Israel", 'יהודה 14, מודיעין-מכבים-רעות'),
      rating: 4.5, reviews: 128, views: 187,
      marker: kBarRed, imageBg: const Color(0xFFCCD4D9),
    ),
  ];

  // ── Most loved ──
  List<RestaurantPlace> get _mostLoved => [
    RestaurantPlace(
      name: _t('Japan Japan Modiin', 'ג׳פן ג׳פן מודיעין'),
      type: _t('Restaurant', 'מסעדה'),
      address: _t('HaNahalım St 8, Modiin', 'הנחלים 8, מודיעין'),
      rating: 4.8, reviews: 128, views: 187,
      marker: kRestaurantGreen, imageBg: const Color(0xFFDCD3C7),
    ),
    RestaurantPlace(
      name: _t('Café Greg Modiin', 'קפה גרג מודיעין'),
      type: _t('Coffee Shop', 'בית קפה'),
      address: _t('HaOmanut St 3, Modiin', 'האומנות 3, מודיעין'),
      rating: 4.8, reviews: 128, views: 187,
      marker: kCafeBlue, imageBg: const Color(0xFFD3DCE0),
    ),
    RestaurantPlace(
      name: _t('The Red Sea Star', 'רד סי סטאר'),
      type: _t('Bar', 'בר'),
      address: _t('Derech Maccabim 6, Modiin', 'דרך המכבים 6, מודיעין'),
      rating: 4.8, reviews: 128, views: 187,
      marker: kBarRed, imageBg: const Color(0xFFD9CFD9),
    ),
    RestaurantPlace(
      name: _t('The Red Sea Star', 'רד סי סטאר'),
      type: _t('Restaurant', 'מסעדה'),
      address: _t('HaNahalım St 8, Modiin', 'הנחלים 8, מודיעין'),
      rating: 4.8, reviews: 128, views: 187,
      marker: kRestaurantGreen, imageBg: const Color(0xFFD5DECE),
    ),
    RestaurantPlace(
      name: _t('Biga Modiin', 'ביגה מודיעין'),
      type: _t('Bar', 'בר'),
      address: _t('Derech Modiin 6, Modiin', 'דרך מודיעין 6, מודיעין'),
      rating: 4.8, reviews: 128, views: 187,
      marker: kBarRed, imageBg: const Color(0xFFE0D8C9),
    ),
  ];

  // ── Lunch nearby (delivery time instead of views) ──
  List<RestaurantPlace> get _lunchNearby => [
    RestaurantPlace(
      name: _t('Orta Abylai Khan', 'אורטה אביליי חאן'),
      type: _t('Restaurant · Asian', 'מסעדה · אסייתי'),
      address: _t('Abylai Khan Ave 54, Modiin', 'שדרות אביליי חאן 54, מודיעין'),
      rating: 4.8, reviews: 128, deliveryTime: _t('30–40 min', '30–40 דק׳'),
      marker: kRestaurantGreen, imageBg: const Color(0xFFDDD2C5),
    ),
    RestaurantPlace(
      name: _t('Japonica Dostyk', 'יאפוניקה דוסטיק'),
      type: _t('Japanese · Sushi', 'יפני · סושי'),
      address: _t('Mayina St 12, Modiin', 'מאיינה 12, מודיעין'),
      rating: 4.8, reviews: 128, deliveryTime: _t('35–45 min', '35–45 דק׳'),
      marker: kRestaurantGreen, imageBg: const Color(0xFFCFD9DE),
    ),
    RestaurantPlace(
      name: _t('Marshal Abylai Khana', 'מרשל אביליי חאנה'),
      type: _t('Restaurant · Fast Food', 'מסעדה · מזון מהיר'),
      address: _t('Abylai Khan Ave 91, Modiin', 'שדרות אביליי חאן 91, מודיעין'),
      rating: 4.8, reviews: 128, deliveryTime: _t('25–35 min', '25–35 דק׳'),
      marker: kRestaurantGreen, imageBg: const Color(0xFFE2D6D0),
    ),
    RestaurantPlace(
      name: _t('Mangal Doner Kaskelen', 'מנגל דונר קסקלן'),
      type: _t('Turkish · Doner', 'טורקי · דונר'),
      address: _t('Dostyk St 8, Modiin', 'דוסטיק 8, מודיעין'),
      rating: 4.8, reviews: 128, deliveryTime: _t('20–30 min', '20–30 דק׳'),
      marker: kRestaurantGreen, imageBg: const Color(0xFFD8DECB),
    ),
    RestaurantPlace(
      name: _t('Orta Abylai Khan', 'אורטה אביליי חאן'),
      type: _t('Restaurant', 'מסעדה'),
      address: _t('Abylai Khan Ave 54, Modiin', 'שדרות אביליי חאן 54, מודיעין'),
      rating: 4.8, reviews: 128, deliveryTime: _t('30–40 min', '30–40 דק׳'),
      marker: kRestaurantGreen, imageBg: const Color(0xFFD2DCD9),
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
              activeId: 'restaurants',
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeroSection(),
                    _buildBannerCarousel(),
                    _buildCategoriesSection(),
                    _buildPlacesSection(
                      icon: IconsaxPlusLinear.reserve,
                      accent: kRestaurantGreen,
                      title: _t('Popular Restaurants in Modiin', 'מסעדות פופולריות במודיעין'),
                      subtitle: _t('Top rated restaurants loved by locals.',
                          'המסעדות המדורגות ביותר שהתושבים אוהבים.'),
                      buttonLabel: _t('View all restaurants', 'כל המסעדות'),
                      places: _popular,
                    ),
                    _buildPlacesSection(
                      icon: IconsaxPlusLinear.coffee,
                      accent: kCafeBlue,
                      title: _t('Coffee Shops in Modiin', 'בתי קפה במודיעין'),
                      subtitle: _t('Cozy places for great coffee and good vibes.',
                          'מקומות נעימים לקפה טוב ואווירה טובה.'),
                      buttonLabel: _t('View all coffee shops', 'כל בתי הקפה'),
                      places: _coffeeShops,
                    ),
                    _buildPlacesSection(
                      icon: IconsaxPlusLinear.cup,
                      accent: kBarRed,
                      title: _t('Bars in Modiin', 'ברים במודיעין'),
                      subtitle: _t('Great spots for drinks and nightlife in Modiin.',
                          'מקומות מעולים לשתייה וחיי לילה במודיעין.'),
                      buttonLabel: _t('View all bars', 'כל הברים'),
                      places: _bars,
                    ),
                    _buildPlacesSection(
                      icon: IconsaxPlusLinear.heart,
                      accent: kHeartRed,
                      title: _t('Most Loved in Modiin', 'האהובים ביותר במודיעין'),
                      subtitle: _t('The places locals love most.', 'המקומות שהתושבים הכי אוהבים.'),
                      buttonLabel: _t('View all places', 'כל המקומות'),
                      places: _mostLoved,
                      compact: true,
                    ),
                    _buildPlacesSection(
                      icon: IconsaxPlusLinear.clock,
                      accent: AppColors.turquoise,
                      title: _t('Lunch Nearby', 'ארוחת צהריים בקרבת מקום'),
                      subtitle: _t('Find great places for lunch around Modiin.',
                          'מצאו מקומות מעולים לארוחת צהריים במודיעין.'),
                      buttonLabel: _t('View all places', 'כל המקומות'),
                      places: _lunchNearby,
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
  // STICKY NAVBAR
  // ─────────────────────────────────────────────
  // ─────────────────────────────────────────────
  // HERO
  // ─────────────────────────────────────────────
  Widget _buildHeroSection() {
    return SizedBox(
      width: double.infinity,
      height: 662,
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
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 112),
                        Text(
                          _t('Restaurants in Modiin', 'מסעדות במודיעין'),
                          style: GoogleFonts.nunito(fontSize: 44, fontWeight: FontWeight.w600, color: Colors.white, height: 1.23),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _t('Discover the best restaurants, cafe and bars in Modiin',
                              'גלו את המסעדות, בתי הקפה והברים הטובים ביותר במודיעין'),
                          style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 43),
                        _buildSearchBar(),
                        const SizedBox(height: 31),
                        _buildCategoryChips(),
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
                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF3D3D3D))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(fontSize: 16, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: _t('Restaurants, cuisines, dish or name...', 'מסעדות, מטבחים, מנה או שם...'),
                      hintStyle: GoogleFonts.inter(fontSize: 16, color: kRGreyText),
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
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
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

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(_chips.length, (i) {
        final chip = _chips[i];
        final selected = _selectedChip == i;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() => _selectedChip = selected ? -1 : i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.midBlue : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(chip.icon, size: 14, color: selected ? Colors.white : AppColors.midBlue),
                  const SizedBox(width: 8),
                  Text(chip.label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: selected ? Colors.white : AppColors.midBlue,
                      )),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────
  // BANNER CAROUSEL — 3 wide promo cards
  // ─────────────────────────────────────────────
  Widget _buildBannerCarousel() {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: _Section(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const gap = 20.0;
            final cols = constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 800 ? 2 : 1);
            final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
            final pages = (_banners.length / cols).ceil();
            final start = (_bannerPage * cols) % _banners.length;
            final visible = List.generate(cols, (i) => _banners[(start + i) % _banners.length]);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  children: [
                    for (var i = 0; i < visible.length; i++) ...[
                      if (i > 0) const SizedBox(width: gap),
                      Container(
                        width: cardWidth,
                        height: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [visible[i], Color.lerp(visible[i], AppColors.midBlue, 0.35)!],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Positioned(
                  left: -20, top: 130,
                  child: _CarouselArrow(
                    icon: IconsaxPlusLinear.arrow_left_2,
                    onTap: () => setState(() => _bannerPage = (_bannerPage - 1 + pages) % pages),
                  ),
                ),
                Positioned(
                  right: -20, top: 130,
                  child: _CarouselArrow(
                    icon: IconsaxPlusLinear.arrow_right_3,
                    onTap: () => setState(() => _bannerPage = (_bannerPage + 1) % pages),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EXPLORE CATEGORIES — 7 cuisine cards
  // ─────────────────────────────────────────────
  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: _Section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('Expore Categories', 'גלו קטגוריות'),
                style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
            const SizedBox(height: 10),
            Text(_t('Discover restaurants by the food you love.', 'גלו מסעדות לפי האוכל שאתם אוהבים.'),
                style: GoogleFonts.inter(fontSize: 14, color: kRGreyText)),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 18.0;
                final cols = constraints.maxWidth > 1400 ? 7 : (constraints.maxWidth > 1000 ? 5 : 3);
                final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
                final pages = (_categories.length / cols).ceil();
                final start = (_categoryPage * cols) % _categories.length;
                final visible = List.generate(cols, (i) => _categories[(start + i) % _categories.length]);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < visible.length; i++) ...[
                          if (i > 0) const SizedBox(width: gap),
                          SizedBox(width: cardWidth, child: _CategoryCard(category: visible[i])),
                        ],
                      ],
                    ),
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
    required String buttonLabel,
    required List<RestaurantPlace> places,
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
                          style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
                      const SizedBox(height: 10),
                      Text(subtitle, style: GoogleFonts.inter(fontSize: 14, color: kRGreyText)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _ViewAllButton(label: buttonLabel, onTap: () {}),
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
                      .map((p) => SizedBox(
                            width: cardWidth,
                            child: RestaurantCard(
                              place: p,
                              compact: compact,
                              isHebrew: _isHebrew,
                              onTap: () => context.push('/restaurant/1'),
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

  // ─────────────────────────────────────────────
  // FOOTER
  // ─────────────────────────────────────────────
}

// ═══════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════

class _Chip {
  final String label;
  final IconData icon;
  const _Chip({required this.label, required this.icon});
}

class _Category {
  final String name;
  final int count;
  final Color imageBg;
  const _Category({required this.name, required this.count, required this.imageBg});
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
              Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
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
  const _CategoryCard({required this.category});

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
                      style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.navy),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text('${c.count} ${_placesLabel(context)}',
                      style: GoogleFonts.inter(fontSize: 14, color: kRGreyText),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _placesLabel(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl ? 'מקומות' : 'places';
}
