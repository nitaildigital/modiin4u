import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../../shared/widgets/web_dotted_band.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../models/event.dart';
import '../models/event_category.dart';
import '../models/event_labels.dart';
import '../providers/event_providers.dart';
import '../../../shared/widgets/web_hero_photo.dart';
import 'web_events_category_screen.dart';

// ═══════════════════════════════════════════════════════════
// Web Events — full desktop layout from Figma
// (Events — 1920 × 3535)
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF5F5E5A);
const _kBodyText = Color(0xFF3D3D3D);
const _kHeading = Color(0xFF1C1C1E);
const _kPlaceholder = Color(0xFF4F4F4F);

/// How many rows of cards the grid opens with, and how many each "Load More"
/// adds. The design draws four rows of four, the last one fading out under
/// the button.
///
/// Both used to run against a fixed pool of sixteen hand-written cards, and
/// the grid repeated that pool with `events[i % events.length]` up to a cap of
/// 32 — so "Load More" showed the same events again rather than more of them.
/// They count real rows now, and the button only appears when there are rows
/// left to show.
const _kFirstRows = 4;
const _kRowsPerLoad = 2;

/// The design's photographs for the category circles, by category slug.
///
/// `categories.image_url` wins when the editor has set one. "All Events" and
/// "Free" are not categories — they filter every event, and free ones — so
/// their pictures are only ever these.
const _kCircleAll = 'assets/web/events/cat_all.webp';
const _kCircleFree = 'assets/web/events/cat_free.webp';
const _kCircleBySlug = {
  'community': 'assets/web/events/cat_community.webp',
  'municipal-community': 'assets/web/events/cat_community.webp',
  'concerts': 'assets/web/events/cat_music.webp',
  'music': 'assets/web/events/cat_music.webp',
  'kids': 'assets/web/events/cat_kids.webp',
  'kids-family': 'assets/web/events/cat_kids.webp',
  'sports-events': 'assets/web/events/cat_sports.webp',
  'sports': 'assets/web/events/cat_sports.webp',
};

/// The events page, and — with `?category=` in the address — the category
/// browser it opens into.
///
/// Every event card, every category tile and every count on this page was
/// written into the source once: sixteen invented events with invented
/// venues, prices and interest figures, and six category circles reading 157,
/// 32, 24, 45, 15 and 41. Every card opened `/event/demo_$i`, which matches
/// no row.
///
/// The grid reads `events`, the circles read `categories` and the links in
/// `entity_categories`, and each count is of the upcoming events it opens.
class WebEventsContent extends ConsumerStatefulWidget {
  const WebEventsContent({super.key});

  @override
  ConsumerState<WebEventsContent> createState() => _WebEventsContentState();
}

class _WebEventsContentState extends ConsumerState<WebEventsContent>
    with WebLanguageState<WebEventsContent> {
  bool get _isHebrew => webIsHebrew.value;
  int _extraRows = 0;
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // The field carries whatever the search already is, so moving between the
    // mobile and desktop layouts does not silently drop it.
    _searchController.text = ref.read(eventSearchProvider);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;
  EventLabels get _labels => EventLabels(_isHebrew);

  // ─────────────────────────────────────────────
  // SEARCH
  // ─────────────────────────────────────────────
  /// Narrows the grid rather than leaving the page.
  ///
  /// The button used to push `/search?q=…`, which meant the events search
  /// never reached `eventSearchProvider` and the grid below it never moved.
  void _applySearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      ref.read(eventSearchProvider.notifier).state = value;
      if (mounted) setState(() => _extraRows = 0);
    });
  }

  void _onSearch() {
    _debounce?.cancel();
    ref.read(eventSearchProvider.notifier).state = _searchController.text;
    setState(() => _extraRows = 0);
  }

  /// The category browser has no route of its own; it is this page with
  /// `?category=all|free|<slug>` in the address, so a filtered view can be
  /// linked to and the browser's Back returns here.
  ///
  /// Read through [GoRouterState.of], which makes this rebuild when the
  /// query changes on the same page.
  String? _categoryParam(BuildContext context) {
    final value = GoRouterState.of(context).uri.queryParameters['category'];
    return (value == null || value.isEmpty) ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    final category = _categoryParam(context);
    if (category != null) {
      return WebEventsCategoryContent(
        key: ValueKey(category),
        initialFilter: category,
      );
    }

    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: 'events',
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeroSection(),
                    _buildCategoriesSection(),
                    _buildEventsSection(),
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
  // HERO — 1920 × 662
  // ─────────────────────────────────────────────
  /// The design's band and photograph: a crowd at a concert, darkened
  /// softly behind the title so it reads, and the search across it.
  Widget _buildHeroSection() {
    return SizedBox(
      width: double.infinity,
      height: 662,
      child: Stack(
        children: [
          const Positioned.fill(child: WebDottedBand()),
          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                height: 551,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: const WebHeroPhoto(asset: 'assets/web/events/hero.webp', placeholder: Color(0xFF43270F)),
                      ),
                      // Ellipse 530: a blurred shadow, half strength, under
                      // the title.
                      Positioned(
                        top: -154,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 846,
                            height: 767,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.35),
                                  Colors.black.withValues(alpha: 0.0),
                                ],
                                stops: const [0.45, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 152,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            Text(
                              _t('Events & Nightlife in Modiin', 'אירועים וחיי לילה במודיעין'),
                              style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 44, fontWeight: FontWeight.w600, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 584,
                              child: Text(
                                _t('Discover concerts, community events, nightlife, family activities and more happening around Modiin.',
                                    'גלו הופעות, אירועי קהילה, חיי לילה, פעילויות למשפחה ועוד — הכל סביב מודיעין.'),
                                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: Colors.white),
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
            ),
          ),
        ],
      ),
    );
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
        ),
        child: Row(
          children: [
            SvgPicture.asset('assets/web/common/search24.svg', width: 24, height: 24),
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
                  filled: false,
                      isDense: true,
                  isCollapsed: true,
                ),
                onChanged: _applySearch,
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
                      SvgPicture.asset('assets/web/common/search_white.svg', width: 18, height: 18),
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
  // EVENT CATEGORIES — title + a row of circles, 1200 wide
  // ─────────────────────────────────────────────
  /// "All Events", each category that has something coming up, and "Free",
  /// with the number of upcoming events each one opens.
  ///
  /// A category with nothing coming is left out: its circle would open an
  /// empty page.
  Widget _buildCategoriesSection() {
    final upcoming = ref.watch(upcomingEventsProvider).valueOrNull;
    final categories = ref.watch(eventCategoriesProvider).valueOrNull ?? const [];
    final byEvent =
        ref.watch(eventCategoriesByEventProvider).valueOrNull ?? const {};

    // Nothing coming at all: the grid below says so, and a lone "All Events
    // 0" circle would only repeat it.
    if (upcoming != null && upcoming.isEmpty) return const SizedBox.shrink();

    final circles = <_CircleData>[];
    if (upcoming != null) {
      circles.add(_CircleData(
        label: _t('All Events', 'כל האירועים'),
        count: upcoming.length,
        asset: _kCircleAll,
        filter: 'all',
      ));
      for (final c in categories) {
        final count = upcoming
            .where((e) => (byEvent[e.id] ?? const []).any((x) => x.id == c.id))
            .length;
        if (count == 0) continue;
        // The editor's picture for the category; else the design's; else the
        // photograph of the category's next event, so a category the design
        // never drew still shows a picture of itself.
        final asset = _kCircleBySlug[c.slug];
        var imageUrl = c.imageUrl;
        if ((imageUrl == null || imageUrl.isEmpty) && asset == null) {
          imageUrl = upcoming
              .where((e) =>
                  (e.imageUrl ?? '').isNotEmpty &&
                  (byEvent[e.id] ?? const []).any((x) => x.id == c.id))
              .firstOrNull
              ?.imageUrl;
        }
        circles.add(_CircleData(
          label: _labels.category(c),
          count: count,
          imageUrl: imageUrl,
          asset: asset,
          filter: c.slug,
        ));
      }
      final free = upcoming.where((e) => e.isFree).length;
      if (free > 0) {
        circles.add(_CircleData(
          label: _t('Free', 'חינם'),
          count: free,
          asset: _kCircleFree,
          filter: 'free',
        ));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 59),
      child: WebSection(
        child: Column(
          children: [
            Text(_t('Event Categories', 'קטגוריות אירועים'),
                style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.midBlue, height: 34 / 28),
                textAlign: TextAlign.center),
            const SizedBox(height: 15),
            Text(_t('From music to family fun, find your next experience.',
                    'ממוזיקה ועד כיף משפחתי — מצאו את החוויה הבאה שלכם.'),
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kGreyText, height: 17 / 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 42),
            SizedBox(
              height: 203,
              child: upcoming == null
                  ? const _CirclesSkeleton()
                  : LayoutBuilder(builder: (context, constraints) {
                      // Six circles 160 wide spread across 1200, as drawn;
                      // fewer keep the drawn spacing and sit in the middle,
                      // more close up and then narrow.
                      final n = circles.length;
                      final avail = math.min(1200.0, constraints.maxWidth);
                      var width = 160.0;
                      var gap = n > 1 ? ((avail - n * width) / (n - 1)).clamp(0.0, 48.0) : 0.0;
                      if (n * width + (n - 1) * gap > avail) width = avail / n;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < n; i++) ...[
                            if (i > 0) SizedBox(width: gap),
                            SizedBox(
                              width: width,
                              child: _CategoryCircle(
                                data: circles[i],
                                onTap: () => context.go('/events?category=${Uri.encodeQueryComponent(circles[i].filter)}'),
                              ),
                            ),
                          ],
                        ],
                      );
                    }),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EVENTS IN MODIIN — card grid + fade + Load More
  // ─────────────────────────────────────────────
  Widget _buildEventsSection() {
    final events = ref.watch(filteredEventsProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 80, bottom: 90),
      child: WebSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('Events in Modiin', 'אירועים במודיעין'),
                style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.midBlue, height: 34 / 28)),
            const SizedBox(height: 10),
            Text(_t('Find something happening near you.', 'מצאו משהו שקורה לידכם.'),
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kGreyText, height: 17 / 14)),
            const SizedBox(height: 32),
            events.when(
              loading: _buildGridSkeleton,
              error: (_, _) => _buildErrorState(),
              data: (list) => list.isEmpty ? _buildEmptyState() : _buildGrid(list),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<Event> events) {
    final byEvent =
        ref.watch(eventCategoriesByEventProvider).valueOrNull ?? const {};

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = webEventGridColumns(constraints.maxWidth);
        final cardWidth = webEventCardWidth(constraints.maxWidth, cols);
        final visibleCount = cols * (_kFirstRows + _extraRows);
        final visible = events.take(visibleCount).toList();
        final hasMore = visible.length < events.length;

        return Stack(
          children: [
            Wrap(
              spacing: kWebEventGridGap,
              runSpacing: kWebEventGridGap,
              children: [
                for (final event in visible)
                  SizedBox(
                    width: cardWidth,
                    child: WebEventCard(
                      event: event,
                      labels: _labels,
                      category: (byEvent[event.id] ?? const []).firstOrNull,
                      onTap: () => context.push('/event/${event.id}'),
                    ),
                  ),
              ],
            ),
            // Rectangle 14505 — the white fade over the last row, 389 tall.
            if (hasMore)
              const Positioned(
                left: -1,
                right: -1,
                bottom: -1,
                height: 389,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00FFFFFF), Colors.white],
                        stops: [0.01675, 0.75644],
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
        );
      },
    );
  }

  Widget _loadMoreButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _extraRows += _kRowsPerLoad),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.midBlue),
            borderRadius: BorderRadius.circular(60),
          ),
          // As wide as its label: a Container told to align its child takes
          // all the width it is offered, and the button spanned the page.
          child: Center(
            widthFactor: 1,
            child: Text(_t('Load More', 'טען עוד'),
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.midBlue, height: 24 / 16)),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LOADING · EMPTY · ERROR
  // ─────────────────────────────────────────────
  /// Two rows of card-shaped blocks, so the grid does not jump when the rows
  /// land.
  Widget _buildGridSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = webEventGridColumns(constraints.maxWidth);
        final cardWidth = webEventCardWidth(constraints.maxWidth, cols);
        return Skeleton(
          child: Wrap(
            spacing: kWebEventGridGap,
            runSpacing: kWebEventGridGap,
            children: List.generate(cols * 2, (_) {
              return SizedBox(
                width: cardWidth,
                height: 364,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 200, radius: 12),
                    SizedBox(height: 16),
                    SkeletonLine(width: 220, fontSize: 20),
                    SizedBox(height: 16),
                    SkeletonLine(width: 140),
                    SizedBox(height: 16),
                    SkeletonLine(width: 180),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final searching = ref.watch(eventSearchProvider).trim().isNotEmpty;
    return _buildNoticeBox(
      icon: searching ? IconsaxPlusLinear.search_status : IconsaxPlusLinear.calendar_1,
      title: searching
          ? _t('No events match your search', 'אין אירועים שתואמים לחיפוש')
          : _t('No events listed yet', 'עדיין לא פורסמו אירועים'),
      body: searching
          ? _t('Try a different word, or clear the search.',
              'נסו מילה אחרת, או נקו את החיפוש.')
          : _t('New events will appear here as they are published.',
              'אירועים חדשים יופיעו כאן עם פרסומם.'),
    );
  }

  Widget _buildErrorState() {
    return _buildNoticeBox(
      icon: IconsaxPlusLinear.wifi_square,
      title: _t('Events could not be loaded', 'לא ניתן לטעון את האירועים'),
      body: _t('Check your connection and try again.',
          'בדקו את החיבור לאינטרנט ונסו שוב.'),
      actionLabel: _t('Try again', 'נסו שוב'),
      onAction: () => ref.invalidate(eventsProvider),
    );
  }

  Widget _buildNoticeBox({
    required IconData icon,
    required String title,
    required String body,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: _kGreyText.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.navy),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(body,
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kGreyText),
              textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onAction,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: AppColors.midBlue,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  alignment: Alignment.center,
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
// CATEGORY CIRCLE — 160 wide, 116 photo
// ═══════════════════════════════════════════════

class _CircleData {
  final String label;
  final int count;
  final String? imageUrl;
  final String? asset;

  /// What goes after `?category=`: `all`, `free` or the category's slug.
  final String filter;
  const _CircleData({
    required this.label,
    required this.count,
    required this.filter,
    this.imageUrl,
    this.asset,
  });
}

class _CategoryCircle extends StatefulWidget {
  final _CircleData data;
  final VoidCallback onTap;
  const _CategoryCircle({required this.data, required this.onTap});

  @override
  State<_CategoryCircle> createState() => _CategoryCircleState();
}

class _CategoryCircleState extends State<_CategoryCircle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final url = d.imageUrl;
    final Widget photo;
    if (url != null && url.isNotEmpty) {
      photo = NetworkPhoto(url: url, width: 116, height: 116, icon: IconsaxPlusBold.calendar_1, iconSize: 32);
    } else if (d.asset != null) {
      photo = Image.asset(d.asset!, width: 116, height: 116, fit: BoxFit.cover);
    } else {
      // A category the design has no photograph for, and the editor has not
      // given one: the brand tint with the events glyph, as a card with no
      // photo shows.
      photo = const NetworkPhoto(url: null, width: 116, height: 116, icon: IconsaxPlusBold.calendar_1, iconSize: 32);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 150),
              scale: _hovered ? 1.04 : 1,
              child: ClipOval(child: SizedBox(width: 116, height: 116, child: photo)),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Text(d.label,
                      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 18, fontWeight: FontWeight.w600, color: _hovered ? AppColors.midBlue : _kHeading, height: 22 / 18),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text('${d.count}',
                      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kGreyText, height: 17 / 14),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CirclesSkeleton extends StatelessWidget {
  const _CirclesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 6; i++) ...[
            if (i > 0) const SizedBox(width: 48),
            const SizedBox(
              width: 160,
              child: Column(
                children: [
                  SkeletonBox(width: 116, height: 116, radius: 58),
                  SizedBox(height: 20),
                  SkeletonLine(width: 100, fontSize: 18),
                  SizedBox(height: 8),
                  SkeletonLine(width: 30),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// EVENT CARD — 382 × 364 ("Frame 1171276543")
// Also the "You May Also Like" card on the event page.
// ═══════════════════════════════════════════════

const kWebEventGridGap = 24.0;

/// Four across at the design's 1600; three, then two, as the column narrows,
/// keeping every card at least 300 wide.
int webEventGridColumns(double width) =>
    ((width + kWebEventGridGap) / (300 + kWebEventGridGap)).floor().clamp(2, 4);

double webEventCardWidth(double width, int cols) =>
    (width - (cols - 1) * kWebEventGridGap) / cols;

class WebEventCard extends StatefulWidget {
  final Event event;
  final EventLabels labels;

  /// The pill in the photo's top corner: the event's primary category, or
  /// none when the event is not filed under one.
  final EventCategory? category;
  final VoidCallback onTap;

  const WebEventCard({
    super.key,
    required this.event,
    required this.labels,
    required this.category,
    required this.onTap,
  });

  @override
  State<WebEventCard> createState() => _WebEventCardState();
}

class _WebEventCardState extends State<WebEventCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final l = widget.labels;
    final date = e.startDate;
    final price = l.price(e);
    final time = l.startTime(e);
    final place = l.venue(e);
    final category = widget.category;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 364,
          clipBehavior: Clip.antiAlias,
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
              // ── Photo, 200 tall ──
              SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: NetworkPhoto(
                        url: e.imageUrl,
                        icon: IconsaxPlusBold.calendar_1,
                        iconSize: 34,
                      ),
                    ),
                    // The heart: saving needs an account, which is the app's,
                    // so on the website it draws nothing.
                    PositionedDirectional(
                      start: 12,
                      top: 12,
                      child: FavoriteButton(kind: FavoriteKind.event, id: e.id, size: 40, iconSize: 20),
                    ),
                    if (category != null)
                      PositionedDirectional(
                        end: 14,
                        top: 15,
                        child: WebEventCategoryPill(label: l.category(category)),
                      ),
                    if (date != null)
                      PositionedDirectional(
                        start: 12,
                        bottom: 12,
                        child: WebEventDateBadge(month: l.shortMonth(date), day: date.day, width: 57),
                      ),
                  ],
                ),
              ),
              // ── Body: padding 16, rows 16 apart ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title,
                        style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.navy, height: 25 / 20),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (time != null) ...[
                        const SizedBox(height: 16),
                        _metaRow(
                          SvgPicture.asset('assets/web/events/card_clock.svg', width: 13, height: 13),
                          time,
                          ltr: true,
                        ),
                      ],
                      if (place != null) ...[
                        const SizedBox(height: 16),
                        _metaRow(
                          e.isOnline
                              ? const Icon(IconsaxPlusBold.global, size: 16, color: AppColors.turquoise)
                              : SvgPicture.asset('assets/web/events/card_pin.svg', width: 12, height: 16),
                          place,
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: price == null
                                ? const SizedBox.shrink()
                                : Text(
                                    price,
                                    style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 20, fontWeight: FontWeight.w600,
                                        color: e.isFree ? AppColors.midBlue : AppColors.navy, height: 25 / 20),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                          // The interest count appears once somebody has
                          // RSVP'd. It used to be an invented figure on every
                          // card, and a live `rsvp_count` of nought would read
                          // as one.
                          if (e.rsvpCount > 0) ...[
                            SvgPicture.asset('assets/web/events/card_star.svg', width: 18, height: 18),
                            const SizedBox(width: 4),
                            Text(l.t('${e.rsvpCount} interested', '${e.rsvpCount} מתעניינים'),
                                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: _kBodyText, height: 17 / 14)),
                          ],
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

  Widget _metaRow(Widget icon, String text, {bool ltr = false}) {
    Widget label = Text(
      text,
      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kGreyText, height: 17 / 14),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    // A clock time stays left to right inside the Hebrew layout.
    if (ltr) label = Directionality(textDirection: TextDirection.ltr, child: label);
    return Row(
      children: [
        SizedBox(width: 16, height: 16, child: Center(child: icon)),
        const SizedBox(width: 8),
        Flexible(child: label),
      ],
    );
  }
}

/// The white date badge on a photo: "AUG" over "21".
class WebEventDateBadge extends StatelessWidget {
  final String month;
  final int day;
  final double width;
  final EdgeInsets padding;
  const WebEventDateBadge({
    super.key,
    required this.month,
    required this.day,
    this.width = 57,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(month,
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.midBlue, height: 15 / 12),
              textAlign: TextAlign.center,
              maxLines: 1),
          const SizedBox(height: 4),
          Text(day.toString().padLeft(2, '0'),
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black, height: 22 / 18),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// The turquoise category pill.
class WebEventCategoryPill extends StatelessWidget {
  final String label;
  final double fontSize;
  final EdgeInsets padding;
  const WebEventCategoryPill({
    super.key,
    required this.label,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.turquoise,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(label,
          style: TextStyle(fontFamily: AppFonts.inter, fontSize: fontSize, fontWeight: FontWeight.w500, color: Colors.white, height: 1.21),
          maxLines: 1),
    );
  }
}
