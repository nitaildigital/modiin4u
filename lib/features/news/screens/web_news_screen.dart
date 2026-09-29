import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/banners_provider.dart';
import '../../../shared/providers/nav_categories_provider.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../models/article.dart';
import '../providers/news_providers.dart';

// ═══════════════════════════════════════════════════════════
// Web Modiin News — full desktop layout from Figma
// (Modiin News — 1920 × 4341)
//
// The page read a frozen WordPress export from `assets/data/`, and fell back
// to nineteen articles written into the source — invented headlines, invented
// excerpts and August 2026 datelines — whenever the export had not loaded.
// The export's ids are WordPress integers, so every card on it opened
// `/article/<integer>`, which matches no row in a table keyed by uuid.
//
// It reads `articles` now, through the news providers.
// ═══════════════════════════════════════════════════════════

const _kLime = Color(0xFFC9F31D);
const _kBodyGrey = Color(0xFF5F5E5A);
const _kBorder = Color(0xFFE7E7E7);

/// How many cards the grid opens with, and how many each "Load more" adds.
/// There are 667 published articles and this is the only index of them, so
/// the grid has to be able to walk past its first screenful.
const _kFirstPage = 12;
const _kPageStep = 9;

/// The front page's geometry at 1920: a 370 column of banners, 48, then the
/// sections, 72 apart, with their cards 32 apart across and 40 down.
const _kBannerWidth = 370.0;
const _kBannerGap = 48.0;
const _kSectionGap = 72.0;
const _kCardGap = 32.0;

/// Three cards across wherever they can be about 340 wide — which the
/// design's 1182 column beside the banners is — then two, then one. The rule
/// was "more than 1200 wide", so the moment a banner was booked the column
/// dropped to 1182 and every section fell to two across.
int _gridColumns(double width) =>
    ((width + _kCardGap) / (340 + _kCardGap)).floor().clamp(1, 3);

class WebNewsContent extends ConsumerStatefulWidget {
  /// Set when the page was reached through a category in the navbar menu.
  final String? categoryId;

  const WebNewsContent({super.key, this.categoryId});

  @override
  ConsumerState<WebNewsContent> createState() => _WebNewsContentState();
}

class _WebNewsContentState extends ConsumerState<WebNewsContent>
    with WebLanguageState<WebNewsContent> {
  bool get _isHebrew => webIsHebrew.value;
  int _visibleCount = _kFirstPage;

  String _t(String en, String he) => _isHebrew ? he : en;

  // The page used to carry nine category headings filled by matching a frozen
  // export's WordPress terms. The categories are real rows now — brought over
  // from the client's site with their 718 links — so the design's sections
  // are drawn from them: one per category that has something in it.

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

  /// "August 5, 2026 | 4:36 p.m.", as the design writes it, or "5 באוגוסט
  /// 2026 | 16:36" — Hebrew keeps the 24-hour clock.
  ///
  /// `published_at` comes back as UTC, so it is moved to the reader's zone
  /// before the hour is printed.
  String _dateLine(DateTime value) {
    final d = value.toLocal();
    final mm = d.minute.toString().padLeft(2, '0');
    if (_isHebrew) {
      return '${d.day} ב${_heMonths[d.month - 1]} ${d.year} | ${d.hour.toString().padLeft(2, '0')}:$mm';
    }
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '${_enMonths[d.month - 1]} ${d.day}, ${d.year} | $h:$mm ${d.hour < 12 ? 'a.m.' : 'p.m.'}';
  }

  /// Newest first.
  ///
  /// The provider orders by `created_at`, and all 669 rows were imported in
  /// one batch within the same second, so that order says nothing about when
  /// a story ran.
  List<Article> _byDate(List<Article> articles) =>
      [...articles]..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

  // ═══════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // Both derive from the same fetch, so they resolve together. Narrowed
    // to one category when the navbar menu sent us here, in which case the
    // hero is that category's own lead rather than the site's.
    final catId = widget.categoryId;
    final AsyncValue<Article?> featured;
    final AsyncValue<List<Article>> rest;
    if (catId == null) {
      featured = ref.watch(featuredArticleProvider);
      rest = ref.watch(restOfArticlesProvider);
    } else {
      final all = ref.watch(articlesByCategoryProvider(catId));
      featured = all.whenData(
        (list) => list.isEmpty ? null : pickHeroArticle(list),
      );
      rest = all.whenData((list) {
        if (list.isEmpty) return const <Article>[];
        final hero = pickHeroArticle(list);
        return list.where((a) => a.id != hero.id).toList();
      });
    }

    final Widget content;
    if (featured.hasError || rest.hasError) {
      content = _buildNotice(
        icon: IconsaxPlusLinear.wifi_square,
        title: _t('News could not be loaded', 'לא ניתן לטעון את החדשות'),
        body: _t(
          'Check your connection and try again.',
          'בדקו את החיבור לאינטרנט ונסו שוב.',
        ),
        actionLabel: _t('Try again', 'נסו שוב'),
        onAction: () => catId == null
            ? ref.invalidate(publishedArticlesProvider)
            : ref.invalidate(articlesByCategoryProvider(catId)),
      );
    } else if (!featured.hasValue || !rest.hasValue) {
      content = _buildSkeleton();
    } else if (featured.value == null) {
      content = _buildNotice(
        icon: IconsaxPlusLinear.note,
        title: catId == null
            ? _t('No articles published yet', 'עדיין לא פורסמו כתבות')
            : _t('Nothing in this category yet', 'אין עדיין כתבות בקטגוריה הזו'),
        body: _t(
          'Stories will appear here as the newsroom publishes them.',
          'כתבות יופיעו כאן עם פרסומן.',
        ),
      );
    } else {
      content = _buildContent(featured.value!, _byDate(rest.value!));
    }

    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: 'news',
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    _centered(child: content),
                    const SizedBox(height: 103),
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

  Widget _buildContent(Article featured, List<Article> rest) {
    // Two stories sit beside the lead.
    final side = rest.take(2).toList();
    final catId = widget.categoryId;
    return Column(
      children: [
        _buildHero(featured, side),
        const SizedBox(height: 64),
        if (catId == null)
          _buildSections({featured.id, for (final a in side) a.id})
        else
          _buildGrid(
            rest.skip(side.length).toList(),
            title: ref.watch(categoryNameProvider(catId)).valueOrNull ?? _t('Latest Stories', 'הכתבות האחרונות'),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // SECTIONS — the design's front page: a heading per category and its six
  // newest stories, beside a column of the banners booked for this page
  // ─────────────────────────────────────────────
  Widget _buildSections(Set<String> alreadyShown) {
    final categories = ref.watch(navCategoriesProvider('article')).valueOrNull ?? const <NavCategory>[];
    final banners = ref.watch(activeBannersProvider('NEWS_SIDEBAR')).valueOrNull ?? const <SiteBanner>[];

    final sections = <({NavCategory category, List<Article> articles})>[];
    for (final c in categories) {
      final list = ref.watch(articlesByCategoryProvider(c.id)).valueOrNull;
      if (list == null) continue;
      final newest = _byDate(list).where((a) => !alreadyShown.contains(a.id)).take(6).toList();
      if (newest.isEmpty) continue;
      sections.add((category: c, articles: newest));
    }
    if (sections.isEmpty) return _buildSkeleton();

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: _kSectionGap),
          _buildGrid(
            sections[i].articles,
            title: sections[i].category.name,
            onTitleTap: () => context.go('/news/category/${sections[i].category.id}'),
            paged: false,
          ),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (banners.isEmpty || c.maxWidth < 1200) return column;
        final mainWidth = c.maxWidth - _kBannerWidth - _kBannerGap;

        // The design hangs the first banner beside the first section and
        // starts the rest beside the second, 17 below its heading's top, one
        // under another 32 apart — however far down that runs. The sections'
        // heights are known from their card counts, so the first banner's
        // slot is sized to reach there.
        final firstSlot = sections.length < 2
            ? 0.0
            : _sectionHeight(sections.first.articles.length, mainWidth) + _kSectionGap + 17;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _kBannerWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: firstSlot),
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: _sideBanner(banners.first),
                      ),
                    ),
                  ),
                  for (var i = 1; i < banners.length; i++) ...[
                    if (i > 1) const SizedBox(height: 32),
                    _sideBanner(banners[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(width: _kBannerGap),
            Expanded(child: column),
          ],
        );
      },
    );
  }

  /// One of the tall banners down the side, at 370 wide and its own height:
  /// the design draws them 630, 225 and 370 tall, which is each creative's
  /// shape, not a slot's.
  Widget _sideBanner(SiteBanner banner) {
    final link = banner.destinationUrl;
    return MouseRegion(
      cursor: link == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: link == null ? null : () => launchUrl(Uri.parse(link)),
        child: Image.network(
          sizedPhotoUrl(banner.imageUrl, _kBannerWidth, MediaQuery.devicePixelRatioOf(context)),
          width: _kBannerWidth,
          fit: BoxFit.fitWidth,
          // A creative that fails to load leaves no gap in the column.
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  /// A section's height: its heading, then rows of 404 cards 40 apart.
  double _sectionHeight(int cards, double width) {
    final rows = (cards / _gridColumns(width)).ceil();
    return 34 + 24 + rows * 404 + (rows - 1) * 40;
  }

  /// The page's content column. It was 1600 including its own 24 of
  /// padding, so this page sat 24 inside the navbar and every other page.
  Widget _centered({required Widget child}) => WebSection(child: child);

  // ─────────────────────────────────────────────
  // HERO — 1014 featured card + two 576 stacked cards
  // ─────────────────────────────────────────────
  Widget _buildHero(Article featured, List<Article> side) {
    return SizedBox(
      height: 552,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 1014, child: _buildFeaturedCard(featured)),
          // With one story published there is nothing to stack beside it, and
          // the lead takes the full width rather than sitting next to a pair
          // of empty rectangles.
          if (side.isNotEmpty) ...[
            const SizedBox(width: 10),
            Expanded(
              flex: 576,
              child: Column(
                children: [
                  for (var i = 0; i < side.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    Expanded(child: _buildHeroSideCard(side[i], scrimTop: i == 0 ? 0 : 27)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(Article article) {
    return _HoverCard(
      onTap: () => context.push('/article/${article.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _articlePhoto(article, glyphSize: 72, icon: null),
            // Bottom scrim — starts 39px below the top of the card
            Positioned(
              left: 0,
              right: 0,
              top: 39,
              bottom: 0,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xFF000000)],
                    stops: [0.5543, 1.0],
                  ),
                ),
              ),
            ),
            // Badges: the design's "Now in Modiin" for a story the newsroom
            // has featured, and the category the story is filed under. The
            // chip used to read "Municipality" on every card, a category the
            // article did not have; it names the article's own now.
            PositionedDirectional(
              start: 16,
              top: 16,
              child: _badgeRow(article, featuredBadge: true),
            ),
            // Headline: two lines at most, in the design's 69 box with the
            // date 11 under it, 28 off the card's foot. A one-line headline
            // sits down on the date rather than at the top of an empty box.
            PositionedDirectional(
              start: 28,
              bottom: 28,
              end: 34,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: _articleText(
                      article.title,
                      style: TextStyle(fontFamily: AppFonts.nunito,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        height: 34 / 28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _dateRow(_dateLine(article.publishedAt), color: Colors.white, iconColor: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// [scrimTop]: the design starts the lower card's shade 27 below its top.
  Widget _buildHeroSideCard(Article article, {double scrimTop = 0}) {
    return _HoverCard(
      onTap: () => context.push('/article/${article.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _articlePhoto(article, glyphSize: 48),
            Positioned(
              left: 0,
              right: 0,
              top: scrimTop,
              bottom: 0,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xFF000000)],
                    stops: [0.3137, 1.0],
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              start: 16,
              top: 16,
              child: _badgeRow(article, featuredBadge: false),
            ),
            // The same 69 box as the lead's, 18 off the foot. Two lines at
            // 24 fill 60 of it, so the date is 20 under the second.
            PositionedDirectional(
              start: 18,
              bottom: 18,
              end: 23,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: _articleText(
                      article.title,
                      style: TextStyle(fontFamily: AppFonts.nunito,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        height: 30 / 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _dateRow(_dateLine(article.publishedAt), color: Colors.white, iconColor: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgeRow(Article article, {required bool featuredBadge}) {
    final category = (ref.watch(articleCategoryNamesProvider).valueOrNull ?? const {})[article.id];
    final badges = <Widget>[
      if (article.isBreaking)
        _badge(
          label: _t('Breaking', 'מבזק'),
          background: AppColors.error,
          foreground: Colors.white,
          icon: const Icon(IconsaxPlusLinear.danger, size: 20, color: Colors.white),
        ),
      if (featuredBadge && article.isFeatured)
        _badge(
          label: _t('Now in Modiin', 'עכשיו במודיעין'),
          background: _kLime,
          foreground: AppColors.navy,
          icon: SvgPicture.asset('assets/web/news/now_in_modiin.svg', width: 20, height: 20),
        ),
      if (category != null)
        _badge(label: category, background: AppColors.turquoise, foreground: Colors.white),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < badges.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          badges[i],
        ],
      ],
    );
  }

  Widget _badge({
    required String label,
    required Color background,
    required Color foreground,
    Widget? icon,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon,
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 24 / 14,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateRow(String date, {required Color color, required Color iconColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/web/home/date.svg',
          width: 16,
          height: 16,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
        const SizedBox(width: 9),
        Text(
          date,
          style: TextStyle(fontFamily: AppFonts.inter,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 17 / 14,
            color: color,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // GRID — every other published article, newest first
  // ─────────────────────────────────────────────
  /// A category's stories, three across. On the front page each section
  /// shows its newest six; on a category's own page the grid pages through
  /// all of them.
  Widget _buildGrid(
    List<Article> articles, {
    required String title,
    VoidCallback? onTitleTap,
    bool paged = true,
  }) {
    if (articles.isEmpty) return const SizedBox.shrink();
    final shown = paged ? articles.take(_visibleCount).toList() : articles;

    final heading = Text(
      title,
      style: TextStyle(fontFamily: AppFonts.nunito,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 34 / 28,
        color: AppColors.midBlue,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A category's heading leads to its own page, where all of its
        // stories are.
        onTitleTap == null
            ? heading
            : MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(onTap: onTitleTap, child: heading),
              ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = _gridColumns(constraints.maxWidth);
            final cardWidth = (constraints.maxWidth - (cols - 1) * _kCardGap) / cols;
            return Wrap(
              spacing: _kCardGap,
              runSpacing: 40,
              children: shown
                  .map((article) => _ArticleCard(
                        article: article,
                        width: cardWidth,
                        date: _dateLine(article.publishedAt),
                        onTap: () => context.push('/article/${article.id}'),
                      ))
                  .toList(),
            );
          },
        ),
        if (paged && shown.length < articles.length) ...[
          const SizedBox(height: 48),
          Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _visibleCount += _kPageStep),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.midBlue),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Text(
                    _t('Load more', 'טען עוד'),
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.midBlue),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────
  // LOADING · EMPTY · ERROR
  // ─────────────────────────────────────────────
  /// The hero and the first row of cards as blocks, at the geometry of the
  /// real thing, so nothing jumps when the articles land.
  Widget _buildSkeleton() {
    return Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 552,
            // Stretch, so the blocks take the hero's full height rather than
            // collapsing to nothing under loose constraints.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 1014, child: SkeletonBox(radius: 12)),
                SizedBox(width: 10),
                Expanded(
                  flex: 576,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: SkeletonBox(radius: 12)),
                      SizedBox(height: 10),
                      Expanded(child: SkeletonBox(radius: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 64),
          const SkeletonLine(width: 260, fontSize: 28),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = _gridColumns(constraints.maxWidth);
              final cardWidth = (constraints.maxWidth - (cols - 1) * _kCardGap) / cols;
              return Wrap(
                spacing: _kCardGap,
                runSpacing: 40,
                children: List.generate(cols, (_) {
                  return SizedBox(
                    width: cardWidth,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 270, radius: 12),
                        SizedBox(height: 16),
                        SkeletonLine(width: 260, fontSize: 20),
                        SizedBox(height: 12),
                        SkeletonLine(width: 200),
                        SizedBox(height: 14),
                        SkeletonLine(width: 140),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotice({
    required IconData icon,
    required String title,
    required String body,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 24),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: _kBodyGrey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center,
              style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.navy)),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center,
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kBodyGrey)),
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
}

// ═══════════════════════════════════════════════
// SHARED PIECES
// ═══════════════════════════════════════════════

/// Articles are published in Hebrew whichever way the page toggle is set, so
/// their text lays out RTL even while the chrome is in English.
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

/// The stand-in behind an article that carries no photograph. Taken from the
/// id, so the same article always looks the same.
const _photoGradients = <List<Color>>[
  [Color(0xFF2E5C8A), Color(0xFF0C1A33)],
  [Color(0xFF7A3B4A), Color(0xFF1E0A10)],
  [Color(0xFF3F6B4F), Color(0xFF0E1C14)],
  [Color(0xFF6B5A3B), Color(0xFF1C160C)],
  [Color(0xFF4A3B7A), Color(0xFF120E22)],
  [Color(0xFF2F6B6B), Color(0xFF0B1C1C)],
];

/// The article's own photograph — 642 of the 669 rows carry one.
Widget _articlePhoto(
  Article article, {
  double radius = 12,
  double glyphSize = 40,
  IconData? icon = IconsaxPlusLinear.image,
}) {
  return NetworkPhoto(
    url: article.imageUrl,
    width: double.infinity,
    height: double.infinity,
    radius: radius == 0 ? null : BorderRadius.circular(radius),
    gradient: _photoGradients[article.id.hashCode.abs() % _photoGradients.length],
    icon: icon,
    iconSize: glyphSize,
  );
}

/// 372.67 × 404 article card — image, 2-line title, 1-line excerpt, date.
class _ArticleCard extends StatefulWidget {
  final Article article;
  final double width;
  final String date;
  final VoidCallback onTap;
  const _ArticleCard({
    required this.article,
    required this.width,
    required this.date,
    required this.onTap,
  });

  @override
  State<_ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<_ArticleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    final excerpt = a.excerpt ?? '';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.width,
          height: 404,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedScale(
                scale: _hovered ? 1.015 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: SizedBox(
                  width: widget.width,
                  height: 270,
                  child: _articlePhoto(a),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: _articleText(
                  a.title,
                  style: TextStyle(fontFamily: AppFonts.nunito,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 25 / 20,
                    color: _hovered ? AppColors.midBlue : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Nothing stands in for an excerpt the row does not have; the
              // line simply is not drawn.
              if (excerpt.isNotEmpty)
                SizedBox(
                  height: 21,
                  child: _articleText(
                    excerpt,
                    maxLines: 1,
                    style: TextStyle(fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      color: _kBodyGrey,
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  SvgPicture.asset('assets/web/home/date.svg', width: 16, height: 16),
                  const SizedBox(width: 9),
                  Text(
                    widget.date,
                    style: TextStyle(fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 17 / 14,
                      color: _kBodyGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Subtle lift on hover for the hero cards.
class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HoverCard({required this.child, required this.onTap});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
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
