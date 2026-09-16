import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/restaurant_place_card.dart';

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
  List<_NavItem> get _navItems => [
    _NavItem(label: _t('Professionals', 'בעלי מקצוע'), route: '/businesses', hasDropdown: true),
    _NavItem(label: _t('Modiin News', 'חדשות מודיעין'), route: '/news', hasDropdown: true),
    _NavItem(label: _t('Events', 'אירועים'), route: '/events'),
    _NavItem(label: _t('Deals', 'מבצעים'), route: '/deals'),
    _NavItem(label: _t('Real Estate in Modiin', 'נדל"ן במודיעין'), route: '/realestate'),
    _NavItem(label: _t('Restaurants in Modiin', 'מסעדות במודיעין'), route: '/restaurants', isActive: true),
    _NavItem(label: _t('Businesses in Modiin', 'עסקים במודיעין'), route: '/businesses', hasDropdown: true),
  ];

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
            _buildStickyNavbar(),
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
  // STICKY NAVBAR
  // ─────────────────────────────────────────────
  Widget _buildStickyNavbar() {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: kRBorder)),
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
                margin: const EdgeInsets.only(right: 12),
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
                            style: GoogleFonts.inter(fontSize: 14, color: kRBorder)),
                        Row(
                          children: [
                            Text(_t('Terms of Use', 'תנאי שימוש'), style: GoogleFonts.inter(fontSize: 14, color: kRBorder)),
                            const SizedBox(width: 4),
                            const Text('|', style: TextStyle(color: kRBorder)),
                            const SizedBox(width: 4),
                            Text(_t('Privacy Policy', 'מדיניות פרטיות'), style: GoogleFonts.inter(fontSize: 14, color: kRBorder)),
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
      padding: const EdgeInsets.only(right: 9),
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
