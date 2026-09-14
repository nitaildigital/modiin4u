import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// Web Homepage — full desktop layout from Figma
// ═══════════════════════════════════════════════════════════

class WebHomeContent extends StatefulWidget {
  const WebHomeContent({super.key});

  @override
  State<WebHomeContent> createState() => _WebHomeContentState();
}

class _WebHomeContentState extends State<WebHomeContent> {
  final _searchController = TextEditingController();
  bool _showTrafficAlert = true;
  bool _isHebrew = false;

  // ── Localization helper ──
  String _t(String en, String he) => _isHebrew ? he : en;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      context.push('/search?q=${Uri.encodeComponent(query)}');
      _searchController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeroSection(),
                  _buildCategoryCards(),
                  _buildNewsSection(),
                  _buildMapSection(),
                  _buildAiPicksSection(),
                  _buildProfessionalsSection(),
                  _buildFooter(),
                ],
              ),
            ),
            // Floating navbar
            Positioned(
              top: 32,
              left: 0,
              right: 0,
              child: _buildNavbar(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // NAVBAR — floating pill
  // ─────────────────────────────────────────────
  Widget _buildNavbar() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1600),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.only(left: 20, right: 16, top: 16, bottom: 16),
        child: Row(
          children: [
            // Logo — actual SVG from design
            GestureDetector(
              onTap: () => context.go('/'),
              child: SvgPicture.asset(
                'assets/images/logo_white.svg',
                width: 90,
                height: 48,
                colorFilter: const ColorFilter.mode(AppColors.midBlue, BlendMode.srcIn),
              ),
            ),
            const Spacer(),
            // Nav links
            ..._navLinksLocalized.map((link) => _NavLink(
              label: link.$1,
              hasDropdown: link.$2,
              onTap: () => context.go(link.$3),
            )),
            const Spacer(),
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
                      Text(_isHebrew ? 'עב | EN' : 'EN | עב', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.midBlue)),
                    ],
                  ),
                ),
              ),
            ),
            // CTA
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.midBlue,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Text(
                  _t('Contact Us', 'צור קשר'),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<(String, bool, String)> get _navLinksLocalized => [
    (_t('Businesses', 'עסקים'), true, '/businesses'),
    (_t('Restaurants', 'מסעדות'), false, '/restaurants'),
    (_t('Real Estate', 'נדל"ן'), false, '/realestate'),
    (_t('Events', 'אירועים'), false, '/events'),
    (_t('Deals', 'מבצעים'), false, '/deals'),
    (_t('News', 'חדשות'), true, '/news'),
    (_t('Professionals', 'בעלי מקצוע'), true, '/businesses'),
  ];

  // ─────────────────────────────────────────────
  // HERO — gradient + title + search + pills
  // ─────────────────────────────────────────────
  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 700),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.0, -0.8),
          end: Alignment(0.1, 1.2),
          colors: [Color(0xFF010A36), Color(0xFF0058B5)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 160), // space for navbar
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _t('Everything Modiin Has to Offer,\nAll in One Place', 'כל מה שמודיעין מציעה,\nבמקום אחד'),
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.22,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _t('Businesses, news, events, real estate and more — all in one smart city platform.', 'עסקים, חדשות, אירועים, נדל"ן ועוד — הכל בפלטפורמה עירונית חכמה אחת.'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Search bar
          _buildSearchBar(),
          const SizedBox(height: 32),
          // Quick filter pills
          _buildHeroPills(),
          const SizedBox(height: 32),
          // Traffic alert
          if (_showTrafficAlert) _buildTrafficAlert(),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Center(
      child: Container(
          constraints: const BoxConstraints(maxWidth: 751),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(IconsaxPlusLinear.search_normal_1, color: Color(0xFF6D6D6D), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _onSearch(),
                  style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF1F1F1F)),
                  decoration: InputDecoration(
                    hintText: _t('What are you looking for?', 'מה אתה מחפש?'),
                    hintStyle: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF4F4F4F)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    fillColor: Colors.transparent,
                    filled: false,
                    isDense: true,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _onSearch,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment(-0.5, -0.5),
                      end: Alignment(0.8, 0.8),
                      colors: [Color(0xFF010928), Color(0xFF00C4DC)],
                    ),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(IconsaxPlusBold.magic_star, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(_t('Ask', 'שאל'), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildHeroPills() {
    final pills = [
      (_t('Businesses', 'עסקים'), IconsaxPlusLinear.shop),
      (_t('News', 'חדשות'), IconsaxPlusLinear.note),
      (_t('Map', 'מפה'), IconsaxPlusLinear.map),
      (_t('Real Estate', 'נדל"ן'), IconsaxPlusLinear.house_2),
      (_t('Professionals', 'בעלי מקצוע'), IconsaxPlusLinear.people),
      (_t('Deals', 'מבצעים'), IconsaxPlusLinear.discount_shape),
    ];
    const routes = ['/businesses', '/news', '/map', '/realestate', '/businesses', '/deals'];

    return Center(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: List.generate(pills.length, (i) {
          final (label, icon) = pills[i];
          return GestureDetector(
            onTap: () => context.go(routes[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTrafficAlert() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 950),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF5E1),
          border: Border.all(color: const Color(0xFFFFD89A)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Text('🚧', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(_t('Traffic update:', 'עדכון תנועה:'), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF1F1F1F))),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _t('Road work on Begin St. – expect delays in the area', 'עבודות כביש ברח׳ בגין – צפויים עיכובים באזור'),
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1F1F1F)),
              ),
            ),
            const SizedBox(width: 6),
            Text(_t('View details', 'צפה בפרטים'), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.midBlue, decoration: TextDecoration.underline)),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() => _showTrafficAlert = false),
              child: const Icon(Icons.close, size: 16, color: Color(0xFF6D6D6D)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CATEGORY CARDS — 7 cards in a row
  // ─────────────────────────────────────────────
  Widget _buildCategoryCards() {
    final categories = [
      (_t('News', 'חדשות'), IconsaxPlusLinear.note, _t('What\'s happening in Modiin', 'מה קורה במודיעין'), '/news'),
      (_t('Events', 'אירועים'), IconsaxPlusLinear.calendar, _t('What\'s on in Modiin', 'מה יש במודיעין'), '/events'),
      (_t('Community', 'קהילה'), IconsaxPlusLinear.people, _t('Groups & Initiatives', 'קבוצות ויוזמות'), '/community'),
      (_t('Professionals', 'בעלי מקצוע'), IconsaxPlusLinear.user, _t('Experts & Services', 'מומחים ושירותים'), '/businesses'),
      (_t('Maps', 'מפות'), IconsaxPlusLinear.map, _t('Explore Modiin', 'גלו את מודיעין'), '/map'),
      (_t('Businesses', 'עסקים'), IconsaxPlusLinear.shop, _t('All Businesses in Modiin', 'כל העסקים במודיעין'), '/businesses'),
      (_t('Real Estate', 'נדל"ן'), IconsaxPlusLinear.house_2, _t('Apartments & Projects', 'דירות ופרויקטים'), '/realestate'),
    ];

    return _SectionWrapper(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols = constraints.maxWidth > 1200 ? 7 : (constraints.maxWidth > 800 ? 4 : 3);
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: categories.map((cat) {
              final cardWidth = (constraints.maxWidth - (cols - 1) * 16) / cols;
              return GestureDetector(
                onTap: () => context.go(cat.$4),
                child: Container(
                  width: cardWidth,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE7E7E7)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(cat.$2, size: 32, color: AppColors.midBlue),
                      const SizedBox(height: 19),
                      Text(cat.$1, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF1F1F1F))),
                      const SizedBox(height: 4),
                      Text(cat.$3, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6D6D6D)), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // NEWS SECTION — two-column layout
  // ─────────────────────────────────────────────
  Widget _buildNewsSection() {
    return _SectionWrapper(
      padding: const EdgeInsets.only(bottom: 56),
      child: Column(
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_t('Intelligence News', 'חדשות מודיעין'), style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.midBlue)),
                    const SizedBox(height: 10),
                    Text(_t('Get the latest news, stories and important updates happening across the city.', 'קבלו את החדשות, הסיפורים והעדכונים החשובים ברחבי העיר.'),
                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5F5E5A))),
                  ],
                ),
              ),
              _ViewAllButton(onTap: () => context.go('/news'), label: _t('View all', 'ראה הכל')),
            ],
          ),
          const SizedBox(height: 24),
          // Two-column grid
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 1100) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildNewsLeftColumn()),
                    const SizedBox(width: 26),
                    Expanded(child: _buildNewsRightColumn()),
                  ],
                );
              }
              return Column(
                children: [
                  _buildNewsLeftColumn(),
                  const SizedBox(height: 24),
                  _buildNewsRightColumn(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNewsLeftColumn() {
    final articles = [
      (_t('Examples of costly mistakes in private construction that a good inspector can prevent',
          'דוגמאות לטעויות יקרות בבנייה פרטית שמפקח טוב יכול למנוע'),
       _t('Yaki Adir, one of the leading construction inspectors in Israel with over 30 years of experience, notes that in private construction projects there are thousands of decisions to be made.',
          'יקי אדיר, אחד ממפקחי הבנייה המובילים בישראל עם למעלה מ-30 שנות ניסיון, מציין שבפרויקטים של בנייה פרטית יש אלפי החלטות לקבל.'),
       _t('August 9, 2026 | 1:31 p.m.', '9 באוגוסט 2026 | 13:31')),
      (_t('Torah wisdom meets community care in this week\'s parsha',
          'חוכמת התורה פוגשת את הדאגה הקהילתית בפרשת השבוע'),
       _t('In this week\'s Torah, there are several verses that command us to care for and be attentive to our surroundings.',
          'בפרשת התורה השבוע, ישנם מספר פסוקים המצווים אותנו לדאוג ולהיות קשובים לסביבה שלנו.'),
       _t('August 7, 2026 | 9:36 am', '7 באוגוסט 2026 | 9:36')),
      (_t('The 2026 Israel Capoeira Championship was held in Modiin',
          'אליפות ישראל בקפוארה 2026 התקיימה במודיעין'),
       _t('Our city became a pilgrimage center for fans of Brazilian rhythm and energy this weekend.',
          'העיר שלנו הפכה למוקד עלייה לרגל לחובבי הקצב והאנרגיה הברזילאית בסוף השבוע.'),
       _t('August 5, 2026 | 4:38 p.m.', '5 באוגוסט 2026 | 16:38')),
    ];

    return Column(
      children: articles.map((article) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE7E7E7)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(article.$1, style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF1F1F1F), height: 1.22),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 14),
                      Text(article.$2, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5F5E5A), height: 1.4),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(IconsaxPlusLinear.calendar_1, size: 16, color: Color(0xFF6D6D6D)),
                          const SizedBox(width: 9),
                          Text(article.$3, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6D6D6D))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 21),
                Container(
                  width: 200,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFE0E8F0), Color(0xFFC8D4E0)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Icon(IconsaxPlusLinear.image, size: 32, color: Color(0xFF9AA0A6))),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNewsRightColumn() {
    final articles = [
      (_t('An end to cycle worries: Modiin is moving to a new efficient recycling model',
          'סוף לדאגות המיחזור: מודיעין עוברת למודל מיחזור יעיל חדש'),
       _t('The Municipality is taking a new step and upgrading the city\'s paper recycling system.',
          'העירייה עושה צעד חדש ומשדרגת את מערכת מיחזור הנייר בעיר.'),
       _t('August 5, 2026', '5 באוגוסט 2026')),
      (_t('Good news: A thorough cleaning of the city center is beginning',
          'בשורה טובה: מתחיל ניקיון יסודי של מרכז העיר'),
       _t('The municipality is launching a large-scale campaign to upgrade the cleanliness.',
          'העירייה משיקה מבצע רחב היקף לשדרוג הניקיון.'),
       _t('August 5, 2026', '5 באוגוסט 2026')),
      (_t('Modiin\'s 30th Anniversary Celebrations Are Underway',
          'חגיגות 30 למודיעין בעיצומן'),
       _t('This is going to be the hottest and most festive week of the summer.',
          'זה הולך להיות השבוע הכי חם וחגיגי של הקיץ.'),
       _t('July 29, 2026', '29 ביולי 2026')),
      (_t('"We don\'t give up on them": A month of chills at Bnei Akiva',
          '"אנחנו לא מוותרים עליהם": חודש של צמרמורת בבני עקיבא'),
       _t('The members of the "Ra\'am" branch in Modi\'in decided not to give in memory of eight fallen graduates.',
          'חברי סניף "רעם" במודיעין החליטו לא לוותר לזכר שמונה בוגרים שנפלו.'),
       _t('July 29, 2026', '29 ביולי 2026')),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List.generate(articles.length, (i) {
          final article = articles[i];
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              border: i < articles.length - 1
                  ? const Border(bottom: BorderSide(color: Color(0xFFE7E7E7)))
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(article.$1, style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1F1F1F), height: 1.3),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Text(article.$2, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5F5E5A), height: 1.4),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(IconsaxPlusLinear.calendar_1, size: 14, color: Color(0xFF6D6D6D)),
                          const SizedBox(width: 8),
                          Text(article.$3, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6D6D6D))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 21),
                Container(
                  width: 160,
                  height: 105,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFE0E8F0), Color(0xFFC8D4E0)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Icon(IconsaxPlusLinear.image, size: 24, color: Color(0xFF9AA0A6))),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MAP SECTION
  // ─────────────────────────────────────────────
  Widget _buildMapSection() {
    return _SectionWrapper(
      padding: const EdgeInsets.only(bottom: 56),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE7E7E7)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 311, child: _buildMapSidebar()),
                  const SizedBox(width: 68),
                  Expanded(child: _buildMapPreview()),
                ],
              );
            }
            return Column(
              children: [
                _buildMapSidebar(),
                const SizedBox(height: 24),
                _buildMapPreview(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMapSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('Explore Modiin', 'גלו את מודיעין'), style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.midBlue)),
        const SizedBox(height: 10),
        Text(_t('Discover businesses, events and places around the city.', 'גלו עסקים, אירועים ומקומות ברחבי העיר.'),
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5F5E5A))),
        const SizedBox(height: 32),
        _MapToggle(label: _t('Businesses', 'עסקים'), icon: IconsaxPlusLinear.shop, color: const Color(0xFF006BF6)),
        _MapToggle(label: _t('Events', 'אירועים'), icon: IconsaxPlusLinear.calendar, color: const Color(0xFF9032E1)),
        _MapToggle(label: _t('Real Estate', 'נדל"ן'), icon: IconsaxPlusLinear.house_2, color: const Color(0xFF31AC4E), isLast: true),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => context.go('/map'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.midBlue,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_t('Open Map', 'פתח מפה'), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                const SizedBox(width: 8),
                Icon(_isHebrew ? Icons.arrow_back : Icons.arrow_forward, size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPreview() {
    return Container(
      constraints: const BoxConstraints(minHeight: 400),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD4E4D8), Color(0xFFA8C4B0), Color(0xFFC8D8C0), Color(0xFFB0C8B8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Map pins
          ..._mapPins.map((pin) => Positioned(
                top: pin.top,
                left: pin.left,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Center(
                    child: Container(width: 16, height: 16, decoration: BoxDecoration(color: pin.color, shape: BoxShape.circle)),
                  ),
                ),
              )),
          // Center label
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_t('Interactive Map', 'מפה אינטראקטיבית'), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.midBlue)),
            ),
          ),
        ],
      ),
    );
  }

  static final _mapPins = [
    _MapPin(top: 60, left: 80, color: const Color(0xFF006BF6)),
    _MapPin(top: 120, left: 200, color: const Color(0xFF006BF6)),
    _MapPin(top: 50, left: 320, color: const Color(0xFF9032E1)),
    _MapPin(top: 160, left: 400, color: const Color(0xFF9032E1)),
    _MapPin(top: 240, left: 120, color: const Color(0xFF9032E1)),
    _MapPin(top: 180, left: 350, color: const Color(0xFF31AC4E)),
    _MapPin(top: 100, left: 480, color: const Color(0xFF31AC4E)),
    _MapPin(top: 280, left: 260, color: const Color(0xFF31AC4E)),
    _MapPin(top: 40, left: 150, color: const Color(0xFF006BF6)),
    _MapPin(top: 300, left: 500, color: const Color(0xFF9032E1)),
  ];

  // ─────────────────────────────────────────────
  // AI PICKS — business cards
  // ─────────────────────────────────────────────
  Widget _buildAiPicksSection() {
    return _SectionWrapper(
      padding: const EdgeInsets.only(bottom: 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.turquoise.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(IconsaxPlusBold.magic_star, size: 20, color: AppColors.midBlue),
                const SizedBox(width: 8),
                Text(_t('AI Picks', 'המלצות AI'), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.midBlue)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_t('Recommended for You', 'מומלץ עבורך'), style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.midBlue)),
                    const SizedBox(height: 10),
                    Text(_t('Discover places, services and activities based on what matters to you.', 'גלו מקומות, שירותים ופעילויות על פי מה שחשוב לכם.'),
                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5F5E5A))),
                  ],
                ),
              ),
              _ViewAllButton(onTap: () => context.go('/businesses'), label: _t('View all', 'ראה הכל')),
            ],
          ),
          const SizedBox(height: 24),
          // Cards grid
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1);
              final gap = 24.0;
              final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: _businessesLocalized.map((b) => SizedBox(
                  width: cardWidth,
                  child: _BusinessCard(data: b, onTap: () => context.push('/business/demo'), isHebrew: _isHebrew),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  List<_BizData> get _businessesLocalized => [
    _BizData(name: _t('Premium Noga Café', 'קפה נוגה פרימיום'), type: _t('Cafe', 'בית קפה'), address: _t('14 Yehuda St, Modi\'in', 'רח׳ יהודה 14, מודיעין'), rating: 4.8, reviews: 128, views: 187,
        badge: _t('Breakfast in Modiin', 'ארוחת בוקר במודיעין'), gradient: [const Color(0xFF8B6914), const Color(0xFFC49B2C)], statusColor: const Color(0xFF006BF6)),
    _BizData(name: _t('Olive & Fire', 'זית ואש'), type: _t('Restaurant', 'מסעדה'), address: _t('HaMaccabim, Modi\'in', 'המכבים, מודיעין'), rating: 4.8, reviews: 254, views: 428,
        badge: _t('Israeli Dining', 'מטבח ישראלי'), gradient: [const Color(0xFF2D6A4F), const Color(0xFF40916C)], statusColor: const Color(0xFF31AC4E)),
    _BizData(name: _t('Anaba Lounge', 'ענבה לאונג׳'), type: _t('Cocktail Bar', 'בר קוקטיילים'), address: _t('14 Yehuda St, Modi\'in', 'רח׳ יהודה 14, מודיעין'), rating: 4.5, reviews: 128, views: 187,
        badge: _t('Mediterranean', 'ים תיכוני'), gradient: [const Color(0xFF6B1D2A), const Color(0xFF9B2335)], statusColor: const Color(0xFFCC0001)),
    _BizData(name: _t('Sea & Spice', 'ים ותבלין'), type: _t('Restaurant', 'מסעדה'), address: _t('21 Sderot, Modi\'in', 'שדרות 21, מודיעין'), rating: 4.5, reviews: 254, views: 428,
        badge: _t('Mediterranean', 'ים תיכוני'), gradient: [const Color(0xFF1A4B6E), const Color(0xFF2980B9)], statusColor: const Color(0xFF31AC4E)),
  ];

  // ─────────────────────────────────────────────
  // PROFESSIONALS
  // ─────────────────────────────────────────────
  Widget _buildProfessionalsSection() {
    return _SectionWrapper(
      padding: const EdgeInsets.only(bottom: 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(_t('Find a Professional in Modiin', 'מצאו בעל מקצוע במודיעין'), style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.midBlue)),
          const SizedBox(height: 10),
          Text(_t('Connect with trusted local professionals for your home, business and everyday needs.', 'התחברו עם בעלי מקצוע מקומיים אמינים לבית, לעסק ולצרכים היומיומיים.'),
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5F5E5A))),
          const SizedBox(height: 24),
          // Filter pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _proFiltersLocalized.asMap().entries.map((e) {
              final isActive = e.key == 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.midBlue : Colors.transparent,
                  border: Border.all(color: isActive ? AppColors.midBlue : const Color(0xFF6D6D6D)),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Text(e.value, style: GoogleFonts.inter(fontSize: 14, color: isActive ? Colors.white : const Color(0xFF6D6D6D))),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // Professional cards
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 1200 ? 6 : (constraints.maxWidth > 800 ? 3 : 2);
              final gap = 16.0;
              final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: _professionalsLocalized.map((p) => SizedBox(
                  width: cardWidth,
                  child: _ProfessionalCard(data: p, isHebrew: _isHebrew),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  List<String> get _proFiltersLocalized => [_t('All', 'הכל'), _t('Refrigerator Technician', 'טכנאי מקררים'), _t('Plumber', 'שרברב'), _t('Electrician', 'חשמלאי'), _t('Cleaning', 'ניקיון'), _t('Handyman', 'הנדימן')];

  List<_ProData> get _professionalsLocalized => [
    _ProData(name: _t('Eldad Nona', 'אלדד נונא'), role: _t('Refrigerator Technician', 'טכנאי מקררים'), emoji: '🧊'),
    _ProData(name: _t('Omer Levi', 'עומר לוי'), role: _t('Electrician', 'חשמלאי'), emoji: '⚡'),
    _ProData(name: _t('Avi Cohen', 'אבי כהן'), role: _t('AC Technician', 'טכנאי מזגנים'), emoji: '❄️'),
    _ProData(name: _t('Yossi Azulay', 'יוסי אזולאי'), role: _t('Handyman', 'הנדימן'), emoji: '🔧', filled: true),
    _ProData(name: _t('Daniel Mizrahi', 'דניאל מזרחי'), role: _t('Handyman', 'הנדימן'), emoji: '🔧'),
    _ProData(name: _t('Noam Ben-David', 'נועם בן-דוד'), role: _t('Cleaning', 'ניקיון'), emoji: '🧹'),
  ];

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
                  // Mobile footer
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFooterContact(),
                      const SizedBox(height: 40),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildFooterLinks(_t('Modiin4u', 'מודיעין4u'), [_t('Home', 'בית'), _t('About Us', 'אודותינו'), _t('Contact Us', 'צור קשר'), _t('Privacy Policy', 'מדיניות פרטיות')])),
                          Expanded(child: _buildFooterLinks(_t('Explore', 'גלו'), [_t('News', 'חדשות'), _t('Events', 'אירועים'), _t('Businesses', 'עסקים'), _t('Real Estate', 'נדל"ן'), _t('Map', 'מפה')])),
                        ],
                      ),
                      const SizedBox(height: 40),
                      _buildFooterAbout(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
              // Bottom bar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white24)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_t('All Rights Reserved to modiin4u.co.il, 2026', 'כל הזכויות שמורות ל-modiin4u.co.il, 2026'),
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFE7E7E7))),
                        Row(
                          children: [
                            Text(_t('Terms of Use', 'תנאי שימוש'), style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFE7E7E7))),
                            const SizedBox(width: 4),
                            const Text('|', style: TextStyle(color: Color(0xFFE7E7E7))),
                            const SizedBox(width: 4),
                            Text(_t('Privacy Policy', 'מדיניות פרטיות'), style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFE7E7E7))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Powered by PersonaAI — links to personaai.me
                    // Always LTR since it's an English brand phrase
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
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ).createShader(bounds),
                                child: Text(
                                  'PersonaAI',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
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
        Text(_t('We are here for\nany questions.', 'אנחנו כאן\nלכל שאלה.'), style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w500, color: Colors.white, height: 1.22)),
        const SizedBox(height: 40),
        _FooterContactItem(icon: IconsaxPlusLinear.call, label: _t('Phone', 'טלפון'), value: '058-4770195'),
        _FooterContactItem(icon: IconsaxPlusLinear.sms, label: _t('Email', 'אימייל'), value: 'modiin4uoffice@gmail.com'),
        _FooterContactItem(icon: IconsaxPlusLinear.message, label: _t('WhatsApp', 'וואטסאפ'), value: '058-4770195'),
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
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white38),
        ),
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
      ],
    );
  }

  Widget _buildFooterAbout() {
    // In RTL, "start" = right side; in LTR, "start" = left side
    // We always want this section on the trailing side of the footer
    final alignment = _isHebrew ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final textAlign = _isHebrew ? TextAlign.start : TextAlign.end;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        // Logo — actual SVG from design
        SvgPicture.asset(
          'assets/images/logo_white.svg',
          width: 164,
          height: 88,
        ),
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
        // App store buttons
        Text(_t('Download Our App', 'הורידו את האפליקציה'), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white), textAlign: textAlign),
        const SizedBox(height: 16),
        // Always LTR for store buttons to prevent RTL reordering
        Directionality(
          textDirection: TextDirection.ltr,
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              _AppStoreButton(store: 'App Store', label: 'Download on the', svgAsset: 'assets/images/apple_logo.svg', isApple: true),
              _AppStoreButton(store: 'Google Play', label: 'GET IT ON', svgAsset: 'assets/images/google_play.svg'),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════

class _SectionWrapper extends StatelessWidget {
  final EdgeInsets padding;
  final Widget child;
  const _SectionWrapper({required this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1600),
        padding: padding.add(const EdgeInsets.symmetric(horizontal: 24)),
        child: child,
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final bool hasDropdown;
  final VoidCallback onTap;
  const _NavLink({required this.label, required this.hasDropdown, required this.onTap});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered ? Colors.black.withValues(alpha: 0.04) : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF0F161E))),
              if (widget.hasDropdown) ...[
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF21272A)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _ViewAllButton({required this.onTap, this.label = 'View all'});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
    );
  }
}

class _MapToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLast;
  const _MapToggle({required this.label, required this.icon, required this.color, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF1F1F1F)))),
          Container(
            width: 44,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.midBlue,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: 2),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Business card ──
class _BizData {
  final String name, type, address, badge;
  final double rating;
  final int reviews, views;
  final List<Color> gradient;
  final Color statusColor;
  const _BizData({
    required this.name, required this.type, required this.address,
    required this.rating, required this.reviews, required this.views,
    required this.badge, required this.gradient, required this.statusColor,
  });
}

class _BusinessCard extends StatefulWidget {
  final _BizData data;
  final VoidCallback onTap;
  final bool isHebrew;
  const _BusinessCard({required this.data, required this.onTap, this.isHebrew = false});

  @override
  State<_BusinessCard> createState() => _BusinessCardState();
}

class _BusinessCardState extends State<_BusinessCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE7E7E7)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 6))]
                : [],
          ),
          transform: _hovered ? Matrix4.translationValues(0, -2, 0) : Matrix4.identity(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: d.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Center(child: Icon(IconsaxPlusLinear.image, size: 40, color: Colors.white.withValues(alpha: 0.4))),
                  ),
                  // Favorite
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      width: 40, height: 40,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Center(child: Icon(IconsaxPlusLinear.heart, size: 20, color: AppColors.midBlue)),
                    ),
                  ),
                  // Badge
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF0033AC), borderRadius: BorderRadius.circular(50)),
                      child: Text(d.badge, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
                    ),
                  ),
                  // Status dot
                  Positioned(
                    bottom: -20, right: 17,
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: d.statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        d.statusColor == const Color(0xFF31AC4E) ? Icons.check : (d.statusColor == const Color(0xFFCC0001) ? Icons.close : IconsaxPlusLinear.shop),
                        size: 18, color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(d.name, style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy)),
                    const SizedBox(height: 4),
                    Text(d.type, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5F5E5A))),
                    const SizedBox(height: 16),
                    // Address
                    Row(
                      children: [
                        const Icon(IconsaxPlusBold.location, size: 16, color: AppColors.turquoise),
                        const SizedBox(width: 8),
                        Expanded(child: Text(d.address, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5F5E5A)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Rating + views
                    Row(
                      children: [
                        const Icon(IconsaxPlusBold.star_1, size: 16, color: Color(0xFFFFC107)),
                        const SizedBox(width: 8),
                        Text('${d.rating}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1F1F1F))),
                        const SizedBox(width: 4),
                        Text('(${d.reviews})', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6D6D6D))),
                        const SizedBox(width: 40),
                        const Icon(IconsaxPlusLinear.eye, size: 16, color: Color(0xFF6D6D6D)),
                        const SizedBox(width: 8),
                        Text('${d.views}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1F1F1F))),
                        const SizedBox(width: 4),
                        Text(widget.isHebrew ? 'צפיות' : 'Views', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6D6D6D))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Contact button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.midBlue),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(IconsaxPlusLinear.call, size: 16, color: AppColors.midBlue),
                          const SizedBox(width: 8),
                          Text(widget.isHebrew ? 'צור קשר' : 'Contact', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.midBlue)),
                        ],
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

// ── Professional card ──
class _ProData {
  final String name, role, emoji;
  final bool filled;
  const _ProData({required this.name, required this.role, required this.emoji, this.filled = false});
}

class _ProfessionalCard extends StatefulWidget {
  final _ProData data;
  final bool isHebrew;
  const _ProfessionalCard({required this.data, this.isHebrew = false});

  @override
  State<_ProfessionalCard> createState() => _ProfessionalCardState();
}

class _ProfessionalCardState extends State<_ProfessionalCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE7E7E7)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _hovered
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [const Color(0xFFDDE4EC), const Color(0xFFC0CCD8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(child: Text(d.emoji, style: const TextStyle(fontSize: 40))),
            ),
            const SizedBox(height: 16),
            Text(d.name, style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(d.role, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5F5E5A)), textAlign: TextAlign.center),
            const SizedBox(height: 34),
            // Call button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: d.filled ? AppColors.midBlue : Colors.transparent,
                border: Border.all(color: AppColors.midBlue),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconsaxPlusLinear.call, size: 16, color: d.filled ? Colors.white : AppColors.midBlue),
                  const SizedBox(width: 8),
                  Text(widget.isHebrew ? 'התקשר עכשיו' : 'Call Now', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: d.filled ? Colors.white : AppColors.midBlue)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Footer helpers ──
class _FooterContactItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _FooterContactItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 34),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38),
            ),
            child: Center(child: Icon(icon, size: 16, color: Colors.white)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9))),
              const SizedBox(height: 4),
              Text(value, style: GoogleFonts.inter(fontSize: 16, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppStoreButton extends StatelessWidget {
  final String store;
  final String label;
  final String svgAsset;
  final bool isApple;
  const _AppStoreButton({required this.store, required this.label, required this.svgAsset, this.isApple = false});

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
          SvgPicture.asset(
            svgAsset,
            width: 24,
            height: 24,
            colorFilter: isApple ? const ColorFilter.mode(Colors.white, BlendMode.srcIn) : null,
          ),
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

// ── Map pin data ──
class _MapPin {
  final double top;
  final double left;
  final Color color;
  const _MapPin({required this.top, required this.left, required this.color});
}
