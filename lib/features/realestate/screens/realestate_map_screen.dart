import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../models/listing.dart';
import '../providers/listing_providers.dart';
import 'my_apartments_screen.dart' show formatShekels;

/// The real-estate map.
///
/// Fourteen invented properties lived in a `static final` list here, at
/// invented coordinates, and every "View full details" pushed `/listing/1` —
/// an id that cannot resolve, so the card's only action always failed. The
/// screen was also unreachable: nothing in the app navigated to
/// `/realestate-map` until the Real Estate tab's map button was wired up.
class RealEstateMapScreen extends ConsumerStatefulWidget {
  const RealEstateMapScreen({super.key});

  @override
  ConsumerState<RealEstateMapScreen> createState() =>
      _RealEstateMapScreenState();
}

class _RealEstateMapScreenState extends ConsumerState<RealEstateMapScreen> {
  String? _selectedId;
  final _searchController = TextEditingController();
  Timer? _debounce;

  static const _center = LatLng(31.8928, 35.0104);

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(listingFilterProvider).search ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final f = ref.read(listingFilterProvider);
      ref.read(listingFilterProvider.notifier).state = f.copyWith(
        search: value.trim(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    // A pin needs coordinates. A listing without them is not on the map,
    // which is why the count here can differ from the list.
    final pinned =
        (ref.watch(listingsProvider).valueOrNull ?? const <Listing>[])
            .where((x) => x.latitude != null && x.longitude != null)
            .toList();
    final selected = pinned.where((x) => x.id == _selectedId).firstOrNull;

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
                      for (final listing in pinned)
                        Marker(
                          point: LatLng(listing.latitude!, listing.longitude!),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedId = listing.id),
                            child: _PropertyPin(
                              isSelected: _selectedId == listing.id,
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
                            hintText: l.searchByLocation,
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

              // Nothing to pin at all — said plainly rather than leaving an
              // empty map that looks broken.
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
                      l.noListingsOnMap,
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
                  left: 16,
                  right: 16,
                  bottom: 80,
                  child: _PropertyCard(
                    listing: selected,
                    onClose: () => setState(() => _selectedId = null),
                  ),
                ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Center(
                  child: GestureDetector(
                    onTap: () => context.goOrPush('/realestate'),
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
// Property map pin (white circle + blue inner circle + icon)
// ═══════════════════════════════════════════════
class _PropertyPin extends StatelessWidget {
  final bool isSelected;

  const _PropertyPin({this.isSelected = false});

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
            color: isSelected
                ? const Color(0xFF17A9D0)
                : const Color(0xFF006BF6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            IconsaxPlusBold.home_2,
            size: 12,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Selected property card
// ═══════════════════════════════════════════════
class _PropertyCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onClose;

  const _PropertyCard({required this.listing, required this.onClose});

  /// 3.5 reads as "3.5"; 4.0 reads as "4".
  static String _rooms(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final price = listing.effectivePrice;
    final address = listing.address ?? listing.neighborhoodName;

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
              if (price != null)
                Text(
                  listing.kind == ListingKind.rent
                      ? l.pricePerMonthValue(formatShekels(price))
                      : formatShekels(price),
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A1230),
                  ),
                ),
              const Spacer(),
              // The badge said FOR SALE on every card, lettings included.
              Text(
                listing.kind == ListingKind.rent
                    ? l.forRentBadge
                    : l.forSaleBadge,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF17A9D0),
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

          const SizedBox(height: 8),
          Text(
            listing.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A1230),
            ),
          ),

          if (address != null && address.isNotEmpty) ...[
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
                    address,
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

          // Only the figures the listing carries; the card used to print
          // "140 m², 6 Rooms, Floor 3" whatever it was.
          if (listing.sqm != null ||
              listing.rooms != null ||
              listing.floor != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (listing.sqm != null) ...[
                  _chip(
                    IconsaxPlusLinear.maximize_3,
                    '${listing.sqm} ${l.sqmUnit}',
                  ),
                  const SizedBox(width: 20),
                ],
                if (listing.rooms != null) ...[
                  _chip(
                    IconsaxPlusLinear.building_3,
                    '${_rooms(listing.rooms!)} ${l.roomsLabel}',
                  ),
                  const SizedBox(width: 20),
                ],
                if (listing.floor != null)
                  _chip(
                    IconsaxPlusLinear.building_4,
                    l.floorLabel('${listing.floor}'),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          GestureDetector(
            // This pushed `/listing/1` for every pin — an id that cannot
            // resolve, so the card's only action always failed.
            onTap: () => context.push('/listing/${listing.id}'),
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

  Widget _chip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6D6D6D)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 13,
            color: const Color(0xFF5F5E5A),
          ),
        ),
      ],
    );
  }
}
