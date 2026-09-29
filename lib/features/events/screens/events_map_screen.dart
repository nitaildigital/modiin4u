import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/network_photo.dart';
import '../models/event.dart';
import '../models/event_labels.dart';
import '../providers/event_providers.dart';
import '../widgets/m_event_card.dart' show mEventsIsHebrew;
import 'web_events_map_screen.dart';
import '../../../shared/widgets/osm_attribution.dart';

/// The events map.
///
/// Fourteen invented events lived in a `static final` list here, at invented
/// coordinates, and every card's "View full details" pushed
/// `/event/map_<hashCode of the title>` — an id no event has, so the button
/// always landed on the detail screen's error state. The screen was also
/// unreachable: nothing navigated to `/events-map` until the events list's
/// floating button was corrected.
class EventsMapScreen extends StatelessWidget {
  const EventsMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) return const WebEventsMapContent();
        return const _MobileEventsMapContent();
      },
    );
  }
}

/// The phone layout (Figma "Event in Modiin Map View", 604:5832): the map,
/// the search pill over it, the "List View" pill under it, and the card of
/// the tapped pin ("Map Card Overlay 3 Event", 604:6148).
class _MobileEventsMapContent extends ConsumerStatefulWidget {
  const _MobileEventsMapContent();

  @override
  ConsumerState<_MobileEventsMapContent> createState() =>
      _MobileEventsMapContentState();
}

class _MobileEventsMapContentState
    extends ConsumerState<_MobileEventsMapContent> {
  String? _selectedId;
  final _searchController = TextEditingController();
  Timer? _debounce;

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
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      ref.read(eventSearchProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final labels = EventLabels(mEventsIsHebrew(context));
    // A pin needs coordinates; an online event has none, so the map can show
    // fewer than the list does.
    final pinned =
        (ref.watch(filteredEventsProvider).valueOrNull ?? const <Event>[])
            .where((e) => e.latitude != 0 && e.longitude != 0)
            .toList();
    final selected = pinned.where((e) => e.id == _selectedId).firstOrNull;
    // The card's category line is the event's primary category, as on the
    // list's cards; it is left out for an event nobody has filed.
    final byEvent =
        ref.watch(eventCategoriesByEventProvider).valueOrNull ?? const {};

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 14.5,
                  onTap: (_, _) => setState(() => _selectedId = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.modiin4u.app',
                  ),
                  MarkerLayer(
                    markers: [
                      for (final event in pinned)
                        Marker(
                          point: LatLng(event.latitude, event.longitude),
                          width: 40,
                          height: 43,
                          // The teardrop's tip, not its middle, marks the
                          // place.
                          alignment: Alignment.topCenter,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedId = event.id),
                            child: _EventMapPin(
                              isSelected: _selectedId == event.id,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const OsmAttribution(),
                ],
              ),

              // ── Search ──
              //
              // A `Text` before, with a filter icon that had no handler. The
              // frame still draws that filter icon; there is nothing on this
              // screen for it to open, so it is left out rather than drawn as
              // a button that does nothing.
              Positioned(
                top: 58,
                left: 16,
                right: 16,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE7E7E7)),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/m_account_search.svg',
                        width: 18,
                        height: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          style: const TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                            color: AppColors.navy,
                          ),
                          decoration: InputDecoration(
                            hintText: l.searchEvents,
                            hintStyle: const TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              color: Color(0xFF6D6D6D),
                            ),
                            // The theme fills inputs grey, drawing a second
                            // pill inside this one; the frame has one.
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (pinned.isEmpty)
                Positioned(
                  top: 122,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Text(
                      l.noEventsOnMap,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 13,
                        color: Color(0xFF6D6D6D),
                      ),
                    ),
                  ),
                ),

              if (selected != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 80,
                  child: _EventCard(
                    event: selected,
                    labels: labels,
                    category: (byEvent[selected.id] ?? const [])
                        .map(labels.category)
                        .firstOrNull,
                    onClose: () => setState(() => _selectedId = null),
                  ),
                ),

              // ── "List View" (Figma 604:6001) ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Center(
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/m_events_list.svg',
                            width: 16,
                            height: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l.listView,
                            style: const TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.navy,
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
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// The design's pin: a white teardrop with a purple disc and a calendar.
// ═══════════════════════════════════════════════
class _EventMapPin extends StatelessWidget {
  final bool isSelected;
  const _EventMapPin({this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    // The frame draws every pin alike. The chosen one is grown a little, as
    // on the website's map, so it can be told from the rest while its card
    // is open.
    return AnimatedScale(
      duration: const Duration(milliseconds: 150),
      scale: isSelected ? 1.15 : 1.0,
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: 40,
        height: 43,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // flutter_svg does not draw the SVG's drop-shadow filter; a soft
            // shadow is painted under the teardrop instead, or the white pin
            // is lost on the pale map.
            Positioned(
              top: 6,
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 4,
                      offset: Offset(0, 2.3),
                    ),
                  ],
                ),
              ),
            ),
            SvgPicture.asset(
              'assets/web/events/map_pin.svg',
              width: 40,
              height: 43,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// The card for the tapped pin (Figma 604:6148, 369 wide): the photo, then
// title, category, time, place, and price with the interest count; the
// button to the event's page beneath.
// ═══════════════════════════════════════════════
class _EventCard extends StatelessWidget {
  final Event event;
  final EventLabels labels;
  final String? category;
  final VoidCallback onClose;

  const _EventCard({
    required this.event,
    required this.labels,
    required this.category,
    required this.onClose,
  });

  // Line heights are the frame's (title and price 25, category 17, the
  // rows 15) and are set rather than left to the font: the titles are
  // Hebrew, which the Latin faces lack, and the fallback face's taller line
  // pushed the column past the photo beside it.
  static const _meta = TextStyle(
    fontFamily: AppFonts.inter,
    fontSize: 12,
    height: 15 / 12,
    color: AppColors.grayText,
  );

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final time = labels.startTime(event);
    final venue = labels.venue(event);
    final price = labels.price(event);
    final rtl = Directionality.of(context) == TextDirection.rtl;

    // Each line is shown only when the row has it, so the gaps are laid
    // between the lines that are there.
    final lines = <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              // "Avenir Next Rounded Pro Demi" in the frame.
              fontFamily: AppFonts.nunito,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 25 / 20,
              color: AppColors.navy,
            ),
          ),
          if (category != null && category!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              category!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                height: 17 / 14,
                color: AppColors.grayText,
              ),
            ),
          ],
        ],
      ),
      if (time != null)
        _MetaRow(
          icon: SvgPicture.asset(
            'assets/web/events/card_clock.svg',
            width: 11.375,
            height: 11.375,
          ),
          text: time,
        ),
      if (venue != null)
        _MetaRow(
          icon: SvgPicture.asset(
            'assets/web/events/card_pin.svg',
            width: 10.5,
            height: 14,
          ),
          text: venue,
        ),
      // The interest count only once somebody has said they are coming, as
      // on the list's cards; a "0 interested" reads as a verdict.
      if (price != null || event.rsvpCount > 0)
        Row(
          children: [
            if (price != null)
              Text(
                price,
                style: TextStyle(
                  fontFamily: AppFonts.nunito,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 25 / 20,
                  color: event.isFree ? AppColors.midBlue : AppColors.navy,
                ),
              ),
            const Spacer(),
            if (event.rsvpCount > 0) ...[
              // The star sits high in its 16-pixel frame, as drawn.
              SizedBox(
                width: 16,
                height: 16,
                child: Padding(
                  padding: const EdgeInsets.only(top: 0.61),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SvgPicture.asset(
                      'assets/web/events/card_star.svg',
                      width: 14.093,
                      height: 13.441,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                l.eventInterestedCount(event.rsvpCount),
                style: const TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 15 / 12,
                  color: Color(0xFF3D3D3D),
                ),
              ),
            ],
          ],
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                height: 140,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: NetworkPhoto(
                        url: event.imageUrl,
                        width: 120,
                        height: 140,
                        radius: BorderRadius.circular(8),
                        icon: IconsaxPlusBold.calendar_1,
                      ),
                    ),
                    // Not in the frame, which closes the card by a tap on
                    // the map; kept so there is a visible way out as well.
                    PositionedDirectional(
                      end: 4,
                      top: 4,
                      child: Semantics(
                        button: true,
                        label: l.close,
                        child: GestureDetector(
                          onTap: onClose,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Color(0xFF3D3D3D),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < lines.length; i++) ...[
                      if (i > 0) const SizedBox(height: 11),
                      lines[i],
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            // This pushed `/event/map_<hashCode of the title>` — an id no
            // event has — so the card's only action always failed.
            onTap: () => context.push('/event/${event.id}'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.midBlue,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l.viewFullDetails,
                    style: const TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 24 / 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Forward: → in English, ← in Hebrew.
                  Transform.flip(
                    flipX: rtl,
                    child: SvgPicture.asset(
                      'assets/icons/m_events_arrow.svg',
                      width: 16,
                      height: 16,
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
}

/// A 14-pixel icon and a line of 12-pixel grey text, cut short when long.
class _MetaRow extends StatelessWidget {
  final Widget icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 14, height: 14, child: Center(child: icon)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _EventCard._meta,
          ),
        ),
      ],
    );
  }
}
