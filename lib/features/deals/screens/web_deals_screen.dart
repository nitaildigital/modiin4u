import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../businesses/providers/business_providers.dart';
import '../models/offer.dart';
import '../providers/offer_providers.dart';

// ═══════════════════════════════════════════════════════════
// Web Deals — full desktop layout from Figma
// (Deals — 1920 × 2876)
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF5F5E5A);
const _kHeading = Color(0xFF1C1C1E);
const _kBodyText = Color(0xFF3D3D3D);
const _kIconGrey = Color(0xFF6D6D6D);
const _kPillBorder = Color(0xFFD1D1D1);

/// How the deals are ordered, once there are some. Each option reads a column
/// the `offers` table actually has.
enum _Order {
  /// `end_at`, soonest first. Offers with no end date come last.
  expiringSoon,

  /// `claim_count`, highest first.
  mostPopular,

  /// `start_at`, most recent first.
  newest,
}

/// The desktop Deals page.
///
/// Everything on it was written into the source. Eight invented offers on
/// shops that are not in Modiin — a Nike store, an "Urban Plate Kitchen & Bar",
/// "Soleil Spa" — each with a discount badge, a "Residents Only" shield and a
/// countdown that was a fixed string rather than a time, all linking to
/// `/deal/demo_$i`. Six category circles reading 62, 48, 31, 27, 19 and 15.
/// Ten "brand" tiles offering "Upto 80% Off" and "Upto 5% Rewards" with
/// nothing behind them at all, and a three-up banner carousel of empty
/// rectangles with working arrows.
///
/// It reads `offers` now. That table is empty until the client loads a deal in
/// the admin panel, so the honest page today is the empty state.
class WebDealsContent extends ConsumerStatefulWidget {
  const WebDealsContent({super.key});

  @override
  ConsumerState<WebDealsContent> createState() => _WebDealsContentState();
}

class _WebDealsContentState extends ConsumerState<WebDealsContent> {
  bool _isHebrew = false;
  _Order? _order;
  final _dealsCarousel = ScrollController();

  @override
  void dispose() {
    _dealsCarousel.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  /// The pills, and the column each one reads. "Residents Only" was a fourth;
  /// nothing on an offer says who may take it, so it is gone.
  List<(_Order, String)> get _orderPills => [
    (_Order.expiringSoon, _t('expiring soon', 'נגמר בקרוב')),
    (_Order.mostPopular, _t('most popular', 'הכי פופולרי')),
    (_Order.newest, _t('new', 'חדש')),
  ];

  List<Offer> _ordered(List<Offer> offers) {
    if (_order == null) return offers;
    final sorted = [...offers];
    switch (_order!) {
      case _Order.expiringSoon:
        sorted.sort((a, b) {
          final x = a.endAt;
          final y = b.endAt;
          if (x == null || y == null) return x == null ? 1 : -1;
          return x.compareTo(y);
        });
      case _Order.mostPopular:
        sorted.sort((a, b) => b.claimCount.compareTo(a.claimCount));
      case _Order.newest:
        sorted.sort((a, b) {
          final x = a.startAt;
          final y = b.startAt;
          if (x == null || y == null) return x == null ? 1 : -1;
          return y.compareTo(x);
        });
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: 'deals',
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeroSection(),
                    _buildCategoriesSection(),
                    _buildPopularDealsSection(),
                    // Ten "Most Popular Brands" tiles stood below the pills,
                    // each promising a discount and a rewards rate. No table
                    // holds a brand, a discount or a reward, so the section is
                    // gone rather than translated.
                    const SizedBox(height: 146),
                    WebFooter(isHebrew: _isHebrew),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STICKY NAVBAR — 1920 × 80
  // ─────────────────────────────────────────────
  // ─────────────────────────────────────────────
  // HERO — title and subtitle
  //
  // A carousel of three 520 × 300 promo banners sat underneath, with arrows
  // that scrolled it. There is no table of banners, so the three were empty
  // rectangles and the arrows moved nothing that meant anything.
  // ─────────────────────────────────────────────
  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          Text(
            _t(
              'Best Deals & Offers in Modiin',
              'המבצעים וההטבות הטובים במודיעין',
            ),
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 44,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              height: 1.23,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            _t(
              'Explore local deals, discounts, and limited-time offers across Modiin.',
              'גלו מבצעים מקומיים, הנחות והטבות לזמן מוגבל בכל מודיעין.',
            ),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              color: _kIconGrey,
              height: 1.19,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EXPLORE DEALS BY CATEGORY — circular tiles
  //
  // `offerCategoriesProvider` returns only the categories that have an active
  // offer in them, so a category never shows a count of nought and the row
  // disappears altogether when the table is empty.
  // ─────────────────────────────────────────────
  Widget _buildCategoriesSection() {
    final categories = ref.watch(offerCategoriesProvider).valueOrNull;
    if (categories == null || categories.isEmpty) return const SizedBox.shrink();

    final counts = ref.watch(offerCountsByCategoryProvider).valueOrNull ?? const {};
    final selected = ref.watch(offerCategoryFilterProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: _Section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('Explore Deals by Category', 'גלו מבצעים לפי קטגוריה'),
              style: TextStyle(
                fontFamily: AppFonts.nunito,
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppColors.midBlue,
              ),
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 30,
              runSpacing: 30,
              children: [
                for (final c in categories)
                  SizedBox(
                    width: 160,
                    child: _CategoryTile(
                      category: c,
                      count: counts[c.id] ?? 0,
                      dealsLabel: _t('Deals', 'מבצעים'),
                      isSelected: selected == c.id,
                      // Tapping the chosen one clears it, so there is a way
                      // back to everything without a separate "all" tile.
                      onTap: () =>
                          ref.read(offerCategoryFilterProvider.notifier).state =
                              selected == c.id ? null : c.id,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // POPULAR DEALS IN MODIIN — 480 × 353 card carousel
  // ─────────────────────────────────────────────
  Widget _buildPopularDealsSection() {
    final offers = ref.watch(offersProvider);
    final list = offers.valueOrNull ?? const <Offer>[];

    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: _Section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t(
                          'Popular Deals in Modiin',
                          'מבצעים פופולריים במודיעין',
                        ),
                        style: TextStyle(
                          fontFamily: AppFonts.nunito,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AppColors.midBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _t(
                          'Local offers, straight from the businesses running them.',
                          'הטבות מקומיות, ישירות מהעסקים שמציעים אותן.',
                        ),
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          color: _kGreyText,
                          height: 1.21,
                        ),
                      ),
                    ],
                  ),
                ),
                // The arrows only appear when there is a row of cards for them
                // to move.
                if (list.length > 1) ...[
                  const SizedBox(width: 24),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _carouselArrow(step: 500, isNext: false),
                        const SizedBox(width: 12),
                        _carouselArrow(step: 500, isNext: true),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 23),
            offers.when(
              loading: _buildDealsSkeleton,
              error: (_, _) => _buildNoticeBox(
                icon: IconsaxPlusLinear.wifi_square,
                title: _t('Deals could not be loaded', 'לא ניתן לטעון את המבצעים'),
                body: _t(
                  'Check your connection and try again.',
                  'בדקו את החיבור לאינטרנט ונסו שוב.',
                ),
                actionLabel: _t('Try again', 'נסו שוב'),
                onAction: () => ref.invalidate(offersProvider),
              ),
              data: (data) =>
                  data.isEmpty ? _buildEmptyDeals() : _buildDealsCarousel(data),
            ),
            // Sorting nothing is not a control, so the pills wait until there
            // is more than one deal to put in order.
            if (list.length > 1) _buildOrderPills(),
          ],
        ),
      ),
    );
  }

  Widget _buildDealsCarousel(List<Offer> offers) {
    final ordered = _ordered(offers);
    return SizedBox(
      height: 353,
      child: ListView.separated(
        controller: _dealsCarousel,
        scrollDirection: Axis.horizontal,
        itemCount: ordered.length,
        separatorBuilder: (_, _) => const SizedBox(width: 20),
        itemBuilder: (context, i) => SizedBox(
          width: 480,
          child: _DealCard(
            offer: ordered[i],
            isHebrew: _isHebrew,
            timeLeftLabel: _t('Time Left', 'זמן שנותר'),
            pointsLabel: _t('points', 'נקודות'),
            viewLabel: ordered[i].hasExpired
                ? _t('Ended', 'הסתיים')
                : _t('View Deal', 'צפו במבצע'),
            onTap: () => context.push('/deal/${ordered[i].id}'),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDeals() {
    final filtered = ref.watch(offerCategoryFilterProvider) != null;
    return _buildNoticeBox(
      icon: IconsaxPlusLinear.discount_shape,
      title: filtered
          ? _t('No deals in this category', 'אין מבצעים בקטגוריה הזו')
          : _t('No deals yet', 'אין עדיין מבצעים'),
      body: filtered
          ? _t(
              'Pick another category to see what else is on.',
              'בחרו קטגוריה אחרת כדי לראות מה יש.',
            )
          : _t(
              'Local businesses have not published an offer yet. They will show up here when they do.',
              'עסקים מקומיים עדיין לא פרסמו הטבות. ההטבות יופיעו כאן כשיפורסמו.',
            ),
      actionLabel: filtered ? _t('Show all deals', 'הצג את כל המבצעים') : null,
      onAction: filtered
          ? () => ref.read(offerCategoryFilterProvider.notifier).state = null
          : null,
    );
  }

  Widget _buildNoticeBox({
    required IconData icon,
    required String title,
    required String body,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      height: 353,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: _kGreyText.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _kHeading,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 520,
            child: Text(
              body,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                color: _kGreyText,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onAction,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.midBlue,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
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

  /// Two card-shaped blocks at the real card's geometry.
  Widget _buildDealsSkeleton() {
    return Skeleton(
      child: Row(
        children: List.generate(
          2,
          (_) => const Padding(
            padding: EdgeInsetsDirectional.only(end: 20),
            child: SkeletonBox(width: 480, height: 353, radius: 12),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ORDER PILLS — 80px tall, radius 50
  // ─────────────────────────────────────────────
  Widget _buildOrderPills() {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Wrap(
          spacing: 21,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            for (final (order, label) in _orderPills)
              _FilterPill(
                label: label,
                isSelected: _order == order,
                onTap: () =>
                    setState(() => _order = _order == order ? null : order),
              ),
          ],
        ),
      ),
    );
  }

  Widget _carouselArrow({required double step, required bool isNext}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (!_dealsCarousel.hasClients) return;
          final delta = step * (isNext ? 1 : -1);
          _dealsCarousel.animateTo(
            (_dealsCarousel.offset + delta).clamp(
              0.0,
              _dealsCarousel.position.maxScrollExtent,
            ),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
          );
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            isNext
                ? IconsaxPlusLinear.arrow_right_3
                : IconsaxPlusLinear.arrow_left_2,
            size: 20,
            color: AppColors.midBlue,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FOOTER — 1920 × 632
  // ─────────────────────────────────────────────
}

// ═══════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════

class _Section extends StatelessWidget {
  final Widget child;
  const _Section({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1648,
        ), // 1600 content + 24 padding each side
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CATEGORY TILE — 116px circle + name + "N Deals"
// ─────────────────────────────────────────────
class _CategoryTile extends StatefulWidget {
  final BusinessCategory category;
  final int count;
  final String dealsLabel;
  final bool isSelected;
  final VoidCallback onTap;
  const _CategoryTile({
    required this.category,
    required this.count,
    required this.dealsLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.category;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 116,
              height: 116,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isSelected
                      ? AppColors.midBlue
                      : (_hovered ? AppColors.turquoise : Colors.transparent),
                  width: 2,
                ),
              ),
              child: NetworkPhoto(
                url: c.imageUrl,
                radius: BorderRadius.circular(55),
                icon: IconsaxPlusBold.discount_shape,
                iconSize: 30,
              ),
            ),
            const SizedBox(height: 20),
            // Fixed two-line box so every count in the row sits on one baseline.
            SizedBox(
              height: 44,
              child: Text(
                c.name,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _kHeading,
                  height: 1.22,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.count} ${widget.dealsLabel}',
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                color: _kGreyText,
                height: 1.21,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FILTER PILL — 80px tall, radius 50
// ─────────────────────────────────────────────
class _FilterPill extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FilterPill> createState() => _FilterPillState();
}

class _FilterPillState extends State<_FilterPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: selected ? AppColors.midBlue : Colors.white,
            border: Border.all(
              color: selected
                  ? AppColors.midBlue
                  : (_hovered ? AppColors.turquoise : _kPillBorder),
            ),
            borderRadius: BorderRadius.circular(50),
          ),
          // mainAxisSize.min keeps the pill hugging its label — a Container
          // `alignment` here would stretch it to the full row width.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: AppFonts.nunito,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : _kBodyText,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DEAL CARD — 480 × 353
// ─────────────────────────────────────────────
class _DealCard extends StatefulWidget {
  final Offer offer;
  final bool isHebrew;
  final String timeLeftLabel, pointsLabel, viewLabel;
  final VoidCallback onTap;
  const _DealCard({
    required this.offer,
    required this.isHebrew,
    required this.timeLeftLabel,
    required this.pointsLabel,
    required this.viewLabel,
    required this.onTap,
  });

  @override
  State<_DealCard> createState() => _DealCardState();
}

class _DealCardState extends State<_DealCard> {
  bool _hovered = false;

  /// "2d : 14h", or "14h : 30m" in the last day. Null when the offer has no end
  /// date, in which case the clock is left off the card — it used to show a
  /// fixed string counting down to nothing.
  String? get _timeLeft {
    final left = widget.offer.timeLeft;
    if (left == null) return null;
    if (left == Duration.zero) return widget.isHebrew ? 'הסתיים' : 'Ended';
    if (left.inDays >= 1) {
      return '${left.inDays}d : ${left.inHours % 24}h';
    }
    return '${left.inHours}h : ${left.inMinutes % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.offer;
    final timeLeft = _timeLeft;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _hovered ? AppColors.midBlue : _kBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo 157 × 191. An orange discount badge sat on top of
                    // it reading "20% OFF", "FLAT ₪300 OFF", "BUY 1 GET 1" —
                    // an offer carries no discount figure, only its name.
                    NetworkPhoto(
                      url: d.imageUrl,
                      width: 157,
                      height: 191,
                      radius: BorderRadius.circular(12),
                      icon: IconsaxPlusBold.discount_shape,
                      iconSize: 30,
                    ),
                    const SizedBox(width: 17),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Merchant logo — 72px ring
                          Container(
                            width: 72,
                            height: 72,
                            padding: const EdgeInsets.all(3.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: _kBorder),
                            ),
                            child: NetworkPhoto(
                              url: d.businessLogoUrl,
                              radius: BorderRadius.circular(33),
                              icon: IconsaxPlusBold.shop,
                              iconSize: 20,
                            ),
                          ),
                          const SizedBox(height: 13),
                          Text(
                            d.name,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: AppColors.midBlue,
                              height: 1.23,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (d.businessName != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              d.businessName!,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _kHeading,
                                height: 1.21,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (d.businessAddress != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  IconsaxPlusLinear.location,
                                  size: 16,
                                  color: _kIconGrey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    d.businessAddress!,
                                    style: TextStyle(
                                      fontFamily: AppFonts.inter,
                                      fontSize: 14,
                                      color: _kBodyText,
                                      height: 1.21,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Spacer(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (timeLeft != null) ...[
                                const Icon(
                                  IconsaxPlusLinear.clock,
                                  size: 20,
                                  color: AppColors.midBlue,
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Text(
                                        timeLeft,
                                        style: TextStyle(
                                          fontFamily: AppFonts.inter,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.navy,
                                          height: 1.19,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.timeLeftLabel,
                                      style: TextStyle(
                                        fontFamily: AppFonts.inter,
                                        fontSize: 12,
                                        color: _kGreyText,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              // A "Residents Only" shield sat here on most of
                              // the invented cards. Nothing on an offer says
                              // who may take it; what it does say is how many
                              // points it costs, where that is not nought.
                              if (d.pointsRequired > 0) ...[
                                const SizedBox(width: 20),
                                const Icon(
                                  IconsaxPlusLinear.medal_star,
                                  size: 20,
                                  color: AppColors.orange,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${d.pointsRequired} ${widget.pointsLabel}',
                                    style: TextStyle(
                                      fontFamily: AppFonts.inter,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.orange,
                                      height: 1.25,
                                    ),
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              // View Deal button — full width, 44px, radius 60. The card is
              // the tap target, so the button carries no handler of its own.
              Container(
                width: double.infinity,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: d.hasExpired
                      ? const Color(0xFFB9C0CE)
                      : AppColors.midBlue,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Text(
                  widget.viewLabel,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.5,
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
