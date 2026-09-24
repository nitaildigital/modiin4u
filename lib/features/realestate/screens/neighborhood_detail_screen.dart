import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../models/listing.dart';
import '../providers/neighborhood_providers.dart';
import 'web_neighborhood_detail_screen.dart';

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
              text: 'לא הצלחנו לטעון את השכונה',
              onBack: () => context.pop(),
            ),
            data: (n) => n == null
                ? _Message(
                    text: 'השכונה לא נמצאה',
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
          // The neighbourhood's own photograph where the admin has set one.
          // Five tappable gradient rectangles sat under this as a thumbnail
          // strip; `neighborhoods` holds a single image, so there was never
          // a gallery to page through.
          _buildHeroImage(context, n),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Text(
              n.name,
              style: TextStyle(
                fontFamily: AppFonts.rubik,
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
                  'מודיעין מכבים רעות',
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

          _buildStatsGrid(ref, n),

          // Only when the client has written one. Three paragraphs about
          // Moriah — when it was settled, where its street names come from —
          // used to appear under every neighbourhood in the city.
          if (n.description != null) _buildAboutSection(n),

          _buildListingSection(context, ref, n, ListingKind.sale),
          _buildListingSection(context, ref, n, ListingKind.rent),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─────────────────────────────────
  // Hero image
  // ─────────────────────────────────
  Widget _buildHeroImage(BuildContext context, Neighborhood n) {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NetworkPhoto(
            url: n.imageUrl,
            fit: BoxFit.cover,
            icon: IconsaxPlusBold.buildings_2,
            iconSize: 80,
          ),
          DecoratedBox(
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
          // Back button
          Positioned(
            left: 12,
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
                  IconsaxPlusLinear.arrow_left,
                  size: 20,
                  color: Color(0xFF3D3D3D),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────
  // Stats grid 2×2
  // ─────────────────────────────────
  Widget _buildStatsGrid(WidgetRef ref, Neighborhood n) {
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
                label: 'נכסים למכירה',
                icon: IconsaxPlusBold.home_2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                value: counts?.businesses,
                label: 'עסקים באזור',
                icon: IconsaxPlusBold.shop,
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
  Widget _buildAboutSection(Neighborhood n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'אודות ${n.name}',
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
        ? 'דירות להשכרה ב${n.name}'
        : 'דירות למכירה ב${n.name}';

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
                    ? 'אין כרגע דירות להשכרה בשכונה הזו'
                    : 'אין כרגע דירות למכירה בשכונה הזו',
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'ראה הכל',
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
          TextButton(onPressed: onBack, child: const Text('חזרה')),
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
  final IconData icon;

  const _StatCard({required this.value, required this.label, required this.icon});

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
          Icon(icon, size: 32, color: const Color(0xFF123A72)),
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
                    child: const Icon(
                      IconsaxPlusLinear.heart,
                      size: 20,
                      color: Color(0xFF123A72),
                    ),
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
                        'Via Broker',
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
                            fontFamily: AppFonts.rubik,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0A1230),
                          ),
                        ),
                        if (_isRent && _price != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'לחודש',
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
                      _isRent ? 'להשכרה' : 'למכירה',
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
                    const Icon(
                      IconsaxPlusBold.location,
                      size: 16,
                      color: Color(0xFF17A9D0),
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
                        IconsaxPlusLinear.maximize_3,
                        '${listing.sqm} מ"ר',
                      ),
                      const SizedBox(width: 31),
                    ],
                    if (listing.rooms != null) ...[
                      _chip(
                        IconsaxPlusLinear.building_3,
                        '${_rooms(listing.rooms!)} חדרים',
                      ),
                      const SizedBox(width: 31),
                    ],
                    if (listing.floor != null)
                      _chip(
                        IconsaxPlusLinear.building_4,
                        'קומה ${listing.floor}',
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

  Widget _chip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6D6D6D)),
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
