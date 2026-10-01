import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/banners_provider.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../businesses/models/business.dart';
import '../../businesses/providers/business_providers.dart';
import '../../map/data/map_pois.dart';
import '../../map/providers/map_providers.dart';
import '../../news/models/article.dart';
import '../../news/providers/news_providers.dart';
import '../../../shared/widgets/web_map_tiles.dart';
import '../../../shared/widgets/web_hero_photo.dart';
import '../providers/home_web_providers.dart';
import '../../../shared/widgets/web_contact_menu.dart';

// ═══════════════════════════════════════════════════════════
// Web Homepage — Figma "Homepage", 1920 wide
//
// Every row of content on this page was once written into the source: seven
// invented news stories with August 2026 datelines and no link on them, a
// road-works alert for a street nobody had checked, ten map pins at fixed
// pixel offsets, four invented cafés with 4.8 ratings and view counts, and
// six invented tradesmen with telephone buttons that did nothing. All of it
// is read from the database now, or gone.
//
// Every section the design draws is here, each fed by a table: the notice
// under the hero is a `home_blocks` alert the control centre publishes (and
// absent when none is running); "AI Picks" are the businesses marked
// recommended or featured; the banner slots — above the news, beside the
// map — draw what the control centre has booked for them. Two things the
// design draws have no source and stay off: the view counts on the cards
// (`businesses` has no such column) and the favourites heart (saving belongs
// to an account, and accounts to the app).
// ═══════════════════════════════════════════════════════════

const _kInk = Color(0xFF0A1230);
const _kGrey = Color(0xFF5F5E5A);
const _kMuted = Color(0xFF6D6D6D);
const _kLine = Color(0xFFE7E7E7);
const _kAsset = 'assets/web/home';

/// The city's TikTok, which the design's "Modiin on TikTok LIVE" strip opens.
const _kTikTokUrl = 'https://www.tiktok.com/@modiin4u';

/// The design's heading face is Avenir Next Rounded Demi, which is licensed
/// and not bundled; Nunito is the rounded face the project carries, at the
/// same weight.
///
/// Both helpers set the spacing and the line height outright. Left unset,
/// a Text takes them from the theme's body style — Material 3's 0.25 of
/// tracking and 1.43 lines — which drew every line on this page wider and
/// taller than the design's, whose text is set solid at the face's own
/// ("normal") leading: 1.21 for Inter, about 1.22 for the Avenir headings.
TextStyle _display(double size, {Color color = _kInk, double? height}) => TextStyle(
  fontFamily: AppFonts.nunito,
  fontSize: size,
  fontWeight: FontWeight.w600,
  color: color,
  height: height ?? 1.22,
  letterSpacing: 0,
);

TextStyle _inter(double size, {FontWeight weight = FontWeight.w400, Color color = Colors.black, double? height}) =>
    TextStyle(
      fontFamily: AppFonts.inter,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height ?? 1.21,
      letterSpacing: 0,
    );

/// A line of the directory's own text — a name, an address — which is Hebrew
/// whatever language the page is in.
///
/// It reads right to left, so a long one is cut at its own end rather than
/// at its first word; it stays lined up with the rest of the card.
class _DataText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  const _DataText(this.text, {required this.style, this.textAlign});

  static final _hebrew = RegExp(r'[֐-׿]');

  @override
  Widget build(BuildContext context) {
    final pageIsRtl = Directionality.of(context) == TextDirection.rtl;
    return Text(
      text,
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textDirection: _hebrew.hasMatch(text) ? TextDirection.rtl : TextDirection.ltr,
      textAlign: textAlign ?? (pageIsRtl ? TextAlign.right : TextAlign.left),
    );
  }
}

class WebHomeContent extends ConsumerStatefulWidget {
  const WebHomeContent({super.key});

  @override
  ConsumerState<WebHomeContent> createState() => _WebHomeContentState();
}

class _WebHomeContentState extends ConsumerState<WebHomeContent> with WebLanguageState<WebHomeContent> {
  final _searchController = TextEditingController();
  bool get _isHebrew => webIsHebrew.value;

  /// Which map layers the preview draws. The three rows in the map sidebar
  /// were switches drawn permanently on with no handler behind them; they
  /// filter the pins now, the way the map page's own rows do.
  final _activeLayers = <String>{for (final layer in mapLayers) layer.$1};

  /// The notice the visitor closed with its ×, by id — so a different notice
  /// published later still shows.
  String? _dismissedNotice;

  /// The trade pill chosen in the professionals row; null is "All".
  String? _trade;

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

  /// "August 5, 2026 | 4:36 p.m." as the design writes it, or
  /// "5 באוגוסט 2026 | 16:36" — Hebrew keeps the 24-hour clock.
  ///
  /// `published_at` comes back as UTC, so it is moved to the reader's zone
  /// before the hour is printed.
  String _dateLine(DateTime value) {
    final d = value.toLocal();
    final minutes = d.minute.toString().padLeft(2, '0');
    if (_isHebrew) {
      return '${d.day} ב${_heMonths[d.month - 1]} ${d.year} | '
          '${d.hour.toString().padLeft(2, '0')}:$minutes';
    }
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '${_enMonths[d.month - 1]} ${d.day}, ${d.year} | '
        '$hour:$minutes ${d.hour < 12 ? 'a.m.' : 'p.m.'}';
  }

  /// The [count] most recently published articles.
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
                  _buildHeroWithNotice(),
                  _buildCategoryCards(),
                  _buildTopBanner(),
                  _buildNewsSection(),
                  const SizedBox(height: 80),
                  _buildMapSection(),
                  const SizedBox(height: 80),
                  _buildBusinessesSection(),
                  const SizedBox(height: 67),
                  _buildJoinBanner(),
                  const SizedBox(height: 80),
                  _buildTikTokSection(),
                  const SizedBox(height: 80),
                  _buildProfessionalsSection(),
                  const SizedBox(height: 128),
                  WebFooter(isHebrew: _isHebrew),
                ],
              ),
            ),
            // The pill floats over the hero, 32 from the top.
            Positioned(
              top: 32,
              left: 0,
              right: 0,
              child: WebNavbar(
                floating: true,
                isHebrew: _isHebrew,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HERO — 700 tall: gradient, the city in line drawing, title, search, pills
  // ─────────────────────────────────────────────
  Widget _buildHeroSection() {
    return SizedBox(
      height: 700,
      width: double.infinity,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            // 182° in the design: all but straight down.
            begin: Alignment(0.03, -1),
            end: Alignment(-0.03, 1),
            colors: [Color(0xFF010A36), Color(0xFF0058B5)],
            stops: [0.091, 1.0],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // The palms, the reeds on the water, the stadium and the torch
            // along the foot of the hero, at half strength. Placed where the
            // 1920 frame places them, across whatever width the window has.
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, c) {
                  double x(double at) => at / 1920 * c.maxWidth;
                  Widget art(String name, double w, double h) => Opacity(
                    opacity: 0.5,
                    child: Image.asset('$_kAsset/hero_$name.png', width: w, height: h, fit: BoxFit.fill),
                  );
                  // The drawing is of the city, not of the text, so it does
                  // not mirror with the language.
                  return Directionality(
                    textDirection: TextDirection.ltr,
                    child: Stack(
                      children: [
                        Positioned(left: x(193), top: 450, child: art('palm', 282, 250)),
                        Positioned(left: x(786), top: 572, child: art('reeds', 348, 121)),
                        Positioned(left: x(1304), top: 562, child: art('stadium', 293, 140)),
                        Positioned(left: x(1534), top: 498, child: art('cloud', 48, 27)),
                        Positioned(left: x(1629), top: 469, child: art('torch', 98, 232)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 190,
              child: Column(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 743),
                    child: Text(
                      _t('Everything Modiin Has to Offer, All in One Place', 'כל מה שמודיעין מציעה, הכל במקום אחד'),
                      textAlign: TextAlign.center,
                      style: _display(48, color: Colors.white, height: 1.22),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _t('Businesses, news, events, real estate and more — all in one smart city platform.',
                          'עסקים, חדשות, אירועים, נדל״ן ועוד — הכל בפלטפורמה עירונית חכמה אחת.'),
                      textAlign: TextAlign.center,
                      style: _inter(16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 38),
                  _buildSearchBar(),
                  const SizedBox(height: 32),
                  _buildHeroPills(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 751,
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsetsDirectional.only(start: 24, end: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(50)),
      child: Row(
        children: [
          SvgPicture.asset('$_kAsset/search.svg', width: 24, height: 24),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _onSearch(),
              style: _inter(16, color: const Color(0xFF1F1F1F)),
              decoration: InputDecoration(
                hintText: _t('What are you looking for?', 'מה אתה מחפש?'),
                hintStyle: _inter(16, color: const Color(0xFF4F4F4F)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                filled: false,
                isDense: true,
                // The theme pads every field 20 in from its edge; here the
                // words start 16 after the glass, as drawn.
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _onSearch,
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    // 155.6° from #010928 at 11% to #00C4DC at 95%.
                    begin: Alignment(-0.45, -1),
                    end: Alignment(0.45, 1),
                    colors: [Color(0xFF010928), Color(0xFF00C4DC)],
                    stops: [0.11, 0.95],
                  ),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Center(child: SvgPicture.asset('$_kAsset/ai.svg', width: 17.45, height: 21)),
                    ),
                    const SizedBox(width: 8),
                    Text(_t('Ask', 'שאל'), style: _inter(16, weight: FontWeight.w600, color: Colors.white, height: 1.5)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPills() {
    final pills = [
      (_t('Businesses', 'עסקים'), 'businesses', '/businesses'),
      (_t('News', 'חדשות'), 'news', '/news'),
      (_t('Map', 'מפה'), 'map', '/map'),
      (_t('Real Estate', 'נדל״ן'), 'realestate', '/realestate'),
      (_t('Professionals', 'בעלי מקצוע'), 'professionals', '/businesses/category/services'),
      (_t('Deals', 'מבצעים'), 'deals', '/deals'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final (label, icon, route) in pills)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go(route),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset('$_kAsset/pill_$icon.svg', width: 14, height: 14),
                    const SizedBox(width: 8),
                    Text(label, style: _inter(12, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // NOTICE — the bar across the foot of the hero
  // ─────────────────────────────────────────────
  /// The hero, and the notice the control centre has running, laid across its
  /// lower edge: 950 wide, its top 23 above the end of the blue.
  ///
  /// This used to be a road-works alert written into the file ("Road work on
  /// Begin St."), with a "View details" that did nothing. It is the published
  /// `alert` row of `home_blocks` now, through [homeNoticeProvider].
  ///
  /// The block is 779 tall whether or not a notice is running, so the cards
  /// under it sit where the design puts them either way. The bar lives inside
  /// the block rather than hanging off the hero, so its lower half (and the ×)
  /// still takes a click.
  Widget _buildHeroWithNotice() {
    final notice = ref.watch(homeNoticeProvider).valueOrNull;
    final show = notice != null && notice.id != _dismissedNotice;
    return SizedBox(
      height: 779,
      child: Stack(
        children: [
          Positioned(left: 0, right: 0, top: 0, child: _buildHeroSection()),
          if (show)
            Positioned(
              left: 24,
              right: 24,
              top: 677,
              child: Center(child: _buildSiteNotice(notice)),
            ),
        ],
      ),
    );
  }

  Widget _buildSiteNotice(HomeNotice notice) {
    final label = notice.label(_isHebrew);
    final message = notice.message(_isHebrew);
    final link = notice.link;
    final text = _inter(12, color: Colors.black);
    final medium = _inter(12, weight: FontWeight.w500, color: Colors.black);

    return Container(
      width: 950,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF5E1),
        border: Border.all(color: const Color(0xFFFFD89A)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SvgPicture.asset('$_kAsset/notice_bell.svg', width: 20, height: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Row(
              children: [
                if (label != null) ...[
                  Text(label.endsWith(':') ? label : '$label:', style: medium),
                  const SizedBox(width: 12),
                ],
                if (message != null)
                  Flexible(
                    child: Text(message, style: text, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                if (link != null) ...[
                  const SizedBox(width: 12),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _openLink(link),
                      child: Text(
                        notice.linkLabel(_isHebrew) ?? _t('View details', 'לפרטים'),
                        style: _inter(12, weight: FontWeight.w500, color: AppColors.midBlue).copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.midBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _dismissedNotice = notice.id),
              child: Tooltip(
                message: _t('Close', 'סגירה'),
                child: SvgPicture.asset('$_kAsset/notice_close.svg', width: 16, height: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A page on this site by its path, anything else in a new tab.
  void _openLink(String link) {
    if (link.startsWith('/')) {
      context.push(link);
    } else {
      launchUrl(Uri.parse(link));
    }
  }

  // ─────────────────────────────────────────────
  // CATEGORY CARDS — eight across the 1600 column
  // ─────────────────────────────────────────────
  Widget _buildCategoryCards() {
    final categories = [
      (_t('News', 'חדשות'), 'news', _t('What’s happening in Modiin', 'מה קורה במודיעין'), '/news'),
      (_t('Events', 'אירועים'), 'events', _t('What’s on in Modiin', 'מה יש במודיעין'), '/events'),
      (_t('Community', 'קהילה'), 'community', _t('Groups & Initiatives', 'קבוצות ויוזמות'), '/community'),
      (_t('Professionals', 'בעלי מקצוע'), 'professionals', _t('Experts & Services', 'מומחים ושירותים'), '/businesses/category/services'),
      (_t('Maps', 'מפות'), 'maps', _t('Explore Modiin', 'גלו את מודיעין'), '/map'),
      (_t('Businesses', 'עסקים'), 'businesses', _t('All Businesses in Modiin', 'כל העסקים במודיעין'), '/businesses'),
      (_t('Real Estate', 'נדל״ן'), 'realestate', _t('Apartments & Projects', 'דירות ופרויקטים'), '/realestate'),
      // Not in the Figma web frame. The desktop site had no way to the
      // Municipal page at all — no card, no navbar or footer link — though
      // the phone's bottom bar has one. The icon is the app's own municipal
      // building, drawn in the same line style as the cards'.
      (_t('Municipal', 'עירייה'), 'municipal', _t('City services & Shabbat', 'שירותי עירייה ושבת'), '/municipal'),
    ];

    Widget card((String, String, String, String) cat) {
      return _HoverTap(
        onTap: () => context.go(cat.$4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _kLine),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SvgPicture.asset('$_kAsset/card_${cat.$2}.svg', width: 32, height: 32),
              const SizedBox(height: 19),
              Text(cat.$1, textAlign: TextAlign.center, style: _inter(16, weight: FontWeight.w500)),
              const SizedBox(height: 8),
              // One line, as drawn: "What’s happening in Modiin" fits the
              // 182 the design gives it in Figma's metrics and runs a few
              // pixels over in the browser's, so it gives way by shrinking.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(cat.$3, textAlign: TextAlign.center, maxLines: 1, style: _inter(14, color: _kMuted)),
              ),
            ],
          ),
        ),
      );
    }

    return _SectionWrapper(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 1200) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < categories.length; i++) ...[
                    if (i > 0) const SizedBox(width: 16),
                    Expanded(child: card(categories[i])),
                  ],
                ],
              ),
            );
          }
          final cols = constraints.maxWidth > 800 ? 4 : 3;
          final width = (constraints.maxWidth - (cols - 1) * 16) / cols;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [for (final c in categories) SizedBox(width: width, child: card(c))],
          );
        },
      ),
    );
  }

  /// The 728 × 90 banner between the cards and the news, when one is booked.
  Widget _buildTopBanner() {
    final banners = ref.watch(activeBannersProvider('HOME_TOP')).valueOrNull ?? const <SiteBanner>[];
    if (banners.isEmpty) return const SizedBox(height: 64);
    return Padding(
      padding: const EdgeInsets.only(top: 56, bottom: 64),
      child: Center(child: _Banner(banner: banners.first, width: 728, height: 90, bordered: true)),
    );
  }

  // ─────────────────────────────────────────────
  // NEWS — three large on the left, four listed on the right
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
      child: Column(
        children: [
          _SectionHeading(
            // The design reads "Intelligence News": a machine translation of
            // מודיעין, which is the city's name and also the word for
            // intelligence.
            title: _t('Modiin News', 'חדשות מודיעין'),
            subtitle: _t('Get the latest news, stories and important updates happening across the city.',
                'קבלו את החדשות, הסיפורים והעדכונים החשובים ברחבי העיר.'),
            action: _ViewAllButton(label: _t('View all', 'הצג הכל'), isHebrew: _isHebrew, onTap: () => context.go('/news')),
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
                        Expanded(flex: 812, child: _buildNewsLeftColumn(lead)),
                        if (rest.isNotEmpty) ...[
                          const SizedBox(width: 26),
                          Expanded(flex: 762, child: _buildNewsRightColumn(rest)),
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

  Widget _dateRow(Article article) {
    return Row(
      children: [
        SvgPicture.asset('$_kAsset/date.svg', width: 16, height: 16),
        const SizedBox(width: 9),
        Text(_dateLine(article.publishedAt), style: _inter(14, color: _kGrey)),
      ],
    );
  }

  Widget _buildNewsLeftColumn(List<Article> articles) {
    return Column(
      children: [
        for (var i = 0; i < articles.length; i++) ...[
          if (i > 0) const SizedBox(height: 20),
          _HoverTap(
            onTap: () => context.push('/article/${articles[i].id}'),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _kLine),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _articleText(articles[i].title, style: _display(22, color: Colors.black, height: 1.24)),
                        if ((articles[i].excerpt ?? '').isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _articleText(articles[i].excerpt!, style: _inter(14, color: _kGrey, height: 1.4)),
                        ],
                        const SizedBox(height: 14),
                        _dateRow(articles[i]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 21),
                  NetworkPhoto(
                    url: articles[i].imageUrl,
                    width: 286,
                    height: 181,
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
        ],
      ],
    );
  }

  Widget _buildNewsRightColumn(List<Article> articles) {
    // 15 below the last rule, not 20: the design draws this list the same
    // 709 tall as the three cards beside it, which its four rows of 172
    // fill to within 15 of the edge.
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (final article in articles)
            _HoverTap(
              onTap: () => context.push('/article/${article.id}'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _kLine))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _articleText(article.title, style: _display(22, color: Colors.black, height: 1.24)),
                          if ((article.excerpt ?? '').isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _articleText(article.excerpt!, maxLines: 1, style: _inter(14, color: _kGrey, height: 1.4)),
                          ],
                          const SizedBox(height: 14),
                          _dateRow(article),
                        ],
                      ),
                    ),
                    const SizedBox(width: 21),
                    NetworkPhoto(
                      url: article.imageUrl,
                      width: 207,
                      height: 131,
                      radius: BorderRadius.circular(12),
                      gradient: const [Color(0xFFE0E8F0), Color(0xFFC8D4E0)],
                      icon: IconsaxPlusLinear.image,
                      iconSize: 24,
                      iconColor: const Color(0xFF9AA0A6),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Every article is published in Hebrew, whichever way the page toggle is
  /// set, so its text lays out RTL even while the chrome is in English.
  Widget _articleText(String value, {required TextStyle style, int maxLines = 2}) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        value,
        style: style,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
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
          border: Border.all(color: _kLine),
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
          children: [for (var i = 0; i < 3; i++) row(imageWidth: 286, imageHeight: 181)],
        );
        final right = Column(
          children: [for (var i = 0; i < 4; i++) row(imageWidth: 207, imageHeight: 131)],
        );
        if (constraints.maxWidth > 1100) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 812, child: left),
              const SizedBox(width: 26),
              Expanded(flex: 762, child: right),
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
        border: Border.all(color: _kLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: _kGrey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: _display(20, color: AppColors.navy)),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center, style: _inter(14, color: _kGrey)),
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
                  child: Text(actionLabel, style: _inter(16, weight: FontWeight.w500, color: Colors.white)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MAP — the preview card, and the banners booked beside it
  // ─────────────────────────────────────────────
  Widget _buildMapSection() {
    final banners = ref.watch(activeBannersProvider('HOME_MAP_SIDE')).valueOrNull ?? const <SiteBanner>[];

    final card = Container(
      height: 518,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 311, child: _buildMapSidebar()),
          const SizedBox(width: 68),
          Expanded(child: _buildMapPreview()),
        ],
      ),
    );

    return _SectionWrapper(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMapSidebar(),
                const SizedBox(height: 24),
                SizedBox(height: 400, child: _buildMapPreview()),
              ],
            );
          }
          if (banners.isEmpty) return card;
          // One wide banner over two squares, as drawn: 460 × 281, then two
          // 220 × 220 side by side.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: card),
              const SizedBox(width: 24),
              SizedBox(
                width: 460,
                child: Column(
                  children: [
                    _Banner(banner: banners[0], width: 460, height: 281),
                    if (banners.length > 1) ...[
                      const SizedBox(height: 17),
                      Row(
                        children: [
                          _Banner(banner: banners[1], width: 220, height: 220),
                          if (banners.length > 2) ...[
                            const SizedBox(width: 20),
                            _Banner(banner: banners[2], width: 220, height: 220),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('Explore Modiin', 'גלו את מודיעין'), style: _display(28, color: AppColors.midBlue)),
        const SizedBox(height: 10),
        Text(_t('Discover businesses, events and places around the city.', 'גלו עסקים, אירועים ומקומות ברחבי העיר.'),
            style: _inter(14, color: _kGrey)),
        const SizedBox(height: 32),
        for (final layer in mapLayers)
          _MapToggle(
            label: _layerLabel(layer.$1),
            icon: switch (layer.$1) {
              'Businesses' => 'businesses',
              'Events' => 'events',
              _ => 'realestate',
            },
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
              decoration: BoxDecoration(color: AppColors.midBlue, borderRadius: BorderRadius.circular(60)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_t('Open Map', 'פתח מפה'), style: _inter(14, weight: FontWeight.w500, color: Colors.white, height: 1.71)),
                  const SizedBox(width: 8),
                  Transform.flip(
                    flipX: _isHebrew,
                    child: SvgPicture.asset('$_kAsset/arrow_open_map.svg', width: 20, height: 20),
                  ),
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
    _ => _t('Real Estate', 'נדל״ן'),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: pois.when(
        loading: () => const Skeleton(child: SkeletonBox(height: 468, radius: 16)),
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
              const WebMapTiles(),
              MarkerLayer(
                markers: [
                  for (final poi in visible)
                    Marker(
                      point: poi.position,
                      width: 40,
                      height: 43.24,
                      // The pin's point, not its middle, sits on the place.
                      alignment: const Alignment(0, -0.77),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => context.push(poi.route ?? '/map'),
                          child: Tooltip(
                            message: poi.name,
                            child: _MapPin(layer: poi.layer),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const WebMapCredit(),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // AI PICKS — two rows of four, a third fading out under "View all"
  // ─────────────────────────────────────────────
  /// "AI Picks · Recommended for You", as the design heads it.
  ///
  /// This section once drew four invented cafés, each opening
  /// `/business/demo`, an id that matches no row. It reads the directory now:
  /// first the businesses the control centre has marked recommended or
  /// featured ([homeRecommendedBusinessesProvider]), then, to fill the rows,
  /// other businesses with a photograph — so the grid is never a row of
  /// placeholders, and never pads itself with invented places.
  Widget _buildBusinessesSection() {
    final businesses = ref.watch(businessesProvider);
    final picks = ref.watch(homeRecommendedBusinessesProvider).valueOrNull ?? const <Business>[];
    final kinds = ref.watch(businessPrimaryCategoryProvider).valueOrNull ?? const {};
    // The client opened the site and saw businesses nowhere near him. When
    // the browser has already given this site a location, the row is the
    // nearest businesses, headed so; until then it is the recommended row,
    // with a button that asks. A browser answers only on a secure page, so
    // on the plain-http address the button is not drawn at all.
    final near = ref.watch(nearbyBusinessesProvider).valueOrNull;
    final byDistance = near?.byDistance ?? false;

    return _SectionWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!byDistance) ...[
            _AiPicksBadge(label: _t('AI Picks', 'בחירות AI')),
            const SizedBox(height: 16),
          ],
          _SectionHeading(
            title: byDistance ? _t('Near You', 'קרוב אליך') : _t('Recommended for You', 'מומלצים בשבילך'),
            subtitle: byDistance
                ? _t('The places closest to where you are right now.', 'המקומות הקרובים ביותר למקום שבו אתם נמצאים.')
                : _t('Discover places, services and activities based on what matters to you.',
                    'גלו מקומות, שירותים ופעילויות לפי מה שחשוב לכם.'),
            action: !byDistance && locationIsAskable
                ? _NearMeButton(
                    label: _t('Show what\'s near me', 'הצג מה קרוב אליי'),
                    onTap: () => askForNearby(ref),
                  )
                : null,
          ),
          const SizedBox(height: 32),
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
              if (list.isEmpty && picks.isEmpty) {
                return _buildNotice(
                  icon: IconsaxPlusLinear.shop,
                  title: _t('No businesses listed yet', 'עדיין לא נרשמו עסקים'),
                  body: _t('Businesses will appear here as they are approved.', 'עסקים יופיעו כאן עם אישורם.'),
                );
              }
              final pickedIds = {for (final b in picks) b.id};
              // Nearest first; among them, those with a photograph ahead of
              // those without, each still in order of distance — or the
              // nearest four can be four blue panels.
              final ordered = byDistance
                  ? [
                      ...near!.businesses.where((b) => (b.imageUrl ?? '').isNotEmpty),
                      ...near.businesses.where((b) => (b.imageUrl ?? '').isEmpty),
                    ]
                  : [
                      ...picks,
                      ...list.where((b) => !pickedIds.contains(b.id) && (b.imageUrl ?? '').isNotEmpty),
                      ...list.where((b) => !pickedIds.contains(b.id) && (b.imageUrl ?? '').isEmpty),
                    ];
              return LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1);
                  const gap = 24.0;
                  final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;

                  Widget rowOf(Iterable<Business> row) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (i, b) in row.indexed) ...[
                        if (i > 0) const SizedBox(width: gap),
                        SizedBox(
                          width: cardWidth,
                          child: _BusinessCard(business: b, kind: kinds[b.id], isHebrew: _isHebrew),
                        ),
                      ],
                    ],
                  );

                  final shown = ordered.take(cols * 2).toList();
                  final faded = ordered.skip(cols * 2).take(cols).toList();
                  return Column(
                    children: [
                      for (var r = 0; r < shown.length; r += cols) ...[
                        if (r > 0) const SizedBox(height: 32),
                        rowOf(shown.skip(r).take(cols)),
                      ],
                      const SizedBox(height: 32),
                      // The next row, cut off under a white fade, with the
                      // way to the rest sitting on it.
                      SizedBox(
                        height: 133,
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            if (faded.isNotEmpty)
                              Positioned(left: 0, right: 0, top: 0, child: IgnorePointer(child: rowOf(faded))),
                            // The fade is drawn 200 tall and cut at 133, as in
                            // the design: white from a little past halfway.
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              height: 200,
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.white.withValues(alpha: 0.8), Colors.white, Colors.white],
                                      stops: const [0.018, 0.53, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 29,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: _OutlineButton(
                                  label: _t('View all', 'הצג הכל'),
                                  isHebrew: _isHebrew,
                                  onTap: () => context.go('/businesses'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  /// The design's banner inviting people into the city's community, leading
  /// to the community page.
  Widget _buildJoinBanner() {
    return Center(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => context.go('/community'),
          // 1024 of picture, with 24 either side kept clear on a narrow
          // window.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1024 + 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AspectRatio(
                aspectRatio: 1024 / 222,
                child: const WebHeroPhoto(asset: '$_kAsset/join_community.webp', placeholder: Color(0xFF4A91B5)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TIKTOK LIVE
  // ─────────────────────────────────────────────
  /// "Modiin on TikTok LIVE": the design's strip of five of the city's
  /// videos, 1600 × 514, opening the city's TikTok. It is the design's own
  /// picture — there is no feed behind it — so it points at the account
  /// rather than at any one video.
  Widget _buildTikTokSection() {
    return _SectionWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            title: _t('Modiin on TikTok LIVE', 'מודיעין בטיקטוק LIVE'),
            subtitle: _t('See what’s happening around the city, straight from the local community.',
                'ראו מה קורה ברחבי העיר, ישירות מהקהילה המקומית.'),
          ),
          const SizedBox(height: 38.5),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => launchUrl(Uri.parse(_kTikTokUrl)),
              child: Semantics(
                link: true,
                label: _t('Modiin on TikTok', 'מודיעין בטיקטוק'),
                child: AspectRatio(
                  aspectRatio: 1600 / 514,
                  // The strip is a picture of the city, not of the text, so
                  // it does not mirror with the language.
                  child: Image.asset(
                    '$_kAsset/tiktok_live.webp',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
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
  // PROFESSIONALS
  // ─────────────────────────────────────────────
  /// Six people were written into this section — Eldad Nona the refrigerator
  /// technician, Omer Levi the electrician and four more — with emoji for
  /// faces and "Call Now" buttons that were plain Containers.
  ///
  /// What the site calls a professional is a business filed under Services,
  /// or under a trade beneath it, so the row shows those, with the business's
  /// own number on the button. The pills beside the heading are those trades
  /// ([professionalTradesProvider]) and filter the row; "All" is everybody.
  /// The section hides itself, heading and all, when there is nobody to show.
  Widget _buildProfessionalsSection() {
    final tradesAsync = ref.watch(professionalTradesProvider);
    final businessesAsync = ref.watch(businessesProvider);
    if (tradesAsync.isLoading || businessesAsync.isLoading) {
      return _buildProfessionalsFrame(trades: const [], child: _buildProfessionalsSkeleton());
    }
    if (tradesAsync.hasError || businessesAsync.hasError) {
      return _buildProfessionalsFrame(
        trades: const [],
        child: _buildNotice(
          icon: IconsaxPlusLinear.wifi_square,
          title: _t('This list could not be loaded', 'לא ניתן לטעון את הרשימה'),
          body: _t('Check your connection and try again.', 'בדקו את החיבור לאינטרנט ונסו שוב.'),
          actionLabel: _t('Try again', 'נסו שוב'),
          onAction: () {
            ref.invalidate(professionalTradesProvider);
            ref.invalidate(businessesProvider);
          },
        ),
      );
    }

    final (:everyone, :trades) = tradesAsync.requireValue;
    final all = businessesAsync.requireValue.where((b) => everyone.contains(b.id)).toList();
    if (all.isEmpty) return const SizedBox.shrink();

    // A pill chosen before the trades were re-read may have gone.
    final chosen = trades.where((t) => t.category.id == _trade).firstOrNull;
    final pool = chosen == null ? all : all.where((b) => chosen.businessIds.contains(b.id)).toList();
    // Faces first: the card is built round the photograph.
    final ordered = [
      ...pool.where((b) => (b.logoUrl ?? b.imageUrl ?? '').isNotEmpty),
      ...pool.where((b) => (b.logoUrl ?? b.imageUrl ?? '').isEmpty),
    ];
    final shown = ordered.take(6).toList();

    String? tradeOf(Business b) =>
        trades.where((t) => t.businessIds.contains(b.id)).firstOrNull?.category.name;

    return _buildProfessionalsFrame(
      trades: trades,
      chosen: chosen?.category.id,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols = constraints.maxWidth > 1200 ? 6 : (constraints.maxWidth > 800 ? 3 : 2);
          const gap = 16.0;
          final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final b in shown)
                SizedBox(
                  width: cardWidth,
                  child: _ProfessionalCard(business: b, trade: tradeOf(b), isHebrew: _isHebrew),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfessionalsFrame({
    required List<ProfessionalTrade> trades,
    String? chosen,
    required Widget child,
  }) {
    final pills = trades.isEmpty
        ? null
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              _TradePill(
                label: _t('All', 'הכל'),
                selected: chosen == null,
                showIcon: true,
                onTap: () => setState(() => _trade = null),
              ),
              for (final t in trades)
                _TradePill(
                  label: t.category.name,
                  selected: chosen == t.category.id,
                  onTap: () => setState(() => _trade = t.category.id),
                ),
            ],
          );
    return _SectionWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionHeading(
                  title: _t('Find a Professional in Modiin', 'מצאו בעל מקצוע במודיעין'),
                  subtitle: _t('Connect with trusted local professionals for your home, business and everyday needs.',
                      'התחברו עם בעלי מקצוע מקומיים לבית, לעסק ולצרכים היומיומיים.'),
                ),
              ),
              // The pills keep to the far end, on the heading's middle line.
              if (pills != null) ...[
                const SizedBox(width: 24),
                Expanded(child: Align(alignment: AlignmentDirectional.centerEnd, child: pills)),
              ],
            ],
          ),
          const SizedBox(height: 33),
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
                    SkeletonBox(height: 40, radius: 60),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════

/// The 1600 content column, with 24 either side on a narrower window.
class _SectionWrapper extends StatelessWidget {
  final Widget child;
  const _SectionWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return WebSection(child: child);
  }
}

/// A section's title in Mid blue, its line of copy under it, and anything
/// that belongs at the far end of the heading.
class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  const _SectionHeading({required this.title, required this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _display(28, color: AppColors.midBlue)),
              const SizedBox(height: 10),
              Text(subtitle, style: _inter(14, color: _kGrey)),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

/// "Show what's near me": an outlined pill with the location mark, beside
/// the recommended row's heading. A tap asks the browser for a location.
class _NearMeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NearMeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.midBlue),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(IconsaxPlusLinear.location, size: 18, color: AppColors.midBlue),
              const SizedBox(width: 8),
              Text(label, style: _inter(14, weight: FontWeight.w500, color: AppColors.midBlue)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "✦ AI Picks" tag above the recommended row: Turquoise at a tenth,
/// 36 high, the sparkle in Mid blue.
class _AiPicksBadge extends StatelessWidget {
  final String label;
  const _AiPicksBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF17A9D0).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Center(child: SvgPicture.asset('$_kAsset/ai_small.svg', width: 14.55, height: 17.5)),
          ),
          const SizedBox(width: 8),
          Text(label, style: _inter(14, weight: FontWeight.w500, color: AppColors.midBlue)),
        ],
      ),
    );
  }
}

/// "View all ›" — filled Mid blue, 36 high.
class _ViewAllButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final bool isHebrew;
  const _ViewAllButton({required this.onTap, required this.label, required this.isHebrew});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: AppColors.midBlue, borderRadius: BorderRadius.circular(60)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: _inter(14, weight: FontWeight.w500, color: Colors.white, height: 1.71)),
              const SizedBox(width: 4),
              Transform.flip(
                flipX: isHebrew,
                child: SvgPicture.asset('$_kAsset/chevron_right_white.svg', width: 16, height: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "View all ›" on white with a Mid blue outline, 46 high.
class _OutlineButton extends StatelessWidget {
  final String label;
  final bool isHebrew;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.isHebrew, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
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
              Text(label, style: _inter(16, weight: FontWeight.w500, color: AppColors.midBlue, height: 1.5)),
              const SizedBox(width: 4),
              Transform.flip(
                flipX: isHebrew,
                child: SvgPicture.asset('$_kAsset/chevron_right_blue20.svg', width: 20, height: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A booked banner, at the size its slot is drawn. A tap follows its link.
///
/// [bordered] draws the hairline the design puts round the 728 × 90 slot,
/// over the picture rather than inside it, so the creative keeps its size.
class _Banner extends StatelessWidget {
  final SiteBanner banner;
  final double width, height;
  final bool bordered;
  const _Banner({required this.banner, required this.width, required this.height, this.bordered = false});

  @override
  Widget build(BuildContext context) {
    final link = banner.destinationUrl;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return MouseRegion(
      cursor: link == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: link == null ? null : () => launchUrl(Uri.parse(link)),
        child: Container(
          width: width,
          height: height,
          foregroundDecoration: bordered ? BoxDecoration(border: Border.all(color: _kLine)) : null,
          child: Image.network(
            sizedPhotoUrl(banner.imageUrl, width, dpr),
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => SizedBox(width: width, height: height),
          ),
        ),
      ),
    );
  }
}

/// The design's map pin: a white drop with the layer's colour and glyph in
/// its head — blue for a business, purple for an event, green for a home.
///
/// The drawing's drop shadow is an SVG filter, which the SVG renderer skips,
/// so it is drawn here from the pin itself: the same shape in black at a
/// quarter, 2.3 lower and softened, as the file specifies.
class _MapPin extends StatelessWidget {
  final String layer;
  const _MapPin({required this.layer});

  @override
  Widget build(BuildContext context) {
    final asset = '$_kAsset/map_pin_${switch (layer) {
      'Businesses' => 'businesses',
      'Events' => 'events',
      _ => 'realestate',
    }}.svg';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 2.29,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 1.14, sigmaY: 1.14),
            child: SvgPicture.asset(
              asset,
              width: 40,
              colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.25), BlendMode.srcIn),
            ),
          ),
        ),
        SvgPicture.asset(asset, width: 40),
      ],
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
  final String icon;
  final bool isOn;
  final bool isLast;
  final VoidCallback onTap;
  const _MapToggle({
    required this.label,
    required this.icon,
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
            border: isLast ? null : const Border(bottom: BorderSide(color: _kLine)),
          ),
          child: Row(
            children: [
              Opacity(
                opacity: isOn ? 1 : 0.4,
                child: SvgPicture.asset('$_kAsset/layer_$icon.svg', width: 24, height: 24),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(label, style: _inter(16, weight: FontWeight.w500))),
              // The design's switch: 44 × 24, a 20 knob two in from the edge.
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: isOn ? AppColors.midBlue : const Color(0xFFD5D7DB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 150),
                  alignment: isOn ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
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
/// One business from the directory, in the design's card: 200 of photograph,
/// the category in a pill at the top, the kosher certificate at the bottom,
/// and a round badge on the edge saying whether it is a café or a restaurant.
///
/// It only prints what the row carries:
///
/// * the rating, where reviews have earned one. Every business in the table
///   has `review_count` 0, so a gold star beside "0.0 (0)" would have read as
///   a bad score rather than as no score.
/// * no view count: `businesses` has no such column, so the "187 Views" on
///   every card in the design has no source.
/// * no heart: saving belongs to an account, and accounts to the app.
/// * the badge only for cafés and restaurants. The design's third colour is
///   for bars, and the database has no bar category.
class _BusinessCard extends StatefulWidget {
  final Business business;
  final ({BusinessCategory category, String rootSlug})? kind;
  final bool isHebrew;
  const _BusinessCard({required this.business, required this.kind, this.isHebrew = false});

  @override
  State<_BusinessCard> createState() => _BusinessCardState();
}

class _BusinessCardState extends State<_BusinessCard> {
  bool _hovered = false;

  String _t(String en, String he) => widget.isHebrew ? he : en;

  @override
  Widget build(BuildContext context) {
    final b = widget.business;
    final kind = widget.kind;
    final categoryName = kind?.category.name ?? '';
    final subtitle = (b.description ?? '').trim().isNotEmpty ? b.description!.trim() : categoryName;
    final address = b.address.isNotEmpty ? b.address : b.neighborhood;
    final phone = b.phone;
    final badge = switch (kind?.rootSlug) {
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
            border: Border.all(color: _kLine),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 200,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: NetworkPhoto(
                        url: b.imageUrl ?? b.logoUrl,
                        icon: IconsaxPlusLinear.shop,
                        iconSize: 40,
                      ),
                    ),
                    if (categoryName.isNotEmpty)
                      PositionedDirectional(
                        top: 15,
                        end: 14,
                        child: _Pill(label: categoryName),
                      ),
                    if (b.kosherLabel != null)
                      PositionedDirectional(
                        top: 161,
                        start: 12,
                        child: _Pill(
                          label: widget.isHebrew ? b.kosherLabel! : 'Kosher',
                          icon: SvgPicture.asset('$_kAsset/card_kosher.svg', width: 14, height: 14),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DataText(b.name, style: _display(20)),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  _DataText(subtitle, style: _inter(14, color: _kGrey)),
                                ],
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
                                  child: Center(child: SvgPicture.asset('$_kAsset/card_pin.svg', width: 12, height: 16)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: _DataText(address, style: _inter(14, color: _kGrey))),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (b.reviewCount == 0)
                            Text(_t('Not rated yet', 'אין דירוג עדיין'), style: _inter(14, color: _kMuted))
                          else
                            Row(
                              children: [
                                SvgPicture.asset('$_kAsset/card_star.svg', width: 16, height: 16),
                                const SizedBox(width: 8),
                                Text(b.rating.toStringAsFixed(1), style: _inter(14, weight: FontWeight.w500)),
                                const SizedBox(width: 8),
                                Text('(${b.reviewCount})', style: _inter(14, color: _kMuted)),
                              ],
                            ),
                          // The "Contact" button was a Container. It dials the
                          // shop's own number now, and is absent where the row
                          // carries none. Outlined, and filled under the
                          // pointer, as the design draws both.
                          if (phone != null && phone.isNotEmpty) ...[
                            const SizedBox(height: 16),
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
                                    SvgPicture.asset(
                                      _hovered ? '$_kAsset/card_phone_white.svg' : '$_kAsset/card_phone.svg',
                                      width: 16,
                                      height: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(_t('Contact', 'צור קשר'),
                                        style: _inter(14, weight: FontWeight.w500, color: _hovered ? Colors.white : AppColors.midBlue, height: 1.71)),
                                  ],
                                ),
                              ),
                            )),
                          ],
                        ],
                      ),
                    ),
                    // The round badge sits on the photograph's edge: 44 across,
                    // half over the picture.
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
                              SvgPicture.asset('$_kAsset/${badge.$1}', width: 44, height: 44),
                              SvgPicture.asset('$_kAsset/${badge.$2}', width: 20, height: 20),
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

/// The dark blue pill on a card's photograph.
class _Pill extends StatelessWidget {
  final String label;
  final Widget? icon;
  const _Pill({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFF0033AC), borderRadius: BorderRadius.circular(50)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 6)],
          Text(label, style: _inter(12, weight: FontWeight.w500, color: Colors.white)),
        ],
      ),
    );
  }
}

/// One trade in the professionals filter: outlined in Grey, or filled Mid
/// blue when chosen. "All" carries the grid glyph.
class _TradePill extends StatelessWidget {
  final String label;
  final bool selected;
  final bool showIcon;
  final VoidCallback onTap;
  const _TradePill({required this.label, required this.selected, required this.onTap, this.showIcon = false});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.midBlue : Colors.transparent,
            border: Border.all(color: selected ? AppColors.midBlue : _kGrey),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                SvgPicture.asset(
                  '$_kAsset/pro_all.svg',
                  width: 16,
                  height: 16,
                  colorFilter: selected ? null : const ColorFilter.mode(_kGrey, BlendMode.srcIn),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: selected
                    ? _inter(14, weight: FontWeight.w500, color: Colors.white, height: 24 / 14)
                    : _inter(14, color: _kGrey, height: 24 / 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Professional card ──
/// One business filed under Services: its own photograph in the circle, its
/// own description, and its own number behind Call Now.
class _ProfessionalCard extends StatefulWidget {
  final Business business;

  /// The trade the business is filed under, which the card names under the
  /// name as the design does ("Refrigerator Technician"); its own one-line
  /// description where it is filed under none.
  final String? trade;
  final bool isHebrew;
  const _ProfessionalCard({required this.business, this.trade, this.isHebrew = false});

  @override
  State<_ProfessionalCard> createState() => _ProfessionalCardState();
}

class _ProfessionalCardState extends State<_ProfessionalCard> {
  bool _hovered = false;

  String _t(String en, String he) => widget.isHebrew ? he : en;

  @override
  Widget build(BuildContext context) {
    final b = widget.business;
    final trade = (widget.trade ?? b.description ?? '').trim();
    final phone = b.phone;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push('/business/${b.id}'),
        child: Container(
          height: 302,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: _kLine),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              NetworkPhoto(
                url: b.logoUrl ?? b.imageUrl,
                width: 120,
                height: 120,
                radius: BorderRadius.circular(60),
                gradient: const [Color(0xFFDDE4EC), Color(0xFFC0CCD8)],
                icon: IconsaxPlusLinear.user,
                iconSize: 44,
                iconColor: _kMuted,
              ),
              const SizedBox(height: 16),
              _DataText(b.name, textAlign: TextAlign.center, style: _display(20)),
              const SizedBox(height: 8),
              _DataText(trade, textAlign: TextAlign.center, style: _inter(14, color: _kGrey)),
              const Spacer(),
              // Call Now, or nothing where the business published no number.
              if (phone != null && phone.isNotEmpty)
                Builder(builder: (anchor) => GestureDetector(
                  onTap: () => showWebContactMenu(anchor, isHebrew: widget.isHebrew, phone: phone, whatsapp: b.whatsapp, email: b.email),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _hovered ? AppColors.midBlue : Colors.transparent,
                      border: Border.all(color: AppColors.midBlue),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          _hovered ? '$_kAsset/card_phone_white.svg' : '$_kAsset/card_phone.svg',
                          width: 16,
                          height: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(_t('Call Now', 'התקשר עכשיו'),
                            style: _inter(14, weight: FontWeight.w500, color: _hovered ? Colors.white : AppColors.midBlue, height: 1.71)),
                      ],
                    ),
                  ),
                )),
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
