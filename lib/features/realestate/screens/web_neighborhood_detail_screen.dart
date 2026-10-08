import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../models/listing.dart';
import '../providers/detail_providers.dart';
import '../providers/neighborhood_providers.dart';
import '../providers/neighborhood_rating_providers.dart';
import '../widgets/web_detail_parts.dart';
import '../../../core/router/app_router.dart' show AppNavigation;

// ═══════════════════════════════════════════════════════════
// Web Neighborhood Detail — desktop layout for /neighborhood/:id
//
// Built to the Figma frame "Neighborhood" (233:1292).
//
// Every neighbourhood in the city used to render as Moriah: its name, three
// paragraphs about when it was settled, four statistics, four bullet points,
// eight flats and five businesses were all written into this file, and the
// id the route carried was never read. What is drawn now comes from the
// neighbourhood's row, its photographs, and the listings and businesses
// filed under it.
//
// Two parts of the design have nothing behind them and are not drawn: the
// "Parks & Playgrounds" and "Schools & Kindergardens" counts in the stats box,
// and the four-point checklist beside "About Moriah" ("Quiet, family-friendly
// environment", …). `neighborhoods` has no column for either, and there is no
// table of parks or of schools.
// ═══════════════════════════════════════════════════════════

class WebNeighborhoodDetailContent extends ConsumerStatefulWidget {
  final String neighborhoodId;
  const WebNeighborhoodDetailContent({super.key, required this.neighborhoodId});

  @override
  ConsumerState<WebNeighborhoodDetailContent> createState() =>
      _WebNeighborhoodDetailContentState();
}

class _WebNeighborhoodDetailContentState extends ConsumerState<WebNeighborhoodDetailContent>
    with WebLanguageState<WebNeighborhoodDetailContent> {
  bool get _isHebrew => webIsHebrew.value;

  String _t(String en, String he) => _isHebrew ? he : en;

  @override
  Widget build(BuildContext context) {
    final neighborhood = ref.watch(neighborhoodByIdProvider(widget.neighborhoodId));

    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: 'realestate',
            ),
            Expanded(
              child: SingleChildScrollView(
                child: neighborhood.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 160),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => _buildNotice(
                    icon: IconsaxPlusLinear.wifi_square,
                    title: _t('This neighbourhood could not be loaded', 'לא ניתן לטעון את השכונה'),
                    body: _t('Check your connection and try again.', 'בדקו את החיבור לאינטרנט ונסו שוב.'),
                    actionLabel: _t('Try again', 'נסו שוב'),
                    onAction: () => ref.invalidate(neighborhoodByIdProvider(widget.neighborhoodId)),
                  ),
                  data: (n) => n == null
                      ? _buildNotice(
                          icon: IconsaxPlusLinear.buildings_2,
                          title: _t('Neighbourhood not found', 'השכונה לא נמצאה'),
                          body: _t(
                            'This address does not match a neighbourhood in the directory.',
                            'הכתובת הזו לא תואמת שכונה במדריך.',
                          ),
                          actionLabel: _t('Back to Real Estate', 'חזרה לנדל״ן'),
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
    // The client's description, one paragraph per entry. The first is the
    // short introduction under the name; the rest are "About".
    final paragraphs = detailParagraphs(n.description);
    final intro = paragraphs.isEmpty ? null : paragraphs.first;
    final about = paragraphs.length > 1 ? paragraphs.sublist(1) : const <String>[];

    final sale = ref.watch(neighborhoodListingsProvider((n.id, ListingKind.sale))).valueOrNull ?? const [];
    final rent = ref.watch(neighborhoodListingsProvider((n.id, ListingKind.rent))).valueOrNull ?? const [];
    final businesses = ref.watch(neighborhoodBusinessesProvider(n.id)).valueOrNull ?? const [];

    DetailStrip listings(String title, List<Listing> items) => DetailStrip(
      maxWidth: 1600,
      title: title,
      titleGap: 24,
      carousel: DetailCarousel(
        itemCount: items.length,
        height: 321,
        gap: 24,
        perView: (_) => 4,
        arrowTop: 141,
        itemBuilder: (context, i) => DetailListingCard(listing: items[i], isHebrew: _isHebrew, large: true),
      ),
    );

    // Each section with the space the design leaves above it; one with
    // nothing in it is left out, and its gap with it.
    final sections = <(double, Widget)>[
      if (about.isNotEmpty) (64, WebSection(child: _buildAbout(n, about))),
      if (sale.isNotEmpty)
        (about.isNotEmpty ? 88 : 64, listings(_t('Apartments for Sale in ${n.name}', 'דירות למכירה ב${n.name}'), sale)),
      if (rent.isNotEmpty)
        (64, listings(_t('Apartments for Rent in ${n.name}', 'דירות להשכרה ב${n.name}'), rent)),
      // The design heads this strip "Businesses for Sale in Moriah" and
      // fills it with restaurants, a café and a bar, rated and open. Nothing
      // in the directory is a business for sale; these are the businesses in
      // the neighbourhood, and the heading says so, as the listing page's
      // strip of the same cards does.
      if (businesses.isNotEmpty)
        (
          64,
          DetailStrip(
            maxWidth: 1600,
            title: _t('Businesses in ${n.name}', 'עסקים ב${n.name}'),
            titleGap: 30,
            carousel: DetailCarousel(
              itemCount: businesses.length,
              height: 348,
              gap: 24,
              // Five across at the design's width; four once the row
              // narrows, where five would squeeze each name.
              perView: (width) => width >= 1500 ? 5 : 4,
              arrowTop: 141,
              itemBuilder: (context, i) =>
                  DetailBusinessCard(business: businesses[i], isHebrew: _isHebrew, large: true),
            ),
          ),
        ),
    ];

    return Column(
      children: [
        const SizedBox(height: 32),
        WebSection(child: _buildHero(n, intro)),
        for (final (gap, section) in sections) ...[
          SizedBox(height: gap),
          section,
        ],
        const SizedBox(height: 124),
        WebFooter(isHebrew: _isHebrew),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // HERO — name, introduction and figures on one side, photographs on the
  // other
  // ─────────────────────────────────────────────
  Widget _buildHero(Neighborhood n, String? intro) {
    final photos = ref.watch(neighborhoodPhotosProvider(n.id));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 592,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.canPop() ? context.back('/realestate') : context.go('/realestate'),
                  child: Transform.flip(
                    flipX: _isHebrew,
                    child: SvgPicture.asset('$kDetailAsset/detail_back.svg', width: 24, height: 24),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              DetailText(n.name, maxLines: 2, style: detailDisplay(36, color: AppColors.navy, height: 44 / 36)),
              const SizedBox(height: 16),
              // Every neighbourhood in the directory is one of this city's.
              DetailPlace(_t('Modiin', 'מודיעין'), style: detailInter(14)),
              _buildRating(n),
              if (intro != null) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: DetailText(intro, maxLines: null, style: detailInter(16, color: kDetailBody, height: 1.6)),
                ),
              ],
              const SizedBox(height: 32),
              _buildStats(n),
            ],
          ),
        ),
        const SizedBox(width: 66),
        Expanded(
          flex: 942,
          child: Padding(
            padding: const EdgeInsets.only(top: 25),
            child: photos.when(
              loading: () => Container(
                height: 425,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F3F8),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              error: (_, _) => _mosaic(const []),
              data: _mosaic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _mosaic(List<String> photos) => DetailPhotoMosaic(
    photos: photos,
    height: 425,
    radius: 10,
    gap: 8,
    fourUp: false,
    buttonInset: 12,
    showAllLabel: _t('Show all photos', 'כל התמונות'),
    fallbackIcon: IconsaxPlusBold.buildings_2,
  );

  /// The two figures the database can answer, in the design's box.
  ///
  /// A dash stands in while a count is in flight: a nought would be a
  /// claim, a dash is not.
  Widget _buildStats(Neighborhood n) {
    final stats = ref.watch(neighborhoodStatsProvider(n.id)).valueOrNull;
    final items = [
      (icon: 'detail_stat_home.svg', value: stats?.forSale, label: _t('Properties for Sale', 'נכסים למכירה')),
      (icon: 'detail_stat_shop.svg', value: stats?.businesses, label: _t('Businesses in the Area', 'עסקים באזור')),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 541),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kDetailLine),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Container(
                    padding: EdgeInsetsDirectional.only(
                      start: i == 0 ? 0 : 16,
                      end: i == items.length - 1 ? 0 : 16,
                    ),
                    decoration: i == items.length - 1
                        ? null
                        : const BoxDecoration(
                            border: BorderDirectional(end: BorderSide(color: kDetailLine)),
                          ),
                    child: Column(
                      children: [
                        SvgPicture.asset('$kDetailAsset/${items[i].icon}', width: 24, height: 24),
                        const SizedBox(height: 12),
                        Text(items[i].value?.toString() ?? '—', style: detailInter(18, weight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(
                          items[i].label,
                          style: detailInter(12, color: kDetailGrey),
                          textAlign: TextAlign.center,
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

  /// The residents' average star rating and how many gave one (00071),
  /// read only: rating needs an account, and accounts are the app's.
  /// Nothing at all until someone has rated — a "0.0" would read as a bad
  /// score rather than as none.
  Widget _buildRating(Neighborhood n) {
    final r = ref.watch(neighborhoodRatingProvider(n.id)).valueOrNull;
    if (r == null) return const SizedBox.shrink();
    final count = r.count == 1
        ? _t('1 rating', 'דירוג אחד')
        : _t('${r.count} ratings', '${r.count} דירוגים');
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(r.average.toStringAsFixed(1), style: detailInter(14, weight: FontWeight.w500)),
          const SizedBox(width: 8),
          _AverageStars(value: r.average),
          const SizedBox(width: 8),
          Text('($count)', style: detailInter(14, color: kDetailMuted)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ABOUT
  // ─────────────────────────────────────────────
  Widget _buildAbout(Neighborhood n, List<String> paragraphs) {
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 931),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('About ${n.name}', 'על ${n.name}'), style: detailDisplay(24)),
            for (final p in paragraphs) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: DetailText(p, maxLines: null, style: detailInter(16, color: kDetailBody, height: 1.6)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Stands in for the page when there is nothing to draw.
  Widget _buildNotice({
    required IconData icon,
    required String title,
    required String body,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: WebSection(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
          decoration: BoxDecoration(
            border: Border.all(color: kDetailLine),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 44, color: kDetailMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(title, style: detailDisplay(20, color: AppColors.navy), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(body, style: detailInter(14, color: kDetailGrey), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.midBlue,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Text(actionLabel, style: detailInter(16, weight: FontWeight.w500, color: Colors.white, height: 1.5)),
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

/// Five of the business page's stars filled to [value], to the nearest half.
/// The first star sits at the reading start, and a half star is filled on
/// that side.
class _AverageStars extends StatelessWidget {
  final double value;
  const _AverageStars({required this.value});

  static const _full = 'assets/web/business/star14_full.svg';
  static const _empty = 'assets/web/business/star14_empty.svg';
  static const _size = 14.0;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final halves = (value * 2).round() / 2;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          SizedBox(
            width: _size,
            height: _size,
            child: Stack(
              children: [
                SvgPicture.asset(_empty, width: _size, height: _size),
                if (halves - i > 0)
                  ClipRect(
                    child: Align(
                      // The filled part grows from the reading start.
                      alignment: rtl ? Alignment.centerRight : Alignment.centerLeft,
                      widthFactor: (halves - i).clamp(0.0, 1.0),
                      child: SvgPicture.asset(_full, width: _size, height: _size),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
