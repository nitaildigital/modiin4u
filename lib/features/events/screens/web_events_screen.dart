import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// Web Events — full desktop layout from Figma
// (Events — 1920 × 3535)
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF5F5E5A);
const _kHeading = Color(0xFF1C1C1E);
const _kBodyText = Color(0xFF3D3D3D);
const _kIconGrey = Color(0xFF6D6D6D);
const _kPlaceholder = Color(0xFF4F4F4F);

/// Upper bound for the "Load More" pagination stub.
const _kMaxEvents = 32;

class WebEventsContent extends StatefulWidget {
  const WebEventsContent({super.key});

  @override
  State<WebEventsContent> createState() => _WebEventsContentState();
}

class _WebEventsContentState extends State<WebEventsContent> {
  bool _isHebrew = false;
  int _selectedCategory = 0;
  int _visibleCount = 16;
  final _searchController = TextEditingController();
  final Set<int> _saved = {};

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
    _NavItem(label: _t('Events', 'אירועים'), route: '/events', isActive: true),
    _NavItem(label: _t('Deals', 'מבצעים'), route: '/deals'),
    _NavItem(label: _t('Real Estate in Modiin', 'נדל"ן במודיעין'), route: '/realestate'),
    _NavItem(label: _t('Restaurants in Modiin', 'מסעדות במודיעין'), route: '/restaurants'),
    _NavItem(label: _t('Businesses in Modiin', 'עסקים במודיעין'), route: '/businesses', hasDropdown: true),
  ];

  // ── Event categories ──
  List<_Category> get _categories => [
    _Category(name: _t('All Events', 'כל האירועים'), count: 157, imageBg: const Color(0xFFD8C7B8)),
    _Category(name: _t('Municipal &\nCommunity', 'עירוני\nוקהילתי'), count: 32, imageBg: const Color(0xFFC6D6E4)),
    _Category(name: _t('Music', 'מוזיקה'), count: 24, imageBg: const Color(0xFFD9C8DE)),
    _Category(name: _t('Kids & Family', 'ילדים ומשפחה'), count: 45, imageBg: const Color(0xFFDCE2C6)),
    _Category(name: _t('Sports', 'ספורט'), count: 15, imageBg: const Color(0xFFC8DDD8)),
    _Category(name: _t('Free', 'חינם'), count: 41, imageBg: const Color(0xFFE4D6C2)),
  ];

  // ── Events (16 cards — 4 × 4 grid) ──
  List<_Event> get _events {
    final music = _t('Music', 'מוזיקה');
    final community = _t('Municipal & Community', 'עירוני וקהילתי');
    final kids = _t('Kids & Family', 'ילדים ומשפחה');
    final sports = _t('Sports', 'ספורט');
    final aug = _t('AUG', 'אוג׳');
    final sep = _t('SEP', 'ספט׳');
    final free = _t('FREE', 'חינם');

    return [
      _Event(month: aug, day: '21', category: music, title: _t('Summer Music Night', 'לילה מוזיקלי קיצי'),
          time: '8:00 PM', venue: _t('Modiin Amphitheater', 'אמפיתאטרון מודיעין'),
          price: '₪50', interested: 124, imageBg: const Color(0xFFD6C6DE)),
      _Event(month: aug, day: '22', category: community, title: _t('Modiin Community Festival', 'פסטיבל הקהילה של מודיעין'),
          time: '10:00 AM', venue: _t('Modiin City Center', 'מרכז העיר מודיעין'),
          price: free, interested: 86, imageBg: const Color(0xFFC6D6E4)),
      _Event(month: aug, day: '23', category: kids, title: _t('Family Fun Day', 'יום כיף משפחתי'),
          time: '11:00 AM', venue: _t('Anava Park', 'פארק ענבה'),
          price: '₪20', interested: 64, imageBg: const Color(0xFFDCE2C6)),
      _Event(month: aug, day: '25', category: sports, title: _t('Modiin Night Run', 'מרוץ הלילה של מודיעין'),
          time: '7:30 PM', venue: _t('Modiin Sports Center', 'מרכז הספורט מודיעין'),
          price: '₪35', interested: 142, imageBg: const Color(0xFFC8DDD8)),
      _Event(month: aug, day: '27', category: music, title: _t('Live Jazz Evening', 'ערב ג׳אז חי'),
          time: '8:30 PM', venue: _t('Local Cultural Center', 'היכל התרבות המקומי'),
          price: '₪60', interested: 51, imageBg: const Color(0xFFDDD0C2)),
      _Event(month: aug, day: '28', category: community, title: _t('Open Air Movie Night', 'ערב סרט תחת כיפת השמיים'),
          time: '8:30 PM', venue: _t('Modiin Park', 'פארק מודיעין'),
          price: free, interested: 93, imageBg: const Color(0xFFCBD4DE)),
      _Event(month: aug, day: '29', category: kids, title: _t('Kids Cooking Workshop', 'סדנת בישול לילדים'),
          time: '10:30 AM', venue: _t('Community Center', 'המרכז הקהילתי'),
          price: '₪30', interested: 35, imageBg: const Color(0xFFE2D4C4)),
      _Event(month: aug, day: '29', category: sports, title: _t('Community Football Match', 'משחק כדורגל קהילתי'),
          time: '10:30 AM', venue: _t('Community Center', 'המרכז הקהילתי'),
          price: free, interested: 68, imageBg: const Color(0xFFCADEC9)),
      _Event(month: sep, day: '01', category: music, title: _t('Summer Nights Live – Modiin', 'לילות קיץ לייב – מודיעין'),
          time: '10:30 AM', venue: _t('Modiin Amphitheater', 'אמפיתאטרון מודיעין'),
          price: free, interested: 248, imageBg: const Color(0xFFD2C6DE)),
      _Event(month: sep, day: '03', category: community, title: _t('Modiin Street Food Festival', 'פסטיבל אוכל רחוב מודיעין'),
          time: '5:00 PM', venue: _t('City Center, Modiin', 'מרכז העיר, מודיעין'),
          price: free, interested: 326, imageBg: const Color(0xFFE0CDBE)),
      _Event(month: sep, day: '05', category: kids, title: _t('Family Fun Day at Anava Park', 'יום כיף משפחתי בפארק ענבה'),
          time: '10:00 AM', venue: _t('Anava Park', 'פארק ענבה'),
          price: '₪25', interested: 184, imageBg: const Color(0xFFD6E2C6)),
      _Event(month: sep, day: '06', category: sports, title: _t('Modiin Night Run 2026', 'מרוץ הלילה מודיעין 2026'),
          time: '7:30 PM', venue: _t('HaShdera Boulevard', 'שדרות השדרה'),
          price: '₪40', interested: 157, imageBg: const Color(0xFFC6DAD8)),
      _Event(month: aug, day: '22', category: community, title: _t('Modiin Community Festival', 'פסטיבל הקהילה של מודיעין'),
          time: '10:00 AM', venue: _t('Modiin City Center', 'מרכז העיר מודיעין'),
          price: free, interested: 86, imageBg: const Color(0xFFC6D6E4)),
      _Event(month: aug, day: '21', category: music, title: _t('Summer Music Night', 'לילה מוזיקלי קיצי'),
          time: '8:00 PM', venue: _t('Modiin Amphitheater', 'אמפיתאטרון מודיעין'),
          price: '₪50', interested: 124, imageBg: const Color(0xFFD6C6DE)),
      _Event(month: aug, day: '28', category: community, title: _t('Open Air Movie Night', 'ערב סרט תחת כיפת השמיים'),
          time: '8:30 PM', venue: _t('Modiin Park', 'פארק מודיעין'),
          price: free, interested: 93, imageBg: const Color(0xFFCBD4DE)),
      _Event(month: aug, day: '27', category: music, title: _t('Live Jazz Evening', 'ערב ג׳אז חי'),
          time: '8:30 PM', venue: _t('Local Cultural Center', 'היכל התרבות המקומי'),
          price: '₪60', interested: 51, imageBg: const Color(0xFFDDD0C2)),
    ];
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
                    _buildEventsSection(),
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
  // HERO — 1920 × 662
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
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              margin: const EdgeInsets.symmetric(horizontal: 40).copyWith(top: 48),
              height: 550,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3B2B63), Color(0xFF2E4E8C), Color(0xFF123A72)],
                ),
              ),
              child: Stack(
                children: [
                  // Ellipse 530 — soft-light darkening blob
                  Positioned(
                    left: -80,
                    bottom: -120,
                    child: Container(
                      width: 646,
                      height: 567,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.22),
                            Colors.black.withValues(alpha: 0.0),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 104),
                        Text(
                          _t('Events & Nightlife in Modiin', 'אירועים וחיי לילה במודיעין'),
                          style: GoogleFonts.nunito(
                              fontSize: 44, fontWeight: FontWeight.w600, color: Colors.white, height: 1.23),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: 584,
                          child: Text(
                            _t('Discover concerts, community events, nightlife, family activities and more happening around Modiin.',
                                'גלו הופעות, אירועי קהילה, חיי לילה, פעילויות למשפחה ועוד — הכל סביב מודיעין.'),
                            style: GoogleFonts.inter(fontSize: 16, color: Colors.white, height: 1.19),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 23),
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
        constraints: const BoxConstraints(maxWidth: 751),
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16)],
        ),
        child: Row(
          children: [
            const Icon(IconsaxPlusLinear.search_normal_1, size: 24, color: _kIconGrey),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(fontSize: 16, color: Colors.black),
                decoration: InputDecoration(
                  hintText: _t('Search events, concerts, activities...', 'חפשו אירועים, הופעות, פעילויות...'),
                  hintStyle: GoogleFonts.inter(fontSize: 16, color: _kPlaceholder),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  isCollapsed: true,
                ),
                onSubmitted: (_) => _onSearch(),
              ),
            ),
            const SizedBox(width: 16),
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

  // ─────────────────────────────────────────────
  // EVENT CATEGORIES — 6 circular tiles
  // ─────────────────────────────────────────────
  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 59),
      child: Column(
        children: [
          Text(_t('Event Categories', 'קטגוריות אירועים'),
              style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.midBlue),
              textAlign: TextAlign.center),
          const SizedBox(height: 15),
          Text(_t('From music to family fun, find your next experience.',
                  'ממוזיקה ועד כיף משפחתי — מצאו את החוויה הבאה שלכם.'),
              style: GoogleFonts.inter(fontSize: 14, color: _kGreyText),
              textAlign: TextAlign.center),
          const SizedBox(height: 42),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1248),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 30,
                  runSpacing: 30,
                  alignment: WrapAlignment.spaceBetween,
                  children: List.generate(_categories.length, (i) {
                    return SizedBox(
                      width: 160,
                      child: _CategoryTile(
                        category: _categories[i],
                        isSelected: _selectedCategory == i,
                        onTap: () => setState(() => _selectedCategory = i),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EVENTS IN MODIIN — 4 × 4 card grid + fade + Load More
  // ─────────────────────────────────────────────
  Widget _buildEventsSection() {
    final events = _events;
    // The export lists 16 cards; "Load More" keeps appending batches of 8
    // from the same pool until the cap is reached.
    final visible = List.generate(_visibleCount, (i) => events[i % events.length]);
    final hasMore = _visibleCount < _kMaxEvents;

    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: _Section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('Events in Modiin', 'אירועים במודיעין'),
                style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
            const SizedBox(height: 10),
            Text(_t('Find something happening near you.', 'מצאו משהו שקורה לידכם.'),
                style: GoogleFonts.inter(fontSize: 14, color: _kGreyText)),
            const SizedBox(height: 32),
            Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 24.0;
                    final cols = constraints.maxWidth > 1400
                        ? 4
                        : (constraints.maxWidth > 1000 ? 3 : 2);
                    final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: List.generate(visible.length, (i) {
                        return SizedBox(
                          width: cardWidth,
                          child: _EventCard(
                            event: visible[i],
                            isSaved: _saved.contains(i),
                            interestedLabel: _t('interested', 'מתעניינים'),
                            onSave: () => setState(() =>
                                _saved.contains(i) ? _saved.remove(i) : _saved.add(i)),
                            onTap: () => context.push('/event/demo_$i'),
                          ),
                        );
                      }),
                    );
                  },
                ),
                // White fade over the bottom of the grid
                if (hasMore)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -1,
                    height: 389,
                    child: IgnorePointer(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00FFFFFF), Colors.white],
                            stops: [0.0168, 0.7564],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (hasMore)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 78,
                    child: Center(child: _loadMoreButton()),
                  ),
              ],
            ),
            if (!hasMore) ...[
              const SizedBox(height: 40),
              Center(
                child: Text(_t("That's everything happening right now.",
                        'זה כל מה שקורה כרגע.'),
                    style: GoogleFonts.inter(fontSize: 14, color: _kGreyText)),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _loadMoreButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _visibleCount = (_visibleCount + 8).clamp(0, _kMaxEvents)),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.midBlue),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_t('Load More', 'טען עוד'),
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.midBlue)),
            ],
          ),
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

class _Event {
  final String month, day, category, title, time, venue, price;
  final int interested;
  final Color imageBg;
  const _Event({
    required this.month,
    required this.day,
    required this.category,
    required this.title,
    required this.time,
    required this.venue,
    required this.price,
    required this.interested,
    required this.imageBg,
  });

  bool get isFree => !price.contains('₪');
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
// CATEGORY TILE — 116px circle + name + count
// ─────────────────────────────────────────────
class _CategoryTile extends StatefulWidget {
  final _Category category;
  final bool isSelected;
  final VoidCallback onTap;
  const _CategoryTile({required this.category, required this.isSelected, required this.onTap});

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
            const SizedBox(height: 8),
            Text(
              '${c.count}',
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
// EVENT CARD — 382 × 364
// ─────────────────────────────────────────────
class _EventCard extends StatefulWidget {
  final _Event event;
  final bool isSaved;
  final String interestedLabel;
  final VoidCallback onSave, onTap;
  const _EventCard({
    required this.event,
    required this.isSaved,
    required this.interestedLabel,
    required this.onSave,
    required this.onTap,
  });

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 364,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _hovered ? AppColors.midBlue : _kBorder),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image area ──
              SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                        child: _imagePlaceholder(e.imageBg,
                            radius: BorderRadius.zero, glyph: 34),
                      ),
                    ),
                    // Save / bookmark
                    PositionedDirectional(
                      start: 12,
                      top: 12,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: widget.onSave,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Icon(
                              widget.isSaved ? IconsaxPlusBold.archive_1 : IconsaxPlusLinear.archive_1,
                              size: 20,
                              color: AppColors.midBlue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Category pill
                    PositionedDirectional(
                      end: 14,
                      top: 15,
                      child: Container(
                        height: 27,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.turquoise,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(e.category,
                            style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white, height: 1.25)),
                      ),
                    ),
                    // Date badge
                    PositionedDirectional(
                      start: 12,
                      bottom: 12,
                      child: Container(
                        width: 57,
                        height: 57,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(e.month,
                                style: GoogleFonts.inter(
                                    fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.midBlue, height: 1.25)),
                            const SizedBox(height: 4),
                            Text(e.day,
                                style: GoogleFonts.inter(
                                    fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black, height: 1.22)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Body ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title,
                        style: GoogleFonts.nunito(
                            fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.navy, height: 1.25),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),
                      _metaRow(IconsaxPlusBold.clock, e.time),
                      const SizedBox(height: 8),
                      _metaRow(IconsaxPlusBold.location, e.venue),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              e.price,
                              style: GoogleFonts.nunito(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: e.isFree ? AppColors.midBlue : AppColors.navy,
                                height: 1.25,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(IconsaxPlusBold.star_1, size: 18, color: AppColors.turquoise),
                              const SizedBox(width: 4),
                              Text('${e.interested} ${widget.interestedLabel}',
                                  style: GoogleFonts.inter(
                                      fontSize: 14, fontWeight: FontWeight.w500, color: _kBodyText, height: 1.21)),
                            ],
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

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.turquoise),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 14, color: _kGreyText, height: 1.21),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
