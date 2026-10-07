import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../models/event.dart';
import '../models/event_category.dart';
import '../models/event_labels.dart';
import '../providers/event_providers.dart';
import '../../../shared/widgets/web_map_tiles.dart';

// ═══════════════════════════════════════════════════════════
// Web Events Category — three-panel layout from the Figma
// frame "Event Category" (1920 × 960).
// Left: filter sidebar 294 | Center: results 900 | Right: map 726
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kSidebarBg = Color(0xFFF7F8FA);
const _kTextDark = Color(0xFF3D3D3D);
const _kTextGrey = Color(0xFF6D6D6D);
const _kSubtitle = Color(0xFF5F5E5A);
const _kRowHover = Color(0xFFF7F8FA);

/// How the list is ordered. The design's box reads "Sort by: Newest": the
/// most recently published first. Soonest orders by when the event is.
enum _Sort { newest, soonest }

/// The events browser a category circle opens: every upcoming event, narrowed
/// by category, price and place, with each one pinned on the map beside it.
///
/// Its list, pins and sidebar counts were all written into the source once:
/// twelve invented events at invented coordinates, counts of 157/32/24/45/15
/// and 157/117/40, a sort box that was a `Text` with a chevron beside it, and
/// rows and pins that both opened `/event/demo_$i`.
///
/// It reads `events`, `categories` and `entity_categories` now, and each count
/// is of the upcoming events that option would show.
class WebEventsCategoryContent extends ConsumerStatefulWidget {
  /// Where the page opens: `all`, `free`, or a category's slug — whatever
  /// followed `?category=` in the address.
  final String initialFilter;
  const WebEventsCategoryContent({super.key, this.initialFilter = 'all'});

  @override
  ConsumerState<WebEventsCategoryContent> createState() =>
      _WebEventsCategoryContentState();
}

class _WebEventsCategoryContentState extends ConsumerState<WebEventsCategoryContent>
    with WebLanguageState<WebEventsCategoryContent> {
  bool get _isHebrew => webIsHebrew.value;
  final _searchController = TextEditingController();
  final _listController = ScrollController();
  final _mapController = MapController();

  /// The categories ticked, by slug. Empty means "All Events".
  final Set<String> _categories = {};
  String _price = 'all'; // all | free | paid
  _Sort _sort = _Sort.newest;
  String _place = '';

  /// The event the cursor is over, in the list or on the map, so the two
  /// panels highlight together.
  String? _hoveredId;

  bool _mapReady = false;
  String _fittedTo = '';

  /// Modiin city centre — where the map opens before it knows better.
  static const _center = LatLng(31.8928, 35.0104);

  @override
  void initState() {
    super.initState();
    switch (widget.initialFilter) {
      case 'all':
        break;
      case 'free':
        _price = 'free';
      default:
        _categories.add(widget.initialFilter);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listController.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;
  EventLabels get _labels => EventLabels(_isHebrew);

  bool _hasCoordinates(Event e) =>
      !e.isOnline && e.latitude != 0 && e.longitude != 0;

  bool _inCategories(Event e, Map<String, List<EventCategory>> byEvent) {
    if (_categories.isEmpty) return true;
    return (byEvent[e.id] ?? const []).any((c) => _categories.contains(c.slug));
  }

  bool _atPrice(Event e) => switch (_price) {
    'free' => e.isFree,
    'paid' => !e.isFree,
    _ => true,
  };

  /// "Search by location…" looks at where the event is — the venue and the
  /// address — and nothing else.
  bool _atPlace(Event e) {
    final q = _place.trim().toLowerCase();
    if (q.isEmpty) return true;
    return (e.venueName ?? '').toLowerCase().contains(q) ||
        e.address.toLowerCase().contains(q);
  }

  /// The rows the panels are showing, in the chosen order.
  List<Event> _visible(List<Event> events, Map<String, List<EventCategory>> byEvent) {
    final rows = events
        .where((e) => _inCategories(e, byEvent) && _atPrice(e) && _atPlace(e))
        .toList();

    int bySoonest(Event a, Event b) {
      final x = a.startsAt;
      final y = b.startsAt;
      // Rows without a date sort last, rather than jumping to the top as an
      // epoch-zero date would.
      if (x == null || y == null) return x == null ? (y == null ? 0 : 1) : -1;
      return x.compareTo(y);
    }

    rows.sort((a, b) {
      if (_sort == _Sort.soonest) return bySoonest(a, b);
      final x = a.publishedAt;
      final y = b.publishedAt;
      if (x == null || y == null) {
        return x == null ? (y == null ? bySoonest(a, b) : 1) : -1;
      }
      final c = y.compareTo(x);
      return c != 0 ? c : bySoonest(a, b);
    });
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(upcomingEventsProvider);
    final categories = ref.watch(eventCategoriesProvider).valueOrNull ?? const [];
    final byEvent =
        ref.watch(eventCategoriesByEventProvider).valueOrNull ?? const {};
    final all = events.valueOrNull ?? const <Event>[];

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
              child: LayoutBuilder(builder: (context, constraints) {
                // 900 : 726 at 1920, as drawn. On a narrower window the map
                // gives way first, so a result row keeps the 720 it needs for
                // its price, interest count and button side by side.
                final rest = constraints.maxWidth - 294;
                final results = (rest * 900 / 1626)
                    .clamp(math.min(720.0, rest - 360), rest - 360)
                    .toDouble();
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFilterSidebar(all, categories, byEvent),
                    SizedBox(
                      width: results,
                      child: _buildResultsPanel(events, categories, byEvent),
                    ),
                    Expanded(child: _buildMapPanel(_visible(all, byEvent))),
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
  // FILTER SIDEBAR — 294px
  // ─────────────────────────────────────────────
  Widget _buildFilterSidebar(
    List<Event> events,
    List<EventCategory> categories,
    Map<String, List<EventCategory>> byEvent,
  ) {
    // Each count is of all the upcoming events under that option, as drawn:
    // the design's price counts do not move when Music is ticked.
    int inCategory(EventCategory c) => events
        .where((e) => (byEvent[e.id] ?? const []).any((x) => x.id == c.id))
        .length;
    final free = events.where((e) => e.isFree).length;

    // A category with nothing coming is left off the list, unless it is the
    // one the page was opened on.
    final shown = [
      for (final c in categories)
        if (inCategory(c) > 0 || _categories.contains(c.slug)) c,
    ];

    return Container(
      width: 294,
      decoration: const BoxDecoration(
        color: _kSidebarBg,
        border: BorderDirectional(end: BorderSide(color: _kBorder)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBox(),
            const SizedBox(height: 16),
            _groupTitle(_t('Event Category', 'קטגוריית אירוע')),
            const SizedBox(height: 17),
            _checkboxRow(
              label: _t('All Events', 'כל האירועים'),
              count: events.length,
              checked: _categories.isEmpty,
              onTap: () => setState(_categories.clear),
            ),
            for (final c in shown) ...[
              const SizedBox(height: 14),
              _checkboxRow(
                label: _labels.category(c),
                count: inCategory(c),
                checked: _categories.contains(c.slug),
                onTap: () => setState(() {
                  if (!_categories.remove(c.slug)) _categories.add(c.slug);
                }),
              ),
            ],
            const SizedBox(height: 24),
            _groupTitle(_t('Price', 'מחיר')),
            const SizedBox(height: 17),
            _checkboxRow(
              label: _t('All', 'הכל'),
              count: events.length,
              checked: _price == 'all',
              onTap: () => setState(() => _price = 'all'),
            ),
            const SizedBox(height: 14),
            _checkboxRow(
              label: _t('Free', 'חינם'),
              count: free,
              checked: _price == 'free',
              onTap: () => setState(() => _price = _price == 'free' ? 'all' : 'free'),
            ),
            const SizedBox(height: 14),
            _checkboxRow(
              label: _t('Paid', 'בתשלום'),
              count: events.length - free,
              checked: _price == 'paid',
              onTap: () => setState(() => _price = _price == 'paid' ? 'all' : 'paid'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupTitle(String text) => Text(text,
      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy, height: 17 / 14));

  Widget _buildSearchBox() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SvgPicture.asset('assets/web/events/search_location.svg', width: 16, height: 16),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _place = v),
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: AppColors.navy),
              decoration: InputDecoration(
                hintText: _t('Search by location...', 'חיפוש לפי מיקום...'),
                hintStyle: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kTextGrey),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkboxRow({
    required String label,
    required int count,
    required bool checked,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            SvgPicture.asset(
              checked ? 'assets/web/events/check_on.svg' : 'assets/web/events/check_off.svg',
              width: 16,
              height: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: _kTextDark, height: 16 / 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 68,
              child: Text('$count',
                  textAlign: TextAlign.end,
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: _kTextDark, height: 16 / 13)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // RESULTS PANEL — 900px
  // ─────────────────────────────────────────────
  Widget _buildResultsPanel(
    AsyncValue<List<Event>> events,
    List<EventCategory> categories,
    Map<String, List<EventCategory>> byEvent,
  ) {
    return Container(
      decoration: const BoxDecoration(
        border: BorderDirectional(end: BorderSide(color: _kBorder)),
      ),
      child: events.when(
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: _buildResultsHeader(null, categories),
            ),
            const SizedBox(height: 26),
            const Expanded(child: _ResultsSkeleton()),
          ],
        ),
        error: (_, _) => _buildNotice(
          icon: IconsaxPlusLinear.wifi_square,
          title: _t('Events could not be loaded', 'לא ניתן לטעון את האירועים'),
          body: _t('Check your connection and try again.',
              'בדקו את החיבור לאינטרנט ונסו שוב.'),
          actionLabel: _t('Try again', 'נסו שוב'),
          onAction: () => ref.invalidate(eventsProvider),
        ),
        data: (all) {
          final visible = _visible(all, byEvent);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 25, 0),
                child: _buildResultsHeader(visible.length, categories),
              ),
              const SizedBox(height: 26),
              Expanded(
                child: visible.isEmpty
                    ? _buildEmptyState()
                    : Scrollbar(
                        controller: _listController,
                        child: ListView.builder(
                          controller: _listController,
                          padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 25, 24),
                          itemCount: visible.length,
                          itemBuilder: (context, i) {
                            final event = visible[i];
                            return _EventListRow(
                              event: event,
                              labels: _labels,
                              selected: _hoveredId == event.id,
                              onTap: () => context.push('/event/${event.id}'),
                              onHover: (hovering) => setState(() {
                                if (hovering) {
                                  _hoveredId = event.id;
                                } else if (_hoveredId == event.id) {
                                  _hoveredId = null;
                                }
                              }),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// "24 Music Events found" when one category is ticked, "24 Events found"
  /// otherwise.
  Widget _buildResultsHeader(int? count, List<EventCategory> categories) {
    EventCategory? only;
    if (_categories.length == 1) {
      for (final c in categories) {
        if (c.slug == _categories.first) only = c;
      }
    }
    final name = only == null ? null : _labels.category(only);
    final String headline;
    if (count == null) {
      headline = _t('Events in Modiin', 'אירועים במודיעין');
    } else if (name != null) {
      headline = _t('$count $name Events found', 'נמצאו $count אירועים בקטגוריית $name');
    } else {
      headline = _t('$count Events found', 'נמצאו $count אירועים');
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(headline,
                  style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 28, fontWeight: FontWeight.w600, height: 34 / 28, color: AppColors.midBlue),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Text(_t('in Modiin Maccabim Reut', 'במודיעין מכבים רעות'),
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kSubtitle, height: 17 / 14)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _buildSortBox(),
      ],
    );
  }

  /// The sort control. It was a `Text` reading "Sort by: Newest" with a chevron
  /// drawn beside it and no menu behind either, so the order never changed.
  Widget _buildSortBox() {
    return PopupMenuButton<_Sort>(
      initialValue: _sort,
      tooltip: '',
      position: PopupMenuPosition.under,
      color: Colors.white,
      onSelected: (value) => setState(() => _sort = value),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _Sort.newest,
          child: Text(_t('Newest', 'החדשים ביותר'),
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14)),
        ),
        PopupMenuItem(
          value: _Sort.soonest,
          child: Text(_t('Soonest', 'הקרובים ביותר'),
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14)),
        ),
      ],
      child: Container(
        height: 42,
        constraints: const BoxConstraints(minWidth: 166),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _sort == _Sort.newest
                  ? _t('Sort by: Newest', 'מיון: החדשים ביותר')
                  : _t('Sort by: Soonest', 'מיון: הקרובים ביותר'),
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: Colors.black, height: 17 / 14),
            ),
            const SizedBox(width: 13),
            SvgPicture.asset('assets/web/events/chevron_down.svg', width: 20, height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final filtering = _place.trim().isNotEmpty || _price != 'all' || _categories.isNotEmpty;
    return _buildNotice(
      icon: filtering ? IconsaxPlusLinear.search_status : IconsaxPlusLinear.calendar_1,
      title: filtering
          ? _t('No events match your filters', 'אין אירועים שתואמים את הסינון')
          : _t('No events listed yet', 'עדיין לא פורסמו אירועים'),
      body: filtering
          ? _t('Try clearing a filter or searching for somewhere else.',
              'נסו להסיר סינון או לחפש מקום אחר.')
          : _t('New events will appear here as they are published.',
              'אירועים חדשים יופיעו כאן עם פרסומם.'),
    );
  }

  Widget _buildNotice({
    required IconData icon,
    required String title,
    required String body,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: _kTextGrey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.navy),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kSubtitle),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onAction,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.midBlue,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Text(actionLabel,
                        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MAP PANEL — 726px, purple event pins
  // ─────────────────────────────────────────────
  /// Brings every pin into view whenever the set of pins changes — a filter
  /// ticked, a place typed — rather than leaving the map where it opened.
  void _fitTo(List<Event> pinned) {
    final key = pinned.map((e) => e.id).join(',');
    if (!_mapReady || pinned.isEmpty || key == _fittedTo) return;
    _fittedTo = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final points = [for (final e in pinned) LatLng(e.latitude, e.longitude)];
      if (points.length == 1) {
        _mapController.move(points.first, 15);
      } else {
        _mapController.fitCamera(CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.all(64),
          maxZoom: 16,
        ));
      }
    });
  }

  Widget _buildMapPanel(List<Event> visible) {
    // An online event, or one whose row has no coordinates, gets no pin
    // rather than a pin somewhere plausible.
    final pinned = visible.where(_hasCoordinates).toList();
    _fitTo(pinned);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 14.2,
        onMapReady: () => setState(() => _mapReady = true),
        onTap: (_, _) => setState(() => _hoveredId = null),
      ),
      children: [
        const WebMapTiles(),
        MarkerLayer(
          markers: [
            for (final event in pinned)
              Marker(
                point: LatLng(event.latitude, event.longitude),
                width: 40,
                height: 43,
                alignment: Alignment.topCenter,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _hoveredId = event.id),
                  onExit: (_) => setState(() {
                    if (_hoveredId == event.id) _hoveredId = null;
                  }),
                  child: GestureDetector(
                    onTap: () => context.push('/event/${event.id}'),
                    child: Tooltip(
                      message: event.title,
                      child: _MapPin(selected: _hoveredId == event.id),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const WebMapCredit(),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// RESULT ROW — 851 × 203
// ═══════════════════════════════════════════════
class _EventListRow extends StatelessWidget {
  final Event event;
  final EventLabels labels;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _EventListRow({
    required this.event,
    required this.labels,
    required this.selected,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final e = event;
    final l = labels;
    final date = e.startDate;
    final time = l.timeRange(e);
    final place = l.address(e);
    final price = l.price(e);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: selected ? _kRowHover : Colors.white,
            border: const Border(bottom: BorderSide(color: _kBorder)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Photo 261 × 162 with the date badge ──
              SizedBox(
                width: 261,
                height: 162,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: NetworkPhoto(
                        url: e.imageUrl,
                        width: 261,
                        height: 162,
                        radius: BorderRadius.circular(12),
                        icon: IconsaxPlusBold.calendar_1,
                        iconSize: 30,
                      ),
                    ),
                    if (date != null)
                      PositionedDirectional(
                        start: 8,
                        top: 8,
                        child: Container(
                          width: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(l.shortMonth(date),
                                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.midBlue, height: 15 / 12),
                                  maxLines: 1),
                              const SizedBox(height: 4),
                              Text(date.day.toString().padLeft(2, '0'),
                                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black, height: 22 / 18)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // ── Detail column ──
              Expanded(
                child: SizedBox(
                  height: 162,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.title,
                                    style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.navy, height: 22 / 18),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                if (time != null) ...[
                                  const SizedBox(height: 12),
                                  _metaRow('assets/web/events/row_clock.svg', time, ltr: true),
                                ],
                                if (place != null) ...[
                                  const SizedBox(height: 12),
                                  _metaRow('assets/web/events/row_pin.svg', place),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 22),
                          // Saving needs an account, which is the app's; on the
                          // website the heart draws nothing.
                          FavoriteButton(kind: FavoriteKind.event, id: e.id, size: 40, iconSize: 20),
                        ],
                      ),
                      // Price at the start; the interest count sits against
                      // the button, 20 before it, as drawn — and gives way
                      // first when the row is narrow.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (price != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(l.t('Price', 'מחיר'),
                                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kSubtitle, height: 17 / 14)),
                                const SizedBox(height: 4),
                                Text(price,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 22, fontWeight: FontWeight.w600,
                                        color: e.isFree ? AppColors.midBlue : AppColors.navy, height: 27 / 22)),
                              ],
                            ),
                          const SizedBox(width: 20),
                          Expanded(
                            // The interest count appears once somebody has
                            // RSVP'd. It was an invented figure on every row.
                            child: e.rsvpCount == 0
                                ? const SizedBox.shrink()
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      SvgPicture.asset('assets/web/events/row_people.svg', width: 14, height: 14),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text.rich(
                                          TextSpan(children: [
                                            TextSpan(text: '${e.rsvpCount} ', style: const TextStyle(color: Colors.black)),
                                            TextSpan(
                                              text: e.rsvpCount == 1
                                                  ? l.t('person interested', 'מתעניין')
                                                  : l.t('people interested', 'מתעניינים'),
                                            ),
                                          ]),
                                          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: _kTextDark, height: 15 / 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(width: 20),
                          _viewDetailButton(),
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

  Widget _metaRow(String icon, String text, {bool ltr = false}) {
    Widget label = Text(text,
        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: _kTextDark, height: 15 / 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis);
    // Clock ranges stay left to right even in the Hebrew layout.
    if (ltr) label = Directionality(textDirection: TextDirection.ltr, child: label);
    return Row(
      children: [
        SvgPicture.asset(icon, width: 14, height: 14),
        const SizedBox(width: 8),
        Flexible(child: label),
      ],
    );
  }

  Widget _viewDetailButton() {
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
              SvgPicture.asset('assets/web/events/row_eye.svg', width: 16, height: 16),
              const SizedBox(width: 8),
              Text(labels.t('View Detail', 'לפרטים'),
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.midBlue, height: 24 / 14)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three result rows' worth of blocks, at the geometry of the real row.
class _ResultsSkeleton extends StatelessWidget {
  const _ResultsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 261, height: 162, radius: 12),
                SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLine(width: 280, fontSize: 18),
                      SizedBox(height: 14),
                      SkeletonLine(width: 160, fontSize: 12),
                      SizedBox(height: 12),
                      SkeletonLine(width: 220, fontSize: 12),
                      SizedBox(height: 40),
                      SkeletonLine(width: 120, fontSize: 22),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// MAP PIN — the design's white teardrop, purple disc, calendar
// ═══════════════════════════════════════════════
class _MapPin extends StatelessWidget {
  final bool selected;
  const _MapPin({required this.selected});

  @override
  Widget build(BuildContext context) {
    // flutter_svg does not draw the SVG's drop-shadow filter; a soft shadow
    // is painted under it instead.
    return AnimatedScale(
      duration: const Duration(milliseconds: 150),
      scale: selected ? 1.15 : 1.0,
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: 40,
        height: 43,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 6,
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2.3))],
                ),
              ),
            ),
            SvgPicture.asset('assets/web/events/map_pin.svg', width: 40, height: 43),
          ],
        ),
      ),
    );
  }
}
