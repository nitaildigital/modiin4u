import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../../../shared/widgets/network_photo.dart';
import '../models/listing.dart';
import '../providers/detail_providers.dart';
import '../providers/neighborhood_providers.dart';
import 'web_neighborhood_detail_screen.dart';

/// The design's outline icons, kept with the website's copies.
const _kAssets = 'assets/web/realestate';

class NeighborhoodDetailScreen extends StatelessWidget {
  final String neighborhoodId;
  const NeighborhoodDetailScreen({super.key, required this.neighborhoodId});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return WebNeighborhoodDetailContent(neighborhoodId: neighborhoodId);
        }
        return _MobileNeighborhoodDetailContent(neighborhoodId: neighborhoodId);
      },
    );
  }
}

class _MobileNeighborhoodDetailContent extends ConsumerWidget {
  final String neighborhoodId;
  const _MobileNeighborhoodDetailContent({required this.neighborhoodId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final neighborhood = ref.watch(neighborhoodByIdProvider(neighborhoodId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: neighborhood.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => _Message(
              text: L.of(context).couldNotLoadNeighborhood,
              onBack: () => context.pop(),
            ),
            data: (n) => n == null
                ? _Message(
                    text: L.of(context).neighborhoodNotFound,
                    onBack: () => context.pop(),
                  )
                : _buildBody(context, ref, n),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, Neighborhood n) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The neighbourhood's own photograph, then its gallery from
          // `entity_media` as the design's thumbnail strip — the same list
          // the website reads. Only real photographs: with one on file there
          // is no strip.
          _NeighborhoodPhotos(neighborhood: n),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Text(
              n.name,
              style: TextStyle(
                fontFamily: AppFonts.nunito,
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Icon(
                  IconsaxPlusLinear.location,
                  size: 16,
                  color: Color(0xFF888888),
                ),
                const SizedBox(width: 8),
                Text(
                  L.of(context).cityFullName,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6D6D6D),
                  ),
                ),
              ],
            ),
          ),

          _buildStatsGrid(context, ref, n),

          // Only when the client has written one. Three paragraphs about
          // Moriah — when it was settled, where its street names come from —
          // used to appear under every neighbourhood in the city.
          if (n.description != null) _buildAboutSection(context, n),

          _buildListingSection(context, ref, n, ListingKind.sale),
          _buildListingSection(context, ref, n, ListingKind.rent),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─────────────────────────────────
  // Stats grid 2×2
  // ─────────────────────────────────
  Widget _buildStatsGrid(BuildContext context, WidgetRef ref, Neighborhood n) {
    final counts = ref.watch(neighborhoodCountsProvider(n.id)).valueOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _StatCard(
                value: counts?.listings,
                label: L.of(context).propertiesForSale,
                asset: '$_kAssets/detail_stat_home.svg',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                value: counts?.businesses,
                label: L.of(context).businessesInArea,
                asset: '$_kAssets/detail_stat_shop.svg',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────
  // About section
  // ─────────────────────────────────
  Widget _buildAboutSection(BuildContext context, Neighborhood n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L.of(context).aboutPlace(n.name),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 12),
          ...n.description!.split('\n\n').map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                p.trim(),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF3D3D3D),
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────
  // Listing section with fade + View All
  // ─────────────────────────────────
  /// One neighbourhood's listings of a kind.
  ///
  /// Two flats for sale and two to let used to sit here, priced, addressed
  /// and titled "Apartments for Sale in Moriah" whichever neighbourhood was
  /// open. `listings` has no rows yet, so both sections say so instead.
  Widget _buildListingSection(
    BuildContext context,
    WidgetRef ref,
    Neighborhood n,
    ListingKind kind,
  ) {
    final listings =
        ref.watch(neighborhoodListingsProvider((n.id, kind))).valueOrNull ??
        const <Listing>[];

    final title = kind == ListingKind.rent
        ? L.of(context).apartmentsForRentIn(n.name)
        : L.of(context).apartmentsForSaleIn(n.name);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
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

          if (listings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                kind == ListingKind.rent
                    ? L.of(context).noRentInNeighborhood
                    : L.of(context).noSaleInNeighborhood,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  color: const Color(0xFF6D6D6D),
                ),
              ),
            )
          else ...[
            for (final listing in listings.take(3))
              _ListingCard(listing: listing),

            // Only worth offering when there is more than this screen shows.
            if (listings.length > 3)
              Center(
                child: GestureDetector(
                  onTap: () => context.goOrPush('/realestate'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF123A72)),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Text(
                      L.of(context).seeAll,
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
          ],
        ],
      ),
    );
  }
}

/// Shown in place of the page when the row cannot be loaded or does not
/// exist, so a bad id is not a blank screen.
class _Message extends StatelessWidget {
  final String text;
  final VoidCallback onBack;

  const _Message({required this.text, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 15,
              color: const Color(0xFF6D6D6D),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onBack, child: Text(L.of(context).sitePageBack)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Stat card widget
// ═══════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  /// Null while the count is still being fetched, which is why it shows a
  /// dash rather than a nought — nought is a claim, a dash is not.
  final int? value;
  final String label;
  final String asset;

  const _StatCard({required this.value, required this.label, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(asset, width: 32, height: 32),
          const SizedBox(height: 12),
          Text(
            value?.toString() ?? '—',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Listing data model
// ═══════════════════════════════════════════════
// ═══════════════════════════════════════════════
// Listing card widget
// ═══════════════════════════════════════════════
class _ListingCard extends StatelessWidget {
  final Listing listing;
  const _ListingCard({required this.listing});

  /// "₪3,650,000", or null where the row carries no price — which is not the
  /// same as free and must not read as ₪0.
  String? get _price {
    final amount = listing.effectivePrice;
    if (amount == null) return null;
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '₪$buffer';
  }

  bool get _isRent => listing.kind == ListingKind.rent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // The card was not tappable at all. Now it opens the row it shows.
      onTap: () => context.push('/listing/${listing.id}'),
      child: Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              children: [
                // The listing's own photograph where it has one, and the
                // brand panel where it does not, at the same size so nothing
                // shifts once the client uploads pictures.
                Positioned.fill(
                  child: NetworkPhoto(
                    url: listing.coverUrl,
                    fit: BoxFit.cover,
                    radius: BorderRadius.circular(12),
                    icon: IconsaxPlusBold.home_2,
                    iconSize: 48,
                  ),
                ),
                // Heart
                // A drawn heart that did nothing; it saves the listing now,
                // in the app (the website offers no saving).
                if (!kIsWeb)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: FavoriteButton(
                      kind: FavoriteKind.listing,
                      id: listing.id,
                      size: 40,
                      iconSize: 20,
                      color: const Color(0xFF123A72),
                    ),
                  ),
                // Badges
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
                        L.of(context).viaBroker,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0033AC),
                        ),
                      ),
                    ),
                  ),
                // A "New" badge sat here. `listings` records when a row was
                // created but nothing says what counts as new, so the badge
                // would have been a rule invented in this widget.
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          _price ?? '',
                          style: TextStyle(
                            fontFamily: AppFonts.nunito,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0A1230),
                          ),
                        ),
                        if (_isRent && _price != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            L.of(context).perMonth,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF5F5E5A),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _isRent ? L.of(context).forRent : L.of(context).forSale,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF17A9D0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Address
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
                        listing.address ?? listing.neighborhoodName ?? '',
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
                const SizedBox(height: 8),

                // Area / Rooms / Floor
                // Each figure only where the row has it, rather than a
                // dash or a nought standing in for one it does not.
                Row(
                  children: [
                    if (listing.sqm != null) ...[
                      _chip(
                        '$_kAssets/spec_sqm.svg',
                        '${listing.sqm} ${L.of(context).sqmUnit}',
                      ),
                      const SizedBox(width: 31),
                    ],
                    if (listing.rooms != null) ...[
                      _chip(
                        '$_kAssets/spec_rooms.svg',
                        '${_rooms(listing.rooms!)} ${L.of(context).roomsLabel}',
                      ),
                      const SizedBox(width: 31),
                    ],
                    if (listing.floor != null)
                      _chip(
                        '$_kAssets/spec_floor.svg',
                        L.of(context).floorLabel('${listing.floor}'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// Half rooms are normal here, so 3.5 must not print as 3.
  static String _rooms(double rooms) =>
      rooms == rooms.roundToDouble() ? '${rooms.toInt()}' : '$rooms';

  Widget _chip(String asset, String text) {
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
            fontWeight: FontWeight.w400,
            color: const Color(0xFF3D3D3D),
          ),
        ),
      ],
    );
  }
}

/// The photograph area of the design: the 260px hero, and under it a strip of
/// 66×44 thumbnails with the one on show outlined.
///
/// The hero swipes between the photographs and a thumbnail brings its own up;
/// tapping the hero opens them full size. Until the gallery arrives the hero
/// shows the neighbourhood's own picture, which the gallery lists first.
class _NeighborhoodPhotos extends ConsumerStatefulWidget {
  final Neighborhood neighborhood;
  const _NeighborhoodPhotos({required this.neighborhood});

  @override
  ConsumerState<_NeighborhoodPhotos> createState() =>
      _NeighborhoodPhotosState();
}

class _NeighborhoodPhotosState extends ConsumerState<_NeighborhoodPhotos> {
  final _pages = PageController();
  int _at = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _show(int i) {
    setState(() => _at = i);
    _pages.animateToPage(
      i,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _openViewer(List<String> photos, int start) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (_) => _PhotoViewer(urls: photos, start: start),
    );
  }

  @override
  Widget build(BuildContext context) {
    final own = widget.neighborhood.imageUrl;
    final photos =
        ref.watch(neighborhoodPhotosProvider(widget.neighborhood.id)).valueOrNull ??
        [if (own != null && own.trim().isNotEmpty) own];

    return Column(
      children: [
        SizedBox(
          height: 260,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photos.isEmpty)
                const NetworkPhoto(
                  url: null,
                  fit: BoxFit.cover,
                  icon: IconsaxPlusBold.buildings_2,
                  iconSize: 80,
                )
              else
                PageView.builder(
                  controller: _pages,
                  itemCount: photos.length,
                  onPageChanged: (i) => setState(() => _at = i),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _openViewer(photos, i),
                    child: NetworkPhoto(
                      url: photos[i],
                      fit: BoxFit.cover,
                      icon: IconsaxPlusBold.buildings_2,
                      iconSize: 80,
                    ),
                  ),
                ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
              ),
              // Back button, at the reading start; the arrow points right in
              // Hebrew.
              PositionedDirectional(
                start: 12,
                top: 51,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      AppIcons.back,
                      size: 20,
                      color: Color(0xFF3D3D3D),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (photos.length > 1)
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _show(i),
                child: Container(
                  width: 66,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: i == _at
                        ? Border.all(color: AppColors.midBlue, width: 2)
                        : null,
                  ),
                  child: NetworkPhoto(
                    url: photos[i],
                    fit: BoxFit.cover,
                    radius: BorderRadius.circular(i == _at ? 2 : 4),
                    icon: IconsaxPlusBold.buildings_2,
                    iconSize: 18,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The photographs full size over a dark page, swiped through; arrows too,
/// since a narrow browser window has a mouse rather than a finger.
///
/// The website's viewer (`DetailPhotoViewer`) keeps 96px either side for its
/// arrows, which on a phone would leave the photograph half the screen wide.
class _PhotoViewer extends StatefulWidget {
  final List<String> urls;
  final int start;
  const _PhotoViewer({required this.urls, required this.start});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final _pages = PageController(initialPage: widget.start);
  late int _at = widget.start;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = (_at + delta).clamp(0, widget.urls.length - 1);
    _pages.animateToPage(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Photographs page left to right in either language, as on the website.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pages,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _at = i),
            itemBuilder: (_, i) => InteractiveViewer(
              child: Center(
                child: NetworkPhoto(
                  url: widget.urls[i],
                  fit: BoxFit.contain,
                  icon: IconsaxPlusBold.buildings_2,
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ),
          if (widget.urls.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${_at + 1} / ${widget.urls.length}',
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    color: Colors.white70,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          if (_at > 0)
            Positioned(
              left: 4,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: () => _go(-1),
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 36),
                ),
              ),
            ),
          if (_at < widget.urls.length - 1)
            Positioned(
              right: 4,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: () => _go(1),
                  icon: const Icon(Icons.chevron_right, color: Colors.white, size: 36),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
