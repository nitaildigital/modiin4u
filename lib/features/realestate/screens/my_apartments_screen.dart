import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/month_names.dart';
import '../../../shared/widgets/network_photo.dart';
import '../models/listing.dart';
import '../providers/listing_providers.dart';

/// My Apartments – what this person has posted, with its status.
///
/// The list was three invented flats in Tel Aviv with fixed dates, shown to
/// everyone and identical for everyone. It reads `listings` now, filtered to
/// the signed-in owner by the row level security policy.
class MyApartmentsScreen extends ConsumerStatefulWidget {
  const MyApartmentsScreen({super.key});

  @override
  ConsumerState<MyApartmentsScreen> createState() => _MyApartmentsScreenState();
}

class _MyApartmentsScreenState extends ConsumerState<MyApartmentsScreen> {
  final _searchController = TextEditingController();

  /// Searching is done here rather than in a query: this is one person's own
  /// listings, so the list is short and a round trip per keystroke would be
  /// worse than filtering what is already loaded.
  List<Listing> _filter(List<Listing> all) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where(
          (l) =>
              l.title.toLowerCase().contains(q) ||
              (l.address ?? '').toLowerCase().contains(q) ||
              (l.neighborhoodName ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final mine = ref.watch(myListingsProvider);
    final all = mine.valueOrNull ?? const <Listing>[];
    final listings = _filter(all);

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
                            l.myApartments,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
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

                // ═══════════════════════════════════
                // Content: empty or populated
                // ═══════════════════════════════════
                if (mine.isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (all.isEmpty)
                  Expanded(child: _buildEmptyState())
                else ...[
                  const SizedBox(height: 18),

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
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF1F1F1F),
                              ),
                              decoration: InputDecoration(
                                hintText: l.searchApartments,
                                hintStyle: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF6D6D6D),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
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
                  const SizedBox(height: 8),

                  // Listings
                  Expanded(
                    child: listings.isEmpty
                        ? Center(
                            child: Text(
                              l.noApartmentsMatch,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
                                color: const Color(0xFF6D6D6D),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: listings.length,
                            itemBuilder: (_, i) => _ListingCard(
                              listing: listings[i],
                              onTap: () =>
                                  context.push('/listing/${listings[i].id}'),
                            ),
                          ),
                  ),

                  // Add Apartment button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: GestureDetector(
                      onTap: () => context.push('/add-apartment'),
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF123A72),
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              IconsaxPlusLinear.add,
                              size: 20,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l.addApartment,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Empty state
  // ═══════════════════════════════════════════════
  Widget _buildEmptyState() {
    final l = L.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Illustration placeholder
        Container(
          width: 205,
          height: 153,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(
              IconsaxPlusLinear.building_3,
              size: 64,
              color: Color(0xFF6D6D6D),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l.noApartmentsYet,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F1F1F),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l.addYourFirstApartment,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6D6D6D),
          ),
        ),
        const SizedBox(height: 40),

        // Add Apartment button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 53),
          child: GestureDetector(
            onTap: () => context.push('/add-apartment'),
            child: Container(
              width: 287,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF123A72),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    IconsaxPlusLinear.add,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.addApartment,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════
// Data model
// ═══════════════════════════════════════════════════

/// Listing card.
///
/// Everything on it comes from the row — including the photograph, which was
/// a blue gradient rectangle for every listing.
class _ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onTap;
  const _ListingCard({required this.listing, this.onTap});

  /// Only three of the seven statuses can appear on a listing someone has
  /// posted, and the rest are treated as still being looked at rather than
  /// given a colour that would claim something untrue.
  ({String text, Color fg, Color bg}) _status(L l) => switch (listing.status) {
    ListingStatus.active => (
      text: l.statusApproved,
      fg: const Color(0xFF0E7E4B),
      bg: const Color(0xFFE3F6EB),
    ),
    ListingStatus.removed || ListingStatus.expired => (
      text: l.statusRejected,
      fg: const Color(0xFFCB3E3C),
      bg: const Color(0xFFFCE9E9),
    ),
    _ => (
      text: l.statusPending,
      fg: const Color(0xFFDC7600),
      bg: const Color(0xFFFFF9EF),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final status = _status(l);
    final price = listing.effectivePrice;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photograph with status badge ──
            SizedBox(
              width: 120,
              height: 100,
              child: Stack(
                children: [
                  NetworkPhoto(
                    url: listing.coverUrl,
                    width: 120,
                    height: 100,
                    radius: BorderRadius.circular(8),
                  ),
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status.bg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status.text,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: status.fg,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // ── Info column ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0A1230),
                    ),
                  ),

                  // A listing entered without an address has nothing to show
                  // here, so the row is left out rather than shown empty.
                  if ((listing.address ?? listing.neighborhoodName) !=
                      null) ...[
                    const SizedBox(height: 8),
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
                            listing.address ?? listing.neighborhoodName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 12,
                              color: const Color(0xFF6D6D6D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (price != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      listing.kind == ListingKind.rent
                          ? l.pricePerMonthValue(formatShekels(price))
                          : formatShekels(price),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1230),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                  Text(
                    l.submittedOn(
                      '${listing.createdAt.day} '
                      '${l.monthShort(listing.createdAt.month)} '
                      '${listing.createdAt.year}',
                    ),
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6D6D6D),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              IconsaxPlusLinear.more,
              size: 20,
              color: Color(0xFF6D6D6D),
            ),
          ],
        ),
      ),
    );
  }
}

/// ₪2,450,000 — grouped in threes, which a plain toString does not do.
String formatShekels(int amount) {
  final digits = amount.toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return '₪$out';
}
