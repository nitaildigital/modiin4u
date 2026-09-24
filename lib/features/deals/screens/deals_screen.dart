import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/network_photo.dart';
import '../models/offer.dart';
import '../providers/offer_providers.dart';
import 'web_deals_screen.dart';

/// Deals – responsive wrapper.
class DealsScreen extends StatelessWidget {
  const DealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) return const WebDealsContent();
        return const _MobileDealsContent();
      },
    );
  }
}

/// Deals discovery screen.
///
/// The list was four invented offers on shops that are not in Modiin — a
/// Nike store, an "Urban Plate Kitchen & Bar" — each with a countdown that
/// was a fixed string rather than a time, and a row of category circles with
/// fixed counts of 62, 48 and 31. Below them sat eight "brand" tiles reading
/// "Upto 80% Off" with nothing behind them at all; those are gone rather
/// than translated.
///
/// It reads `offers` now. The table is empty until the client adds one in
/// the admin panel, so the honest state today is the empty message.
class _MobileDealsContent extends ConsumerWidget {
  const _MobileDealsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final offers = ref.watch(offersProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(offersProvider);
              ref.invalidate(offerCountsByCategoryProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(context),
                  const SizedBox(height: 20),
                  _buildBanner(),
                  const SizedBox(height: 12),
                  _buildPageDots(),
                  const SizedBox(height: 16),

                  // Categories are only worth a row when something is in
                  // them, so an empty table shows no circles rather than a
                  // row of zeroes.
                  _buildCategoryRow(ref, l),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l.popularDealsInModiin,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F1F1F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  offers.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, _) => _empty(l),
                    data: (list) =>
                        list.isEmpty ? _empty(l) : _buildDealCards(list, l),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(L l) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
    child: Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFFF2F2F2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            IconsaxPlusLinear.discount_shape,
            size: 30,
            color: Color(0xFF6D6D6D),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l.noDealsYet,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F1F1F),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.noDealsYetBody,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 13,
            color: const Color(0xFF6D6D6D),
          ),
        ),
      ],
    ),
  );

  Widget _buildHero(BuildContext context) {
    final l = L.of(context);
    return SizedBox(
      height: 210,
      child: Stack(
        children: [
          // Turquoise gradient wash
          Container(
            width: double.infinity,
            height: 210,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF17A9D0).withValues(alpha: 0.2),
                  const Color(0xFF17A9D0).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),

          // Back button
          Positioned(
            left: 15,
            top: 10,
            child: GestureDetector(
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
          ),

          // "Deals" title
          Positioned(
            top: 13,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                l.deals,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          // Big heading
          Positioned(
            top: 57,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 54),
              child: Text(
                l.bestDealsHeading,
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  height: 39 / 32,
                  color: const Color(0xFF001650),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Subtitle
          Positioned(
            top: 148,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                l.dealsHeroSubtitle,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 19 / 16,
                  color: const Color(0xFF6D6D6D),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Hero banner (361×200)
  // ═══════════════════════════════════════════════
  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 200,
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
            IconsaxPlusBold.discount_shape,
            size: 48,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Page dots (3 dots, middle active)
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
            color: i == 1 ? const Color(0xFF123A72) : const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(50),
          ),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════
  // Category circles (horizontal scroll)
  // ═══════════════════════════════════════════════
  Widget _buildCategoryRow(WidgetRef ref, L l) {
    final categories = ref.watch(offerCategoriesProvider).valueOrNull;
    if (categories == null || categories.isEmpty)
      return const SizedBox.shrink();
    final counts =
        ref.watch(offerCountsByCategoryProvider).valueOrNull ?? const {};
    final selected = ref.watch(offerCategoryFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l.exploreDealsByCategory,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 144,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final c = categories[i];
              return _CategoryCircle(
                name: c.name,
                count: counts[c.id] ?? 0,
                imageUrl: c.imageUrl,
                selected: selected == c.id,
                // Tapping the one already chosen clears it, so there is a way
                // back to everything without a separate "all" circle.
                onTap: () =>
                    ref.read(offerCategoryFilterProvider.notifier).state =
                        selected == c.id ? null : c.id,
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDealCards(List<Offer> offers, L l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var i = 0; i < offers.length; i++) ...[
            _DealCard(offer: offers[i]),
            if (i < offers.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Data models
// ═══════════════════════════════════════════════
class _CategoryCircle extends StatelessWidget {
  final String name;
  final int count;
  final String? imageUrl;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryCircle({
    required this.name,
    required this.count,
    required this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 100,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(color: const Color(0xFF123A72), width: 2.5)
                    : null,
              ),
              child: NetworkPhoto(
                url: imageUrl,
                width: 64,
                height: 64,
                radius: BorderRadius.circular(32),
                icon: IconsaxPlusBold.discount_shape,
                iconSize: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              l.dealsCount(count),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                color: const Color(0xFF5F5E5A),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Deal card – image + brand logo + discount badge + info + button
// ═══════════════════════════════════════════════
class _DealCard extends StatelessWidget {
  final Offer offer;
  const _DealCard({required this.offer});

  /// "2d 14h", from the offer's own end date. The old card carried a fixed
  /// string — "2d : 14h" — that never moved and meant nothing.
  String? _countdown(L l) {
    final left = offer.timeLeft;
    if (left == null) return null;
    if (left.inDays >= 1) return l.daysShort(left.inDays);
    if (left.inHours >= 1) return l.hoursShort(left.inHours);
    return l.minutesShort(left.inMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return GestureDetector(
      onTap: () => context.push('/deal/${offer.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area with brand logo + discount badge
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                // The offer's own picture, falling back to the business's.
                NetworkPhoto(
                  url: offer.imageUrl ?? offer.businessLogoUrl,
                  width: double.infinity,
                  radius: BorderRadius.circular(12),
                  icon: IconsaxPlusBold.discount_shape,
                  iconSize: 40,
                ),

                // Brand logo (bottom-left)
                Positioned(
                  left: 12,
                  top: 141,
                  child: Container(
                    width: 47,
                    height: 47,
                    padding: const EdgeInsets.all(2.3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: NetworkPhoto(
                      url: offer.businessLogoUrl,
                      radius: BorderRadius.circular(21),
                      icon: IconsaxPlusBold.shop,
                      iconSize: 18,
                    ),
                  ),
                ),

                // Discount badge (top-left)
                if (offer.code != null && offer.code!.isNotEmpty)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFB7901),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        offer.code!,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Info section
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  offer.name,
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 25 / 20,
                    color: const Color(0xFF0A1230),
                  ),
                ),
                const SizedBox(height: 8),

                // Business name
                Text(
                  offer.businessName ?? '',
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF5F5E5A),
                  ),
                ),
                const SizedBox(height: 12),

                // Location
                Row(
                  children: [
                    const Icon(
                      IconsaxPlusBold.location,
                      size: 16,
                      color: Color(0xFF17A9D0),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      offer.businessAddress ?? '',
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF5F5E5A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Countdown + audience row
                //
                // An offer with no end date shows no clock at all, rather
                // than a countdown to a time that was never set.
                Builder(
                  builder: (context) {
                    final countdown = _countdown(l);
                    final residentsOnly = offer.pointsRequired > 0;
                    if (countdown == null && !residentsOnly) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (countdown != null)
                            Row(
                              children: [
                                const Icon(
                                  IconsaxPlusLinear.clock,
                                  size: 16,
                                  color: Color(0xFF123A72),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  countdown,
                                  style: TextStyle(
                                    fontFamily: AppFonts.inter,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l.timeLeft,
                                  style: TextStyle(
                                    fontFamily: AppFonts.inter,
                                    fontSize: 14,
                                    color: const Color(0xFF6D6D6D),
                                  ),
                                ),
                              ],
                            )
                          else
                            const SizedBox.shrink(),
                          if (residentsOnly)
                            Row(
                              children: [
                                const Icon(
                                  IconsaxPlusLinear.crown_1,
                                  size: 16,
                                  color: Color(0xFFFB7901),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l.residentsOnly,
                                  style: TextStyle(
                                    fontFamily: AppFonts.inter,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFFB7901),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // "View Deal" button
                Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF123A72),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Center(
                    child: Text(
                      l.viewDeal,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
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
