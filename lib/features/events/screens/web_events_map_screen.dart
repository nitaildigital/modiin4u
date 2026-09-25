import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../models/event.dart';
import '../providers/event_providers.dart';

// ═══════════════════════════════════════════════════════════
// Web Events Map — desktop layout for /events-map
//
// The mobile screen is a 430px map with the selected event in a card floating
// over it, so only one of the nine can be read at a time. On a laptop the
// events move into a panel of their own beside a full-height map, the same
// shape web_restaurants_map_screen.dart uses for places.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kSubtitle = Color(0xFF5F5E5A);
const _kTextGrey = Color(0xFF6D6D6D);
const _kEventPurple = Color(0xFF9032E1);

class WebEventsMapContent extends ConsumerStatefulWidget {
  const WebEventsMapContent({super.key});

  @override
  ConsumerState<WebEventsMapContent> createState() =>
      _WebEventsMapContentState();
}

class _WebEventsMapContentState extends ConsumerState<WebEventsMapContent> {
  bool _isHebrew = false;
  String? _selectedId;

  final _searchController = TextEditingController();
  final _listController = ScrollController();
  final _mapController = MapController();
  Timer? _debounce;

  static const _center = LatLng(31.8928, 35.0104);

  static const _monthsEn = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _monthsHe = [
    'ינו׳',
    'פבר׳',
    'מרץ',
    'אפר׳',
    'מאי',
    'יונ׳',
    'יול׳',
    'אוג׳',
    'ספט׳',
    'אוק׳',
    'נוב׳',
    'דצמ׳',
  ];

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

  String _month(DateTime d) => (_isHebrew ? _monthsHe : _monthsEn)[d.month - 1];

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
            // A share of the window rather than a fixed width, so a 1101px
            // laptop does not end up with a map no wider than the list.
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final panelWidth = (constraints.maxWidth * 0.38).clamp(
                    360.0,
                    560.0,
                  );
                  return Row(
                    children: [
                      SizedBox(width: panelWidth, child: _buildListPanel()),
                      Expanded(child: _buildMapPanel()),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LIST PANEL — the events, scrolling on their own
  // ─────────────────────────────────────────────
  Widget _buildListPanel() {
    final events = ref.watch(filteredEventsProvider);
    final rows = events.valueOrNull ?? const <Event>[];

    return Container(
      decoration: const BoxDecoration(
        border: BorderDirectional(end: BorderSide(color: _kBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _buildPanelHeader(rows),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: events.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _buildNotice(
                icon: IconsaxPlusLinear.wifi_square,
                title: _t(
                  'Events could not be loaded',
                  'לא ניתן לטעון את האירועים',
                ),
                body: _t(
                  'Check your connection and try again.',
                  'בדקו את החיבור לאינטרנט ונסו שוב.',
                ),
              ),
              data: (all) => all.isEmpty
                  ? _buildNotice(
                      icon: IconsaxPlusLinear.calendar_1,
                      title: _searchController.text.trim().isEmpty
                          ? _t('No events coming up', 'אין אירועים קרובים')
                          : _t(
                              'No events match your search',
                              'אין אירועים שתואמים את החיפוש',
                            ),
                      body: _t(
                        'Try another word, or come back closer to the weekend.',
                        'נסו מילה אחרת, או חזרו לקראת סוף השבוע.',
                      ),
                    )
                  : Scrollbar(
                      controller: _listController,
                      child: ListView.builder(
                        controller: _listController,
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount: all.length,
                        itemBuilder: (context, i) {
                          final e = all[i];
                          final date = e.startDate;
                          return _EventRow(
                            event: e,
                            isHebrew: _isHebrew,
                            selected: _selectedId == e.id,
                            dayLabel: date == null ? null : '${date.day}',
                            monthLabel: date == null ? null : _month(date),
                            onMapLabel: _hasPin(e)
                                ? null
                                : _t('Not on the map', 'לא על המפה'),
                            onTap: () => context.push('/event/${e.id}'),
                            onHover: (hovering) => _hover(e, hovering),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// An online event has no coordinates, so it is in the panel but not on the
  /// map. The row says so rather than looking like a pin that went missing.
  static bool _hasPin(Event e) => e.latitude != 0 && e.longitude != 0;

  void _hover(Event event, bool hovering) {
    setState(() {
      if (hovering) {
        _selectedId = event.id;
      } else if (_selectedId == event.id) {
        _selectedId = null;
      }
    });
    if (hovering && _hasPin(event)) {
      _mapController.move(
        LatLng(event.latitude, event.longitude),
        _mapController.camera.zoom,
      );
    }
  }

  Widget _buildPanelHeader(List<Event> rows) {
    final pinned = rows.where(_hasPin).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                rows.length == 1
                    ? _t('1 Event', 'אירוע אחד')
                    : _t('${rows.length} Events', '${rows.length} אירועים'),
                style: TextStyle(
                  fontFamily: AppFonts.nunito,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  height: 34 / 28,
                  color: AppColors.midBlue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _listViewButton(),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          pinned == rows.length
              ? _t('in Modiin Maccabim Reut', 'במודיעין מכבים רעות')
              : _t(
                  'in Modiin Maccabim Reut · $pinned on the map',
                  'במודיעין מכבים רעות · $pinned על המפה',
                ),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            color: _kSubtitle,
          ),
        ),
        const SizedBox(height: 20),
        _buildSearchField(),
      ],
    );
  }

  /// The mobile screen's "List View" pill, which leads to the events page.
  Widget _listViewButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/events'),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                IconsaxPlusLinear.menu,
                size: 16,
                color: AppColors.midBlue,
              ),
              const SizedBox(width: 6),
              Text(
                _t('List View', 'תצוגת רשימה'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.midBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            IconsaxPlusLinear.search_normal_1,
            size: 18,
            color: _kTextGrey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                // The app theme fills every field with a grey pill, which
                // would draw a second, rounder box inside this one.
                filled: false,
                hintText: _t(
                  'Search events, shows and activities',
                  'חיפוש אירועים, הופעות ופעילויות',
                ),
                hintStyle: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: _kTextGrey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice({
    required IconData icon,
    required String title,
    required String body,
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
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.nunito,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                height: 1.4,
                color: _kSubtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MAP PANEL — full height, with its own zoom controls
  // ─────────────────────────────────────────────
  Widget _buildMapPanel() {
    final pinned =
        (ref.watch(filteredEventsProvider).valueOrNull ?? const <Event>[])
            .where(_hasPin)
            .toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 14.2,
            onTap: (_, _) => setState(() => _selectedId = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.modiin4u.app',
            ),
            MarkerLayer(
              markers: [
                for (final e in pinned)
                  Marker(
                    point: LatLng(e.latitude, e.longitude),
                    width: 40,
                    height: 40,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => setState(() => _selectedId = e.id),
                      onExit: (_) => setState(() {
                        if (_selectedId == e.id) _selectedId = null;
                      }),
                      child: GestureDetector(
                        onTap: () => context.push('/event/${e.id}'),
                        child: _EventMapPin(selected: _selectedId == e.id),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        if (pinned.isEmpty)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Text(
                  _t(
                    'No events have a location on the map yet',
                    'אין אירועים עם מיקום על המפה',
                  ),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    color: _kSubtitle,
                  ),
                ),
              ),
            ),
          ),

        PositionedDirectional(
          end: 16,
          bottom: 24,
          child: Column(
            children: [
              _MapFab(
                icon: IconsaxPlusLinear.gps,
                onTap: () => _mapController.move(_center, 14.2),
              ),
              const SizedBox(height: 12),
              _MapFab(
                icon: IconsaxPlusLinear.add,
                onTap: () => _mapController.move(
                  _mapController.camera.center,
                  _mapController.camera.zoom + 1,
                ),
              ),
              const SizedBox(height: 12),
              _MapFab(
                icon: IconsaxPlusLinear.minus,
                onTap: () => _mapController.move(
                  _mapController.camera.center,
                  _mapController.camera.zoom - 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// EVENT ROW — one event in the panel
// ═══════════════════════════════════════════════

class _EventRow extends StatelessWidget {
  final Event event;
  final bool isHebrew, selected;

  /// Null when the event has no start date, in which case no date block is
  /// drawn rather than one showing a guess.
  final String? dayLabel, monthLabel;

  /// Set only when the event cannot be pinned.
  final String? onMapLabel;

  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _EventRow({
    required this.event,
    required this.isHebrew,
    required this.selected,
    required this.dayLabel,
    required this.monthLabel,
    required this.onMapLabel,
    required this.onTap,
    required this.onHover,
  });

  String _t(String en, String he) => isHebrew ? he : en;

  @override
  Widget build(BuildContext context) {
    final venue = event.venueName ?? event.address;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: selected ? _kEventPurple : _kBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (dayLabel != null && monthLabel != null)
                _dateBlock()
              else
                NetworkPhoto(
                  url: event.imageUrl,
                  width: 64,
                  height: 72,
                  radius: BorderRadius.circular(10),
                  icon: IconsaxPlusLinear.calendar_1,
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.rubik,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: AppColors.navy,
                      ),
                    ),
                    // An all-day event has no time to show, so the row is
                    // left out rather than printed empty.
                    if (event.displayTime != null) ...[
                      const SizedBox(height: 6),
                      _metaRow(IconsaxPlusLinear.clock, event.displayTime!),
                    ],
                    if (venue.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _metaRow(IconsaxPlusLinear.location, venue),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (event.isFree)
                          _tag(_t('Free', 'חינם'), AppColors.success)
                        else if (event.displayPrice != null)
                          _tag(event.displayPrice!, AppColors.midBlue),
                        if (event.isOnline)
                          _tag(_t('Online', 'אונליין'), _kEventPurple),
                        if (event.isSoldOut)
                          _tag(_t('Sold out', 'אזל'), AppColors.error),
                        if (onMapLabel != null) _tag(onMapLabel!, _kTextGrey),
                      ],
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

  Widget _dateBlock() {
    return Container(
      width: 64,
      height: 72,
      decoration: BoxDecoration(
        color: _kEventPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            dayLabel!,
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: _kEventPurple,
            ),
          ),
          Text(
            monthLabel!,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _kEventPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.turquoise),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 13,
              color: _kSubtitle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tag(String label, Color colour) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colour,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// MAP PIN — the mobile screen's purple pin, at the same size
// ═══════════════════════════════════════════════

class _EventMapPin extends StatelessWidget {
  final bool selected;
  const _EventMapPin({this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 2.28,
            offset: const Offset(0, 2.28),
          ),
        ],
        border: selected
            ? Border.all(color: AppColors.midBlue, width: 2)
            : null,
      ),
      child: Center(
        child: Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: _kEventPurple,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            IconsaxPlusBold.calendar_1,
            size: 12,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapFab({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(child: Icon(icon, size: 20, color: AppColors.navy)),
        ),
      ),
    );
  }
}
