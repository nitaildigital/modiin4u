import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/web_banner_row.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../businesses/providers/business_providers.dart';
import '../models/offer.dart';
import '../providers/offer_providers.dart';

// ═══════════════════════════════════════════════════════════
// Web Deals — Figma "Deals" (395:4351), 1920 × 2876
//
// Everything on this page used to be written into the source: eight offers
// on shops that are not in Modiin, category counts of 62, 48 and 31, ten
// "brand" tiles promising rewards nobody offered. It reads `offers` now, and
// every section the design draws is built from those rows:
//
// * the banners are the campaigns booked for DEALS_TOP;
// * a category is the category of the offer's business — `offers` has no
//   category column — and its circle is the photograph of a deal in it;
// * the orange badge is the discount the offer's own title states;
// * "Residents Only" is an offer the admin limited to verified residents;
// * "Most Popular Brands" are the businesses behind the most-claimed offers.
// ═══════════════════════════════════════════════════════════

const _kAsset = 'assets/web/deals';
const _kLine = Color(0xFFE7E7E7);
const _kHeading = Color(0xFF1C1C1E);
const _kGrey = Color(0xFF5F5E5A);
const _kMuted = Color(0xFF6D6D6D);
const _kBody = Color(0xFF3D3D3D);
const _kPillLine = Color(0xFFD1D1D1);
const _kOrange = Color(0xFFFB7901);

TextStyle _display(double size, {Color color = AppColors.midBlue, double? height}) =>
    TextStyle(fontFamily: AppFonts.nunito, fontSize: size, fontWeight: FontWeight.w600, color: color, height: height);

TextStyle _inter(double size, {FontWeight weight = FontWeight.w400, Color color = Colors.black, double? height}) =>
    TextStyle(fontFamily: AppFonts.inter, fontSize: size, fontWeight: weight, color: color, height: height);

final _hebrew = RegExp(r'[֐-׿]');

/// Text from the database reads in its own direction whatever the page does.
TextDirection _dirOf(String s) => _hebrew.hasMatch(s) ? TextDirection.rtl : TextDirection.ltr;

/// ...and lines up with the page's start, so a Hebrew headline on the English
/// page sits beside the logo above it rather than against the far edge.
TextAlign _alignOf(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl ? TextAlign.right : TextAlign.left;

/// The four pills under the carousel. Three put the deals in an order, from a
/// column the table has; the fourth keeps only the residents-only ones.
enum _Pill { expiringSoon, mostPopular, newest, residentsOnly }

class WebDealsContent extends ConsumerStatefulWidget {
  const WebDealsContent({super.key});

  @override
  ConsumerState<WebDealsContent> createState() => _WebDealsContentState();
}

class _WebDealsContentState extends ConsumerState<WebDealsContent>
    with WebLanguageState<WebDealsContent> {
  bool get _isHebrew => webIsHebrew.value;
  _Pill? _pill;

  /// The category circle chosen, if any. Held here rather than in the shared
  /// provider, so the phone's Deals screen keeps its own choice.
  String? _category;

  /// The brand tile chosen, if any — the carousel then shows that business's
  /// deals only.
  String? _business;

  final _dealsCarousel = ScrollController();
  final _dealsKey = GlobalKey();

  @override
  void dispose() {
    _dealsCarousel.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  /// Offers still running. The table keeps an offer `active` until the admin
  /// expires it; one whose end date has passed is not a deal any more.
  List<Offer> get _live =>
      (ref.watch(activeOffersProvider).valueOrNull ?? const <Offer>[]).where((o) => !o.hasExpired).toList();

  Map<String, Set<String>> get _kinds => ref.watch(offerBusinessCategoriesProvider).valueOrNull ?? const {};

  bool _inCategory(Offer o, String categoryId) => _kinds[o.businessId]?.contains(categoryId) ?? false;

  List<Offer> _shown(List<Offer> all) {
    var list = all;
    if (_category != null) list = list.where((o) => _inCategory(o, _category!)).toList();
    if (_business != null) list = list.where((o) => o.businessId == _business).toList();
    switch (_pill) {
      case null:
        break;
      case _Pill.residentsOnly:
        list = list.where((o) => o.isResidentsOnly).toList();
      case _Pill.expiringSoon:
        list = [...list]
          ..sort((a, b) {
            final x = a.endAt, y = b.endAt;
            if (x == null || y == null) return x == null ? (y == null ? 0 : 1) : -1;
            return x.compareTo(y);
          });
      case _Pill.mostPopular:
        list = [...list]..sort((a, b) => b.claimCount.compareTo(a.claimCount));
      case _Pill.newest:
        list = [...list]
          ..sort((a, b) {
            final x = a.startAt ?? a.createdAt, y = b.startAt ?? b.createdAt;
            if (x == null || y == null) return x == null ? (y == null ? 0 : 1) : -1;
            return y.compareTo(x);
          });
    }
    return list;
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
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTitle(),
                    const WebBannerRow(code: 'DEALS_TOP', top: 48),
                    _buildCategories(),
                    _buildPopularDeals(),
                    _buildBrands(),
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
  // TITLE — 44 over 16, centred, 56 under the bar
  // ─────────────────────────────────────────────
  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: WebSection(
        child: Column(
          children: [
            Text(
              _t('Best Deals & Offers in Modiin', 'המבצעים וההטבות הטובים במודיעין'),
              textAlign: TextAlign.center,
              style: _display(44, color: Colors.black, height: 1.23),
            ),
            const SizedBox(height: 14),
            Text(
              _t('Explore local deals, discounts, and limited-time offers across Modiin.',
                  'גלו מבצעים מקומיים, הנחות והטבות לזמן מוגבל בכל מודיעין.'),
              textAlign: TextAlign.center,
              style: _inter(16, color: _kMuted, height: 1.19),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EXPLORE DEALS BY CATEGORY — six columns, a 116 circle in each
  //
  // Only the categories that hold a running deal, in the admin's order, so no
  // circle ever reads "0 Deals"; the section is not drawn while there are none.
  // ─────────────────────────────────────────────
  Widget _buildCategories() {
    final live = _live;
    final all = ref.watch(businessCategoriesProvider).valueOrNull ?? const <BusinessCategory>[];
    final tiles = <({BusinessCategory category, int count, String? photo})>[];
    for (final c in all) {
      final inIt = live.where((o) => _inCategory(o, c.id)).toList();
      if (inIt.isEmpty) continue;
      // The category's own picture where the admin set one; otherwise the
      // photograph of a deal filed under it.
      final photo = c.imageUrl ??
          inIt.map((o) => o.imageUrl ?? o.businessCoverUrl).firstWhere((u) => (u ?? '').isNotEmpty, orElse: () => null);
      tiles.add((category: c, count: inIt.length, photo: photo));
    }
    if (tiles.isEmpty) return const SizedBox.shrink();
    final perRow = tiles.length <= 6 ? 6 : (tiles.length <= 8 ? tiles.length : 8);

    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: WebSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('Explore Deals by Category', 'גלו מבצעים לפי קטגוריה'), style: _display(28, height: 1.21)),
            const SizedBox(height: 40),
            // The design's single row of six equal columns; a seventh or
            // eighth category narrows the columns rather than starting a
            // second row of one. Past eight they wrap, eight to a row.
            for (var row = 0; row * perRow < tiles.length; row++) ...[
              if (row > 0) const SizedBox(height: 40),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = row * perRow; i < row * perRow + perRow; i++)
                    Expanded(
                      child: i >= tiles.length
                          ? const SizedBox.shrink()
                          : _CategoryTile(
                              name: tiles[i].category.name,
                              photo: tiles[i].photo,
                              countLabel: tiles[i].count == 1
                                  ? _t('1 Deal', 'מבצע אחד')
                                  : _t('${tiles[i].count} Deals', '${tiles[i].count} מבצעים'),
                              isSelected: _category == tiles[i].category.id,
                              // Choosing the chosen one again clears it, so
                              // there is a way back to everything.
                              onTap: () => setState(() {
                                final id = tiles[i].category.id;
                                _category = _category == id ? null : id;
                                _business = null;
                              }),
                            ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // POPULAR DEALS IN MODIIN — 480 × 353 cards running off the right edge
  // ─────────────────────────────────────────────
  Widget _buildPopularDeals() {
    final async = ref.watch(activeOffersProvider);
    final shown = _shown(_live);
    final width = MediaQuery.sizeOf(context).width;
    final gutter = webGutter(width);
    // The design's row starts at the column's edge and runs past the window's
    // far side; the list is as wide as the window and indented by the gutter.
    final inset = gutter + (width - 2 * gutter - 1600).clamp(0.0, double.infinity) / 2;

    return Padding(
      key: _dealsKey,
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WebSection(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_t('Popular Deals in Modiin', 'מבצעים פופולריים במודיעין'), style: _display(28, height: 1.21)),
                      const SizedBox(height: 8),
                      Text(_t('Top deals handpicked for you', 'המבצעים הנבחרים בשבילכם'), style: _inter(14, color: _kGrey, height: 1.21)),
                    ],
                  ),
                ),
                if (shown.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HeaderArrow(back: true, onTap: () => _scrollDeals(-1)),
                        const SizedBox(width: 12),
                        _HeaderArrow(back: false, onTap: () => _scrollDeals(1)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 23),
          async.when(
            loading: () => Padding(
              padding: EdgeInsetsDirectional.only(start: inset),
              child: const _DealsSkeleton(),
            ),
            error: (_, _) => WebSection(
              child: _NoticeBox(
                icon: IconsaxPlusLinear.wifi_square,
                title: _t('Deals could not be loaded', 'לא ניתן לטעון את המבצעים'),
                body: _t('Check your connection and try again.', 'בדקו את החיבור לאינטרנט ונסו שוב.'),
                actionLabel: _t('Try again', 'נסו שוב'),
                onAction: () => ref.invalidate(activeOffersProvider),
              ),
            ),
            data: (_) => shown.isEmpty
                ? WebSection(child: _buildEmpty())
                : SizedBox(
                    height: 353,
                    child: ListView.separated(
                      controller: _dealsCarousel,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsetsDirectional.only(start: inset, end: inset),
                      itemCount: shown.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 20),
                      itemBuilder: (context, i) => SizedBox(
                        width: 480,
                        child: _DealCard(
                          offer: shown[i],
                          isHebrew: _isHebrew,
                          onTap: () => context.push('/deal/${shown[i].id}'),
                        ),
                      ),
                    ),
                  ),
          ),
          // The pills sort and narrow the row above, so they are drawn once
          // there is a row to act on.
          if (_live.isNotEmpty) _buildPills(),
        ],
      ),
    );
  }

  void _scrollDeals(int direction) {
    if (!_dealsCarousel.hasClients) return;
    final target = (_dealsCarousel.offset + direction * 500).clamp(0.0, _dealsCarousel.position.maxScrollExtent);
    _dealsCarousel.animateTo(target, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  Widget _buildEmpty() {
    final narrowed = _category != null || _business != null || _pill == _Pill.residentsOnly;
    return _NoticeBox(
      icon: IconsaxPlusLinear.discount_shape,
      title: narrowed ? _t('No deals match', 'אין מבצעים מתאימים') : _t('No deals yet', 'אין עדיין מבצעים'),
      body: narrowed
          ? _t('Clear the filter to see every deal running now.', 'נקו את הסינון כדי לראות את כל המבצעים.')
          : _t('Local businesses have not published an offer yet. They will show up here when they do.',
              'עסקים מקומיים עדיין לא פרסמו הטבות. ההטבות יופיעו כאן כשיפורסמו.'),
      actionLabel: narrowed ? _t('Show all deals', 'הצג את כל המבצעים') : null,
      onAction: narrowed
          ? () => setState(() {
                _category = null;
                _business = null;
                _pill = null;
              })
          : null,
    );
  }

  // ─────────────────────────────────────────────
  // PILLS — 80 tall, 21 apart, centred 48 under the cards
  // ─────────────────────────────────────────────
  Widget _buildPills() {
    final pills = [
      (_Pill.expiringSoon, _t('Expiring Soon', 'נגמר בקרוב')),
      (_Pill.mostPopular, _t('Most Popular', 'הכי פופולרי')),
      (_Pill.newest, _t('New', 'חדש')),
      (_Pill.residentsOnly, _t('Residents Only', 'לתושבים בלבד')),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: WebSection(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 21,
          runSpacing: 16,
          children: [
            for (final (pill, label) in pills)
              _FilterPill(
                label: label,
                isSelected: _pill == pill,
                onTap: () => setState(() => _pill = _pill == pill ? null : pill),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MOST POPULAR BRANDS — 300 × 210 tiles, five across, 25 apart
  //
  // The businesses behind the deals, the most-claimed first. The pink strip
  // is the best discount among its deals, where their titles state one; the
  // button opens its deal, or narrows the carousel to its deals when it has
  // several. The design's "Upto 5% Rewards" has no column behind it anywhere.
  // ─────────────────────────────────────────────
  Widget _buildBrands() {
    final byBusiness = <String, List<Offer>>{};
    for (final o in _live) {
      final id = o.businessId;
      if (id == null || o.businessName == null) continue;
      byBusiness.putIfAbsent(id, () => []).add(o);
    }
    if (byBusiness.isEmpty) return const SizedBox.shrink();

    int claims(List<Offer> l) => l.fold(0, (s, o) => s + o.claimCount);
    final brands = byBusiness.entries.toList()
      ..sort((a, b) {
        final c = claims(b.value).compareTo(claims(a.value));
        if (c != 0) return c;
        final f = b.value.where((o) => o.isFeatured).length.compareTo(a.value.where((o) => o.isFeatured).length);
        return f != 0 ? f : b.value.length.compareTo(a.value.length);
      });

    return Padding(
      padding: const EdgeInsets.only(top: 70),
      child: WebSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('Most Popular Brands', 'המותגים הפופולריים'), style: _display(28, height: 1.21)),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, c) {
                const gap = 25.0;
                final w = (c.maxWidth - 4 * gap) / 5;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final e in brands.take(10))
                      SizedBox(
                        width: w,
                        height: 210,
                        child: _BrandTile(
                          offers: e.value,
                          isHebrew: _isHebrew,
                          isSelected: _business == e.key,
                          onTap: () {
                            if (e.value.length == 1) {
                              context.push('/deal/${e.value.first.id}');
                              return;
                            }
                            setState(() {
                              _business = _business == e.key ? null : e.key;
                              _category = null;
                            });
                            if (_dealsCarousel.hasClients) _dealsCarousel.jumpTo(0);
                            final target = _dealsKey.currentContext;
                            if (target != null && _business != null) {
                              Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 400), alignment: 0.1);
                            }
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// PIECES
// ═══════════════════════════════════════════════

/// The pair beside a section heading: white, grey ring, no shadow.
class _HeaderArrow extends StatelessWidget {
  final bool back;
  final VoidCallback onTap;
  const _HeaderArrow({required this.back, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _kLine),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(child: _Arrow(back: back)),
        ),
      ),
    );
  }
}

/// The design's arrow, pointing along the reading direction or against it.
class _Arrow extends StatelessWidget {
  final bool back;
  const _Arrow({required this.back});

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: back != (Directionality.of(context) == TextDirection.rtl),
      child: SvgPicture.asset('$_kAsset/arrow20.svg', width: 20, height: 20),
    );
  }
}

/// A 116 circle with the category's name and how many deals it holds.
class _CategoryTile extends StatefulWidget {
  final String name;
  final String? photo;
  final String countLabel;
  final bool isSelected;
  final VoidCallback onTap;
  const _CategoryTile({
    required this.name,
    required this.photo,
    required this.countLabel,
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
    final ring = widget.isSelected ? AppColors.midBlue : (_hovered ? AppColors.turquoise : null);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Container(
              width: 116,
              height: 116,
              foregroundDecoration: ring == null
                  ? null
                  : BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ring, width: 3)),
              child: NetworkPhoto(
                url: widget.photo,
                width: 116,
                height: 116,
                radius: BorderRadius.circular(58),
                icon: IconsaxPlusBold.discount_shape,
                iconSize: 30,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Text(
                    widget.name,
                    textDirection: _dirOf(widget.name),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _inter(18, weight: FontWeight.w600, color: _kHeading, height: 1.21),
                  ),
                  const SizedBox(height: 6),
                  Text(widget.countLabel, textAlign: TextAlign.center, style: _inter(14, color: _kGrey, height: 1.21)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterPill({required this.label, required this.isSelected, required this.onTap});

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
            border: Border.all(color: selected ? AppColors.midBlue : (_hovered ? AppColors.turquoise : _kPillLine)),
            borderRadius: BorderRadius.circular(50),
          ),
          // A Row with mainAxisSize.min keeps the pill hugging its label.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label, style: _display(24, color: selected ? Colors.white : _kBody, height: 1.25)),
            ],
          ),
        ),
      ),
    );
  }
}

/// One deal, 480 × 353: photograph with its badge, the business's mark, the
/// headline, the business and where it is, the time left, and the button.
class _DealCard extends StatefulWidget {
  final Offer offer;
  final bool isHebrew;
  final VoidCallback onTap;
  const _DealCard({required this.offer, required this.isHebrew, required this.onTap});

  @override
  State<_DealCard> createState() => _DealCardState();
}

class _DealCardState extends State<_DealCard> {
  bool _hovered = false;

  String _t(String en, String he) => widget.isHebrew ? he : en;

  @override
  Widget build(BuildContext context) {
    final d = widget.offer;
    final timeLeft = d.timeLeftLabel(isHebrew: widget.isHebrew);
    final place = d.businessNeighborhood ?? d.businessAddress;
    final badge = d.badge;

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
            border: Border.all(color: _hovered ? AppColors.midBlue : _kLine),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 250,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 157,
                      height: 191,
                      child: Stack(
                        children: [
                          NetworkPhoto(
                            url: d.imageUrl ?? d.businessCoverUrl,
                            width: 157,
                            height: 191,
                            radius: BorderRadius.circular(12),
                            icon: IconsaxPlusBold.discount_shape,
                            iconSize: 30,
                          ),
                          if (badge != null)
                            PositionedDirectional(
                              top: 12,
                              start: 12,
                              end: 12,
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: _Badge(label: badge),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 17),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LogoRing(url: d.businessLogoUrl, size: 72),
                          const SizedBox(height: 13),
                          SizedBox(
                            height: 54,
                            width: double.infinity,
                            child: Text(
                              d.name,
                              textDirection: _dirOf(d.name),
                              textAlign: _alignOf(context),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _inter(22, weight: FontWeight.w600, color: AppColors.midBlue, height: 1.21),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 17,
                            width: double.infinity,
                            child: Text(
                              d.businessName ?? '',
                              textDirection: _dirOf(d.businessName ?? ''),
                              textAlign: _alignOf(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _inter(14, weight: FontWeight.w500, color: _kHeading, height: 1.21),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 17,
                            child: place == null
                                ? null
                                : Row(
                                    children: [
                                      SvgPicture.asset('$_kAsset/card_pin.svg', width: 16, height: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          place,
                                          textDirection: _dirOf(place),
                                          textAlign: _alignOf(context),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: _inter(14, color: _kBody, height: 1.21),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const Spacer(),
                          SizedBox(
                            height: 36,
                            child: Row(
                              children: [
                                if (timeLeft != null) ...[
                                  SvgPicture.asset('$_kAsset/card_clock.svg', width: 20, height: 20),
                                  const SizedBox(width: 8),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        timeLeft,
                                        textDirection: TextDirection.ltr,
                                        style: _inter(16, weight: FontWeight.w600, color: AppColors.navy, height: 1.19),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(_t('Time Left', 'זמן שנותר'), style: _inter(12, color: _kGrey, height: 1.25)),
                                    ],
                                  ),
                                  const SizedBox(width: 44),
                                ],
                                if (d.isResidentsOnly)
                                  Flexible(child: _ResidentsOnly(isHebrew: widget.isHebrew)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              // The card is the tap target; the button is its label.
              Container(
                width: double.infinity,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.midBlue, borderRadius: BorderRadius.circular(60)),
                child: Text(_t('View Deal', 'צפו במבצע'), style: _inter(16, weight: FontWeight.w500, color: Colors.white, height: 1.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The orange label on a deal's photograph.
class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: _kOrange, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        textDirection: _dirOf(label),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _inter(14, weight: FontWeight.w600, color: Colors.white, height: 1.21),
      ),
    );
  }
}

/// The padlock and "Residents Only", orange, on two lines as the design sets
/// it.
class _ResidentsOnly extends StatelessWidget {
  final bool isHebrew;
  const _ResidentsOnly({required this.isHebrew});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset('$_kAsset/card_lock.svg', width: 20, height: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            isHebrew ? 'לתושבים\nבלבד' : 'Residents\nOnly',
            maxLines: 2,
            style: _inter(12, weight: FontWeight.w600, color: _kOrange, height: 1.25),
          ),
        ),
      ],
    );
  }
}

/// The business's mark in a thin grey ring.
class _LogoRing extends StatelessWidget {
  final String? url;
  final double size;
  const _LogoRing({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    final pad = size * 0.0488;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: _kLine, width: 0.878),
      ),
      child: NetworkPhoto(
        url: url,
        radius: BorderRadius.circular(size),
        icon: IconsaxPlusBold.shop,
        iconSize: size * 0.28,
      ),
    );
  }
}

/// A business behind the deals: the pink strip with its best discount, its
/// logo, and the button.
class _BrandTile extends StatefulWidget {
  final List<Offer> offers;
  final bool isHebrew;
  final bool isSelected;
  final VoidCallback onTap;
  const _BrandTile({required this.offers, required this.isHebrew, required this.isSelected, required this.onTap});

  @override
  State<_BrandTile> createState() => _BrandTileState();
}

class _BrandTileState extends State<_BrandTile> {
  bool _hovered = false;

  String _t(String en, String he) => widget.isHebrew ? he : en;

  /// "Upto 30% Off" when the business runs several percentage deals, the one
  /// deal's own badge otherwise, and how many deals it has when no title
  /// states a discount.
  String get _strip {
    final pcts = widget.offers.map((o) => o.percentOff).whereType<int>().toList();
    if (pcts.length > 1) {
      final best = pcts.reduce((a, b) => a > b ? a : b);
      return _t('Upto $best% Off', 'עד $best% הנחה');
    }
    for (final o in widget.offers) {
      final b = o.badge;
      if (b != null) return b;
    }
    final n = widget.offers.length;
    return n == 1 ? _t('1 Deal', 'מבצע אחד') : _t('$n Deals', '$n מבצעים');
  }

  @override
  Widget build(BuildContext context) {
    final first = widget.offers.first;
    final name = first.businessName ?? '';
    final logo = first.businessLogo;
    final strip = _strip;
    final n = widget.offers.length;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: widget.isSelected || _hovered ? AppColors.midBlue : _kLine),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 33,
                width: double.infinity,
                alignment: Alignment.center,
                color: const Color(0xFFFFE6E6),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  strip,
                  textDirection: _dirOf(strip),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _inter(14, weight: FontWeight.w500, color: const Color(0xFFE90052), height: 1.21),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: logo != null
                              ? ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 204, maxHeight: 96),
                                  child: Image.network(
                                    sizedPhotoUrl(logo, 204, MediaQuery.devicePixelRatioOf(context)),
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => _Wordmark(name: name),
                                  ),
                                )
                              // Where the business has no logo, its name
                              // stands in for one rather than a photograph.
                              : _Wordmark(name: name),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.midBlue, borderRadius: BorderRadius.circular(60)),
                        child: Text(
                          n == 1 ? _t('View Deal', 'צפו במבצע') : _t('View $n Deals', 'צפו ב־$n מבצעים'),
                          style: _inter(16, weight: FontWeight.w500, color: Colors.white, height: 1.5),
                        ),
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

class _Wordmark extends StatelessWidget {
  final String name;
  const _Wordmark({required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      textDirection: _dirOf(name),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: _display(24, color: AppColors.navy, height: 1.2),
    );
  }
}

/// Two card-shaped blocks at the real card's geometry.
class _DealsSkeleton extends StatelessWidget {
  const _DealsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 353,
      child: Skeleton(
        child: Row(
          children: List.generate(
            2,
            (_) => const Padding(
              padding: EdgeInsetsDirectional.only(end: 20),
              child: SkeletonBox(width: 480, height: 353, radius: 12),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticeBox extends StatelessWidget {
  final IconData icon;
  final String title, body;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _NoticeBox({required this.icon, required this.title, required this.body, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 353,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(border: Border.all(color: _kLine), borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: _kGrey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: _inter(18, weight: FontWeight.w600, color: _kHeading)),
          const SizedBox(height: 8),
          SizedBox(
            width: 520,
            child: Text(body, textAlign: TextAlign.center, style: _inter(14, color: _kGrey, height: 1.5)),
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
                  decoration: BoxDecoration(color: AppColors.midBlue, borderRadius: BorderRadius.circular(60)),
                  child: Text(actionLabel!, style: _inter(16, weight: FontWeight.w500, color: Colors.white)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
