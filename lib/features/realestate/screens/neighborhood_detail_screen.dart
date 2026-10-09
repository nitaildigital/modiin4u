import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/router/app_router.dart';
import '../../../core/supabase/account_blocked.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/m_account_widgets.dart' show mTr;
import '../../favorites/repositories/favorite_repository.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/sign_in_action.dart';
import '../models/listing.dart';
import '../providers/detail_providers.dart';
import '../providers/neighborhood_providers.dart';
import '../providers/neighborhood_rating_providers.dart';
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
              onBack: () => context.back('/realestate'),
            ),
            data: (n) => n == null
                ? _Message(
                    text: L.of(context).neighborhoodNotFound,
                    onBack: () => context.back('/realestate'),
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

          // Residents' stars, after what the page says about the place and
          // before its listings.
          _RatingCard(neighborhoodId: n.id),

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

// ═══════════════════════════════════════════════
// Neighbourhood rating
// ═══════════════════════════════════════════════

/// The design's star colours, as on a business page.
const _kStarGold = Color(0xFFFFC107);
const _kStarGrey = Color(0xFFD1D1D1);
const _kStarOutline = Color(0xFFBDBDBD);

/// "Rate this neighbourhood": the residents' average and count, and under it
/// five stars the signed-in person sets their own rating with (00071).
///
/// One rating per person, changed at will and saved on the tap. In a narrow
/// browser this layout is the website's, where accounts are the app's, so
/// there it only shows the average — and nothing when nobody has rated.
class _RatingCard extends ConsumerStatefulWidget {
  final String neighborhoodId;
  const _RatingCard({required this.neighborhoodId});

  @override
  ConsumerState<_RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends ConsumerState<_RatingCard> {
  /// The rating just tapped, shown while it is saved and until the stored
  /// one has been read back, so the stars do not jump back for a moment.
  /// [_pending] tells "cleared" (null) apart from "nothing pending".
  bool _pending = false;
  int? _pendingValue;

  String get _id => widget.neighborhoodId;

  void _snack(String text, {bool error = false, SnackBarAction? action}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(text, style: TextStyle(fontFamily: AppFonts.rubik)),
        backgroundColor: error ? AppColors.error : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: action,
      ),
    );
  }

  Future<void> _rate(int? rating, int? current) async {
    if (_pending || rating == current) return;

    // Rating needs an account, so offer one rather than doing nothing.
    if (ref.read(authProvider) == null) {
      _snack(
        mTr(
          context,
          'Sign in to rate this neighbourhood',
          'התחברו כדי לדרג את השכונה',
        ),
        action: signInAction(context),
      );
      return;
    }

    setState(() {
      _pending = true;
      _pendingValue = rating;
    });
    try {
      await setMyNeighborhoodRating(ref, _id, rating);
      if (!mounted) return;
      _snack(
        rating == null
            ? mTr(context, 'Your rating was removed', 'הדירוג שלך הוסר')
            : mTr(context, 'Thanks for rating', 'תודה על הדירוג'),
      );
    } catch (e) {
      // A blocked account is refused by the database; say so, since "try
      // again" would never work for them.
      final blocked = await refusedAsBlocked(e);
      if (!mounted) return;
      _snack(
        blocked ? accountBlockedMessage(context) : L.of(context).errCouldNotSave,
        error: true,
      );
    }
    // Keep the tapped stars until the stored rating is back — the one just
    // saved, or the earlier one when the save was refused.
    try {
      await ref.read(myNeighborhoodRatingProvider(_id).future);
    } catch (_) {}
    if (mounted) setState(() => _pending = false);
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(neighborhoodRatingProvider(_id));
    final average = summary.valueOrNull;

    if (kIsWeb) {
      if (average == null) return const SizedBox.shrink();
      return _frame(
        title: L.of(context).whatLocalsSay,
        children: [_averageRow(average)],
      );
    }

    final stored = ref.watch(myNeighborhoodRatingProvider(_id)).valueOrNull;
    final mine = _pending ? _pendingValue : stored;

    return _frame(
      // The client's name for what residents think (8 Oct).
      title: L.of(context).whatLocalsSay,
      children: [
        // Nothing while the figures load, so "no ratings yet" does not flash
        // up before an average that exists.
        if (average != null)
          _averageRow(average)
        else if (summary.hasValue)
          Text(
            mTr(
              context,
              'No ratings yet — be the first',
              'עדיין אין דירוגים — היו הראשונים',
            ),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: const Color(0xFF6D6D6D),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          mTr(context, 'Your rating', 'הדירוג שלך'),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6D6D6D),
          ),
        ),
        const SizedBox(height: 8),
        // The business page's star picker: first star at the reading start,
        // the motion lines turned with it in Hebrew.
        Row(
          children: List.generate(5, (i) {
            final value = i + 1;
            final on = mine != null && mine >= value;
            return Semantics(
              button: true,
              selected: mine == value,
              label: mTr(context, '$value of 5 stars', '$value מתוך 5 כוכבים'),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _rate(value, mine),
                child: Padding(
                  padding: EdgeInsetsDirectional.only(end: i < 4 ? 12 : 0),
                  child: Transform.flip(
                    flipX: Directionality.of(context) == TextDirection.rtl,
                    child: Icon(
                      on ? IconsaxPlusBold.star_1 : IconsaxPlusLinear.star,
                      size: 32,
                      color: on ? _kStarGold : _kStarOutline,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        if (mine != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: _pending ? null : () => _rate(null, mine),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                mTr(context, 'Remove my rating', 'הסרת הדירוג שלי'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.midBlue,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// The page's bordered card, as the figures above it are drawn.
  Widget _frame({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE7E7E7)),
          borderRadius: BorderRadius.circular(12),
        ),
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
            ...children,
          ],
        ),
      ),
    );
  }

  /// "4.3 ★★★★½ (12 ratings)".
  Widget _averageRow(NeighborhoodRating r) {
    final count = r.count == 1
        ? mTr(context, '1 rating', 'דירוג אחד')
        : mTr(context, '${r.count} ratings', '${r.count} דירוגים');
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(
          r.average.toStringAsFixed(1),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        _AverageStars(value: r.average, size: 18),
        Text(
          '($count)',
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            color: const Color(0xFF6D6D6D),
          ),
        ),
      ],
    );
  }
}

/// Five stars filled to [value], to the nearest half, starting at the
/// reading start — a half star is filled on its reading-start side.
class _AverageStars extends StatelessWidget {
  final double value;
  final double size;
  const _AverageStars({required this.value, required this.size});

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final halves = (value * 2).round() / 2;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final fill = (halves - i).clamp(0.0, 1.0);
        return Padding(
          padding: EdgeInsetsDirectional.only(end: i < 4 ? 4 : 0),
          // Flipped whole in Hebrew, so the motion lines and the filled half
          // both face the reading start.
          child: Transform.flip(
            flipX: rtl,
            child: Stack(
              // Left, not start: the flip above already turns it for Hebrew.
              alignment: Alignment.topLeft,
              children: [
                Icon(IconsaxPlusBold.star_1, size: size, color: _kStarGrey),
                if (fill > 0)
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: fill,
                      child: Icon(
                        IconsaxPlusBold.star_1,
                        size: size,
                        color: _kStarGold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
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
                  onTap: () => context.back('/realestate'),
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
