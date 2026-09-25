import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../models/event.dart';
import '../providers/event_providers.dart';

// ═══════════════════════════════════════════════════════════
// Web Events — full desktop layout from Figma
// (Events — 1920 × 3535)
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF5F5E5A);
const _kBodyText = Color(0xFF3D3D3D);
const _kIconGrey = Color(0xFF6D6D6D);
const _kPlaceholder = Color(0xFF4F4F4F);

/// How many cards the grid opens with, and how many each "Load More" adds.
///
/// Both used to run against a fixed pool of sixteen hand-written cards, and
/// the grid repeated that pool with `events[i % events.length]` up to a cap of
/// 32 — so "Load More" showed the same events again rather than more of them.
/// They count real rows now, and the button only appears when there are rows
/// left to show.
const _kFirstPage = 12;
const _kPageStep = 8;

/// Every event card, every category tile and every count on this page was
/// written into the source: sixteen invented events with invented venues,
/// prices and interest figures, and six category circles reading 157, 32, 24,
/// 45, 15 and 41. Every card opened `/event/demo_$i`, which matches no row.
///
/// The grid reads `events` now. The category circles are gone: there is no
/// category on an event, so the row could only ever have been decoration with
/// numbers on it.
class WebEventsContent extends ConsumerStatefulWidget {
  const WebEventsContent({super.key});

  @override
  ConsumerState<WebEventsContent> createState() => _WebEventsContentState();
}

class _WebEventsContentState extends ConsumerState<WebEventsContent> {
  bool _isHebrew = false;
  int _visibleCount = _kFirstPage;
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

  /// The month on a date badge, in the language being shown.
  String _month(DateTime date) {
    const en = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    const he = [
      'ינו׳', 'פבר׳', 'מרץ', 'אפר׳', 'מאי', 'יונ׳',
      'יול׳', 'אוג׳', 'ספט׳', 'אוק׳', 'נוב׳', 'דצמ׳',
    ];
    return (_isHebrew ? he : en)[date.month - 1];
  }

  /// What the ticket costs, or null when the row does not say.
  ///
  /// `Event.displayPrice` answers in Hebrew, so the free case is worded here
  /// instead — this layout is shown in both languages.
  String? _price(Event e) {
    if (e.isFree) return _t('FREE', 'חינם');
    final p = e.price;
    if (p == null || p.isEmpty) return null;
    return p.startsWith('₪') ? p : '₪$p';
  }

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
      if (mounted) setState(() => _visibleCount = _kFirstPage);
    });
  }

  void _onSearch() {
    _debounce?.cancel();
    ref.read(eventSearchProvider.notifier).state = _searchController.text;
    setState(() => _visibleCount = _kFirstPage);
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
  // EVENTS IN MODIIN — card grid + fade + Load More
  // ─────────────────────────────────────────────
  Widget _buildEventsSection() {
    final events = ref.watch(filteredEventsProvider);

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
            events.when(
              loading: _buildGridSkeleton,
              error: (_, _) => _buildErrorState(),
              data: (list) => list.isEmpty ? _buildEmptyState() : _buildGrid(list),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<Event> events) {
    final visible = events.take(_visibleCount).toList();
    final hasMore = visible.length < events.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  children: [
                    for (final event in visible)
                      SizedBox(
                        width: cardWidth,
                        child: _EventCard(
                          event: event,
                          month: event.startDate == null ? null : _month(event.startDate!),
                          price: _price(event),
                          interestedLabel: _t('interested', 'מתעניינים'),
                          onTap: () => context.push('/event/${event.id}'),
                        ),
                      ),
                  ],
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
                child: Center(child: _loadMoreButton(events.length)),
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
      ],
    );
  }

  Widget _loadMoreButton(int total) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(
            () => _visibleCount = (_visibleCount + _kPageStep).clamp(0, total)),
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
  // LOADING · EMPTY · ERROR
  // ─────────────────────────────────────────────
  /// Three rows of card-shaped blocks, so the grid does not jump when the
  /// rows land.
  Widget _buildGridSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 24.0;
        final cols = constraints.maxWidth > 1400
            ? 4
            : (constraints.maxWidth > 1000 ? 3 : 2);
        final cardWidth = (constraints.maxWidth - (cols - 1) * gap) / cols;
        return Skeleton(
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: List.generate(cols * 2, (_) {
              return SizedBox(
                width: cardWidth,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 200, radius: 12),
                    SizedBox(height: 16),
                    SkeletonLine(width: 220, fontSize: 20),
                    SizedBox(height: 14),
                    SkeletonLine(width: 140),
                    SizedBox(height: 8),
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

  // ─────────────────────────────────────────────
  // FOOTER
  // ─────────────────────────────────────────────
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

// ─────────────────────────────────────────────
// EVENT CARD — 382 × 364
// ─────────────────────────────────────────────
class _EventCard extends StatefulWidget {
  final Event event;

  /// The month on the date badge, or null when the row has no start date.
  final String? month;

  /// What it costs, or null when the row does not say — in which case the
  /// slot is left empty rather than filled with a zero.
  final String? price;
  final String interestedLabel;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.month,
    required this.price,
    required this.interestedLabel,
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
    final month = widget.month;
    final price = widget.price;
    final time = e.displayTime;
    final place = e.venueName ?? (e.address.isEmpty ? null : e.address);

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
                      child: NetworkPhoto(
                        url: e.imageUrl,
                        radius: const BorderRadius.vertical(top: Radius.circular(11)),
                        icon: IconsaxPlusBold.calendar_1,
                        iconSize: 34,
                      ),
                    ),
                    // Save — writes to `favorites`. It used to hold a set of
                    // grid indexes in the page's own state, so it forgot
                    // everything on reload and told nobody.
                    PositionedDirectional(
                      start: 12,
                      top: 12,
                      child: FavoriteButton(
                        kind: FavoriteKind.event,
                        id: e.id,
                        size: 40,
                        iconSize: 20,
                      ),
                    ),
                    // A turquoise category pill sat here. Events carry no
                    // category, so it named one of five invented ones.
                    // Date badge
                    if (month != null)
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
                              Text(month,
                                  style: TextStyle(fontFamily: AppFonts.inter,
                                      fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.midBlue, height: 1.25)),
                              const SizedBox(height: 4),
                              Text('${e.startDate!.day}',
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
                      if (time != null) _metaRow(IconsaxPlusBold.clock, time),
                      if (time != null) const SizedBox(height: 8),
                      if (e.isOnline)
                        _metaRow(IconsaxPlusBold.global, _onlineLabel(context))
                      else if (place != null)
                        _metaRow(IconsaxPlusBold.location, place),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (price != null)
                            Flexible(
                              child: Text(
                                price,
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
                          // The interest count only appears once somebody has
                          // RSVP'd. It used to be an invented figure on every
                          // card, and a live `rsvp_count` of nought would read
                          // as one.
                          if (e.rsvpCount > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(IconsaxPlusBold.star_1, size: 18, color: AppColors.turquoise),
                                const SizedBox(width: 4),
                                Text('${e.rsvpCount} ${widget.interestedLabel}',
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

  /// "Online" reads off the surrounding layout's direction, because the card
  /// does not carry the page's language flag.
  String _onlineLabel(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl ? 'אונליין' : 'Online';

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
