import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/month_names.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../auth/widgets/m_account_widgets.dart';
import '../models/listing.dart';
import '../providers/listing_providers.dart';
import '../widgets/my_listing_menu.dart';
import 'web_my_apartments_screen.dart';

/// My Apartments – what this person has posted, with its status.
///
/// The list was three invented flats in Tel Aviv with fixed dates, shown to
/// everyone and identical for everyone. It reads `listings` now, filtered to
/// the signed-in owner by the row level security policy.
class MyApartmentsScreen extends StatelessWidget {
  const MyApartmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) return const WebMyApartmentsContent();
        return const _MobileMyApartmentsContent();
      },
    );
  }
}

const _mid = Color(0xFF123A72);
const _navy = Color(0xFF0A1230);
const _grey = Color(0xFF6D6D6D);
const _hairline = Color(0xFFE7E7E7);

class _MobileMyApartmentsContent extends ConsumerStatefulWidget {
  const _MobileMyApartmentsContent();

  @override
  ConsumerState<_MobileMyApartmentsContent> createState() =>
      _MobileMyApartmentsContentState();
}

class _MobileMyApartmentsContentState
    extends ConsumerState<_MobileMyApartmentsContent> {
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

  /// A draft goes back into the form to be finished; anything sent already
  /// opens as the listing.
  void _open(Listing listing) {
    if (listing.status == ListingStatus.draft) {
      context.push('/add-apartment?draft=${listing.id}');
    } else {
      context.push('/listing/${listing.id}');
    }
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
                MAccountTopBar(title: l.myApartments),

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
                        border: Border.all(color: _hairline),
                        borderRadius: BorderRadius.circular(50),
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
                                  color: _grey,
                                ),
                                // The theme fills inputs grey; this one sits
                                // inside the white pill.
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          SvgPicture.asset(
                            'assets/icons/m_realestate_filter.svg',
                            width: 20,
                            height: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Listings
                  Expanded(
                    child: listings.isEmpty
                        ? Center(
                            child: Text(
                              l.noApartmentsMatch,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
                                color: _grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: listings.length,
                            itemBuilder: (_, i) => _ListingCard(
                              listing: listings[i],
                              onOpen: () => _open(listings[i]),
                            ),
                          ),
                  ),

                  // Add Apartment button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 11),
                    child: _AddApartmentButton(label: l.addApartment),
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
        // The design's illustration (a grey box with a glyph stood here).
        Image.asset(
          'assets/images/m_realestate_no_apartments.webp',
          width: 205,
          height: 153,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 327,
          child: Column(
            children: [
              Text(
                l.noApartmentsYet,
                textAlign: TextAlign.center,
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
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: _grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(width: 287, child: _AddApartmentButton(label: l.addApartment)),
        // As tall as the top bar, so the block is centred on the whole
        // screen as drawn rather than on the space under the bar.
        const SizedBox(height: 34),
      ],
    );
  }
}

/// The 48px mid-blue pill with the circled plus that opens the form.
class _AddApartmentButton extends StatelessWidget {
  final String label;
  const _AddApartmentButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/add-apartment'),
      child: Container(
        width: double.infinity,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: _mid,
          borderRadius: BorderRadius.circular(60),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/m_realestate_add_circle.svg',
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 24 / 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Listing card
// ═══════════════════════════════════════════════════

/// Listing card.
///
/// Everything on it comes from the row — including the photograph, which was
/// a blue gradient rectangle for every listing.
class _ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onOpen;
  const _ListingCard({required this.listing, required this.onOpen});

  /// Only three of the seven statuses can appear on a listing someone has
  /// posted, plus a draft kept to finish later; the rest are treated as
  /// still being looked at rather than given a colour that would claim
  /// something untrue.
  ({String text, Color fg, Color bg}) _status(BuildContext context, L l) => switch (listing.status) {
    ListingStatus.active => (
      text: l.statusApproved,
      fg: const Color(0xFF0E7E4B),
      bg: const Color(0xFFE3F6EB),
    ),
    // Marked by its owner (00055); both leave the site.
    ListingStatus.sold || ListingStatus.rented => (
      text: listing.status == ListingStatus.sold
          ? mTr(context, 'Sold', 'נמכר')
          : mTr(context, 'Rented', 'הושכר'),
      fg: _grey,
      bg: const Color(0xFFF1F1F1),
    ),
    // An expired listing was approved and ran its time; it was not rejected.
    ListingStatus.expired => (
      text: mTr(context, 'Expired', 'פג תוקף'),
      fg: _grey,
      bg: const Color(0xFFF1F1F1),
    ),
    ListingStatus.removed => (
      text: l.statusRejected,
      fg: const Color(0xFFCB3E3C),
      bg: const Color(0xFFFCE9E9),
    ),
    // Not in the design, which has no drafts; grey, as nothing has been
    // sent yet.
    ListingStatus.draft => (
      text: l.statusDraft,
      fg: _grey,
      bg: const Color(0xFFF1F1F1),
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
    final status = _status(context, l);
    final price = listing.effectivePrice;
    final place = listing.address ?? listing.neighborhoodName;
    final isDraft = listing.status == ListingStatus.draft;

    return GestureDetector(
      onTap: onOpen,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _hairline)),
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
                  PositionedDirectional(
                    start: 6,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _navy,
                    ),
                  ),

                  // A listing entered without an address has nothing to show
                  // here, so the row is left out rather than shown empty.
                  if (place != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 15,
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/m_realestate_pin14.svg',
                            width: 14,
                            height: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              place,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: _grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (price != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      listing.kind == ListingKind.rent
                          ? l.pricePerMonthValue(formatShekels(price))
                          : formatShekels(price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _navy,
                      ),
                    ),
                  ],

                  // The design dates each card by its status ("Approved on",
                  // "Rejected on"). `listings` keeps no time of approval or
                  // rejection — `published_at` exists but nothing writes it —
                  // so every card gives the day it was sent, which is known.
                  // A draft has not been sent, so it has no such line.
                  if (!isDraft) ...[
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
                        color: _grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Kebab: open, and the owner's actions ──
            MyListingMenu(
              listing: listing,
              openLabel: isDraft ? l.continueEditing : l.viewFullDetails,
              onOpen: onOpen,
              child: SvgPicture.asset(
                'assets/icons/m_realestate_kebab.svg',
                width: 20,
                height: 20,
              ),
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
