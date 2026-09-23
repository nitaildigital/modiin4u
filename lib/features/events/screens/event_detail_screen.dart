import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';
import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/network_photo.dart';
import '../models/event.dart';
import '../providers/event_providers.dart';
import 'web_event_detail_screen.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../../favorites/repositories/favorite_repository.dart';

/// Event detail screen — responsive wrapper.
/// Desktop (> 1100px) renders the web detail layout; mobile keeps the app UI.
class EventDetailScreen extends ConsumerWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return WebEventDetailContent(eventId: eventId);
        }

        final provider = eventByIdProvider(eventId);
        return ref
            .watch(provider)
            .when(
              loading: () => const _EventDetailSkeleton(),
              error: (error, _) => Scaffold(
                backgroundColor: Colors.white,
                body: SafeArea(
                  child: ErrorRetry(onRetry: () => ref.invalidate(provider)),
                ),
              ),
              data: (event) => _MobileEventDetailContent(event: event),
            );
      },
    );
  }
}

/// Mobile layout – hero image, date badge, info section, organizer,
/// about, what's included, mini-map, "You May Also Like" cards, RSVP bar.
class _MobileEventDetailContent extends ConsumerStatefulWidget {
  final Event event;
  const _MobileEventDetailContent({required this.event});

  @override
  ConsumerState<_MobileEventDetailContent> createState() =>
      _MobileEventDetailContentState();
}

class _MobileEventDetailContentState
    extends ConsumerState<_MobileEventDetailContent> {
  bool _isGoing = false;

  Event get event => widget.event;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                // ═══════════════════════════════════
                // Scrollable content
                // ═══════════════════════════════════
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHero(context),
                        const SizedBox(
                          height: 49,
                        ), // space for overlapping badges
                        _buildInfoSection(),
                        _buildOrganizedBy(),
                        const SizedBox(height: 24),
                        _buildAbout(),
                        const SizedBox(height: 32),
                        const SizedBox(height: 32),
                        _buildWhereIsIt(),
                        const SizedBox(height: 32),
                        _buildYouMayAlsoLike(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // ═══════════════════════════════════
                // Sticky RSVP bar
                // ═══════════════════════════════════
                _buildBottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Hero image (260px) with date badge + category badge
  // ═══════════════════════════════════════════════
  Widget _buildHero(BuildContext context) {
    return SizedBox(
      height: 310, // 260 hero + space for overlapping badges
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Hero image
          SizedBox(
            width: double.infinity,
            height: 260,
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetworkPhoto(
                  url: event.imageUrl,
                  icon: IconsaxPlusBold.calendar_1,
                  iconSize: 60,
                ),
                // Dark overlay gradient, so the badges stay legible on any photo
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0x66000000), // 40% black
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Back button (top-left)
          Positioned(
            left: 12,
            top: MediaQuery.of(context).padding.top + 7,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    IconsaxPlusLinear.arrow_left,
                    size: 20,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
              ),
            ),
          ),

          // Share button (top-right second)
          Positioned(
            right: 56,
            top: MediaQuery.of(context).padding.top + 7,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  IconsaxPlusLinear.export_1,
                  size: 20,
                  color: Color(0xFF3D3D3D),
                ),
              ),
            ),
          ),

          // Heart button (top-right)
          Positioned(
            right: 12,
            top: MediaQuery.of(context).padding.top + 7,
            child: FavoriteButton(
              kind: FavoriteKind.event,
              id: event.id,
              size: 40,
              iconSize: 20,
              color: const Color(0xFF3D3D3D),
            ),
          ),

          // Date badge (overlapping bottom-left)
          Positioned(
            left: 12,
            top: 215,
            child: Container(
              width: 81,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF123A72), width: 2),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                children: [
                  Text(
                    event.startDate == null
                        ? ''
                        : _months[event.startDate!.month - 1],
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF123A72),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${event.startDate?.day ?? ''}',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Category badge (right side, below hero)
          Positioned(
            right: 13,
            top: 272,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF17A9D0),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                'Music',
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Info section – title, time, address, interested, price
  // ═══════════════════════════════════════════════
  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            event.title,
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              height: 34 / 28,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),

          // Info rows
          Column(
            children: [
              // Time
              Row(
                children: [
                  const Icon(
                    IconsaxPlusLinear.clock,
                    size: 16,
                    color: Color(0xFF888888),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    [
                      event.displayTime,
                      event.endTime?.substring(0, 5),
                    ].whereType<String>().join(' – '),
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6D6D6D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Address
              Row(
                children: [
                  const Icon(
                    IconsaxPlusLinear.location,
                    size: 16,
                    color: Color(0xFF888888),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      [event.venueName, event.address]
                          .whereType<String>()
                          .where((s) => s.isNotEmpty)
                          .join(', '),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6D6D6D),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // People interested
              Row(
                children: [
                  const Icon(
                    IconsaxPlusLinear.people,
                    size: 16,
                    color: Color(0xFF888888),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${event.rsvpCount} מתעניינים',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Price, only when the event has one on record.
          if (event.displayPrice != null) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  event.displayPrice!,
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    height: 34 / 28,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'מחיר',
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6D6D6D),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Organized by section
  // ═══════════════════════════════════════════════
  Widget _buildOrganizedBy() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'מארגן האירוע',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Organizer avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE7E7E7),
                      width: 0.625,
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0058B5), Color(0xFF010A36)],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      IconsaxPlusBold.building,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modiin Community Events',
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Community & Municipal Events',
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6D6D6D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // About This Event
  // ═══════════════════════════════════════════════
  Widget _buildAbout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'על האירוע',
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            event.fullDescription ?? event.shortDescription ?? '',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.6,
              color: const Color(0xFF3D3D3D),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Whether you\'re coming with friends, family, or simply looking '
            'for a great night out, Summer Music Night is the perfect way to '
            'enjoy the summer evening.',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.6,
              color: const Color(0xFF3D3D3D),
            ),
          ),
        ],
      ),
    );
  }
  // "What's Included" used to sit here, listing live music, food and
  // outdoor seating for every event. There is no column behind it, so it
  // said the same five things whatever the event was.

  // ═══════════════════════════════════════════════
  // Where Is It? (mini FlutterMap)
  // ═══════════════════════════════════════════════
  Widget _buildWhereIsIt() {
    const venuePosition = LatLng(31.8928, 35.0104);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'איפה זה?',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 230,
              child: Stack(
                children: [
                  // Map
                  IgnorePointer(
                    child: FlutterMap(
                      options: const MapOptions(
                        initialCenter: venuePosition,
                        initialZoom: 15.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.modiin4u.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: venuePosition,
                              width: 48,
                              height: 48,
                              child: _buildMapPin(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // "Open in Maps" floating button
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: Center(
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
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              IconsaxPlusLinear.map,
                              size: 16,
                              color: Color(0xFF0A1230),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Open in Maps',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Blue location pin for the mini-map
  Widget _buildMapPin() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 2.74,
            offset: const Offset(0, 2.74),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFF006BF6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            IconsaxPlusBold.location,
            size: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // You May Also Like
  // ═══════════════════════════════════════════════
  /// Other events from the database, not four invented ones on a page
  /// showing a real one. The current event is left out, and the section
  /// disappears rather than standing empty when it is the only one.
  Widget _buildYouMayAlsoLike() {
    final all = ref.watch(eventsProvider).valueOrNull ?? const <Event>[];
    final related = all
        .where((e) => e.id != event.id)
        .take(4)
        .map(_RelatedEvent.from)
        .toList();
    if (related.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You May Also Like',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(related.length, (i) {
            return Padding(
              padding: EdgeInsets.only(bottom: i < related.length - 1 ? 12 : 0),
              child: _RelatedEventCard(event: related[i]),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Bottom RSVP bar
  // ═══════════════════════════════════════════════
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE7E7E7))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () => setState(() => _isGoing = !_isGoing),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF123A72),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    IconsaxPlusLinear.tick_circle,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isGoing ? 'מגיע/ה' : 'אני מגיע/ה',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Data model for related events
// ═══════════════════════════════════════════════
class _RelatedEvent {
  final String title;
  final String category;
  final String month;
  final int day;
  final String time;
  final String venue;
  final String price;
  final int interested;

  final String id;

  const _RelatedEvent(
    this.id,
    this.title,
    this.category,
    this.month,
    this.day,
    this.time,
    this.venue,
    this.price,
    this.interested,
  );

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

  factory _RelatedEvent.from(Event e) {
    final start = e.startDate;
    return _RelatedEvent(
      e.id,
      e.title,
      // Events carry no category column; the venue reads better in that slot
      // than an empty line would.
      e.venueName ?? '',
      start == null ? '' : _months[start.month - 1],
      start?.day ?? 0,
      e.displayTime ?? '',
      e.venueName ?? e.address,
      e.displayPrice ?? '',
      e.rsvpCount,
    );
  }

  bool get isFree => price.isEmpty || price == 'FREE' || price == 'חינם';
}

// ═══════════════════════════════════════════════
// Related event card (same pattern as events list)
// image 361×200 + date badge + heart + info section
// ═══════════════════════════════════════════════
class _RelatedEventCard extends StatelessWidget {
  final _RelatedEvent event;
  const _RelatedEventCard({required this.event});

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
                // Image placeholder
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0058B5), Color(0xFF010A36)],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      IconsaxPlusBold.calendar_1,
                      size: 40,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
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
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        IconsaxPlusLinear.heart,
                        size: 23,
                        color: Color(0xFF123A72),
                      ),
                    ),
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
                    Row(
                      children: [
                        const Icon(
                          IconsaxPlusBold.star_1,
                          size: 18,
                          color: Color(0xFF17A9D0),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.interested} interested',
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

/// Placeholder for the event page: the banner, the date tile that overlaps
/// it, then the title and the time, place and interest lines.
class _EventDetailSkeleton extends StatelessWidget {
  const _EventDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Skeleton(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            const SkeletonBox(height: 260, radius: 0),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 81, height: 86, radius: 11),
                  SizedBox(height: 20),
                  SkeletonLine(width: 250, fontSize: 24),
                  SizedBox(height: 16),
                  SkeletonLine(width: 160, fontSize: 14),
                  SizedBox(height: 12),
                  SkeletonLine(width: 240, fontSize: 14),
                  SizedBox(height: 12),
                  SkeletonLine(width: 120, fontSize: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
