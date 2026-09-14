import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Favorites screen – horizontal filter chips (All, Restaurants, Events,
/// Bars, Apartments, News) and a scrollable list of favorited items,
/// each with image thumbnail, info rows, type badge, and red heart icon.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  int _activeFilter = 0;

  // ── Filter chips ──
  static const _filters = [
    _FilterDef('All', IconsaxPlusLinear.element_3),
    _FilterDef('Restaurants', IconsaxPlusLinear.shop),
    _FilterDef('Events', IconsaxPlusLinear.calendar_1),
    _FilterDef('Bars', IconsaxPlusLinear.coffee),
    _FilterDef('Apartments', IconsaxPlusLinear.building_3),
    _FilterDef('News', IconsaxPlusLinear.document_text),
  ];

  // ── Demo favorites ──
  static final _allFavorites = <_FavoriteItem>[
    _FavoriteItem(
      title: 'Premium Noga Café',
      location: 'Tel Aviv, Israel',
      rating: 4.8,
      reviewCount: 128,
      typeName: 'Cafe',
      typeColor: const Color(0xFF006BF6),
      category: 'Restaurants',
    ),
    _FavoriteItem(
      title: 'Modiin Music Festival',
      location: 'Modiin Amphitheater',
      date: 'May 24, 2026',
      typeName: 'Event',
      typeColor: const Color(0xFF7247ED),
      category: 'Events',
    ),
    _FavoriteItem(
      title: 'The Corner Bar',
      location: 'Emek HaEla St, Modiin',
      rating: 4.4,
      reviewCount: 128,
      typeName: 'Bar',
      typeColor: const Color(0xFFCC0001),
      category: 'Bars',
    ),
    _FavoriteItem(
      title: '₪3,650,000',
      location: 'Weizmann Street Modiin',
      area: '140 m²',
      rooms: '6 Rooms',
      typeName: 'Apartments',
      typeColor: const Color(0xFF1E40B5),
      category: 'Apartments',
    ),
    _FavoriteItem(
      title: 'The Garden Kitchen',
      location: 'Shlomo Hamelech St, Modiin',
      rating: 4.5,
      reviewCount: 132,
      typeName: 'Restaurant',
      typeColor: const Color(0xFF31AC4E),
      category: 'Restaurants',
    ),
    _FavoriteItem(
      title: 'New Walking and Cycling Path Opens in Modiin',
      date: 'May 24, 2026',
      typeName: 'News',
      typeColor: const Color(0xFF1E40B5),
      category: 'News',
    ),
  ];

  List<_FavoriteItem> get _filteredItems {
    if (_activeFilter == 0) return _allFavorites;
    final category = _filters[_activeFilter].label;
    return _allFavorites.where((f) => f.category == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ═══════════════════════════════════
                // Back button + title
                // ═══════════════════════════════════
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: Icon(
                            IconsaxPlusLinear.arrow_left,
                            size: 24,
                            color: Color(0xFF3D3D3D),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Favorites',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ═══════════════════════════════════
                // Filter chips (horizontal scroll)
                // ═══════════════════════════════════
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final f = _filters[index];
                      final active = index == _activeFilter;
                      return GestureDetector(
                        onTap: () => setState(() => _activeFilter = index),
                        child: Container(
                          height: 36,
                          padding: EdgeInsets.symmetric(
                            horizontal: index == 0 ? 15 : 12,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFFEEF4FD)
                                : Colors.white,
                            border: Border.all(
                              color: active
                                  ? const Color(0xFF123A72)
                                      .withValues(alpha: 0.8)
                                  : const Color(0xFFE7E7E7),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                f.icon,
                                size: 16,
                                color: active
                                    ? const Color(0xFF123A72)
                                    : const Color(0xFF6D6D6D),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                f.label,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: active
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  color: active
                                      ? const Color(0xFF123A72)
                                      : const Color(0xFF6D6D6D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // ═══════════════════════════════════
                // Favorites list
                // ═══════════════════════════════════
                Expanded(
                  child: items.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: items.length,
                          itemBuilder: (_, i) =>
                              _FavoriteCard(item: items[i]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              IconsaxPlusLinear.heart,
              size: 32,
              color: Color(0xFF6D6D6D),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No favorites yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save places and items you love',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6D6D6D),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Data models
// ═══════════════════════════════════════════════

class _FilterDef {
  final String label;
  final IconData icon;
  const _FilterDef(this.label, this.icon);
}

class _FavoriteItem {
  final String title;
  final String? location;
  final String? date;
  final double? rating;
  final int? reviewCount;
  final String? area;
  final String? rooms;
  final String typeName;
  final Color typeColor;
  final String category;

  const _FavoriteItem({
    required this.title,
    this.location,
    this.date,
    this.rating,
    this.reviewCount,
    this.area,
    this.rooms,
    required this.typeName,
    required this.typeColor,
    required this.category,
  });
}

// ═══════════════════════════════════════════════
// Favorite card – 120×100 image + info + heart
// ═══════════════════════════════════════════════

class _FavoriteCard extends StatelessWidget {
  final _FavoriteItem item;
  const _FavoriteCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image thumbnail ──
          Container(
            width: 120,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0058B5), Color(0xFF010A36)],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ── Info column ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0A1230),
                  ),
                ),
                const SizedBox(height: 8),

                // Location row
                if (item.location != null) ...[
                  Row(
                    children: [
                      const Icon(
                        IconsaxPlusLinear.location,
                        size: 14,
                        color: Color(0xFF6D6D6D),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.location!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6D6D6D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Date row (events & news)
                if (item.date != null) ...[
                  Row(
                    children: [
                      const Icon(
                        IconsaxPlusLinear.calendar_1,
                        size: 14,
                        color: Color(0xFF888888),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.date!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6D6D6D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Rating row (businesses)
                if (item.rating != null) ...[
                  Row(
                    children: [
                      const Icon(
                        IconsaxPlusBold.star_1,
                        size: 16,
                        color: Color(0xFFFFC107),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.rating!.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${item.reviewCount})',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6D6D6D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Area + rooms row (apartments)
                if (item.area != null) ...[
                  Row(
                    children: [
                      const Icon(
                        IconsaxPlusLinear.ruler,
                        size: 14,
                        color: Color(0xFF6D6D6D),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.area!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6D6D6D),
                        ),
                      ),
                      const SizedBox(width: 31),
                      const Icon(
                        IconsaxPlusLinear.house_2,
                        size: 14,
                        color: Color(0xFF6D6D6D),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.rooms ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6D6D6D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Type badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.typeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.typeName,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Heart icon ──
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(
              IconsaxPlusBold.heart,
              size: 20,
              color: Color(0xFFEB3F3C),
            ),
          ),
        ],
      ),
    );
  }
}
