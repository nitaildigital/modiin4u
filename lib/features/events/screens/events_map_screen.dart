import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../models/event.dart';
import '../providers/event_providers.dart';

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
    return const _MobileEventsMapContent();
  }
}

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
    // A pin needs coordinates; an online event has none, so the map can show
    // fewer than the list does.
    final pinned =
        (ref.watch(filteredEventsProvider).valueOrNull ?? const <Event>[])
            .where((e) => e.latitude != 0 && e.longitude != 0)
            .toList();
    final selected = pinned.where((e) => e.id == _selectedId).firstOrNull;

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
                          height: 40,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedId = event.id),
                            child: _EventMapPin(
                              isSelected: _selectedId == event.id,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // ── Search ──
              //
              // A `Text` before, with a filter icon that had no handler.
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
                        blurRadius: 16,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        IconsaxPlusLinear.search_normal_1,
                        size: 18,
                        color: Color(0xFF6D6D6D),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: l.searchEvents,
                            hintStyle: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              color: const Color(0xFF6D6D6D),
                            ),
                            border: InputBorder.none,
                            isDense: true,
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
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 13,
                        color: const Color(0xFF6D6D6D),
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
                    onClose: () => setState(() => _selectedId = null),
                  ),
                ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Center(
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            IconsaxPlusLinear.menu,
                            size: 16,
                            color: Color(0xFF0A1230),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l.listView,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0A1230),
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
// ═══════════════════════════════════════════════
// Purple event map pin (white circle + purple inner + calendar icon)
// ═══════════════════════════════════════════════
class _EventMapPin extends StatelessWidget {
  final bool isSelected;
  const _EventMapPin({this.isSelected = false});

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
        border: isSelected
            ? Border.all(color: const Color(0xFF123A72), width: 2)
            : null,
      ),
      child: Center(
        child: Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Color(0xFF9032E1),
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

// ═══════════════════════════════════════════════
// Selected event card
// ═══════════════════════════════════════════════
class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onClose;

  const _EventCard({required this.event, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final venue = event.venueName ?? event.address;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1230),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onClose,
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: Color(0xFF6D6D6D),
                ),
              ),
            ],
          ),

          // A category line sat here; `events` carries no category, so the
          // old card printed one that came from nowhere.
          // An all-day event has no time to show, so the row is left out
          // rather than printed empty.
          if (event.displayTime != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  IconsaxPlusLinear.clock,
                  size: 16,
                  color: Color(0xFF17A9D0),
                ),
                const SizedBox(width: 8),
                Text(
                  event.displayTime!,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    color: const Color(0xFF5F5E5A),
                  ),
                ),
              ],
            ),
          ],

          if (venue.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  IconsaxPlusLinear.location,
                  size: 16,
                  color: Color(0xFF17A9D0),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    venue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      color: const Color(0xFF5F5E5A),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          GestureDetector(
            // This pushed `/event/map_<hashCode of the title>` — an id no
            // event has — so the card's only action always failed.
            onTap: () => context.push('/event/${event.id}'),
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF123A72),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Center(
                child: Text(
                  l.viewFullDetails,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
