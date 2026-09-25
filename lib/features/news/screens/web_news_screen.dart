import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/theme/app_colors.dart';
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
const _kIconGrey = Color(0xFF6D6D6D);
const _kBorder = Color(0xFFE7E7E7);

/// How many cards the grid opens with, and how many each "Load more" adds.
/// There are 667 published articles and this is the only index of them, so
/// the grid has to be able to walk past its first screenful.
const _kFirstPage = 12;
const _kPageStep = 9;

class WebNewsContent extends ConsumerStatefulWidget {
  const WebNewsContent({super.key});

  @override
  ConsumerState<WebNewsContent> createState() => _WebNewsContentState();
}

class _WebNewsContentState extends ConsumerState<WebNewsContent> {
  bool _isHebrew = false;
  int _visibleCount = _kFirstPage;

  String _t(String en, String he) => _isHebrew ? he : en;

  // The page used to carry nine category headings — Municipality Updates,
  // Urban, Business, People, Food & Drink and four more — each filled by
  // matching the export's WordPress terms. The `articles` table has no
  // category column, and `entity_categories` holds business links only: not
  // one of the 669 articles is filed under a category. So a per-category
  // section, tab or count has nothing behind it and none is drawn. When the
  // article links are loaded, the headings can come back.

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
    // Both derive from the same fetch, so they resolve together.
    final featured = ref.watch(featuredArticleProvider);
    final rest = ref.watch(restOfArticlesProvider);

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
        onAction: () => ref.invalidate(publishedArticlesProvider),
      );
    } else if (!featured.hasValue || !rest.hasValue) {
      content = _buildSkeleton();
    } else if (featured.value == null) {
      content = _buildNotice(
        icon: IconsaxPlusLinear.note,
        title: _t('No articles published yet', 'עדיין לא פורסמו כתבות'),
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
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
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
    // Two stories sit beside the lead; the grid below starts after them.
    final side = rest.take(2).toList();
    final grid = rest.skip(side.length).toList();
    return Column(
      children: [
        _buildHero(featured, side),
        const SizedBox(height: 64),
        _buildGrid(grid),
      ],
    );
  }

  /// 1600px content column (160px page padding at 1920).
  Widget _centered({required Widget child}) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1600),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: child,
      ),
    );
  }

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
                    Expanded(child: _buildHeroSideCard(side[i])),
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
            _articlePhoto(article, glyphSize: 72),
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
            // Badges. Two used to sit here reading "Now in Modiin" and
            // "Municipality" — the second a category the article does not
            // have. These are the flags the row actually carries.
            PositionedDirectional(
              start: 16,
              top: 16,
              child: Row(
                children: [
                  if (article.isBreaking)
                    _badge(
                      label: _t('Breaking', 'מבזק'),
                      background: AppColors.error,
                      foreground: Colors.white,
                      icon: IconsaxPlusLinear.danger,
                    ),
                  if (article.isBreaking && article.isFeatured)
                    const SizedBox(width: 12),
                  if (article.isFeatured)
                    _badge(
                      label: _t('Featured', 'כתבה נבחרת'),
                      background: _kLime,
                      foreground: AppColors.navy,
                      icon: IconsaxPlusLinear.star,
                    ),
                ],
              ),
            ),
            // Headline
            PositionedDirectional(
              start: 28,
              bottom: 29,
              end: 34,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _articleText(
                    article.title,
                    maxLines: 3,
                    style: TextStyle(fontFamily: AppFonts.nunito,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      height: 34 / 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 11),
                  _dateRow(_dateLine(article.publishedAt), color: Colors.white, iconColor: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSideCard(Article article) {
    return _HoverCard(
      onTap: () => context.push('/article/${article.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _articlePhoto(article, glyphSize: 48),
            Positioned.fill(
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
            if (article.isBreaking)
              PositionedDirectional(
                start: 16,
                top: 16,
                child: _badge(
                  label: _t('Breaking', 'מבזק'),
                  background: AppColors.error,
                  foreground: Colors.white,
                  icon: IconsaxPlusLinear.danger,
                ),
              ),
            PositionedDirectional(
              start: 18,
              bottom: 27,
              end: 23,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _articleText(
                    article.title,
                    style: TextStyle(fontFamily: AppFonts.nunito,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      height: 30 / 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 11),
                  _dateRow(_dateLine(article.publishedAt), color: Colors.white, iconColor: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge({
    required String label,
    required Color background,
    required Color foreground,
    IconData? icon,
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
            Icon(icon, size: 20, color: foreground),
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
        Icon(IconsaxPlusLinear.calendar_1, size: 16, color: iconColor),
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
  /// A 370px column of four gradient rectangles used to run down the left of
  /// this grid as advertising slots. Nothing fills them — there is no ad
  /// table and no campaign behind them — so the grid has the full width.
  Widget _buildGrid(List<Article> articles) {
    if (articles.isEmpty) return const SizedBox.shrink();
    final shown = articles.take(_visibleCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Latest Stories', 'הכתבות האחרונות'),
          style: TextStyle(fontFamily: AppFonts.nunito,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 34 / 28,
            color: AppColors.midBlue,
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 32.0;
            final cols = constraints.maxWidth > 1200
                ? 3
                : (constraints.maxWidth > 800 ? 2 : 1);
            final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
            return Wrap(
              spacing: gap,
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
        if (shown.length < articles.length) ...[
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
              const gap = 32.0;
              final cols = constraints.maxWidth > 1200
                  ? 3
                  : (constraints.maxWidth > 800 ? 2 : 1);
              final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
              return Wrap(
                spacing: gap,
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
}) {
  return NetworkPhoto(
    url: article.imageUrl,
    width: double.infinity,
    height: double.infinity,
    radius: radius == 0 ? null : BorderRadius.circular(radius),
    gradient: _photoGradients[article.id.hashCode.abs() % _photoGradients.length],
    icon: IconsaxPlusLinear.image,
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
                  const Icon(IconsaxPlusLinear.calendar_1, size: 16, color: _kIconGrey),
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
