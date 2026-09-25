import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../businesses/models/business.dart';
import '../../businesses/providers/business_providers.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../../map/data/map_pois.dart';
import '../../map/providers/map_providers.dart';
import '../../news/models/article.dart';
import '../../news/providers/news_providers.dart';

// ═══════════════════════════════════════════════════════════
// Web Homepage — full desktop layout from Figma
//
// Every row of content on this page was written into the source: seven
// invented news stories with August 2026 datelines and no link on them, a
// road-works alert for a street nobody had checked, ten map pins at fixed
// pixel offsets, four invented cafés with 4.8 ratings and view counts, and
// six invented tradesmen with telephone buttons that did nothing. All of it
// is read from the database now, or gone.
// ═══════════════════════════════════════════════════════════

class WebHomeContent extends ConsumerStatefulWidget {
  const WebHomeContent({super.key});

  @override
  ConsumerState<WebHomeContent> createState() => _WebHomeContentState();
}

class _WebHomeContentState extends ConsumerState<WebHomeContent> {
  final _searchController = TextEditingController();
  bool _isHebrew = false;

  /// Which map layers the preview draws. The three rows in the map sidebar
  /// were switches drawn permanently on with no handler behind them; they
  /// filter the pins now, the way the map page's own rows do.
  final _activeLayers = <String>{for (final layer in mapLayers) layer.$1};

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

  // ─────────────────────────────────────────────
  // DATES
  // ─────────────────────────────────────────────
  static const _enMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _heMonths = [
    'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
    'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
  ];

  /// "August 5, 2026 | 16:36", or "5 באוגוסט 2026 | 16:36".
  ///
  /// `published_at` comes back as UTC, so it is moved to the reader's zone
  /// before the hour is printed.
  String _dateLine(DateTime value) {
    final d = value.toLocal();
    final time =
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
    return _isHebrew
        ? '${d.day} ב${_heMonths[d.month - 1]} ${d.year} | $time'
        : '${_enMonths[d.month - 1]} ${d.day}, ${d.year} | $time';
  }

  /// The [count] most recently published articles.
  ///
  /// `publishedArticlesProvider` orders by `created_at`, and all 669 rows
  /// were imported in one batch within the same second, so that order says
  /// nothing about when a story ran. Sorted on the publication date here.
  List<Article> _newest(List<Article> all, int count) {
    final sorted = [...all]
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return sorted.take(count).toList();
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
                  _buildBusinessesSection(),
                  _buildProfessionalsSection(),
                  WebFooter(isHebrew: _isHebrew),
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
              onTap: () => context.go(link.$2),
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
                      Text(_isHebrew ? 'עב | EN' : 'EN | עב', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.midBlue)),
                    ],
                  ),
                ),
              ),
            ),
            // CTA — it read "Contact Us" and did nothing. The address is the
            // one the footer has always published.
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => launchUrl(Uri(scheme: 'mailto', path: kContactEmail)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.midBlue,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Text(
                    _t('Contact Us', 'צור קשר'),
                    style: TextStyle(fontFamily: AppFonts.inter,
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
      ),
    );
  }

  /// The nav, in display order.
  ///
  /// Three of these links carried a dropdown chevron and no dropdown. The
  /// chevron is gone; the link itself goes where it always did.
  List<(String, String)> get _navLinksLocalized => [
    (_t('Businesses', 'עסקים'), '/businesses'),
    (_t('Restaurants', 'מסעדות'), '/restaurants'),
    (_t('Real Estate', 'נדל"ן'), '/realestate'),
    (_t('Events', 'אירועים'), '/events'),
    (_t('Deals', 'מבצעים'), '/deals'),
    (_t('News', 'חדשות'), '/news'),
    (_t('Professionals', 'בעלי מקצוע'), '/businesses'),
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
              style: TextStyle(fontFamily: AppFonts.nunito, 
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
              style: TextStyle(fontFamily: AppFonts.inter, 
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
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: const Color(0xFF1F1F1F)),
                  decoration: InputDecoration(
                    hintText: _t('What are you looking for?', 'מה אתה מחפש?'),
                    hintStyle: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: const Color(0xFF4F4F4F)),
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
                      Text(_t('Ask', 'שאל'), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
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
                  Text(label, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: Colors.white)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // A road-works banner used to sit here, under a 🚧, reading "Road work on
  // Begin St. – expect delays in the area", with an underlined "View details"
  // that was a plain Text with no handler. There is no traffic source behind
  // the app, so the alert was an invented fact about the city and is gone.

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
                      Text(cat.$1, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF1F1F1F))),
                      const SizedBox(height: 4),
                      Text(cat.$3, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: const Color(0xFF6D6D6D)), textAlign: TextAlign.center),
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
  /// The seven stories in this section were written into the file: invented
  /// titles, invented excerpts, August 2026 datelines and grey rectangles
  /// where the photograph goes. None of the seven cards carried a tap
  /// handler, so the whole section was a picture of a news page.
  ///
  /// It reads `articles` now, through [publishedArticlesProvider], and each
  /// card opens `/article/<uuid>`.
  Widget _buildNewsSection() {
    final articles = ref.watch(publishedArticlesProvider);
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
                    // It read "Intelligence News" in English — a machine
                    // translation of מודיעין, the city's name.
                    Text(_t('Modiin News', 'חדשות מודיעין'), style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.midBlue)),
                    const SizedBox(height: 10),
                    Text(_t('Get the latest news, stories and important updates happening across the city.', 'קבלו את החדשות, הסיפורים והעדכונים החשובים ברחבי העיר.'),
                        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: const Color(0xFF5F5E5A))),
                  ],
                ),
              ),
              _ViewAllButton(onTap: () => context.go('/news'), label: _t('View all', 'ראה הכל')),
            ],
          ),
          const SizedBox(height: 24),
          articles.when(
            loading: _buildNewsSkeleton,
            error: (_, _) => _buildNotice(
              icon: IconsaxPlusLinear.wifi_square,
              title: _t('News could not be loaded', 'לא ניתן לטעון את החדשות'),
              body: _t('Check your connection and try again.', 'בדקו את החיבור לאינטרנט ונסו שוב.'),
              actionLabel: _t('Try again', 'נסו שוב'),
              onAction: () => ref.invalidate(publishedArticlesProvider),
            ),
            data: (all) {
              if (all.isEmpty) {
                return _buildNotice(
                  icon: IconsaxPlusLinear.note,
                  title: _t('No articles published yet', 'עדיין לא פורסמו כתבות'),
                  body: _t('New stories will appear here as they are published.', 'כתבות חדשות יופיעו כאן עם פרסומן.'),
                );
              }
              final latest = _newest(all, 7);
              final lead = latest.take(3).toList();
              final rest = latest.skip(3).toList();
              return LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 1100) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildNewsLeftColumn(lead)),
                        if (rest.isNotEmpty) ...[
                          const SizedBox(width: 26),
                          Expanded(child: _buildNewsRightColumn(rest)),
                        ],
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _buildNewsLeftColumn(lead),
                      if (rest.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildNewsRightColumn(rest),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNewsLeftColumn(List<Article> articles) {
    return Column(
      children: articles.map((article) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _HoverTap(
            onTap: () => context.push('/article/${article.id}'),
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
                        _articleText(article.title,
                            style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF1F1F1F), height: 1.22)),
                        if ((article.excerpt ?? '').isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _articleText(article.excerpt!,
                              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: const Color(0xFF5F5E5A), height: 1.4)),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(IconsaxPlusLinear.calendar_1, size: 16, color: Color(0xFF6D6D6D)),
                            const SizedBox(width: 9),
                            Text(_dateLine(article.publishedAt), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: const Color(0xFF6D6D6D))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 21),
                  NetworkPhoto(
                    url: article.imageUrl,
                    width: 200,
                    height: 140,
                    radius: BorderRadius.circular(12),
                    gradient: const [Color(0xFFE0E8F0), Color(0xFFC8D4E0)],
                    icon: IconsaxPlusLinear.image,
                    iconSize: 32,
                    iconColor: const Color(0xFF9AA0A6),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNewsRightColumn(List<Article> articles) {
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
          return _HoverTap(
            onTap: () => context.push('/article/${article.id}'),
            child: Container(
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
                        _articleText(article.title,
                            style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1F1F1F), height: 1.3)),
                        if ((article.excerpt ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _articleText(article.excerpt!, maxLines: 1,
                              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: const Color(0xFF5F5E5A), height: 1.4)),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(IconsaxPlusLinear.calendar_1, size: 14, color: Color(0xFF6D6D6D)),
                            const SizedBox(width: 8),
                            Text(_dateLine(article.publishedAt), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: const Color(0xFF6D6D6D))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 21),
                  NetworkPhoto(
                    url: article.imageUrl,
                    width: 160,
                    height: 105,
                    radius: BorderRadius.circular(12),
                    gradient: const [Color(0xFFE0E8F0), Color(0xFFC8D4E0)],
                    icon: IconsaxPlusLinear.image,
                    iconSize: 24,
                    iconColor: const Color(0xFF9AA0A6),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Every article is published in Hebrew, whichever way the page toggle is
  /// set, so its text lays out RTL even while the chrome is in English.
  Widget _articleText(String value, {required TextStyle style, int maxLines = 2}) {
    return Text(
      value,
      style: style,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Placeholders at the geometry of the rows above, so the section does not
  /// jump when the articles land.
  Widget _buildNewsSkeleton() {
    Widget row({required double imageWidth, required double imageHeight}) {
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE7E7E7)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Skeleton(
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: 240, fontSize: 22),
                    SizedBox(height: 14),
                    SkeletonLine(width: 180),
                    SizedBox(height: 14),
                    SkeletonLine(width: 120),
                  ],
                ),
              ),
              const SizedBox(width: 21),
              SkeletonBox(width: imageWidth, height: imageHeight, radius: 12),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final left = Column(
          children: [for (var i = 0; i < 3; i++) row(imageWidth: 200, imageHeight: 140)],
        );
        final right = Column(
          children: [for (var i = 0; i < 4; i++) row(imageWidth: 160, imageHeight: 105)],
        );
        if (constraints.maxWidth > 1100) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 26),
              Expanded(child: right),
            ],
          );
        }
        return Column(children: [left, const SizedBox(height: 24), right]);
      },
    );
  }

  /// The box a section shows in place of its content when the table is empty
  /// or the request failed.
  Widget _buildNotice({
    required IconData icon,
    required String title,
    required String body,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: const Color(0xFF5F5E5A).withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center,
              style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.navy)),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center,
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: const Color(0xFF5F5E5A))),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onAction,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.midBlue,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Text(actionLabel,
                      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                ),
              ),
            ),
          ],
        ],
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
              // Stretch, so the map below the sidebar has a width to fill.
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
        Text(_t('Explore Modiin', 'גלו את מודיעין'), style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.midBlue)),
        const SizedBox(height: 10),
        Text(_t('Discover businesses, events and places around the city.', 'גלו עסקים, אירועים ומקומות ברחבי העיר.'),
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: const Color(0xFF5F5E5A))),
        const SizedBox(height: 32),
        for (final layer in mapLayers)
          _MapToggle(
            label: _layerLabel(layer.$1),
            icon: layer.$2,
            color: layer.$3,
            isOn: _activeLayers.contains(layer.$1),
            isLast: layer == mapLayers.last,
            onTap: () => setState(() {
              if (!_activeLayers.remove(layer.$1)) _activeLayers.add(layer.$1);
            }),
          ),
        const SizedBox(height: 32),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
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
                  Text(_t('Open Map', 'פתח מפה'), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                  const SizedBox(width: 8),
                  Icon(_isHebrew ? Icons.arrow_back : Icons.arrow_forward, size: 18, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The layer names in [mapLayers] are the ones the map page uses in code;
  /// these are how they read on screen.
  String _layerLabel(String layer) => switch (layer) {
    'Businesses' => _t('Businesses', 'עסקים'),
    'Events' => _t('Events', 'אירועים'),
    _ => _t('Real Estate', 'נדל"ן'),
  };

  /// The map, at the pins the map page shows.
  ///
  /// This was a green gradient with ten white dots at hardcoded pixel offsets
  /// and the words "Interactive Map" in the middle of it — no tiles, no
  /// places, nothing to click. It reads [mapPoisProvider] now, the same source
  /// the map page uses, so a pin is a business or an event that exists and
  /// opens its own page.
  Widget _buildMapPreview() {
    final pois = ref.watch(mapPoisProvider);
    return SizedBox(
      height: 400,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: pois.when(
          loading: () => const Skeleton(child: SkeletonBox(height: 400, radius: 16)),
          error: (_, _) => _buildNotice(
            icon: IconsaxPlusLinear.wifi_square,
            title: _t('The map could not be loaded', 'לא ניתן לטעון את המפה'),
            body: _t('Check your connection and try again.', 'בדקו את החיבור לאינטרנט ונסו שוב.'),
            actionLabel: _t('Try again', 'נסו שוב'),
            onAction: () => ref.invalidate(mapPoisProvider),
          ),
          data: (all) {
            final visible = all.where((p) => _activeLayers.contains(p.layer)).toList();
            return FlutterMap(
              options: MapOptions(
                initialCenter: modiinCenter,
                initialZoom: 13,
                backgroundColor: const Color(0xFFF9F5ED),
                // A preview, not the map itself: the page keeps scrolling
                // under the pointer, and a tap opens the full map.
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                onTap: (_, _) => context.go('/map'),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.modiin4u.app',
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    for (final poi in visible)
                      Marker(
                        point: poi.position,
                        width: 32,
                        height: 32,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => context.push(poi.route ?? '/map'),
                            child: Tooltip(
                              message: poi.name,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))],
                                ),
                                child: Center(
                                  child: Container(width: 16, height: 16, decoration: BoxDecoration(color: poi.color, shape: BoxShape.circle)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUSINESSES — cards from the directory
  // ─────────────────────────────────────────────
  /// This section was headed "AI Picks · Recommended for You" over four
  /// invented cafés: Premium Noga Café, 4.8 from 128 reviews with 187 views;
  /// Olive & Fire, 4.8 from 254 with 428 views; Anaba Lounge and Sea & Spice
  /// besides. Each card opened `/business/demo`, an id that matches no row,
  /// and each carried a coloured dot saying it was open or closed.
  ///
  /// Nothing here recommends anything — there is no recommender, and not one
  /// business in the table is flagged featured or recommended — so the badge
  /// and the heading are gone and the row says what it is: businesses from
  /// the directory, read through [businessesProvider].
  Widget _buildBusinessesSection() {
    final businesses = ref.watch(businessesProvider);
    return _SectionWrapper(
      padding: const EdgeInsets.only(bottom: 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_t('Businesses in Modiin', 'עסקים במודיעין'), style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.midBlue)),
                    const SizedBox(height: 10),
                    Text(_t('Places, services and shops listed across the city.', 'מקומות, שירותים וחנויות מכל רחבי העיר.'),
                        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: const Color(0xFF5F5E5A))),
                  ],
                ),
              ),
              _ViewAllButton(onTap: () => context.go('/businesses'), label: _t('View all', 'ראה הכל')),
            ],
          ),
          const SizedBox(height: 24),
          businesses.when(
            loading: () => _buildBusinessSkeleton(),
            error: (_, _) => _buildNotice(
              icon: IconsaxPlusLinear.wifi_square,
              title: _t('Businesses could not be loaded', 'לא ניתן לטעון את העסקים'),
              body: _t('Check your connection and try again.', 'בדקו את החיבור לאינטרנט ונסו שוב.'),
              actionLabel: _t('Try again', 'נסו שוב'),
              onAction: () => ref.invalidate(businessesProvider),
            ),
            data: (list) {
              if (list.isEmpty) {
                return _buildNotice(
                  icon: IconsaxPlusLinear.shop,
                  title: _t('No businesses listed yet', 'עדיין לא נרשמו עסקים'),
                  body: _t('Businesses will appear here as they are approved.', 'עסקים יופיעו כאן עם אישורם.'),
                );
              }
              final shown = list.take(4).toList();
              return LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1);
                  const gap = 24.0;
                  final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: shown.map((b) => SizedBox(
                      width: cardWidth,
                      child: _BusinessCard(business: b, isHebrew: _isHebrew),
                    )).toList(),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1);
        const gap = 24.0;
        final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
        return Skeleton(
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: List.generate(cols, (_) {
              return SizedBox(
                width: cardWidth,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 200, radius: 12),
                    SizedBox(height: 20),
                    SkeletonLine(width: 180, fontSize: 20),
                    SizedBox(height: 10),
                    SkeletonLine(width: 120),
                    SizedBox(height: 18),
                    SkeletonLine(width: 200),
                    SizedBox(height: 18),
                    SkeletonLine(width: 100),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // PROFESSIONALS
  // ─────────────────────────────────────────────
  /// Six people were written into this section — Eldad Nona the refrigerator
  /// technician, Omer Levi the electrician, Avi Cohen, Yossi Azulay, Daniel
  /// Mizrahi and Noam Ben-David — with emoji for faces and "Call Now" buttons
  /// that were plain Containers with no number behind them. Above them sat
  /// six filter pills naming trades that are not categories in the database,
  /// with the first drawn permanently selected and none of them tappable.
  ///
  /// There is no `professionals` table, and no source for one. What the nav
  /// means by a professional is a business filed under Services, so the row
  /// shows those, with the business's own telephone number on the button.
  /// The section hides itself, heading and all, when that category is empty.
  Widget _buildProfessionalsSection() {
    final categories = ref.watch(businessCategoriesProvider);
    if (categories.isLoading) {
      return _buildProfessionalsFrame(child: _buildProfessionalsSkeleton());
    }
    final services =
        (categories.valueOrNull ?? const []).where((c) => c.slug == 'services').toList();
    if (services.isEmpty) return const SizedBox.shrink();

    final businesses = ref.watch(businessesByCategoryProvider(services.first.id));
    return businesses.when(
      loading: () => _buildProfessionalsFrame(child: _buildProfessionalsSkeleton()),
      error: (_, _) => _buildProfessionalsFrame(
        child: _buildNotice(
          icon: IconsaxPlusLinear.wifi_square,
          title: _t('This list could not be loaded', 'לא ניתן לטעון את הרשימה'),
          body: _t('Check your connection and try again.', 'בדקו את החיבור לאינטרנט ונסו שוב.'),
          actionLabel: _t('Try again', 'נסו שוב'),
          onAction: () => ref.invalidate(businessesByCategoryProvider(services.first.id)),
        ),
      ),
      data: (list) {
        // Nothing to show means no heading either, rather than a title over
        // an empty strip.
        if (list.isEmpty) return const SizedBox.shrink();
        final shown = list.take(6).toList();
        return _buildProfessionalsFrame(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 1200 ? 6 : (constraints.maxWidth > 800 ? 3 : 2);
              const gap = 16.0;
              final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: shown.map((b) => SizedBox(
                  width: cardWidth,
                  child: _ProfessionalCard(business: b, isHebrew: _isHebrew),
                )).toList(),
              );
            },
          ),
        );
      },
    );
  }

  /// The heading and copy the professionals row sits under.
  Widget _buildProfessionalsFrame({required Widget child}) {
    return _SectionWrapper(
      padding: const EdgeInsets.only(bottom: 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('Find a Professional in Modiin', 'מצאו בעל מקצוע במודיעין'), style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.midBlue)),
          const SizedBox(height: 10),
          Text(_t('Connect with local professionals for your home, business and everyday needs.', 'התחברו עם בעלי מקצוע מקומיים לבית, לעסק ולצרכים היומיומיים.'),
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: const Color(0xFF5F5E5A))),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildProfessionalsSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 1200 ? 6 : (constraints.maxWidth > 800 ? 3 : 2);
        const gap = 16.0;
        final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
        return Skeleton(
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: List.generate(cols, (_) {
              return SizedBox(
                width: cardWidth,
                child: const Column(
                  children: [
                    SkeletonCircle(size: 120),
                    SizedBox(height: 18),
                    SkeletonLine(width: 110, fontSize: 20),
                    SizedBox(height: 10),
                    SkeletonLine(width: 80),
                    SizedBox(height: 34),
                    SkeletonBox(height: 34, radius: 60),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // FOOTER
  // ─────────────────────────────────────────────
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
  final VoidCallback onTap;
  const _NavLink({required this.label, required this.onTap});

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
              Text(widget.label, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF0F161E))),
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
            Text(label, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// One layer row beside the map preview.
///
/// The switch was drawn permanently blue and on, and the row had no handler:
/// it looked like a control and was a picture of one. It reports [isOn] and
/// calls [onTap] now.
class _MapToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isOn;
  final bool isLast;
  final VoidCallback onTap;
  const _MapToggle({
    required this.label,
    required this.icon,
    required this.color,
    required this.isOn,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: isOn ? color : const Color(0xFF9AA0A6)),
              const SizedBox(width: 16),
              Expanded(child: Text(label, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF1F1F1F)))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: isOn ? AppColors.midBlue : const Color(0xFFD5D7DB),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Align(
                  alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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

// ── Business card ──
/// One business from the directory.
///
/// It took a `_BizData` of pre-written strings — name, type, address, rating,
/// review count, view count, a badge and a status colour — which is how four
/// invented cafés came to be hardcoded above it. It takes the row now, and
/// only prints what the row carries:
///
/// * the rating, where reviews have earned one. Every business in the table
///   has `review_count` 0, so a gold star beside "0.0 (0)" would have read as
///   a bad score rather than as no score.
/// * no view count at all: `businesses` has no such column, so the "187
///   Views" on every card came from nowhere.
/// * no open/closed dot: the query does not fetch opening hours, so the app
///   cannot know, and the dot said "closed" for every shop in the city.
class _BusinessCard extends StatefulWidget {
  final Business business;
  final bool isHebrew;
  const _BusinessCard({required this.business, this.isHebrew = false});

  @override
  State<_BusinessCard> createState() => _BusinessCardState();
}

class _BusinessCardState extends State<_BusinessCard> {
  bool _hovered = false;

  String _t(String en, String he) => widget.isHebrew ? he : en;

  @override
  Widget build(BuildContext context) {
    final b = widget.business;
    // `businesses` has no category column — categories are linked through
    // `entity_categories` — so the line under the name is the shop's own
    // short description where it has one.
    final subtitle = b.category.isNotEmpty ? b.category : (b.description ?? '');
    final address = b.address.isNotEmpty ? b.address : b.neighborhood;
    final phone = b.phone;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push('/business/${b.id}'),
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
                children: [
                  NetworkPhoto(
                    url: b.imageUrl ?? b.logoUrl,
                    width: double.infinity,
                    height: 200,
                    radius: const BorderRadius.vertical(top: Radius.circular(12)),
                    icon: IconsaxPlusLinear.shop,
                    iconSize: 40,
                  ),
                  // Favourite — the heart was a white circle with nothing
                  // behind the tap.
                  PositionedDirectional(
                    top: 12, start: 12,
                    child: FavoriteButton(
                      kind: FavoriteKind.business,
                      id: b.id,
                      size: 40,
                      iconSize: 20,
                    ),
                  ),
                  // The badge read "Breakfast in Modiin" and the like on every
                  // card. The kosher certification is a real column, so that
                  // is what the badge says where a business carries one.
                  if (b.kosherLabel != null)
                    PositionedDirectional(
                      top: 12, end: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF0033AC), borderRadius: BorderRadius.circular(50)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(IconsaxPlusBold.verify, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(b.kosherLabel!, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
                          ],
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
                    Text(b.name, style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: const Color(0xFF5F5E5A)), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(IconsaxPlusBold.location, size: 16, color: AppColors.turquoise),
                          const SizedBox(width: 8),
                          Expanded(child: Text(address, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: const Color(0xFF5F5E5A)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (b.reviewCount == 0)
                      Text(_t('Not rated yet', 'אין דירוג עדיין'), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: const Color(0xFF6D6D6D)))
                    else
                      Row(
                        children: [
                          const Icon(IconsaxPlusBold.star_1, size: 16, color: Color(0xFFFFC107)),
                          const SizedBox(width: 8),
                          Text(b.rating.toStringAsFixed(1), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1F1F1F))),
                          const SizedBox(width: 4),
                          Text('(${b.reviewCount})', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: const Color(0xFF6D6D6D))),
                        ],
                      ),
                    // The "Contact" button was a Container. It dials the
                    // shop's own number now, and is absent where the row
                    // carries none.
                    if (phone != null && phone.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => launchUrl(Uri(scheme: 'tel', path: phone)),
                          child: Container(
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
                                Text(_t('Contact', 'צור קשר'), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.midBlue)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
/// One business filed under Services.
///
/// It took a `_ProData` of a name, a trade and an emoji, which is how six
/// invented tradesmen came to be hardcoded above it, one of them arbitrarily
/// drawn with a filled button. It takes the row now: the business's own
/// photograph, its own description, and its own number behind Call Now.
class _ProfessionalCard extends StatefulWidget {
  final Business business;
  final bool isHebrew;
  const _ProfessionalCard({required this.business, this.isHebrew = false});

  @override
  State<_ProfessionalCard> createState() => _ProfessionalCardState();
}

class _ProfessionalCardState extends State<_ProfessionalCard> {
  bool _hovered = false;

  String _t(String en, String he) => widget.isHebrew ? he : en;

  @override
  Widget build(BuildContext context) {
    final b = widget.business;
    final trade = b.category.isNotEmpty ? b.category : (b.description ?? '');
    final phone = b.phone;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push('/business/${b.id}'),
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
              // Avatar — an emoji sat here for want of a photograph.
              NetworkPhoto(
                url: b.logoUrl ?? b.imageUrl,
                width: 120,
                height: 120,
                radius: BorderRadius.circular(60),
                gradient: const [Color(0xFFDDE4EC), Color(0xFFC0CCD8)],
                icon: IconsaxPlusLinear.user,
                iconSize: 44,
                iconColor: const Color(0xFF6D6D6D),
              ),
              const SizedBox(height: 16),
              Text(b.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy)),
              if (trade.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(trade, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: const Color(0xFF5F5E5A))),
              ],
              const SizedBox(height: 24),
              // Call Now, or nothing where the business published no number.
              if (phone != null && phone.isNotEmpty)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => launchUrl(Uri(scheme: 'tel', path: phone)),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.midBlue),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(IconsaxPlusLinear.call, size: 16, color: AppColors.midBlue),
                          const SizedBox(width: 8),
                          Text(_t('Call Now', 'התקשר עכשיו'), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.midBlue)),
                        ],
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

/// A card that lifts slightly under the pointer and opens something when
/// clicked. The news rows had the look of a link and no handler.
class _HoverTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HoverTap({required this.child, required this.onTap});

  @override
  State<_HoverTap> createState() => _HoverTapState();
}

class _HoverTapState extends State<_HoverTap> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.008 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: widget.child,
        ),
      ),
    );
  }
}

// The ten `_MapPin`s that used to be listed here — fixed top/left offsets in
// three colours — were the whole of the map preview. The preview draws the
// real map now, so the class has gone with them.
