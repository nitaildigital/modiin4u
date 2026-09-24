import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../businesses/models/business.dart';
import '../../businesses/providers/business_providers.dart';
import '../providers/restaurant_providers.dart';
import 'web_restaurants_screen.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../../favorites/repositories/favorite_repository.dart';

/// Restaurants discovery screen — responsive wrapper.
/// Desktop (> 1100px) renders the full web layout; mobile keeps the app UI.
class RestaurantsScreen extends StatelessWidget {
  const RestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return const WebRestaurantsContent();
        }
        return const _MobileRestaurantsContent();
      },
    );
  }
}

/// Mobile layout — hero banner, cuisine category cards,
/// vertical restaurant/coffee/bar listings with fade + "View All",
/// and a horizontal best-rated row. "Lunch nearby" is left out until the app
/// can ask for the device location.
class _MobileRestaurantsContent extends ConsumerStatefulWidget {
  const _MobileRestaurantsContent();

  @override
  ConsumerState<_MobileRestaurantsContent> createState() =>
      _MobileRestaurantsContentState();
}

class _MobileRestaurantsContentState
    extends ConsumerState<_MobileRestaurantsContent> {
  final int _bannerPage = 1; // 0-indexed, starts on second dot active

  // ── Popular Restaurants ──

  // ── Coffee Shops ──

  // ── Bars ──

  // ── Most Loved (horizontal) ──

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
                      const SizedBox(height: 16),

                      // Hero banner
                      _buildHeroBanner(),
                      const SizedBox(height: 12),

                      // Page dots
                      _buildPageDots(),
                      const SizedBox(height: 16),

                      // "Explore Modiin"
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'גלו את מודיעין',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Cuisine category cards
                      _buildCuisineRow(),
                      const SizedBox(height: 24),

                      // Restaurants
                      _buildVerticalSection(
                        'מסעדות במודיעין',
                        'restaurants',
                        'לכל המסעדות',
                      ),
                      const SizedBox(height: 40),

                      // Cafes and bakeries
                      _buildVerticalSection(
                        'בתי קפה ומאפיות',
                        'cafe-bakery',
                        'לכל בתי הקפה',
                      ),
                      const SizedBox(height: 40),

                      // Best rated
                      _buildHorizontalSection('המומלצים ביותר'),
                      const SizedBox(height: 40),

                      const SizedBox(height: 40),
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
                  child: _buildStickyHeader(),
                ),

                // ═══════════════════════════════════
                // Floating "View on Map" button
                // ═══════════════════════════════════
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: Center(
                    child: GestureDetector(
                      // The food map, not the general city map. This went to
                      // `/map`, which left `/restaurants-map` with no way in.
                      onTap: () => context.push('/restaurants-map'),
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
                              IconsaxPlusLinear.map,
                              size: 16,
                              color: Color(0xFF0A1230),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'הצג במפה',
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
  // Sticky header: title + search bar
  // ═══════════════════════════════════════════════
  Widget _buildStickyHeader() {
    return ClipRect(
      child: Container(
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9)),
        child: Column(
          children: [
            // Title
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
                    'מסעדות',
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
                      child: Text(
                        'חיפוש מסעדה, מטבח או מיקום',
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
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
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Hero banner
  // ═══════════════════════════════════════════════
  Widget _buildHeroBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 200,
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
            IconsaxPlusBold.reserve,
            size: 48,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Page dots
  // ═══════════════════════════════════════════════
  Widget _buildPageDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Container(
          width: 20,
          height: 4,
          margin: EdgeInsets.only(right: i < 2 ? 3 : 0),
          decoration: BoxDecoration(
            color: i == _bannerPage
                ? const Color(0xFF123A72)
                : const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(50),
          ),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════
  // Cuisine category horizontal row
  // ═══════════════════════════════════════════════
  Widget _buildCuisineRow() {
    final cuisines = ref.watch(cuisineCategoriesProvider);
    final counts =
        ref.watch(businessCountsByCategoryProvider).valueOrNull ?? const {};

    return SizedBox(
      height: 150,
      child: cuisines.when(
        loading: () => Skeleton(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, _) => const SkeletonBox(width: 120, radius: 12),
          ),
        ),
        error: (_, _) => ErrorRetry(
          onRetry: () => ref.invalidate(cuisineCategoriesProvider),
        ),
        data: (list) => list.isEmpty
            ? const SizedBox.shrink()
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _CuisineCard(
                  cuisine: _Cuisine.from(list[i], counts[list[i].id]),
                ),
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Vertical section (3 cards + fade + "View All")
  // ═══════════════════════════════════════════════
  /// Opens the full list for a section. The section knows its category by
  /// slug; the list screen addresses it by id, so it is resolved here rather
  /// than adding a second route that means the same thing.
  void _openCategory(String slug, String title) {
    final category = ref.read(categoriesBySlugProvider).valueOrNull?[slug];
    if (category == null) return;
    context.push(
      '/businesses/category/${category.id}?title=${Uri.encodeComponent(title)}',
    );
  }

  /// One category's businesses. [slug] names the category in the database,
  /// so the section follows whatever the admin panel defines.
  Widget _buildVerticalSection(String title, String slug, String viewAllLabel) {
    final provider = businessesBySlugProvider(slug);
    final places = (ref.watch(provider).valueOrNull ?? const <Business>[])
        .take(3)
        .map(_Place.from)
        .toList();
    if (places.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),

          // Cards stack with fade
          Stack(
            children: [
              Column(
                children: [
                  for (int i = 0; i < places.length; i++) ...[
                    _PlaceCard(place: places[i]),
                    if (i < places.length - 1) const SizedBox(height: 16),
                  ],
                ],
              ),

              // Fade gradient overlay at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 222,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00FFFFFF), Colors.white],
                    ),
                  ),
                ),
              ),

              // "View All" button
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => _openCategory(slug, title),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFF123A72)),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Center(
                        child: Text(
                          viewAllLabel,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF123A72),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Horizontal section (scroll cards)
  // ═══════════════════════════════════════════════
  Widget _buildHorizontalSection(String title) {
    final places =
        (ref.watch(topRatedBusinessesProvider).valueOrNull ??
                const <Business>[])
            .map(_HPlace.from)
            .toList();
    if (places.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          // Headroom over the card's fixed content, now that the name and
          // type lines are bounded to one line each.
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 18, right: 18),
            itemCount: places.length,
            separatorBuilder: (_, _) => const SizedBox(width: 20),
            itemBuilder: (_, i) => _HPlaceCard(place: places[i]),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// Data models
// ═══════════════════════════════════════════════
enum _BadgeColor { green, blue, red }

class _Cuisine {
  final String id;
  final String name;

  /// Null until `entity_categories` links businesses to categories, at which
  /// point the card picks up its count with no further change here.
  final int? count;

  final String? imageUrl;

  const _Cuisine(this.id, this.name, this.count, this.imageUrl);

  factory _Cuisine.from(BusinessCategory c, int? count) =>
      _Cuisine(c.id, c.name, count, c.imageUrl);
}

class _Place {
  final String id;
  final String name;
  final String type;
  final String address;
  final double rating;
  final int reviews;
  final bool isKosher;
  final String? imageUrl;
  final _BadgeColor badgeColor = _BadgeColor.green;

  const _Place(
    this.id,
    this.name,
    this.type,
    this.address,
    this.rating,
    this.reviews, {
    this.isKosher = false,
    this.imageUrl,
  });

  factory _Place.from(Business b) => _Place(
    b.id,
    b.name,
    b.description ?? '',
    [b.address, b.neighborhood].where((s) => s.isNotEmpty).join(', '),
    b.rating,
    b.reviewCount,
    isKosher: b.kosherLabel != null,
    imageUrl: b.imageUrl,
  );
}

class _HPlace {
  final String id;
  final String name;
  final String type;
  final String address;
  final double rating;
  final int reviews;
  final int? views;
  final String? imageUrl;
  final String? deliveryTime = null;

  const _HPlace(
    this.id,
    this.name,
    this.type,
    this.address,
    this.rating,
    this.reviews,
    this.views,
    this.imageUrl,
  );

  factory _HPlace.from(Business b) => _HPlace(
    b.id,
    b.name,
    b.description ?? '',
    [b.address, b.neighborhood].where((s) => s.isNotEmpty).join(', '),
    b.rating,
    b.reviewCount,
    null,
    b.imageUrl,
  );
}

// ═══════════════════════════════════════════════
// Cuisine category card (120 × 142.5)
// ═══════════════════════════════════════════════
class _CuisineCard extends StatelessWidget {
  final _Cuisine cuisine;
  const _CuisineCard({required this.cuisine});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NetworkPhoto(
            url: cuisine.imageUrl,
            height: 90,
            radius: const BorderRadius.vertical(top: Radius.circular(11)),
            icon: IconsaxPlusBold.reserve,
            iconSize: 24,
          ),
          // Label
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cuisine.name,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0A1230),
                  ),
                ),
                const SizedBox(height: 2.5),
                if (cuisine.count != null)
                  Text(
                    '${cuisine.count} מקומות',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF5F5E5A),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Full-width place card (361 × 340)
// ═══════════════════════════════════════════════
class _PlaceCard extends StatelessWidget {
  final _Place place;
  const _PlaceCard({required this.place});

  Color get _badgeCircleColor => switch (place.badgeColor) {
    _BadgeColor.green => const Color(0xFF31AC4E),
    _BadgeColor.blue => const Color(0xFF006BF6),
    _BadgeColor.red => const Color(0xFFCC0001),
  };

  IconData get _badgeIcon => switch (place.badgeColor) {
    _BadgeColor.green => IconsaxPlusBold.verify,
    _BadgeColor.blue => IconsaxPlusBold.coffee,
    _BadgeColor.red => IconsaxPlusBold.cup,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/business/${place.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                Positioned.fill(
                  child: NetworkPhoto(
                    url: place.imageUrl,
                    radius: BorderRadius.circular(12),
                    icon: IconsaxPlusBold.reserve,
                    iconSize: 40,
                  ),
                ),

                // Kosher badge
                if (place.isKosher)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      height: 27,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0033AC),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            IconsaxPlusLinear.shield_tick,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'כשר',
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Heart button
                Positioned(
                  right: 12,
                  top: 12,
                  child: FavoriteButton(
                    kind: FavoriteKind.business,
                    id: place.id,
                    size: 40,
                    iconSize: 23,
                    color: const Color(0xFF123A72),
                  ),
                ),

                // Places badge (colored circle)
                Positioned(
                  right: 12,
                  bottom: -20,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _badgeCircleColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Icon(_badgeIcon, size: 20, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + type
                Text(
                  place.name,
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1230),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  place.type,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF5F5E5A),
                  ),
                ),
                const SizedBox(height: 12),

                // Address
                Row(
                  children: [
                    const Icon(
                      IconsaxPlusBold.location,
                      size: 16,
                      color: Color(0xFF17A9D0),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        place.address,
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

                // A business nobody has reviewed says so, rather than
                // showing a gold star beside "0.0 (0)". The row also carried
                // "👁 0 Views" — in English, always zero, against no column.
                if (place.reviews == 0)
                  Text(
                    L.of(context).notRatedYet,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6D6D6D),
                    ),
                  )
                else
                  Row(
                    children: [
                      const Icon(
                        IconsaxPlusBold.star_1,
                        size: 16,
                        color: Color(0xFFFFC107),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        place.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${place.reviews})',
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6D6D6D),
                        ),
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

// ═══════════════════════════════════════════════
// Horizontal place card (250 × 266)
// ═══════════════════════════════════════════════
class _HPlaceCard extends StatelessWidget {
  final _HPlace place;
  const _HPlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/business/${place.id}'),
      child: SizedBox(
        width: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 150,
              child: Stack(
                children: [
                  NetworkPhoto(
                    url: place.imageUrl,
                    width: 250,
                    height: 150,
                    radius: BorderRadius.circular(12),
                    icon: IconsaxPlusBold.reserve,
                    iconSize: 32,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: FavoriteButton(
                      kind: FavoriteKind.business,
                      id: place.id,
                      size: 32,
                      iconSize: 19,
                      color: const Color(0xFF123A72),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Name + type
            Text(
              place.name,
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0A1230),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              place.type,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF5F5E5A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Address
            Row(
              children: [
                const Icon(
                  IconsaxPlusBold.location,
                  size: 16,
                  color: Color(0xFF17A9D0),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    place.address,
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
            const Spacer(),

            // Rating + time row
            Row(
              children: [
                if (place.reviews == 0)
                  Text(
                    L.of(context).notRatedYet,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6D6D6D),
                    ),
                  )
                else ...[
                  const Icon(
                    IconsaxPlusBold.star_1,
                    size: 16,
                    color: Color(0xFFFFC107),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    place.rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${place.reviews})',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6D6D6D),
                    ),
                  ),
                ],
                const SizedBox(width: 40),

                if (place.views != null) ...[
                  const Icon(
                    IconsaxPlusLinear.eye,
                    size: 16,
                    color: Color(0xFF0A1230),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${place.views}',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Views',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6D6D6D),
                    ),
                  ),
                ] else if (place.deliveryTime != null) ...[
                  const Icon(
                    IconsaxPlusLinear.clock,
                    size: 16,
                    color: Color(0xFF5D5D5D),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    place.deliveryTime!,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
