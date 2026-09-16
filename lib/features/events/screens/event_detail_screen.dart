import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';
import 'web_event_detail_screen.dart';

/// Event detail screen — responsive wrapper.
/// Desktop (> 1100px) renders the web detail layout; mobile keeps the app UI.
class EventDetailScreen extends StatelessWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return WebEventDetailContent(eventId: eventId);
        }
        return _MobileEventDetailContent(eventId: eventId);
      },
    );
  }
}

/// Mobile layout – hero image, date badge, info section, organizer,
/// about, what's included, mini-map, "You May Also Like" cards, RSVP bar.
class _MobileEventDetailContent extends StatefulWidget {
  final String eventId;
  const _MobileEventDetailContent({required this.eventId});

  @override
  State<_MobileEventDetailContent> createState() =>
      _MobileEventDetailContentState();
}

class _MobileEventDetailContentState extends State<_MobileEventDetailContent> {
  bool _isGoing = false;

  // ── Related events (You May Also Like) ──
  static const _related = [
    _RelatedEvent(
      'Modiin Community Festival',
      'Municipal & Community',
      'AUG', 22,
      '10:00 AM',
      'Modiin City Center',
      'FREE', 86,
    ),
    _RelatedEvent(
      'Family Fun Day',
      'Kids & Family',
      'AUG', 23,
      '11:00 AM',
      'Anava Park',
      '₪20', 86,
    ),
    _RelatedEvent(
      'Live Jazz Evening',
      'Music',
      'AUG', 24,
      '8:30 PM',
      'Local Cultural Center',
      '₪60', 51,
    ),
    _RelatedEvent(
      'Kids Cooking Workshop',
      'Kids & Family',
      'AUG', 26,
      '8:30 PM',
      'Local Cultural Center',
      '₪60', 51,
    ),
  ];

  // What's included items
  static const _included = [
    'Live music performances',
    'Food & refreshments',
    'Outdoor seating',
    'Family-friendly atmosphere',
    'Local artists',
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
                        const SizedBox(height: 49), // space for overlapping badges
                        _buildInfoSection(),
                        _buildOrganizedBy(),
                        const SizedBox(height: 24),
                        _buildAbout(),
                        const SizedBox(height: 32),
                        _buildWhatsIncluded(),
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
          Container(
            width: double.infinity,
            height: 260,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF0058B5), Color(0xFF010A36)],
              ),
            ),
            child: Stack(
              children: [
                // Dark overlay gradient
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
                // Placeholder icon
                Center(
                  child: Icon(
                    IconsaxPlusBold.calendar_1,
                    size: 60,
                    color: Colors.white.withValues(alpha: 0.1),
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
                  child: Icon(IconsaxPlusLinear.arrow_left,
                      size: 20, color: Color(0xFF3D3D3D)),
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
                child: Icon(IconsaxPlusLinear.export_1,
                    size: 20, color: Color(0xFF3D3D3D)),
              ),
            ),
          ),

          // Heart button (top-right)
          Positioned(
            right: 12,
            top: MediaQuery.of(context).padding.top + 7,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(IconsaxPlusLinear.heart,
                    size: 20, color: Color(0xFF3D3D3D)),
              ),
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
                border: Border.all(
                    color: const Color(0xFF123A72), width: 2),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                children: [
                  Text(
                    'AUG',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF123A72),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '25',
                    style: GoogleFonts.inter(
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF17A9D0),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                'Music',
                style: GoogleFonts.inter(
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
        border: Border(
          bottom: BorderSide(color: Color(0xFFE7E7E7)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Summer Music Night',
            style: GoogleFonts.rubik(
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
                  const Icon(IconsaxPlusLinear.clock,
                      size: 16, color: Color(0xFF888888)),
                  const SizedBox(width: 8),
                  Text(
                    '8:00 PM – 11:00 PM',
                    style: GoogleFonts.inter(
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
                  const Icon(IconsaxPlusLinear.location,
                      size: 16, color: Color(0xFF888888)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '21 Sderot El Melachot, Modi\'in Maccabim-Re\'ut',
                      style: GoogleFonts.inter(
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
                  const Icon(IconsaxPlusLinear.people,
                      size: 16, color: Color(0xFF888888)),
                  const SizedBox(width: 8),
                  Text(
                    '124 people interested',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₪50',
                style: GoogleFonts.rubik(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  height: 34 / 28,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Price',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6D6D6D),
                ),
              ),
            ],
          ),
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
            'Organized by',
            style: GoogleFonts.inter(
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
                        color: const Color(0xFFE7E7E7), width: 0.625),
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
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Community & Municipal Events',
                        style: GoogleFonts.inter(
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
            'About This Event',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Get ready for an unforgettable evening of live music under the '
            'stars in Modiin. Enjoy performances from local artists, great '
            'music, food, and a vibrant community atmosphere.',
            style: GoogleFonts.inter(
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
            style: GoogleFonts.inter(
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

  // ═══════════════════════════════════════════════
  // What's Included
  // ═══════════════════════════════════════════════
  Widget _buildWhatsIncluded() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s Included',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(_included.length, (i) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: i < _included.length - 1 ? 14 : 0),
              child: Row(
                children: [
                  const Icon(IconsaxPlusLinear.tick_circle,
                      size: 16, color: Color(0xFF17A9D0)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _included[i],
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF3D3D3D),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

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
            'Where Is It?',
            style: GoogleFonts.inter(
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
                            horizontal: 16, vertical: 12),
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
                            const Icon(IconsaxPlusLinear.map,
                                size: 16, color: Color(0xFF0A1230)),
                            const SizedBox(width: 6),
                            Text(
                              'Open in Maps',
                              style: GoogleFonts.inter(
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
  Widget _buildYouMayAlsoLike() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You May Also Like',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_related.length, (i) {
            return Padding(
              padding:
                  EdgeInsets.only(bottom: i < _related.length - 1 ? 12 : 0),
              child: _RelatedEventCard(event: _related[i], index: i),
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
        border: const Border(
          top: BorderSide(color: Color(0xFFE7E7E7)),
        ),
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
                  const Icon(IconsaxPlusLinear.tick_circle,
                      size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _isGoing ? 'Going' : 'I\'m Going',
                    style: GoogleFonts.inter(
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

  const _RelatedEvent(
    this.title,
    this.category,
    this.month,
    this.day,
    this.time,
    this.venue,
    this.price,
    this.interested,
  );

  bool get isFree => price == 'FREE';
}

// ═══════════════════════════════════════════════
// Related event card (same pattern as events list)
// image 361×200 + date badge + heart + info section
// ═══════════════════════════════════════════════
class _RelatedEventCard extends StatelessWidget {
  final _RelatedEvent event;
  final int index;
  const _RelatedEventCard({required this.event, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/event/related_$index'),
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
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF123A72),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${event.day}',
                          style: GoogleFonts.inter(
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
                      child: Icon(IconsaxPlusLinear.heart,
                          size: 23, color: Color(0xFF123A72)),
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
                  style: GoogleFonts.rubik(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1230),
                  ),
                ),
                const SizedBox(height: 8),

                // Category
                Text(
                  event.category,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF5F5E5A),
                  ),
                ),
                const SizedBox(height: 12),

                // Time + Location row
                Row(
                  children: [
                    const Icon(IconsaxPlusBold.clock,
                        size: 16, color: Color(0xFF17A9D0)),
                    const SizedBox(width: 8),
                    Text(
                      event.time,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF5F5E5A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(IconsaxPlusBold.location,
                        size: 16, color: Color(0xFF17A9D0)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.venue,
                        style: GoogleFonts.inter(
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
                      style: GoogleFonts.rubik(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: event.isFree
                            ? const Color(0xFF123A72)
                            : const Color(0xFF0A1230),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(IconsaxPlusBold.star_1,
                            size: 18, color: Color(0xFF17A9D0)),
                        const SizedBox(width: 4),
                        Text(
                          '${event.interested} interested',
                          style: GoogleFonts.inter(
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
