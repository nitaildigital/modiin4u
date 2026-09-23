import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';
import 'web_events_category_screen.dart';

/// Events map view – responsive wrapper.
/// Desktop (> 1100px) renders the filtered "Event Category" layout;
/// mobile keeps the existing app map UI.
class EventsMapScreen extends StatelessWidget {
  const EventsMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return const WebEventsCategoryContent();
        }
        return const _MobileEventsMapContent();
      },
    );
  }
}

/// Mobile layout – event venue pins (purple) on the map with a search bar,
/// tappable popup cards, and a "View as List" toggle.
class _MobileEventsMapContent extends StatefulWidget {
  const _MobileEventsMapContent();

  @override
  State<_MobileEventsMapContent> createState() =>
      _MobileEventsMapContentState();
}

class _MobileEventsMapContentState extends State<_MobileEventsMapContent> {
  int? _selectedPin;

  // Modi'in center
  static const _center = LatLng(31.8928, 35.0104);

  // ── Event venue pins (all purple #9032E1) ──
  static final _events = [
    _EventPin(
      'Summer Music Night',
      'Music',
      '8:00 PM',
      'Modiin Amphitheater',
      '₪50', 124,
      const LatLng(31.8960, 35.0080),
    ),
    _EventPin(
      'Modiin Community Festival',
      'Municipal & Community',
      '10:00 AM',
      'Modiin City Center',
      'FREE', 86,
      const LatLng(31.8945, 35.0120),
    ),
    _EventPin(
      'Family Fun Day',
      'Kids & Family',
      '11:00 AM',
      'Anava Park',
      '₪20', 86,
      const LatLng(31.8910, 35.0060),
    ),
    _EventPin(
      'Live Jazz Evening',
      'Music',
      '8:30 PM',
      'Local Cultural Center',
      '₪60', 51,
      const LatLng(31.8890, 35.0140),
    ),
    _EventPin(
      'Kids Cooking Workshop',
      'Kids & Family',
      '8:30 PM',
      'Local Cultural Center',
      '₪60', 51,
      const LatLng(31.8975, 35.0050),
    ),
    _EventPin(
      'Morning Yoga in the Park',
      'Sports',
      '7:00 AM',
      'Anava Park',
      'FREE', 89,
      const LatLng(31.8930, 35.0180),
    ),
    _EventPin(
      'Community Running Event',
      'Sports',
      '19:00 PM',
      'Anava Lake',
      'FREE', 167,
      const LatLng(31.8870, 35.0100),
    ),
    _EventPin(
      'Outdoor Movie Night',
      'Music',
      '9:00 PM',
      'Modiin Park',
      '₪30', 203,
      const LatLng(31.8955, 35.0160),
    ),
    _EventPin(
      'Art Workshop for Kids',
      'Kids & Family',
      '10:00 AM',
      'Community Center Buchman',
      '₪40', 67,
      const LatLng(31.8920, 35.0040),
    ),
    _EventPin(
      'Local Market Day',
      'Municipal & Community',
      '9:00 AM',
      'HaMar Center',
      'FREE', 298,
      const LatLng(31.8985, 35.0130),
    ),
    _EventPin(
      'Stand-Up Comedy Night',
      'Music',
      '9:30 PM',
      'Modiin Theater',
      '₪80', 145,
      const LatLng(31.8905, 35.0190),
    ),
    _EventPin(
      'Book Club Meetup',
      'Municipal & Community',
      '7:00 PM',
      'City Library',
      'FREE', 34,
      const LatLng(31.8940, 35.0020),
    ),
    _EventPin(
      'Startup Networking',
      'Municipal & Community',
      '6:00 PM',
      'WeWork Modiin',
      'FREE', 112,
      const LatLng(31.8965, 35.0095),
    ),
    _EventPin(
      'Weekend Bike Tour',
      'Sports',
      '8:00 AM',
      'Modiin Trails',
      '₪25', 78,
      const LatLng(31.8880, 35.0150),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Stack(
            children: [
              // ═══════════════════════════════════
              // Map
              // ═══════════════════════════════════
              FlutterMap(
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 14.5,
                  onTap: (_, _) => setState(() => _selectedPin = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.modiin4u.app',
                  ),
                  MarkerLayer(
                    markers: List.generate(_events.length, (i) {
                      final e = _events[i];
                      final isSelected = _selectedPin == i;
                      return Marker(
                        point: e.position,
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPin = i),
                          child: _EventMapPin(isSelected: isSelected),
                        ),
                      );
                    }),
                  ),
                ],
              ),

              // ═══════════════════════════════════
              // Search bar
              // ═══════════════════════════════════
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
                        child: Text(
                          'Search events, concerts, activities...',
                          style: TextStyle(fontFamily: AppFonts.inter, 
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6D6D6D),
                          ),
                        ),
                      ),
                      const Icon(
                        IconsaxPlusLinear.setting_4,
                        size: 20,
                        color: Color(0xFF123A72),
                      ),
                    ],
                  ),
                ),
              ),

              // ═══════════════════════════════════
              // Selected pin card overlay
              // ═══════════════════════════════════
              if (_selectedPin != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 80,
                  child: _EventCard(
                    event: _events[_selectedPin!],
                    onClose: () => setState(() => _selectedPin = null),
                  ),
                ),

              // ═══════════════════════════════════
              // "View as List" floating button
              // ═══════════════════════════════════
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Center(
                  child: GestureDetector(
                    onTap: () => context.push('/events'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
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
                            'View as List',
                            style: TextStyle(fontFamily: AppFonts.inter, 
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
// Data model
// ═══════════════════════════════════════════════
class _EventPin {
  final String title;
  final String category;
  final String time;
  final String venue;
  final String price;
  final int interested;
  final LatLng position;

  const _EventPin(
    this.title,
    this.category,
    this.time,
    this.venue,
    this.price,
    this.interested,
    this.position,
  );

  bool get isFree => price == 'FREE';
}

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
// Event popup card (horizontal layout: image + info)
// ═══════════════════════════════════════════════
class _EventCard extends StatelessWidget {
  final _EventPin event;
  final VoidCallback onClose;

  const _EventCard({
    required this.event,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: image + info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                width: 120,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0058B5), Color(0xFF010A36)],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        IconsaxPlusBold.calendar_1,
                        size: 32,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: GestureDetector(
                        onTap: onClose,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 14, color: Color(0xFF3D3D3D)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Info column
              Expanded(
                child: SizedBox(
                  height: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        event.title,
                        style: TextStyle(fontFamily: AppFonts.rubik, 
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 25 / 20,
                          color: const Color(0xFF0A1230),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Category
                      Text(
                        event.category,
                        style: TextStyle(fontFamily: AppFonts.inter, 
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF5F5E5A),
                        ),
                      ),
                      const SizedBox(height: 11),

                      // Time
                      Row(
                        children: [
                          const Icon(IconsaxPlusBold.clock,
                              size: 14, color: Color(0xFF17A9D0)),
                          const SizedBox(width: 8),
                          Text(
                            event.time,
                            style: TextStyle(fontFamily: AppFonts.inter, 
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF5F5E5A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Venue
                      Row(
                        children: [
                          const Icon(IconsaxPlusBold.location,
                              size: 14, color: Color(0xFF17A9D0)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.venue,
                              style: TextStyle(fontFamily: AppFonts.inter, 
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF5F5E5A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Price + interested
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            event.price,
                            style: TextStyle(fontFamily: AppFonts.rubik, 
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
                                  size: 16, color: Color(0xFF17A9D0)),
                              const SizedBox(width: 4),
                              Text(
                                '${event.interested} interested',
                                style: TextStyle(fontFamily: AppFonts.inter, 
                                  fontSize: 12,
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
              ),
            ],
          ),
          const SizedBox(height: 12),

          // "View Full Details" button
          GestureDetector(
            onTap: () => context.push('/event/map_${event.title.hashCode}'),
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF123A72),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Full Details',
                      style: TextStyle(fontFamily: AppFonts.inter, 
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      IconsaxPlusLinear.arrow_right_3,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
