import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/web_chrome.dart';

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
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: 'events',
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeroSection(),
                    _buildCategoriesSection(),
                    _buildEventsSection(),
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
                          style: TextStyle(fontFamily: AppFonts.nunito, 
                              fontSize: 44, fontWeight: FontWeight.w600, color: Colors.white, height: 1.23),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: 584,
                          child: Text(
                            _t('Discover concerts, community events, nightlife, family activities and more happening around Modiin.',
                                'גלו הופעות, אירועי קהילה, חיי לילה, פעילויות למשפחה ועוד — הכל סביב מודיעין.'),
                            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: Colors.white, height: 1.19),
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
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: Colors.black),
                decoration: InputDecoration(
                  hintText: _t('Search events, concerts, activities...', 'חפשו אירועים, הופעות, פעילויות...'),
                  hintStyle: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: _kPlaceholder),
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
  // EVENT CATEGORIES — 6 circular tiles
  // ─────────────────────────────────────────────
  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 59),
      child: Column(
        children: [
          Text(_t('Event Categories', 'קטגוריות אירועים'),
              style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.midBlue),
              textAlign: TextAlign.center),
          const SizedBox(height: 15),
          Text(_t('From music to family fun, find your next experience.',
                  'ממוזיקה ועד כיף משפחתי — מצאו את החוויה הבאה שלכם.'),
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kGreyText),
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
                style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.midBlue)),
            const SizedBox(height: 10),
            Text(_t('Find something happening near you.', 'מצאו משהו שקורה לידכם.'),
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kGreyText)),
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
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kGreyText)),
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
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.midBlue)),
            ],
          ),
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
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 18, fontWeight: FontWeight.w600, color: _kHeading, height: 1.22),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${c.count}',
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kGreyText, height: 1.21),
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
                            style: TextStyle(fontFamily: AppFonts.inter, 
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
                                style: TextStyle(fontFamily: AppFonts.inter, 
                                    fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.midBlue, height: 1.25)),
                            const SizedBox(height: 4),
                            Text(e.day,
                                style: TextStyle(fontFamily: AppFonts.inter, 
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
                        style: TextStyle(fontFamily: AppFonts.nunito, 
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
                              style: TextStyle(fontFamily: AppFonts.nunito, 
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
                                  style: TextStyle(fontFamily: AppFonts.inter, 
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
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kGreyText, height: 1.21),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
