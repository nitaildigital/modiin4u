import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'web_events_screen.dart';

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
class _MobileEventsContent extends StatelessWidget {
  const _MobileEventsContent();

  // ── Event categories ──
  static const _categories = [
    _Category('All Events', 157),
    _Category('Municipal &\nCommunity', 32),
    _Category('Music', 24),
    _Category('Kids & Family', 45),
    _Category('Sports', 15),
    _Category('Free', 41),
  ];

  // ── Events data ──
  static const _events = [
    _Event(
      'Summer Music Night',
      'Music',
      'AUG', 21,
      '8:00 PM',
      'Modiin Amphitheater',
      '₪50',
      124,
    ),
    _Event(
      'Modiin Community Festival',
      'Municipal & Community',
      'AUG', 22,
      '10:00 AM',
      'Modiin City Center',
      'FREE',
      86,
    ),
    _Event(
      'Family Fun Day',
      'Kids & Family',
      'AUG', 23,
      '11:00 AM',
      'Anava Park',
      '₪20',
      86,
    ),
    _Event(
      'Live Jazz Evening',
      'Music',
      'AUG', 24,
      '8:30 PM',
      'Local Cultural Center',
      '₪60',
      51,
    ),
    _Event(
      'Kids Cooking Workshop',
      'Kids & Family',
      'AUG', 26,
      '8:30 PM',
      'Local Cultural Center',
      '₪60',
      51,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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

                      // "Event Categories"
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Event Categories',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category circles row
                      _buildCategoryRow(),
                      const SizedBox(height: 24),

                      // "Events in Modiin"
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Events in Modiin',
                          style: GoogleFonts.inter(
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
                        child: Column(
                          children: [
                            for (int i = 0; i < _events.length; i++) ...[
                              _EventCard(event: _events[i], index: i),
                              if (i < _events.length - 1)
                                const SizedBox(height: 12),
                            ],
                          ],
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
                // Floating "Add to Calendar" button
                // ═══════════════════════════════════
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
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(IconsaxPlusLinear.calendar_1,
                              size: 16, color: Color(0xFF0A1230)),
                          const SizedBox(width: 6),
                          Text(
                            'Add to Calendar',
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
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Sticky header: back + title + search bar
  // ═══════════════════════════════════════════════
  Widget _buildStickyHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
      ),
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
                  'Events',
                  style: GoogleFonts.inter(
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
                    child: Text(
                      'Search events, concerts, activities...',
                      style: GoogleFonts.inter(
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
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Category circles horizontal row
  // ═══════════════════════════════════════════════
  Widget _buildCategoryRow() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 16),
        itemCount: _categories.length,
        itemBuilder: (_, i) => _CategoryCircle(category: _categories[i]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Data models
// ═══════════════════════════════════════════════
class _Category {
  final String name;
  final int count;
  const _Category(this.name, this.count);
}

class _Event {
  final String title;
  final String category;
  final String month;
  final int day;
  final String time;
  final String venue;
  final String price;
  final int interested;

  const _Event(
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
// Category circle (64px avatar + name + count)
// ═══════════════════════════════════════════════
class _CategoryCircle extends StatelessWidget {
  final _Category category;
  const _CategoryCircle({required this.category});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          // Circle avatar
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0058B5), Color(0xFF010A36)],
              ),
            ),
            child: Center(
              child: Icon(
                IconsaxPlusBold.calendar_1,
                size: 24,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Name
          Text(
            category.name,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Count
          Text(
            '${category.count}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF5F5E5A),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Event card (361 × 348)
// ═══════════════════════════════════════════════
class _EventCard extends StatelessWidget {
  final _Event event;
  final int index;
  const _EventCard({required this.event, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/event/event_$index'),
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
                    // Time
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
                    // Location
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
                    // Price
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
