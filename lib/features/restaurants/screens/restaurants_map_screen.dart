import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/restaurant_providers.dart';
import 'web_restaurants_map_screen.dart';

/// Restaurants map view — responsive wrapper.
/// Desktop (> 1100px) renders the web search + map layout; mobile keeps the app UI.
class RestaurantsMapScreen extends StatelessWidget {
  const RestaurantsMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return const WebRestaurantsMapContent();
        }
        return const _MobileRestaurantsMapContent();
      },
    );
  }
}

/// Mobile layout — the city's food businesses as pins, with a search box,
/// a tappable card per pin, and a "View as List" toggle.
class _MobileRestaurantsMapContent extends ConsumerStatefulWidget {
  const _MobileRestaurantsMapContent();

  @override
  ConsumerState<_MobileRestaurantsMapContent> createState() =>
      _MobileRestaurantsMapContentState();
}

class _MobileRestaurantsMapContentState
    extends ConsumerState<_MobileRestaurantsMapContent> {
  /// The selected place by id, not by index: the list changes as the search
  /// narrows it, so an index would point at a different place afterwards.
  String? _selectedId;

  final _searchController = TextEditingController();
  Timer? _debounce;

  // Modi'in centre.
  static const _center = LatLng(31.8928, 35.0104);

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      ref.read(restaurantMapSearchProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    // A pin needs coordinates, so the map can show fewer places than the list
    // does.
    final places =
        (ref.watch(filteredFoodMapPlacesProvider).valueOrNull ??
                const <FoodPlace>[])
            .where((p) => p.hasLocation)
            .toList();
    final selected = places
        .where((p) => p.business.id == _selectedId)
        .firstOrNull;

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
                      for (final place in places)
                        Marker(
                          point: LatLng(
                            place.business.latitude,
                            place.business.longitude,
                          ),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedId = place.business.id),
                            child: _MapPin(
                              isCafe: place.isCafe,
                              isSelected: _selectedId == place.business.id,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // ── Search ──
              //
              // A `Text` before, so nothing could be typed.
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
                            hintText: l.searchPlaces,
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

              // Said plainly rather than left as an empty map, which reads as
              // a failure to load.
              if (places.isEmpty)
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
                      // Two different emptinesses: nothing matched what was
                      // typed, or nothing in the city has coordinates. Saying
                      // the second when the first is true sounds like a fault.
                      // The provider, not the controller: it is what the
                      // list was actually filtered by, and it is what this
                      // rebuild is watching.
                      ref.watch(restaurantMapSearchProvider).trim().isEmpty
                          ? l.noPlacesOnMap
                          : l.noPlacesMatch,
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
                  child: _PlaceCard(
                    place: selected,
                    onClose: () => setState(() => _selectedId = null),
                  ),
                ),

              // ── "View as List" ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Center(
                  child: GestureDetector(
                    onTap: () => context.push('/restaurants'),
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
                            l.viewAsList,
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
// Map pin — white circle, coloured inner circle, icon.
//
// Green for a restaurant, blue for a café. The design also has a red bar pin,
// but there is no bar category in the database, so nothing can fill it.
// ═══════════════════════════════════════════════
class _MapPin extends StatelessWidget {
  final bool isCafe;
  final bool isSelected;

  const _MapPin({required this.isCafe, this.isSelected = false});

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
          decoration: BoxDecoration(
            color: isCafe ? const Color(0xFF006BF6) : const Color(0xFF31AC4E),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCafe ? IconsaxPlusBold.coffee : IconsaxPlusBold.reserve,
            size: 12,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// The card for the selected pin.
// ═══════════════════════════════════════════════
class _PlaceCard extends StatelessWidget {
  final FoodPlace place;
  final VoidCallback onClose;

  const _PlaceCard({required this.place, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final business = place.business;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                height: 140,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _CoverImage(url: business.imageUrl),
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
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Color(0xFF3D3D3D),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: SizedBox(
                  height: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.name,
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 25 / 20,
                          color: const Color(0xFF0A1230),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      Text(
                        place.categoryName,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF5F5E5A),
                        ),
                      ),

                      if (business.address.isNotEmpty) ...[
                        const SizedBox(height: 11),
                        Row(
                          children: [
                            const Icon(
                              IconsaxPlusBold.location,
                              size: 14,
                              color: Color(0xFF17A9D0),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                business.address,
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF5F5E5A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Spacer(),

                      // Only where reviews have earned one. The card used to
                      // print a rating and a review count for every place,
                      // copied between them, and a "Views" figure the
                      // businesses table has no column for.
                      if (business.rating > 0)
                        Row(
                          children: [
                            const Icon(
                              IconsaxPlusBold.star_1,
                              size: 16,
                              color: Color(0xFFFFC107),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              business.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${business.reviewCount})',
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
              ),
            ],
          ),
          const SizedBox(height: 12),

          GestureDetector(
            // The real row, so the detail page can load it. This used to push
            // `/business/restaurant_<hashCode>`, which matched nothing.
            onTap: () => context.push('/business/${business.id}'),
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
                      l.viewFullDetails,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
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

/// The cover photo, or the brand gradient where a business has none — which
/// is most of them.
class _CoverImage extends StatelessWidget {
  final String? url;

  const _CoverImage({required this.url});

  static const _fallback = DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0058B5), Color(0xFF010A36)],
      ),
    ),
    child: Center(
      child: Icon(IconsaxPlusBold.reserve, size: 32, color: Colors.white24),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final src = url;
    if (src == null || src.isEmpty) return _fallback;
    return Image.network(
      src,
      fit: BoxFit.cover,
      // A broken link should look like a place with no photo, not like an
      // error.
      errorBuilder: (_, _, _) => _fallback,
    );
  }
}
