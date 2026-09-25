import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../businesses/models/business.dart';
import '../../businesses/providers/business_providers.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../models/listing.dart';
import '../providers/neighborhood_providers.dart';
import 'my_apartments_screen.dart' show formatShekels;

// ═══════════════════════════════════════════════════════════
// Web Neighborhood Detail — desktop layout for /neighborhood/:id
//
// Every neighbourhood in the city used to render as Moriah. The name, the
// city, three paragraphs about when Moriah was settled and where its street
// names come from, four statistics (12 properties, 18 businesses, 6 parks,
// 7 schools), four bullet points about its schools and highways, four flats
// for sale, four to let and five local businesses with star ratings — all of
// it was written into this file, and the id the route carried was never read.
// ═══════════════════════════════════════════════════════════

/// Active businesses filed under one neighbourhood.
///
/// [BusinessRepository.fetchAll] already answers this, but the businesses
/// feature exposes no provider keyed by neighbourhood and this change does not
/// own that file, so the family is named here.
final _neighborhoodBusinessesProvider =
    FutureProvider.family<List<Business>, String>((ref, id) async {
      final rows = await ref
          .watch(businessRepositoryProvider)
          .fetchAll(status: 'active', neighborhoodId: id);
      return rows.map(Business.fromJson).toList();
    });

class WebNeighborhoodDetailContent extends ConsumerStatefulWidget {
  final String neighborhoodId;
  const WebNeighborhoodDetailContent({super.key, required this.neighborhoodId});

  @override
  ConsumerState<WebNeighborhoodDetailContent> createState() =>
      _WebNeighborhoodDetailContentState();
}

class _WebNeighborhoodDetailContentState
    extends ConsumerState<WebNeighborhoodDetailContent> {
  bool _isHebrew = false;
  bool _aboutExpanded = false;
  final _scrollController = ScrollController();

  // The three carousels each used to build a fresh ScrollController inside
  // build(), so the arrows scrolled a controller that the next rebuild threw
  // away and none of them was ever disposed.
  final _saleController = ScrollController();
  final _rentController = ScrollController();
  final _businessController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    _saleController.dispose();
    _rentController.dispose();
    _businessController.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  @override
  Widget build(BuildContext context) {
    final neighborhood = ref.watch(
      neighborhoodByIdProvider(widget.neighborhoodId),
    );

    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: 'realestate',
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: neighborhood.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 160),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => _buildNotice(
                    icon: IconsaxPlusLinear.wifi_square,
                    title: _t(
                      'This neighbourhood could not be loaded',
                      'לא ניתן לטעון את השכונה',
                    ),
                    body: _t(
                      'Check your connection and try again.',
                      'בדקו את החיבור לאינטרנט ונסו שוב.',
                    ),
                    actionLabel: _t('Try again', 'נסו שוב'),
                    onAction: () => ref.invalidate(
                      neighborhoodByIdProvider(widget.neighborhoodId),
                    ),
                  ),
                  data: (n) => n == null
                      ? _buildNotice(
                          icon: IconsaxPlusLinear.buildings_2,
                          title: _t(
                            'Neighbourhood not found',
                            'השכונה לא נמצאה',
                          ),
                          body: _t(
                            'This address does not match a neighbourhood in the directory.',
                            'הכתובת הזו לא תואמת שכונה במדריך.',
                          ),
                          actionLabel: _t('Back to Real Estate', 'חזרה לנדל"ן'),
                          onAction: () => context.go('/realestate'),
                        )
                      : _buildBody(n),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Neighborhood n) {
    return Column(
      children: [
        const SizedBox(height: 48),
        _buildHeroSection(n),
        // Only when the client has written a description. Three paragraphs
        // about Moriah, and a "Neighborhood Highlights" column asserting
        // excellent schools and nearby highways, used to appear under every
        // neighbourhood in the city. Nothing in the database says either.
        if (n.description != null) ...[
          const SizedBox(height: 64),
          _buildAboutSection(n),
        ],
        const SizedBox(height: 64),
        _buildListingCarousel(n, ListingKind.sale),
        const SizedBox(height: 64),
        _buildListingCarousel(n, ListingKind.rent),
        _buildBusinessesSection(n),
        const SizedBox(height: 64),
        WebFooter(isHebrew: _isHebrew),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // HERO SECTION — info on the left, the photo on the right
  // ─────────────────────────────────────────────
  Widget _buildHeroSection(Neighborhood n) {
    return _Section(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT COLUMN — info
          Expanded(
            flex: 592,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go('/realestate'),
                    child: Icon(
                      _isHebrew
                          ? IconsaxPlusLinear.arrow_right_3
                          : IconsaxPlusLinear.arrow_left,
                      size: 24,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  n.name,
                  style: TextStyle(
                    fontFamily: AppFonts.nunito,
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      IconsaxPlusBold.location,
                      size: 16,
                      color: AppColors.turquoise,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _t('Modiin Maccabim Reut', 'מודיעין מכבים רעות'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        color: const Color(0xFF6D6D6D),
                      ),
                    ),
                  ],
                ),
                if (n.description != null) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 540,
                    child: Text(
                      n.description!.split('\n\n').first.trim(),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        color: const Color(0xFF3D3D3D),
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                _buildStatsBar(n),
              ],
            ),
          ),
          const SizedBox(width: 40),
          // RIGHT COLUMN — the neighbourhood's photograph.
          //
          // A three-image collage stood here: one large panel and two smaller
          // ones. `neighborhoods` holds a single `image_url`, so there was
          // never a gallery of three to show.
          Expanded(
            flex: 942,
            child: SizedBox(
              height: 425,
              child: NetworkPhoto(
                url: n.imageUrl,
                radius: BorderRadius.circular(16),
                icon: IconsaxPlusBold.buildings_2,
                iconSize: 80,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The two figures the database can answer.
  ///
  /// There were four, the same four under every neighbourhood: 12 properties
  /// for sale, 18 businesses in the area, 6 parks and playgrounds, 7 schools
  /// and kindergartens. There is no table of parks and none of schools, so
  /// those two are gone rather than approximated.
  Widget _buildStatsBar(Neighborhood n) {
    final counts = ref.watch(neighborhoodCountsProvider(n.id)).valueOrNull;

    final stats = [
      (
        // Null while the count is in flight, which is why it shows a dash
        // rather than a nought — a nought is a claim, a dash is not.
        value: counts?.listings,
        label: _t('Properties Listed', 'נכסים מפורסמים'),
        icon: IconsaxPlusBold.home_2,
      ),
      (
        value: counts?.businesses,
        label: _t('Businesses in Area', 'עסקים באזור'),
        icon: IconsaxPlusBold.shop,
      ),
    ];

    return Container(
      width: 541,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++)
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: i == stats.length - 1
                      ? null
                      : BorderDirectional(
                          end: BorderSide(
                            color: const Color(
                              0xFFE7E7E7,
                            ).withValues(alpha: 0.6),
                          ),
                        ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(stats[i].icon, size: 28, color: AppColors.midBlue),
                    const SizedBox(height: 10),
                    Text(
                      stats[i].value?.toString() ?? '—',
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stats[i].label,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 11,
                        color: const Color(0xFF6D6D6D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ABOUT — the client's own description, when there is one
  // ─────────────────────────────────────────────
  Widget _buildAboutSection(Neighborhood n) {
    // The first paragraph already sits in the hero, so this section carries
    // the rest of what was written.
    final paragraphs = n.description!
        .split('\n\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .skip(1)
        .toList();
    if (paragraphs.isEmpty) return const SizedBox.shrink();

    final shown = _aboutExpanded ? paragraphs : paragraphs.take(2).toList();

    return _Section(
      child: SizedBox(
        width: 931,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('About ${n.name}', 'על שכונת ${n.name}'),
              style: TextStyle(
                fontFamily: AppFonts.nunito,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.midBlue,
              ),
            ),
            const SizedBox(height: 24),
            for (var i = 0; i < shown.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i == shown.length - 1 ? 0 : 16,
                ),
                child: Text(
                  shown[i],
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    color: const Color(0xFF3D3D3D),
                    height: 1.6,
                  ),
                ),
              ),
            // Only worth offering when something is being held back. The
            // button used to be drawn whatever the length of the text.
            if (paragraphs.length > 2) ...[
              const SizedBox(height: 16),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => _aboutExpanded = !_aboutExpanded),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.midBlue),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Text(
                      _aboutExpanded
                          ? _t('Show Less', 'הצג פחות')
                          : _t('Read More', 'קרא עוד'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.midBlue,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // APARTMENTS FOR SALE / FOR RENT
  // ─────────────────────────────────────────────
  /// One neighbourhood's listings of a kind.
  ///
  /// Four invented flats sat in each carousel, priced, addressed and headed
  /// "in Moriah" whichever neighbourhood was open. `listings` has no rows
  /// yet, so both carousels say so.
  Widget _buildListingCarousel(Neighborhood n, ListingKind kind) {
    final isRent = kind == ListingKind.rent;
    final async = ref.watch(neighborhoodListingsProvider((n.id, kind)));

    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isRent
                      ? _t(
                          'Apartments for Rent in ${n.name}',
                          'דירות להשכרה ב${n.name}',
                        )
                      : _t(
                          'Apartments for Sale in ${n.name}',
                          'דירות למכירה ב${n.name}',
                        ),
                  style: TextStyle(
                    fontFamily: AppFonts.nunito,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.midBlue,
                  ),
                ),
              ),
              // It went to the Real Estate front page whichever carousel it
              // sat over; now it opens the matching search.
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.push(
                    isRent ? '/apartments-rent' : '/apartments-sale',
                  ),
                  child: Text(
                    _t('View All', 'הצג הכל'),
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.turquoise,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          async.when(
            loading: () => const SizedBox(
              height: 321,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => _buildNotice(
              icon: IconsaxPlusLinear.wifi_square,
              title: _t(
                'Properties could not be loaded',
                'לא ניתן לטעון את הנכסים',
              ),
              body: _t(
                'Check your connection and try again.',
                'בדקו את החיבור לאינטרנט ונסו שוב.',
              ),
              actionLabel: _t('Try again', 'נסו שוב'),
              onAction: () =>
                  ref.invalidate(neighborhoodListingsProvider((n.id, kind))),
              padded: false,
            ),
            data: (listings) => listings.isEmpty
                ? _buildNotice(
                    icon: IconsaxPlusLinear.home_2,
                    title: isRent
                        ? _t(
                            'Nothing to let here yet',
                            'אין כרגע דירות להשכרה בשכונה הזו',
                          )
                        : _t(
                            'Nothing for sale here yet',
                            'אין כרגע דירות למכירה בשכונה הזו',
                          ),
                    body: _t(
                      'Properties will appear here as they are published.',
                      'נכסים יופיעו כאן עם פרסומם.',
                    ),
                    padded: false,
                  )
                : _buildCarousel(
                    controller: isRent ? _rentController : _saleController,
                    height: 321,
                    itemWidth: 382,
                    step: 402,
                    itemCount: listings.length,
                    itemBuilder: (i) => _PropertyCardWidget(
                      listing: listings[i],
                      isHebrew: _isHebrew,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUSINESSES IN THIS NEIGHBOURHOOD
  // ─────────────────────────────────────────────
  /// Real businesses filed under this neighbourhood.
  ///
  /// Five were written in — a dentist, a café, a pharmacy, a mini market and
  /// a hair salon, each with a star rating and a review count, all of them in
  /// "Moriah, Modiin". Most neighbourhoods have none on file, and the section
  /// is then left out rather than filled.
  Widget _buildBusinessesSection(Neighborhood n) {
    final businesses = ref
        .watch(_neighborhoodBusinessesProvider(n.id))
        .valueOrNull;
    if (businesses == null || businesses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: _Section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _t('Businesses in ${n.name}', 'עסקים ב${n.name}'),
                    style: TextStyle(
                      fontFamily: AppFonts.nunito,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.midBlue,
                    ),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.go('/businesses'),
                    child: Text(
                      _t('View All', 'הצג הכל'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.turquoise,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildCarousel(
              controller: _businessController,
              height: 348,
              itemWidth: 301,
              step: 321,
              itemCount: businesses.length,
              itemBuilder: (i) => _BusinessCardWidget(business: businesses[i]),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SHARED PIECES
  // ─────────────────────────────────────────────
  Widget _buildCarousel({
    required ScrollController controller,
    required double height,
    required double itemWidth,
    required double step,
    required int itemCount,
    required Widget Function(int) itemBuilder,
  }) {
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ListView.separated(
            controller: controller,
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            separatorBuilder: (_, _) => const SizedBox(width: 20),
            itemBuilder: (context, index) =>
                SizedBox(width: itemWidth, child: itemBuilder(index)),
          ),
          PositionedDirectional(
            start: -20,
            top: 0,
            bottom: 0,
            child: Center(
              child: _CarouselArrow(
                isBack: true,
                isHebrew: _isHebrew,
                onTap: () => controller.animateTo(
                  controller.offset - step,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                ),
              ),
            ),
          ),
          PositionedDirectional(
            end: -20,
            top: 0,
            bottom: 0,
            child: Center(
              child: _CarouselArrow(
                isBack: false,
                isHebrew: _isHebrew,
                onTap: () => controller.animateTo(
                  controller.offset + step,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Stands in for a section, or for the page, when there is nothing to draw.
  Widget _buildNotice({
    required IconData icon,
    required String title,
    required String body,
    String? actionLabel,
    VoidCallback? onAction,
    bool padded = true,
  }) {
    final box = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE7E7E7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 44,
            color: const Color(0xFF6D6D6D).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: const Color(0xFF5F5E5A),
            ),
            textAlign: TextAlign.center,
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
                  decoration: BoxDecoration(
                    color: AppColors.midBlue,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  alignment: Alignment.center,
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

    return padded
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: _Section(child: box),
          )
        : box;
  }
}

// ═══════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════

class _Section extends StatelessWidget {
  final Widget child;
  const _Section({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1600),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: child,
        ),
      ),
    );
  }
}

class _CarouselArrow extends StatefulWidget {
  /// Which way the carousel moves, rather than which way the glyph points —
  /// in Hebrew the two are opposites.
  final bool isBack;
  final bool isHebrew;
  final VoidCallback onTap;
  const _CarouselArrow({
    required this.isBack,
    required this.isHebrew,
    required this.onTap,
  });

  @override
  State<_CarouselArrow> createState() => _CarouselArrowState();
}

class _CarouselArrowState extends State<_CarouselArrow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final pointsLeft = widget.isBack != widget.isHebrew;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFF8F8F8) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF6F6F6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Icon(
            pointsLeft
                ? IconsaxPlusLinear.arrow_left_2
                : IconsaxPlusLinear.arrow_right_3,
            size: 20,
            color: AppColors.midBlue,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// PROPERTY CARD — used in the sale & rent carousels
// ═══════════════════════════════════════════════

class _PropertyCardWidget extends StatefulWidget {
  final Listing listing;
  final bool isHebrew;
  const _PropertyCardWidget({required this.listing, required this.isHebrew});

  @override
  State<_PropertyCardWidget> createState() => _PropertyCardWidgetState();
}

class _PropertyCardWidgetState extends State<_PropertyCardWidget> {
  bool _hovered = false;

  String _t(String en, String he) => widget.isHebrew ? he : en;

  /// Half rooms are normal here, so 3.5 must not print as 3.
  static String _rooms(double rooms) =>
      rooms == rooms.roundToDouble() ? '${rooms.toInt()}' : '$rooms';

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final isRent = l.kind == ListingKind.rent;
    final price = l.effectivePrice;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        // The card was not tappable at all. It opens the row it shows now.
        onTap: () => context.push('/listing/${l.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE7E7E7)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          transform: _hovered
              ? Matrix4.translationValues(0, -2, 0)
              : Matrix4.identity(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: NetworkPhoto(
                      url: l.coverUrl,
                      radius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      icon: IconsaxPlusBold.home_2,
                      iconSize: 40,
                    ),
                  ),
                  // A drawing of a heart with nothing behind it; it saves the
                  // listing now.
                  PositionedDirectional(
                    end: 12,
                    top: 12,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: FavoriteButton(
                          kind: FavoriteKind.listing,
                          id: l.id,
                          iconSize: 18,
                        ),
                      ),
                    ),
                  ),
                  // A "New" badge sat beside this one. `listings` records
                  // when a row was created but nothing says what counts as
                  // new, so the rule would have been invented here.
                  if (l.isBroker)
                    PositionedDirectional(
                      start: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCCD6EE),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          _t('Via Broker', 'דרך מתווך'),
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0033AC),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // A listing with no price is not a free one, so
                          // nothing is printed where there is no figure.
                          Flexible(
                            child: price == null
                                ? Text(
                                    _t('Price on request', 'מחיר לפי בקשה'),
                                    style: TextStyle(
                                      fontFamily: AppFonts.inter,
                                      fontSize: 14,
                                      color: const Color(0xFF5F5E5A),
                                    ),
                                  )
                                : Row(
                                    children: [
                                      Text(
                                        formatShekels(price),
                                        style: TextStyle(
                                          fontFamily: AppFonts.nunito,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.navy,
                                        ),
                                      ),
                                      if (isRent) ...[
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            _t('/ month', '/ לחודש'),
                                            style: TextStyle(
                                              fontFamily: AppFonts.inter,
                                              fontSize: 13,
                                              color: const Color(0xFF5F5E5A),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                          Text(
                            isRent
                                ? _t('FOR RENT', 'להשכרה')
                                : _t('FOR SALE', 'למכירה'),
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.turquoise,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            IconsaxPlusBold.location,
                            size: 14,
                            color: AppColors.turquoise,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              l.address ?? l.neighborhoodName ?? l.title,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 13,
                                color: const Color(0xFF5F5E5A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Each figure only where the row carries it, rather
                      // than a nought or a dash standing in for one.
                      Row(
                        children: [
                          if (l.sqm != null) ...[
                            _miniStat(
                              IconsaxPlusLinear.maximize_3,
                              _t('${l.sqm} m²', '${l.sqm} מ"ר'),
                            ),
                            const SizedBox(width: 24),
                          ],
                          if (l.rooms != null) ...[
                            _miniStat(
                              IconsaxPlusLinear.building_3,
                              _t(
                                '${_rooms(l.rooms!)} Rooms',
                                '${_rooms(l.rooms!)} חדרים',
                              ),
                            ),
                            const SizedBox(width: 24),
                          ],
                          if (l.floor != null)
                            _miniStat(
                              IconsaxPlusLinear.building_4,
                              _t('Floor ${l.floor}', 'קומה ${l.floor}'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6D6D6D)),
        const SizedBox(width: 6),
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

// ═══════════════════════════════════════════════
// BUSINESS CARD — used in the businesses carousel
// ═══════════════════════════════════════════════

class _BusinessCardWidget extends StatefulWidget {
  final Business business;
  const _BusinessCardWidget({required this.business});

  @override
  State<_BusinessCardWidget> createState() => _BusinessCardWidgetState();
}

class _BusinessCardWidgetState extends State<_BusinessCardWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.business;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push('/business/${b.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE7E7E7)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          transform: _hovered
              ? Matrix4.translationValues(0, -2, 0)
              : Matrix4.identity(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: NetworkPhoto(
                      url: b.imageUrl,
                      radius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      icon: IconsaxPlusBold.shop,
                      iconSize: 36,
                    ),
                  ),
                  // `businesses` keeps its categories in `entity_categories`,
                  // which this query does not join, so the badge is drawn
                  // only when a category actually came back.
                  if (b.category.isNotEmpty)
                    PositionedDirectional(
                      start: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          b.category,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.name,
                        style: TextStyle(
                          fontFamily: AppFonts.nunito,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // No review has been written yet, so nothing is rated.
                      // The card used to print 4.8 out of 127 reviews, and a
                      // rating of 0.0 out of 0 would be no better.
                      if (b.reviewCount > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              IconsaxPlusBold.star_1,
                              size: 14,
                              color: Color(0xFFFFC107),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              b.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.navy,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${b.reviewCount})',
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 12,
                                color: const Color(0xFF6D6D6D),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Spacer(),
                      if (b.address.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              IconsaxPlusBold.location,
                              size: 14,
                              color: AppColors.turquoise,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                b.address,
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 13,
                                  color: const Color(0xFF5F5E5A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
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
