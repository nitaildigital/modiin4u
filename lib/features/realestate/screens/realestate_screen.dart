import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../models/listing.dart';
import '../providers/listing_providers.dart';
import '../widgets/m_price_text.dart';
import 'web_realestate_screen.dart';

/// The Real Estate tab.
///
/// This was eight invented flats held in two `const` lists — ₪3,650,000 at
/// "3 Yona Hanavi Street" and so on — with cards that could not be tapped,
/// property-type chips that selected but filtered nothing, a search field
/// that was a `Text`, and a floating button labelled "Sign up with Email",
/// copied from an auth screen, that did nothing. `listingsProvider` existed
/// and this file imported nothing.
/// The outline icons the design uses, kept with the website's copies.
const _kAssets = 'assets/web/realestate';

class RealEstateScreen extends StatelessWidget {
  const RealEstateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return const WebRealEstateContent();
        }
        return const _MobileRealEstateContent();
      },
    );
  }
}

class _MobileRealEstateContent extends ConsumerStatefulWidget {
  const _MobileRealEstateContent();

  @override
  ConsumerState<_MobileRealEstateContent> createState() =>
      _MobileRealEstateContentState();
}

class _MobileRealEstateContentState
    extends ConsumerState<_MobileRealEstateContent> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  /// The design's outline type icons — the website's copies of the same
  /// drawings.
  static const _types = [
    (PropertyType.apartment, '$_kAssets/type_apartment.svg'),
    (PropertyType.penthouse, '$_kAssets/type_penthouse.svg'),
    (PropertyType.garden, '$_kAssets/type_garden.svg'),
    (PropertyType.duplex, '$_kAssets/type_duplex.svg'),
    (PropertyType.villa, '$_kAssets/type_villa.svg'),
    (PropertyType.studio, '$_kAssets/type_studio.svg'),
  ];

  @override
  void initState() {
    super.initState();
    // The tab opens on sale, which is what the two buttons below assume.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final f = ref.read(listingFilterProvider);
      if (f.kind == null) {
        ref.read(listingFilterProvider.notifier).state = f.copyWith(
          kind: ListingKind.sale,
        );
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Typing runs a query, so it waits for a pause rather than firing on
  /// every keystroke.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final f = ref.read(listingFilterProvider);
      ref.read(listingFilterProvider.notifier).state = f.copyWith(
        search: value.trim(),
      );
    });
  }

  static String _typeLabel(L l, PropertyType t) => switch (t) {
    PropertyType.apartment => l.propTypeApartment,
    PropertyType.penthouse => l.propTypePenthouse,
    PropertyType.garden => l.propTypeGarden,
    PropertyType.duplex => l.propTypeDuplex,
    PropertyType.villa => l.propTypeVilla,
    PropertyType.studio => l.propTypeStudio,
    PropertyType.other => l.propTypeOther,
  };

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final filter = ref.watch(listingFilterProvider);
    final async = ref.watch(listingsProvider);
    final listings = async.valueOrNull ?? const <Listing>[];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 300)),

                    if (async.isLoading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (listings.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _empty(l, filter),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _ListingCard(
                                listing: listings[index],
                                onTap: () => context.push(
                                  '/listing/${listings[index].id}',
                                ),
                              ),
                            ),
                            childCount: listings.length,
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 72)),
                  ],
                ),

                // ── Fixed header ──
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: const Color(0xE6FFFFFF),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        // Back arrow and centred title, as in the design. The
                        // arrow only when there is somewhere to go back to.
                        SizedBox(
                          height: 24,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                // The title read "Filter Your Discover Feed".
                                l.realEstateInModiin,
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              if (context.canPop())
                                PositionedDirectional(
                                  start: 15,
                                  child: GestureDetector(
                                    onTap: () => context.pop(),
                                    child: const Icon(
                                      Icons.arrow_back,
                                      size: 24,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Search — a `Text` before, so nothing could be typed.
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFE7E7E7),
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
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
                                    // The app theme fills every field; the
                                    // design's search is a plain white pill.
                                    decoration: InputDecoration(
                                      filled: false,
                                      contentPadding: EdgeInsets.zero,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
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
                                const SizedBox(width: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Property-type chips. These used to set a field that
                        // nothing read, so a chip selected and the list
                        // stayed exactly as it was.
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _types.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final (type, asset) = _types[index];
                              final selected = filter.propertyType == type;
                              return GestureDetector(
                                onTap: () {
                                  final f = ref.read(listingFilterProvider);
                                  ref
                                      .read(listingFilterProvider.notifier)
                                      .state = selected
                                      ? f.copyWith(clearPropertyType: true)
                                      : f.copyWith(propertyType: type);
                                },
                                child: Container(
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.midBlue
                                          : const Color(0xFFE7E7E7),
                                      width: selected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        asset,
                                        width: 32,
                                        height: 32,
                                      ),
                                      const SizedBox(height: 6),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                        ),
                                        child: Text(
                                          _typeLabel(l, type),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: AppFonts.inter,
                                            fontSize: 14,
                                            fontWeight: selected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              _TabButton(
                                label: l.forSale,
                                active: filter.kind == ListingKind.sale,
                                onTap: () => _setKind(ListingKind.sale),
                              ),
                              const SizedBox(width: 20),
                              _TabButton(
                                label: l.forRent,
                                active: filter.kind == ListingKind.rent,
                                onTap: () => _setKind(ListingKind.rent),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // ── Floating map button ──
                //
                // It read "Sign up with Email" and had no handler, which is
                // why the map screen was reachable from nowhere in the app.
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => context.push('/realestate-map'),
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              IconsaxPlusLinear.map_1,
                              size: 16,
                              color: AppColors.navy,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l.viewOnMapBtn,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.navy,
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

  void _setKind(ListingKind kind) {
    final f = ref.read(listingFilterProvider);
    ref.read(listingFilterProvider.notifier).state = f.copyWith(kind: kind);
  }

  Widget _empty(L l, ListingFilter filter) {
    // "Nothing here yet" and "nothing matched what you asked for" are
    // different things to a reader.
    final filtering =
        (filter.search ?? '').isNotEmpty || filter.propertyType != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F2F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              IconsaxPlusLinear.home_2,
              size: 30,
              color: Color(0xFF6D6D6D),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            filtering ? l.noListingsMatch : l.noListingsYet,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          if (!filtering) ...[
            const SizedBox(height: 8),
            Text(
              l.noListingsYetBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 13,
                color: const Color(0xFF6D6D6D),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Tab button
// ═══════════════════════════════════════════════
class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.midBlue : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: active ? 20 : 16,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? AppColors.midBlue : const Color(0xFF6D6D6D),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Listing card (full-width image + details)
// ═══════════════════════════════════════════════
class _ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onTap;

  const _ListingCard({required this.listing, this.onTap});

  /// 3.5 reads as "3.5"; 4.0 reads as "4".
  static String _rooms(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : '$v';

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final price = listing.effectivePrice;
    // As on the website's card and in the design: the place, with the
    // listing's own title standing in when there is no address.
    final address = listing.address ?? listing.neighborhoodName;
    final place = (address == null || address.isEmpty) ? listing.title : address;
    // Anything posted in the last fortnight. The badge used to be a fixed
    // flag on four of the eight invented flats.
    final isNew = DateTime.now().difference(listing.createdAt).inDays < 14;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // A flat pastel rectangle with a grey image glyph stood here.
              NetworkPhoto(
                url: listing.coverUrl,
                height: 200,
                width: double.infinity,
                radius: BorderRadius.circular(12),
                icon: IconsaxPlusBold.home_2,
                iconSize: 48,
              ),

              if (listing.isBroker)
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCD6EE),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      l.viaBroker,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0033AC),
                      ),
                    ),
                  ),
                ),

              if (isNew)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.turquoise,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      l.newBadge,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // A drawn heart before — it saves the listing now.
              // The button draws its own circle, and nothing on the website
              // (no saving there), so no empty white disc is left behind.
              if (!kIsWeb)
                Positioned(
                  right: 12,
                  top: 12,
                  child: FavoriteButton(
                    kind: FavoriteKind.listing,
                    id: listing.id,
                    size: 40,
                    iconSize: 23,
                    color: AppColors.midBlue,
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (price != null)
                      MPriceText(
                        amount: price,
                        kind: listing.kind,
                        color: AppColors.navy,
                      )
                    else
                      const SizedBox.shrink(),
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
                  ],
                ),

                if (place.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: Center(
                          child: SvgPicture.asset(
                            '$_kAssets/card_pin.svg',
                            width: 12,
                            height: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          place,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                            color: const Color(0xFF5F5E5A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // Only the figures the listing carries. Every one of the
                // eight invented cards printed 140 m², 6 rooms and floor 3.
                if (listing.sqm != null ||
                    listing.rooms != null ||
                    listing.floor != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (listing.sqm != null) ...[
                        _Spec(
                          asset: '$_kAssets/spec_sqm.svg',
                          text: '${listing.sqm} ${l.sqmUnit}',
                        ),
                        const SizedBox(width: 24),
                      ],
                      if (listing.rooms != null) ...[
                        _Spec(
                          asset: '$_kAssets/spec_rooms.svg',
                          text: '${_rooms(listing.rooms!)} ${l.roomsLabel}',
                        ),
                        const SizedBox(width: 24),
                      ],
                      if (listing.floor != null)
                        _Spec(
                          asset: '$_kAssets/spec_floor.svg',
                          text: l.floorLabel('${listing.floor}'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One icon-and-text figure on a listing card.
class _Spec extends StatelessWidget {
  final String asset;
  final String text;
  const _Spec({required this.asset, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(asset, width: 14, height: 14),
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
