import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../l10n/app_localizations.dart';
import '../models/event.dart';
import '../providers/event_providers.dart';
import 'web_events_screen.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../../favorites/repositories/favorite_repository.dart';

/// Events – responsive wrapper.
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) return const WebEventsContent();
        return const _MobileEventsContent();
      },
    );
  }
}

/// Events discovery screen – category circles, vertical event cards
/// with date badges, time/location/price, and interest counts.
class _MobileEventsContent extends ConsumerStatefulWidget {
  const _MobileEventsContent();

  @override
  ConsumerState<_MobileEventsContent> createState() =>
      _MobileEventsContentState();
}

class _MobileEventsContentState extends ConsumerState<_MobileEventsContent> {
  final _searchController = TextEditingController();
  Timer? _debounce;

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
    final events = ref.watch(filteredEventsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Stack(
              children: [
                // ═══════════════════════════════════
                // Scrollable content
                // ═══════════════════════════════════
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 100), // space for sticky header
                      const SizedBox(height: 20),

                      // "Events in Modiin"
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'אירועים במודיעין',
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Event cards
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: events.when(
                          loading: () => const _EventListSkeleton(),
                          error: (_, _) => ErrorRetry(
                            onRetry: () =>
                                ref.invalidate(filteredEventsProvider),
                          ),
                          data: (list) => list.isEmpty
                              ? (ref.watch(eventSearchProvider).isNotEmpty
                                    ? EmptyState(
                                        icon: Icons.search_off,
                                        title: l.noEventsMatch,
                                      )
                                    : const EmptyState(
                                        icon: Icons.event_busy_outlined,
                                        title: 'אין אירועים קרובים',
                                        subtitle: 'אירועים חדשים יופיעו כאן',
                                      ))
                              : Column(
                                  children: [
                                    for (var i = 0; i < list.length; i++) ...[
                                      _EventCard(event: _Event.from(list[i])),
                                      if (i < list.length - 1)
                                        const SizedBox(height: 12),
                                    ],
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),

                // ═══════════════════════════════════
                // Frosted sticky header
                // ═══════════════════════════════════
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildStickyHeader(context),
                ),

                // ═══════════════════════════════════
                // Floating "view on map" button
                // ═══════════════════════════════════
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => context.push('/events-map'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
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
                              IconsaxPlusLinear.map_1,
                              size: 16,
                              color: Color(0xFF0A1230),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l.viewOnMapBtn,
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
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Sticky header: back + title + search bar
  // ═══════════════════════════════════════════════
  Widget _buildStickyHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9)),
      child: Column(
        children: [
          // Title row
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Row(
              children: [
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Icon(
                    IconsaxPlusLinear.arrow_left,
                    size: 24,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
                const Spacer(),
                Text(
                  'אירועים',
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 40), // balance back button
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE7E7E7)),
                borderRadius: BorderRadius.circular(50),
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
                        hintText: L.of(context).searchEvents,
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
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Category circles horizontal row
  // ═══════════════════════════════════════════════
}

// ═══════════════════════════════════════════════
// Data models
// ═══════════════════════════════════════════════

class _Event {
  final String id;
  final String title;
  final String category;
  final String month;
  final int day;
  final String time;
  final String venue;
  final String price;
  final int interested;
  final String? imageUrl;

  const _Event(
    this.id,
    this.title,
    this.category,
    this.month,
    this.day,
    this.time,
    this.venue,
    this.price,
    this.interested,
    this.imageUrl,
  );

  bool get isFree => price == 'חינם' || price == 'FREE';

  static const _months = [
    'ינו',
    'פבר',
    'מרץ',
    'אפר',
    'מאי',
    'יונ',
    'יול',
    'אוג',
    'ספט',
    'אוק',
    'נוב',
    'דצמ',
  ];

  factory _Event.from(Event e) {
    final start = e.startDate;
    return _Event(
      e.id,
      e.title,
      '',
      start == null ? '' : _months[start.month - 1],
      start?.day ?? 0,
      e.displayTime ?? '',
      e.venueName ?? e.address,
      e.displayPrice ?? '',
      e.rsvpCount,
      e.imageUrl,
    );
  }
}

// ═══════════════════════════════════════════════
// Category circle (64px avatar + name + count)
// ═══════════════════════════════════════════════

// ═══════════════════════════════════════════════
// Event card (361 × 348)
// ═══════════════════════════════════════════════
class _EventCard extends StatelessWidget {
  final _Event event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/event/${event.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area with date badge + heart
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                Positioned.fill(
                  child: NetworkPhoto(
                    url: event.imageUrl,
                    radius: BorderRadius.circular(12),
                    icon: IconsaxPlusBold.calendar_1,
                    iconSize: 40,
                  ),
                ),

                // Date badge (bottom-left)
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    width: 57,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          event.month,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF123A72),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${event.day}',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Heart button (top-right)
                Positioned(
                  right: 12,
                  top: 12,
                  child: FavoriteButton(
                    kind: FavoriteKind.event,
                    id: event.id,
                    size: 40,
                    iconSize: 23,
                    color: const Color(0xFF123A72),
                  ),
                ),
              ],
            ),
          ),

          // Info section
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  event.title,
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1230),
                  ),
                ),
                const SizedBox(height: 8),

                // Category
                Text(
                  event.category,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF5F5E5A),
                  ),
                ),
                const SizedBox(height: 12),

                // Time + Location row
                Row(
                  children: [
                    // Time
                    const Icon(
                      IconsaxPlusBold.clock,
                      size: 16,
                      color: Color(0xFF17A9D0),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      event.time,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF5F5E5A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Location
                    const Icon(
                      IconsaxPlusBold.location,
                      size: 16,
                      color: Color(0xFF17A9D0),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.venue,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF5F5E5A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Price + Interested row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price
                    Text(
                      event.price,
                      style: TextStyle(
                        fontFamily: AppFonts.rubik,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: event.isFree
                            ? const Color(0xFF123A72)
                            : const Color(0xFF0A1230),
                      ),
                    ),
                    // Interested
                    Row(
                      children: [
                        Icon(
                          IconsaxPlusBold.star_1,
                          size: 18,
                          color: const Color(0xFF17A9D0),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.interested} מתעניינים',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF3D3D3D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder for the event cards — the same 200px banner and the same
/// three lines beneath it.
class _EventListSkeleton extends StatelessWidget {
  const _EventListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Column(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 200, radius: 12),
                SizedBox(height: 12),
                SkeletonLine(width: 230, fontSize: 20),
                SizedBox(height: 10),
                SkeletonLine(width: 170, fontSize: 14),
                SizedBox(height: 12),
                SkeletonLine(width: 110, fontSize: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
