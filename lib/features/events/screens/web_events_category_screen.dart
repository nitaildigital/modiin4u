import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../providers/event_providers.dart';

// ═══════════════════════════════════════════════════════════
// Web Events Category — three-panel layout from the Figma
// export "Event Category" (1920 × 960).
// Left: filter sidebar 294 | Center: results 900 | Right: map 726
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kSidebarBg = Color(0xFFF7F8FA);
const _kTextDark = Color(0xFF3D3D3D);
const _kTextGrey = Color(0xFF6D6D6D);
const _kSubtitle = Color(0xFF5F5E5A);
const _kCheckBorder = Color(0xFF7B899A);
const _kPinPurple = Color(0xFF9032E1);

/// How the list is ordered. Both options read `start_date`, which is the only
/// thing on an event that can be ordered.
enum _Sort { soonest, latest }

/// The three-panel events browser.
///
/// The list, the map pins and the sidebar counts were all written into the
/// source: twelve invented events at invented coordinates, a category filter
/// offering five categories that no column holds, counts of 157/32/24/45/15 and
/// 157/117/40, a sort box that was a `Text` with a chevron beside it, and rows
/// and pins that both opened `/event/demo_$i`.
///
/// It reads `events` now. The category filter is gone — an event has no
/// category — and the price filter counts the rows it is looking at.
class WebEventsCategoryContent extends ConsumerStatefulWidget {
  const WebEventsCategoryContent({super.key});

  @override
  ConsumerState<WebEventsCategoryContent> createState() =>
      _WebEventsCategoryContentState();
}

class _WebEventsCategoryContentState
    extends ConsumerState<WebEventsCategoryContent> {
  bool _isHebrew = false;
  final _searchController = TextEditingController();
  final _listController = ScrollController();
  final _mapController = MapController();
  Timer? _debounce;

  String _price = 'all'; // all | free | paid
  _Sort _sort = _Sort.soonest;

  /// The event the cursor is over, in the list or on the map, so the two
  /// panels highlight together. It was an index into the invented list.
  String? _hoveredId;

  /// Modiin city centre — where the map opens before it knows better.
  static const _center = LatLng(31.8928, 35.0104);

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(eventSearchProvider);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _listController.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      ref.read(eventSearchProvider.notifier).state = value;
    });
  }

  // ── Reading a row ──

  String _shortMonth(DateTime date) {
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

  String? _timeRange(Event e) {
    if (e.isAllDay) return _t('All day', 'כל היום');
    final start = e.displayTime;
    if (start == null) return null;
    final endParts = (e.endTime ?? '').split(':');
    if (endParts.length < 2) return start;
    return '$start – ${endParts[0]}:${endParts[1]}';
  }

  /// `Event.displayPrice` answers in Hebrew only, and this layout is shown in
  /// both languages.
  String? _priceOf(Event e) {
    if (e.isFree) return _t('FREE', 'חינם');
    final p = e.price;
    if (p == null || p.isEmpty) return null;
    return p.startsWith('₪') ? p : '₪$p';
  }

  String? _place(Event e) {
    if (e.isOnline) return _t('Online', 'אונליין');
    final address = e.address;
    if (address.isNotEmpty) return address;
    return e.venueName;
  }

  bool _hasCoordinates(Event e) =>
      !e.isOnline && e.latitude != 0 && e.longitude != 0;

  /// The rows the panels are showing: the searched set, narrowed by price and
  /// put in the chosen order.
  List<Event> _visible(List<Event> events) {
    final filtered = events.where((e) {
      if (_price == 'free') return e.isFree;
      if (_price == 'paid') return !e.isFree;
      return true;
    }).toList();

    filtered.sort((a, b) {
      final x = a.startsAt;
      final y = b.startsAt;
      // Rows without a date sort last either way, rather than jumping to the
      // top as an epoch-zero date would.
      if (x == null || y == null) return x == null ? 1 : -1;
      return _sort == _Sort.soonest ? x.compareTo(y) : y.compareTo(x);
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(filteredEventsProvider);

    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // The page carried its own copy of the navbar, including a
            // "Contact Us" button whose handler was empty. It uses the shared
            // chrome now, like the rest of the desktop pages.
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: 'events',
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFilterSidebar(events.valueOrNull ?? const []),
                  Expanded(flex: 900, child: _buildResultsPanel(events)),
                  Expanded(
                    flex: 726,
                    child: _buildMapPanel(events.valueOrNull ?? const []),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FILTER SIDEBAR — 294px
  // ─────────────────────────────────────────────
  Widget _buildFilterSidebar(List<Event> events) {
    // The counts beside each option are of the rows in hand. They were fixed
    // numbers that no query produced.
    final free = events.where((e) => e.isFree).length;
    final options = [
      _Option('all', _t('All', 'הכל'), events.length),
      _Option('free', _t('Free', 'חינם'), free),
      _Option('paid', _t('Paid', 'בתשלום'), events.length - free),
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
            const SizedBox(height: 24),
            // An "Event Category" group sat above this one, offering Music,
            // Kids & Family, Sports and the rest. `events` has no category
            // column, so nothing could have answered it.
            _buildFilterGroup(
              title: _t('Price', 'מחיר'),
              options: options,
              isChecked: (o) => _price == o.key,
              onTap: (o) => setState(() => _price = o.key),
            ),
          ],
        ),
      ),
    );
  }

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
          const Icon(IconsaxPlusLinear.search_normal_1, size: 16, color: AppColors.midBlue),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: AppColors.navy),
              decoration: InputDecoration(
                hintText: _t('Search events or places...', 'חיפוש אירועים או מקומות...'),
                hintStyle: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kTextGrey),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterGroup({
    required String title,
    required List<_Option> options,
    required bool Function(_Option) isChecked,
    required void Function(_Option) onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontFamily: AppFonts.inter,
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
        const SizedBox(height: 17),
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _checkboxRow(
            option: options[i],
            checked: isChecked(options[i]),
            onTap: () => onTap(options[i]),
          ),
        ],
      ],
    );
  }

  Widget _checkboxRow({
    required _Option option,
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
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: checked ? AppColors.midBlue : Colors.white,
                border: Border.all(
                  color: checked ? AppColors.midBlue : _kCheckBorder,
                  width: checked ? 1 : 0.89,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(option.label,
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: _kTextDark, height: 16 / 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Text('${option.count}',
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: _kTextDark, height: 16 / 13)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // RESULTS PANEL — 900px
  // ─────────────────────────────────────────────
  Widget _buildResultsPanel(AsyncValue<List<Event>> events) {
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
              child: _buildResultsHeader(null),
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
          final visible = _visible(all);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _buildResultsHeader(visible.length),
              ),
              const SizedBox(height: 26),
              Expanded(
                child: visible.isEmpty
                    ? _buildEmptyState()
                    : Scrollbar(
                        controller: _listController,
                        child: ListView.builder(
                          controller: _listController,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: visible.length,
                          itemBuilder: (context, i) {
                            final event = visible[i];
                            return _EventListRow(
                              event: event,
                              isHebrew: _isHebrew,
                              month: event.startDate == null
                                  ? null
                                  : _shortMonth(event.startDate!),
                              time: _timeRange(event),
                              place: _place(event),
                              price: _priceOf(event),
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

  Widget _buildResultsHeader(int? count) {
    // The headline named a category — "24 Music Events found" — from a filter
    // with nothing behind it.
    final headline = count == null
        ? _t('Events in Modiin', 'אירועים במודיעין')
        : _t('$count Events found', '$count אירועים נמצאו');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(headline,
                  style: TextStyle(fontFamily: AppFonts.nunito,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      height: 34 / 28,
                      color: AppColors.midBlue)),
              const SizedBox(height: 8),
              Text(_t('in Modiin Maccabim Reut', 'במודיעין מכבים רעות'),
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kSubtitle)),
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
      onSelected: (value) => setState(() => _sort = value),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _Sort.soonest,
          child: Text(_t('Soonest first', 'הקרוב ביותר'),
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14)),
        ),
        PopupMenuItem(
          value: _Sort.latest,
          child: Text(_t('Latest first', 'המרוחק ביותר'),
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14)),
        ),
      ],
      child: Container(
        width: 190,
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _sort == _Sort.soonest
                    ? _t('Sort by: Soonest', 'מיון: הקרוב ביותר')
                    : _t('Sort by: Latest', 'מיון: המרוחק ביותר'),
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: Colors.black),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF4F4F4F)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final searching = ref.watch(eventSearchProvider).trim().isNotEmpty;
    final filtering = _price != 'all';
    return _buildNotice(
      icon: searching || filtering
          ? IconsaxPlusLinear.search_status
          : IconsaxPlusLinear.calendar_1,
      title: searching || filtering
          ? _t('No events match your filters', 'אין אירועים שתואמים את הסינון')
          : _t('No events listed yet', 'עדיין לא פורסמו אירועים'),
      body: searching || filtering
          ? _t('Try clearing a filter or searching for something else.',
              'נסו להסיר סינון או לחפש משהו אחר.')
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
            Icon(icon, size: 48, color: _kCheckBorder.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontFamily: AppFonts.nunito,
                  fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.navy),
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
                        style: TextStyle(fontFamily: AppFonts.inter,
                            fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
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
  Widget _buildMapPanel(List<Event> events) {
    // An online event, or one whose row has no coordinates, gets no pin
    // rather than a pin somewhere plausible.
    final pinned = _visible(events).where(_hasCoordinates).toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 14.2,
        onTap: (_, _) => setState(() => _hoveredId = null),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.modiin4u.app',
        ),
        MarkerLayer(
          markers: [
            for (final event in pinned)
              Marker(
                point: LatLng(event.latitude, event.longitude),
                width: 40,
                height: 44,
                alignment: Alignment.topCenter,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _hoveredId = event.id),
                  onExit: (_) => setState(() {
                    if (_hoveredId == event.id) _hoveredId = null;
                  }),
                  child: GestureDetector(
                    onTap: () => context.push('/event/${event.id}'),
                    child: _MapPin(selected: _hoveredId == event.id),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// RESULT ROW — 851 × 203
// ═══════════════════════════════════════════════
class _EventListRow extends StatelessWidget {
  final Event event;
  final bool isHebrew, selected;

  /// Null where the row does not carry the value, in which case the line is
  /// left out rather than filled in.
  final String? month, time, place, price;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _EventListRow({
    required this.event,
    required this.isHebrew,
    required this.month,
    required this.time,
    required this.place,
    required this.price,
    required this.selected,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final e = event;
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
            color: selected ? _kSidebarBg : Colors.transparent,
            border: const Border(bottom: BorderSide(color: _kBorder)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail 261 × 162 with date badge ──
              SizedBox(
                width: 261,
                height: 162,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: NetworkPhoto(
                        url: e.imageUrl,
                        radius: BorderRadius.circular(12),
                        icon: IconsaxPlusBold.calendar_1,
                        iconSize: 30,
                      ),
                    ),
                    if (month != null)
                      PositionedDirectional(
                        start: 8,
                        top: 8,
                        child: Container(
                          width: 52,
                          height: 57,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(month!,
                                  style: TextStyle(fontFamily: AppFonts.inter,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.midBlue,
                                      height: 15 / 12)),
                              const SizedBox(height: 4),
                              Text('${e.startDate!.day}',
                                  style: TextStyle(fontFamily: AppFonts.inter,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                      height: 22 / 18)),
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
                                    style: TextStyle(fontFamily: AppFonts.nunito,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.navy,
                                        height: 22 / 18),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 12),
                                if (time != null) ...[
                                  _metaRow(IconsaxPlusLinear.clock, time!,
                                      forceLtr: true),
                                  const SizedBox(height: 12),
                                ],
                                if (place != null)
                                  _metaRow(
                                    e.isOnline
                                        ? IconsaxPlusLinear.global
                                        : IconsaxPlusLinear.location,
                                    place!,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 22),
                          // Saving held a set of row indexes in the page's
                          // own state, so it was forgotten on reload.
                          FavoriteButton(
                            kind: FavoriteKind.event,
                            id: e.id,
                            size: 40,
                            iconSize: 20,
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 100,
                            child: price == null
                                ? const SizedBox.shrink()
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(isHebrew ? 'מחיר' : 'Price',
                                          style: TextStyle(fontFamily: AppFonts.inter,
                                              fontSize: 14, color: _kSubtitle, height: 17 / 14)),
                                      const SizedBox(height: 4),
                                      Text(price!,
                                          style: TextStyle(fontFamily: AppFonts.nunito,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w600,
                                              color: e.isFree ? AppColors.midBlue : AppColors.navy,
                                              height: 27 / 22)),
                                    ],
                                  ),
                          ),
                          const SizedBox(width: 20),
                          // The interest count appears once somebody has
                          // RSVP'd. It was an invented figure on every row.
                          Expanded(
                            flex: 146,
                            child: e.rsvpCount == 0
                                ? const SizedBox.shrink()
                                : Row(
                                    children: [
                                      const Icon(IconsaxPlusLinear.star_1,
                                          size: 14, color: AppColors.turquoise),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          isHebrew
                                              ? '${e.rsvpCount} מתעניינים'
                                              : '${e.rsvpCount} people interested',
                                          style: TextStyle(fontFamily: AppFonts.inter,
                                              fontSize: 12,
                                              color: Colors.black,
                                              height: 15 / 12),
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

  Widget _metaRow(IconData icon, String text, {bool forceLtr = false}) {
    Widget label = Text(text,
        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: _kTextDark, height: 15 / 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis);
    // Clock ranges stay left-to-right even in the Hebrew layout.
    if (forceLtr) {
      label = Align(
        alignment: AlignmentDirectional.centerStart,
        child: Directionality(textDirection: TextDirection.ltr, child: label),
      );
    }
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.turquoise),
        const SizedBox(width: 8),
        Expanded(child: label),
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
            border: Border.all(color: AppColors.midBlue),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(IconsaxPlusLinear.export_3, size: 16, color: AppColors.midBlue),
              const SizedBox(width: 8),
              Text(isHebrew ? 'לפרטים' : 'View Detail',
                  style: TextStyle(fontFamily: AppFonts.inter,
                      fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.midBlue)),
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
            padding: EdgeInsets.only(bottom: 20),
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
                      SizedBox(height: 28),
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
// MAP PIN — Ellipse 521 · #9032E1
// ═══════════════════════════════════════════════
class _MapPin extends StatelessWidget {
  final bool selected;
  const _MapPin({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 150),
      scale: selected ? 1.15 : 1.0,
      child: SizedBox(
        width: 40,
        height: 44,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            const Icon(
              IconsaxPlusBold.location,
              size: 40,
              color: Colors.white,
              shadows: [
                Shadow(color: Color(0x40000000), blurRadius: 2.29, offset: Offset(0, 2.29)),
              ],
            ),
            Positioned(
              top: 5.8,
              child: Container(
                width: 21.4,
                height: 21.4,
                decoration: const BoxDecoration(color: _kPinPurple, shape: BoxShape.circle),
                child: const Center(
                  child: Icon(IconsaxPlusLinear.calendar, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════

class _Option {
  final String key, label;
  final int count;
  const _Option(this.key, this.label, this.count);
}
