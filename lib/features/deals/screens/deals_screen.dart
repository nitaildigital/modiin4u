import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/network_photo.dart';
import '../models/offer.dart';
import '../providers/offer_providers.dart';
import '../widgets/m_deal_card.dart';
import '../widgets/m_deals_sections.dart';
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

/// Deals discovery screen — Figma mobile "Deals" (631:3902).
///
/// The list was four invented offers on shops that are not in Modiin — a
/// Nike store, an "Urban Plate Kitchen & Bar" — each with a countdown that
/// was a fixed string rather than a time, and a row of category circles with
/// fixed counts of 62, 48 and 31. It reads `offers` now:
///
/// * the banner is the campaigns booked for `DEALS_TOP`, and absent without;
/// * the category circles are the categories that have an offer in them;
/// * the list shows three deals and fades the fourth under "View All";
/// * "Most Popular Brands" are the businesses behind the most-claimed
///   offers, and tapping one narrows the list to its deals.
class _MobileDealsContent extends ConsumerStatefulWidget {
  const _MobileDealsContent();

  @override
  ConsumerState<_MobileDealsContent> createState() =>
      _MobileDealsContentState();
}

class _MobileDealsContentState extends ConsumerState<_MobileDealsContent> {
  /// How many deals the list shows before "View All".
  static const _kFolded = 3;

  bool _expanded = false;

  /// The brand tile chosen, if any: the list then shows its deals only.
  String? _business;

  final _listKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
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
              ref.invalidate(activeOffersProvider);
              ref.invalidate(offerCountsByCategoryProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The turquoise wash runs 315 down the design's frame,
                  // behind the heading and into the banner.
                  Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 271 + MediaQuery.paddingOf(context).top,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF17A9D0).withValues(alpha: 0.2),
                                const Color(0xFF17A9D0).withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          _buildHeader(context, l),
                          const MDealsBanner(),
                        ],
                      ),
                    ],
                  ),

                  // Categories are only worth a row when something is in
                  // them, so an empty table shows no circles rather than a
                  // row of zeroes.
                  _buildCategoryRow(l),

                  Padding(
                    key: _listKey,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(l.popularDealsInModiin, style: _sectionTitle),
                  ),
                  const SizedBox(height: 16),

                  offers.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, _) => _empty(l),
                    data: (list) {
                      final shown = _business == null
                          ? list
                          : list.where((o) => o.businessId == _business).toList();
                      return shown.isEmpty ? _empty(l) : _buildDealCards(shown, l);
                    },
                  ),
                  _buildBrands(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static final _sectionTitle = mDealsInter(
    16,
    weight: FontWeight.w600,
    color: const Color(0xFF1F1F1F),
  );

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
            color: kMDealsMuted,
          ),
        ),
        const SizedBox(height: 16),
        Text(l.noDealsYet, style: _sectionTitle),
        const SizedBox(height: 8),
        Text(
          l.noDealsYetBody,
          textAlign: TextAlign.center,
          style: mDealsInter(13, color: kMDealsMuted),
        ),
      ],
    ),
  );

  // ═══════════════════════════════════════════════
  // Header — turquoise wash, back, "Deals", heading, subtitle
  // ═══════════════════════════════════════════════
  Widget _buildHeader(BuildContext context, L l) {
    final top = MediaQuery.paddingOf(context).top;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: top, bottom: 25),
      child: Column(
        children: [
          SizedBox(
            height: 44,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PositionedDirectional(
                  start: 15,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                    child: Transform.flip(
                      flipX: rtl,
                      child: const Icon(
                        IconsaxPlusLinear.arrow_left,
                        size: 24,
                        color: Color(0xFF3D3D3D),
                      ),
                    ),
                  ),
                ),
                Text(l.deals, style: mDealsInter(16, weight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              l.bestDealsHeading,
              textAlign: TextAlign.center,
              style: mDealsDisplay(32, color: const Color(0xFF001650), height: 39 / 32),
            ),
          ),
          const SizedBox(height: 13),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Text(
              l.dealsHeroSubtitle,
              textAlign: TextAlign.center,
              style: mDealsInter(16, color: kMDealsMuted, height: 19 / 16),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Category circles (horizontal scroll)
  // ═══════════════════════════════════════════════
  Widget _buildCategoryRow(L l) {
    final categories = ref.watch(offerCategoriesProvider).valueOrNull;
    if (categories == null || categories.isEmpty) {
      return const SizedBox.shrink();
    }
    final counts =
        ref.watch(offerCountsByCategoryProvider).valueOrNull ?? const {};
    final selected = ref.watch(offerCategoryFilterProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(l.exploreDealsByCategory, style: _sectionTitle),
          ),
          const SizedBox(height: 16),
          SizedBox(
            // The circle, the gaps and two lines of 14 px text, at the size
            // the phone draws text. A fixed 114 fitted the design's Inter,
            // but Hebrew names fall back to a taller face, and a larger text
            // setting grows them again: the row overflowed by 6 px.
            height: 64 + 12 + 4 + 2 * MediaQuery.textScalerOf(context).scale(14 * 1.5),
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
                  // Tapping the one already chosen clears it, so there is a
                  // way back to everything without a separate "all" circle.
                  onTap: () => setState(() {
                    ref.read(offerCategoryFilterProvider.notifier).state =
                        selected == c.id ? null : c.id;
                    _expanded = false;
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealCards(List<Offer> offers, L l) {
    final folded = !_expanded && offers.length > _kFolded;
    final visible = folded ? offers.take(_kFolded).toList() : offers;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final o in visible) MDealCard(offer: o),
          if (folded)
            MDealsViewAll(
              label: l.viewAll,
              onTap: () => setState(() => _expanded = true),
              child: MDealCard(offer: offers[_kFolded]),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Most Popular Brands — two across, 173.5 × 174, 12 apart
  // ═══════════════════════════════════════════════
  Widget _buildBrands(BuildContext context) {
    final live = (ref.watch(activeOffersProvider).valueOrNull ?? const <Offer>[])
        .where((o) => !o.hasExpired);
    final byBusiness = <String, List<Offer>>{};
    for (final o in live) {
      final id = o.businessId;
      if (id == null || o.businessName == null) continue;
      byBusiness.putIfAbsent(id, () => []).add(o);
    }
    if (byBusiness.isEmpty) return const SizedBox.shrink();

    int claims(List<Offer> l) => l.fold(0, (s, o) => s + o.claimCount);
    final brands = byBusiness.entries.toList()
      ..sort((a, b) {
        final c = claims(b.value).compareTo(claims(a.value));
        return c != 0 ? c : b.value.length.compareTo(a.value.length);
      });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mDealsT(context, 'Most Popular Brands', 'המותגים הפופולריים'),
            style: _sectionTitle,
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, c) {
              const gap = 12.0;
              final w = (c.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final e in brands.take(8))
                    SizedBox(
                      width: w,
                      height: 174,
                      child: MBrandTile(
                        offers: e.value,
                        isSelected: _business == e.key,
                        onTap: () => _openBrand(context, e.key, e.value),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// One deal opens it; several narrow the list to them, or widen it back
  /// when the same tile is tapped again.
  void _openBrand(BuildContext context, String id, List<Offer> offers) {
    if (offers.length == 1) {
      context.push('/deal/${offers.first.id}');
      return;
    }
    final narrowing = _business != id;
    setState(() {
      _business = narrowing ? id : null;
      _expanded = narrowing;
      if (narrowing) ref.read(offerCategoryFilterProvider.notifier).state = null;
    });
    final target = _listKey.currentContext;
    if (narrowing && target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 400),
        alignment: 0.05,
      );
    }
  }
}

// ═══════════════════════════════════════════════
// A category circle: 64 photograph, name, how many deals
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
                    ? Border.all(color: AppColors.midBlue, width: 2.5)
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                name,
                style: mDealsInter(
                  14,
                  weight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.dealsCount(count),
              style: mDealsInter(14, color: kMDealsGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
