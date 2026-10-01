import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/network_photo.dart';
import '../models/listing.dart';
import '../providers/listing_providers.dart';
import '../widgets/m_listing_filter_sheet.dart';
import 'my_apartments_screen.dart' show formatShekels;
import 'web_realestate_map_screen.dart';
import '../../../shared/widgets/app_map.dart';

/// The real-estate map.
///
/// Fourteen invented properties lived in a `static final` list here, at
/// invented coordinates, and every "View full details" pushed `/listing/1` —
/// an id that cannot resolve, so the card's only action always failed. The
/// screen was also unreachable: nothing in the app navigated to
/// `/realestate-map` until the Real Estate tab's map button was wired up.
///
/// The phone layout is drawn to the Figma frame "Real Estate in Modiin Map
/// View", with "Map Card Overlay 2" for a tapped pin.
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return const WebRealEstateMapContent();
        }
        return _buildMobile(context);
      },
    );
  }

  Widget _buildMobile(BuildContext context) {
    final l = L.of(context);
    final filter = ref.watch(listingFilterProvider);
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
              // Google's map (AppMap). The frame draws every pin alike; the
              // chosen one is drawn larger so its card can be told apart.
              AppMap(
                center: _center,
                selectedId: _selectedId,
                onSelect: (id) => setState(() => _selectedId = id),
                pins: [
                  for (final listing in pinned)
                    AppMapPin(
                      id: listing.id,
                      position: LatLng(listing.latitude!, listing.longitude!),
                      asset: 'assets/web/map/pin_biz.svg',
                    ),
                ],
              ),

              // ── Search + filter control ──
              //
              // A `Text` before, with a filter icon that had no handler. The
              // icon opens the listing filters now, and carries a dot while
              // any of them is set — the same mark the Bars page's filter
              // control uses.
              Positioned(
                top: 58,
                left: 16,
                right: 16,
                child: Container(
                  height: 48,
                  padding: const EdgeInsetsDirectional.only(start: 16, end: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE7E7E7)),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/m_account_search.svg',
                        width: 18,
                        height: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          textInputAction: TextInputAction.search,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: l.searchByLocation,
                            hintStyle: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              color: const Color(0xFF6D6D6D),
                            ),
                            // The theme fills inputs grey, drawing a second
                            // pill inside this one; the frame has one.
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l.listingFilters,
                        onPressed: () => showListingFilterSheet(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 40,
                          height: 40,
                        ),
                        icon: Badge(
                          isLabelVisible: filter.hasFilters,
                          smallSize: 8,
                          backgroundColor: AppColors.turquoise,
                          child: SvgPicture.asset(
                            'assets/icons/m_realestate_filter.svg',
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Nothing to pin — said plainly rather than leaving an empty
              // map that looks broken.
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
                      _emptyMessage(l, filter),
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
                  child: _PropertyCard(
                    listing: selected,
                    onClose: () => setState(() => _selectedId = null),
                  ),
                ),

              // ── List View ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Center(
                  child: GestureDetector(
                    onTap: () => context.goOrPush('/realestate'),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Bullets lead the lines, so in Hebrew they sit on
                          // the right.
                          Transform.flip(
                            flipX:
                                Directionality.of(context) == TextDirection.rtl,
                            child: SvgPicture.asset(
                              'assets/icons/m_realestate_list.svg',
                              width: 16,
                              height: 16,
                            ),
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

  /// Two different emptinesses: nothing matched what was asked, or nothing
  /// on file has a location at all. Saying the first when the second is true
  /// sends the reader off to loosen filters that were never the reason, so
  /// the unfiltered list is asked — and only when this map is empty.
  String _emptyMessage(L l, ListingFilter filter) {
    final narrowed = filter.hasFilters || (filter.search ?? '').isNotEmpty;
    if (!narrowed) return l.noListingsOnMap;
    final anyPinned =
        (ref.watch(allActiveListingsProvider).valueOrNull ?? const [])
            .any((x) => x.latitude != null && x.longitude != null);
    return anyPinned ? l.noListingsMatch : l.noListingsOnMap;
  }
}

// ═══════════════════════════════════════════════
// Selected property card — "Map Card Overlay 2"
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
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // Only the figures the listing carries; the card used to print
    // "140 m², 6 Rooms, Floor 3" whatever it was. The frame sets them two to
    // a row.
    final specs = <Widget>[
      if (listing.sqm != null)
        _spec(
          'assets/web/realestate/detail_card_area.svg',
          '${listing.sqm} ${l.sqmUnit}',
        ),
      if (listing.rooms != null)
        _spec(
          'assets/web/realestate/detail_card_rooms.svg',
          '${_rooms(listing.rooms!)} ${l.roomsLabel}',
        ),
      if (listing.floor != null)
        _spec(
          'assets/web/realestate/detail_card_floor.svg',
          l.floorLabel('${listing.floor}'),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
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
                      child: NetworkPhoto(
                        url: listing.coverUrl,
                        width: 120,
                        height: 140,
                        radius: BorderRadius.circular(8),
                        icon: IconsaxPlusBold.home_2,
                      ),
                    ),
                    // The frame has no close control; the restaurants map's
                    // card keeps one here, and so does this one, since a tap
                    // on the map behind is not an obvious way out.
                    PositionedDirectional(
                      end: 4,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The badge said FOR SALE on every card, lettings
                    // included.
                    Text(
                      listing.kind == ListingKind.rent
                          ? l.forRentBadge
                          : l.forSaleBadge,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.turquoise,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // The frame heads the card with the price. A listing
                    // posted without one is headed by its title instead,
                    // rather than by nothing.
                    Text(
                      price != null
                          ? (listing.kind == ListingKind.rent
                                ? l.pricePerMonthValue(formatShekels(price))
                                : formatShekels(price))
                          : listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        // "Avenir Next Rounded Pro Demi" in the frame.
                        fontFamily: AppFonts.nunito,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 25 / 20,
                        color: AppColors.navy,
                      ),
                    ),

                    if (address != null && address.isNotEmpty) ...[
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/m_deals_pin.svg',
                            width: 14,
                            height: 14,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 12,
                                color: AppColors.grayText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    for (var i = 0; i < specs.length; i += 2) ...[
                      SizedBox(height: i == 0 ? 11 : 16),
                      Row(
                        children: [
                          specs[i],
                          if (i + 1 < specs.length) ...[
                            const SizedBox(width: 16),
                            specs[i + 1],
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          GestureDetector(
            // This pushed `/listing/1` for every pin — an id that cannot
            // resolve, so the card's only action always failed.
            onTap: () => context.push('/listing/${listing.id}'),
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.midBlue,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                  // Forward: → in English, ← in Hebrew.
                  Transform.flip(
                    flipX: isRtl,
                    child: SvgPicture.asset(
                      'assets/icons/m_account_arrow_right.svg',
                      width: 16,
                      height: 16,
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

  Widget _spec(String icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(icon, width: 14, height: 14),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 12,
            color: const Color(0xFF3D3D3D),
          ),
        ),
      ],
    );
  }
}
