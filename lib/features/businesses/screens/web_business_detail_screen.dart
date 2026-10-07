import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/web_share_menu.dart';
import '../models/menu_item.dart' as menu_item;
import '../repositories/business_stats.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/web_map_tiles.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../models/business.dart';
import '../models/business_review.dart';
import '../models/review_reply.dart';
import '../providers/business_providers.dart';
import '../../../shared/widgets/web_contact_menu.dart';

// ═══════════════════════════════════════════════════════════
// Business page, desktop — Figma "Restaurant Detail", 1920 wide
//
// The design was built once before, as a restaurant page at /restaurant/:id,
// around one invented grill restaurant: its menu prose, seven days of opening
// hours, a 4.6 from 128 reviews, five invented reviewers and five invented
// neighbours. None of it was anybody's. This is the same page read from the
// business it is about.
//
// The design also draws what a signed-in resident does — Save, "Have you
// visited?", upload a photo, write a review. The client has decided accounts
// belong to the app, so those are not drawn here.
// ═══════════════════════════════════════════════════════════

const _kAsset = 'assets/web/business';
const _kHomeAsset = 'assets/web/home';
const _kInk = Color(0xFF0A1230);
const _kBody = Color(0xFF3D3D3D);
const _kGrey = Color(0xFF5F5E5A);
const _kMuted = Color(0xFF6D6D6D);
const _kLine = Color(0xFFE7E7E7);
const _kOpen = Color(0xFF00BA00);
const _kClosed = Color(0xFFF21C1C);

TextStyle _display(double size, {Color color = AppColors.midBlue, double? height}) =>
    TextStyle(fontFamily: AppFonts.nunito, fontSize: size, fontWeight: FontWeight.w600, color: color, height: height);

TextStyle _inter(double size, {FontWeight weight = FontWeight.w400, Color color = Colors.black, double? height, TextDecoration? decoration}) =>
    TextStyle(fontFamily: AppFonts.inter, fontSize: size, fontWeight: weight, color: color, height: height, decoration: decoration, decorationColor: color);

final _hebrew = RegExp(r'[֐-׿]');

/// Text from the directory reads in its own direction whatever the page does.
TextDirection _dirOf(String s) => _hebrew.hasMatch(s) ? TextDirection.rtl : TextDirection.ltr;

class WebBusinessDetailContent extends ConsumerStatefulWidget {
  final Business business;
  const WebBusinessDetailContent({super.key, required this.business});

  @override
  ConsumerState<WebBusinessDetailContent> createState() => _WebBusinessDetailContentState();
}

class _WebBusinessDetailContentState extends ConsumerState<WebBusinessDetailContent>
    with WebLanguageState<WebBusinessDetailContent> {
  bool get _isHebrew => webIsHebrew.value;
  final _galleryController = ScrollController();
  final _hoursKey = GlobalKey();
  int _reviewsShown = 5;
  _ReviewOrder _reviewOrder = _ReviewOrder.recent;

  /// The star count the list is narrowed to, or null for all of them.
  int? _ratingFilter;

  Business get b => widget.business;
  String _t(String en, String he) => _isHebrew ? he : en;

  @override
  void initState() {
    super.initState();
    BusinessStats.record(b.id, BusinessStat.view);
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gallery = ref.watch(businessGalleryProvider(b.id)).valueOrNull ?? const <String>[];
    // Only approved ones here: the website has no resident accounts, so a
    // pending review in the list could only be an admin's own.
    final reviews = [
      for (final r in ref.watch(businessReviewsProvider(b.id)).valueOrNull ?? const <BusinessReview>[])
        if (r.isApproved) r,
    ];
    final kind = (ref.watch(businessPrimaryCategoryProvider).valueOrNull ?? const {})[b.id];

    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              // A park belongs to the Municipal page, which the navbar has
              // no item for; lighting Businesses said it was a business.
              activeId: b.isPark ? null : 'businesses',
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHero(gallery, kind?.category.name),
                    const SizedBox(height: 56),
                    WebSection(
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final main = _buildMainColumn(gallery, reviews);
                          final side = Column(
                            children: [
                              _buildLocationHoursCard(),
                              const SizedBox(height: 20),
                              _buildMoreInfoCard(),
                            ],
                          );
                          // Two columns on any laptop: the design's 136
                          // between them at full width, closing to 48 when
                          // the window is narrower, rather than dropping the
                          // map above the page.
                          if (c.maxWidth < 1000) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [main, const SizedBox(height: 56), side],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: main),
                              SizedBox(width: c.maxWidth >= 1500 ? 136 : 48),
                              SizedBox(width: 376, child: side),
                            ],
                          );
                        },
                      ),
                    ),
                    _buildMoreBusinesses(),
                    const SizedBox(height: 120),
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
  // HERO — the cover across the page, darkened under the name
  // ─────────────────────────────────────────────
  Widget _buildHero(List<String> gallery, String? categoryName) {
    final facts = [
      if ((categoryName ?? '').isNotEmpty) categoryName!,
      if (b.kosherLabel != null) _isHebrew ? 'כשר' : 'Kosher',
    ];

    return SizedBox(
      height: 550,
      child: Stack(
        children: [
          Positioned.fill(
            child: NetworkPhoto(
              url: b.imageUrl ?? gallery.firstOrNull,
              icon: null,
            ),
          ),
          // The design darkens the half the name sits on, fading to clear.
          Positioned.fill(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.centerStart,
                      end: AlignmentDirectional.centerEnd,
                      stops: const [0.012, 0.523, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: WebSection(
              child: Stack(
                children: [
                  PositionedDirectional(
                    top: 158,
                    start: 0,
                    end: 0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroLogo(url: b.logoUrl, isPark: b.isPark),
                        const SizedBox(width: 33),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.name,
                                textDirection: _dirOf(b.name),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: _display(48, color: Colors.white, height: 1.23),
                              ),
                              if (facts.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Text(facts.join(' · '), style: _inter(16, color: Colors.white)),
                              ],
                              if (b.reviewCount > 0 || b.kosherLabel != null) ...[
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    if (b.reviewCount > 0)
                                      _GlassPill(
                                        icon: '$_kAsset/star14.svg',
                                        label: _t('${b.rating.toStringAsFixed(1)} · ${b.reviewCount} reviews',
                                            '${b.rating.toStringAsFixed(1)} · ${b.reviewCount} ביקורות'),
                                      ),
                                    if (b.reviewCount > 0 && b.kosherLabel != null) const SizedBox(width: 16),
                                    if (b.kosherLabel != null)
                                      _GlassPill(
                                        icon: '$_kAsset/check14.svg',
                                        label: _isHebrew ? b.kosherLabel! : 'Kosher',
                                      ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 32),
                              if (b.hours.isNotEmpty) ...[
                                _buildOpenLine(),
                                const SizedBox(height: 16),
                              ],
                              if (b.address.isNotEmpty)
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: Center(child: SvgPicture.asset('$_kAsset/pin.svg', width: 12, height: 16)),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(b.address,
                                          textDirection: _dirOf(b.address),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: _inter(14, weight: FontWeight.w500, color: Colors.white)),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (gallery.isNotEmpty)
                    PositionedDirectional(
                      top: 486,
                      end: 0,
                      child: _HeroButton(
                        icon: '$_kAsset/gallery.svg',
                        label: _t('Show all photos', 'כל התמונות'),
                        onTap: () => _openPhotos(gallery, 0),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Open now · Closes 22:00 · See all hours", from today's row.
  Widget _buildOpenLine() {
    final today = b.hours.where((h) => h.dayOfWeek == DateTime.now().weekday && !h.isClosed).toList();
    final open = b.isOpenNow;
    final closes = open && today.isNotEmpty ? today.first.closeTime : null;

    return Row(
      children: [
        if (open) ...[
          SvgPicture.asset('$_kAsset/clock_open.svg', width: 16, height: 16),
          const SizedBox(width: 8),
          Text(_t('Open now', 'פתוח עכשיו'), style: _inter(14, weight: FontWeight.w500, color: _kOpen)),
        ] else ...[
          const Icon(IconsaxPlusLinear.clock, size: 16, color: _kClosed),
          const SizedBox(width: 8),
          Text(_t('Closed now', 'סגור עכשיו'), style: _inter(14, weight: FontWeight.w500, color: _kClosed)),
        ],
        const SizedBox(width: 12),
        if (closes != null)
          Text('${_t('Closes', 'נסגר ב-')} ${_time(closes)} · ', style: _inter(14, weight: FontWeight.w500, color: Colors.white)),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              final target = _hoursKey.currentContext;
              if (target != null) {
                Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 400), alignment: 0.1);
              }
            },
            child: Text(_t('See all hours', 'כל שעות הפעילות'),
                style: _inter(14, weight: FontWeight.w500, color: Colors.white, decoration: TextDecoration.underline)),
          ),
        ),
      ],
    );
  }

  /// "21:30" as the design prints it in English, "9:30 PM"; Hebrew keeps
  /// the 24-hour clock Israel reads.
  String _time(String hhmm) {
    if (_isHebrew) return hhmm;
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? parts[1] : '00';
    final suffix = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $suffix';
  }

  void _openPhotos(List<String> photos, int start) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (_) => _PhotoViewer(photos: photos, initial: start),
    );
  }

  // ─────────────────────────────────────────────
  // MAIN COLUMN
  // ─────────────────────────────────────────────
  Widget _buildMainColumn(List<String> gallery, List<BusinessReview> reviews) {
    final about = (b.about ?? b.description ?? '').trim();
    final highlights = _highlights();

    final menu = ref.watch(businessMenuProvider(b.id)).valueOrNull ?? const [];

    final sections = <Widget>[
      if (about.isNotEmpty) _buildAbout(about),
      if (highlights.isNotEmpty) _buildHighlights(highlights),
      // The menu the panel keeps: the phone page showed it, this one did not.
      if (menu.isNotEmpty) _buildMenu(menu),
      if (gallery.isNotEmpty) _buildGallery(gallery),
      _buildReviews(reviews),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 56),
          sections[i],
        ],
      ],
    );
  }

  Widget _title(String text) => Text(text, style: _display(24));

  /// The menu, by its sections in the panel's order: name, description, price.
  Widget _buildMenu(List<menu_item.MenuItem> items) {
    final bySection = <String, List<menu_item.MenuItem>>{};
    for (final i in items.where((i) => i.isAvailable)) {
      bySection.putIfAbsent(i.section?.trim().isNotEmpty == true ? i.section!.trim() : '', () => []).add(i);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(_t('Menu', 'תפריט')),
        for (final e in bySection.entries) ...[
          if (e.key.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(e.key, style: _inter(18, weight: FontWeight.w600)),
          ],
          const SizedBox(height: 8),
          for (final i in e.value)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _kLine))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(i.name, style: _inter(16, weight: FontWeight.w500)),
                        if ((i.description ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(i.description!.trim(), style: _inter(14, color: _kMuted)),
                        ],
                      ],
                    ),
                  ),
                  if (i.priceLabel != null) ...[
                    const SizedBox(width: 16),
                    Text(i.priceLabel!, style: _inter(16, weight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildAbout(String about) {
    final paragraphs = about.split(RegExp(r'\n\s*\n')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 896),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(_t('About ${b.name}', 'אודות ${b.name}')),
          const SizedBox(height: 24),
          for (var i = 0; i < paragraphs.length; i++) ...[
            if (i > 0) const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: Text(
                paragraphs[i],
                textDirection: _dirOf(paragraphs[i]),
                style: _inter(16, color: _kBody, height: 1.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// What the row says the place offers. The design's list ("High quality
  /// meats", "Family friendly") is prose somebody would have to write; these
  /// are the facts the table holds, and only the true ones.
  List<String> _highlights() => [
    if (b.kosherLabel != null) _t('Kosher', 'כשר'),
    if (b.hasDelivery) _t('Delivery', 'משלוחים'),
    if (b.hasOutdoorSeating) _t('Outdoor seating', 'ישיבה בחוץ'),
    if (b.isAccessible) _t('Accessible', 'נגיש'),
    if (b.hasParking) _t('Parking', 'חניה'),
    if (b.petFriendly) _t('Pet friendly', 'ידידותי לחיות מחמד'),
    if (b.openOnShabbat) _t('Open on Shabbat', 'פתוח בשבת'),
  ];

  Widget _buildHighlights(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(_t('Highlights', 'נקודות בולטות')),
        const SizedBox(height: 24),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          Row(
            children: [
              SvgPicture.asset('$_kAsset/highlight_check.svg', width: 20, height: 20),
              const SizedBox(width: 12),
              Text(items[i], style: _inter(16, color: _kBody)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildGallery(List<String> photos) {
    // Arrows only where there is further to go: five photographs fill the
    // design's column exactly, and arrows that move nothing are decoration.
    void scroll(int direction) {
      if (!_galleryController.hasClients) return;
      final target = (_galleryController.offset + direction * 222 * 3)
          .clamp(0.0, _galleryController.position.maxScrollExtent);
      _galleryController.animateTo(target, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(_t('Business Gallery', 'גלריית העסק')),
        const SizedBox(height: 23),
        LayoutBuilder(
          builder: (context, c) => SizedBox(
            height: 202,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ListView.separated(
                  controller: _galleryController,
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 22),
                  itemBuilder: (context, i) => MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _openPhotos(photos, i),
                      child: NetworkPhoto(
                        url: photos[i],
                        width: 200,
                        height: 202,
                        radius: BorderRadius.circular(8),
                        icon: IconsaxPlusLinear.gallery,
                      ),
                    ),
                  ),
                ),
                if (photos.length * 222 - 22 > c.maxWidth) ...[
                  PositionedDirectional(start: -20, top: 81, child: _CarouselArrow(back: true, onTap: () => scroll(-1))),
                  PositionedDirectional(end: -20, top: 81, child: _CarouselArrow(back: false, onTap: () => scroll(1))),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Reviews ──
  Widget _buildReviews(List<BusinessReview> reviews) {
    final summary = ReviewSummary.of(reviews);
    final replies = ref.watch(reviewRepliesProvider(b.id)).valueOrNull ?? const <String, List<ReviewReply>>{};
    final filtered = [
      for (final r in reviews)
        if (_ratingFilter == null || r.rating == _ratingFilter) r,
    ];
    switch (_reviewOrder) {
      case _ReviewOrder.recent:
        break; // The provider returns them newest first.
      case _ReviewOrder.highest:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
      case _ReviewOrder.lowest:
        filtered.sort((a, b) => a.rating.compareTo(b.rating));
    }
    final shown = filtered.take(_reviewsShown).toList();
    final more = filtered.length > shown.length;

    final orderLabels = {_ReviewOrder.recent: _t('Most Recent', 'האחרונות'), _ReviewOrder.highest: _t('Highest Rated', 'הדירוג הגבוה'), _ReviewOrder.lowest: _t('Lowest Rated', 'הדירוג הנמוך')};
    String ratingLabel(int? stars) => stars == null ? _t('All', 'הכל') : '$stars ★';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 918),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(_t('Reviews for ${b.name}', 'ביקורות על ${b.name}')),
          const SizedBox(height: 39),
          if (reviews.isEmpty)
            // Nothing to average, and no place on the website to write the
            // first one: reviews are written in the app.
            Text(_t('No reviews yet. Reviews are written by residents in the Modiin4u app.', 'עדיין אין ביקורות. תושבים כותבים ביקורות באפליקציית מודיעין בשבילך.'), style: _inter(16, color: _kBody))
          else ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 240,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      border: BorderDirectional(end: BorderSide(color: _kLine)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(summary.average.toStringAsFixed(1), style: _inter(48, weight: FontWeight.w600, height: 1.21)),
                        const SizedBox(height: 16),
                        _Stars(value: summary.average.round(), size: 24, gap: 7),
                        const SizedBox(height: 16),
                        Text(_t('Based on ${summary.total} reviews', 'מבוסס על ${summary.total} ביקורות'), style: _inter(16, color: _kBody, height: 1.19)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 81),
                  SizedBox(
                    width: 393,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var score = 5; score >= 1; score--) ...[if (score < 5) const SizedBox(height: 12), _ShareRow(score: score, share: summary.shareOf(score))],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                _DropdownBox<_ReviewOrder>(
                  label: _t('Sort By: ${orderLabels[_reviewOrder]}', 'מיון: ${orderLabels[_reviewOrder]}'),
                  options: [for (final e in orderLabels.entries) (e.key, e.value)],
                  selected: _reviewOrder,
                  onSelected: (v) => setState(() {
                    _reviewOrder = v;
                    _reviewsShown = 5;
                  }),
                ),
                const SizedBox(width: 12),
                _DropdownBox<int?>(
                  label: _t('Rating: ${ratingLabel(_ratingFilter)}', 'דירוג: ${ratingLabel(_ratingFilter)}'),
                  options: [
                    for (final v in const [null, 5, 4, 3, 2, 1]) (v, ratingLabel(v)),
                  ],
                  selected: _ratingFilter,
                  onSelected: (v) => setState(() {
                    _ratingFilter = v;
                    _reviewsShown = 5;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 30),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(_t('No reviews with this rating.', 'אין ביקורות בדירוג הזה.'), style: _inter(16, color: _kBody)),
              )
            // While there are more to load, the last one fades out under the
            // button, as the design draws it.
            else if (more)
              Stack(
                children: [
                  Column(
                    children: [for (final r in shown) _ReviewRow(review: r, isHebrew: _isHebrew, replies: replies[r.id] ?? const [])],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -2,
                    height: 222,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0, 0.978], colors: [Colors.white.withValues(alpha: 0), Colors.white]),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 2,
                    child: Center(
                      child: _OutlinePill(label: _t('Load More', 'טען עוד'), onTap: () => setState(() => _reviewsShown += 5)),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [for (final r in shown) _ReviewRow(review: r, isHebrew: _isHebrew, replies: replies[r.id] ?? const [])],
              ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SIDEBAR
  // ─────────────────────────────────────────────
  Widget _buildLocationHoursCard() {
    final hasPlace = b.latitude != 0 && b.longitude != 0;
    const dayNames = {
      1: ('Mon', 'שני'), 2: ('Tue', 'שלישי'), 3: ('Wed', 'רביעי'), 4: ('Thu', 'חמישי'),
      5: ('Fri', 'שישי'), 6: ('Sat', 'שבת'), 7: ('Sun', 'ראשון'),
    };
    // The week as the design lays it out, Monday first, from whichever days
    // the business has published.
    final days = [
      for (final d in [1, 2, 3, 4, 5, 6, 7])
        if (b.hours.any((h) => h.dayOfWeek == d)) d,
    ];

    return Container(
      key: _hoursKey,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_t('Location & Hours', 'מיקום ושעות'), style: _display(20)),
                if (b.address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(b.address, textDirection: _dirOf(b.address), style: _inter(14, color: _kMuted)),
                ],
              ],
            ),
          ),
          if (hasPlace) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 231,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(b.latitude, b.longitude),
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  onTap: (_, _) {
                    BusinessStats.record(b.id, BusinessStat.directions);
                    launchUrl(Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${b.latitude},${b.longitude}'));
                  },
                ),
                children: [
                  const WebMapTiles(),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(b.latitude, b.longitude),
                        width: 48,
                        height: 52,
                        alignment: Alignment.topCenter,
                        child: SvgPicture.asset('$_kAsset/map_marker.svg', width: 48, height: 51.9),
                      ),
                    ],
                  ),
                  const WebMapCredit(),
                ],
              ),
            ),
          ],
          if (days.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  for (var i = 0; i < days.length; i++) ...[
                    if (i > 0) const SizedBox(height: 20),
                    Builder(
                      builder: (context) {
                        final rows = b.hours.where((h) => h.dayOfWeek == days[i]).toList();
                        final open = rows.where((h) => !h.isClosed).toList();
                        final label = _isHebrew ? dayNames[days[i]]!.$2 : dayNames[days[i]]!.$1;
                        return Row(
                          children: [
                            Text(label, style: _inter(14, weight: FontWeight.w500, color: _kBody)),
                            const Spacer(),
                            if (open.isEmpty)
                              Text(_t('Close', 'סגור'), style: _inter(14, weight: FontWeight.w500, color: _kClosed))
                            else
                              Text(
                                open.map((h) => '${_time(h.openTime!)} - ${_time(h.closeTime!)}').join(', '),
                                style: _inter(14, weight: FontWeight.w500, color: _kBody),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoreInfoCard() {
    final website = (b.website ?? '').trim();
    final phone = (b.phone ?? '').trim();
    final whatsapp = (b.whatsapp ?? '').trim();
    // A park has no contact details to offer (the client's rule for parks).
    if (b.isPark) return const SizedBox.shrink();
    final instagram = (b.instagram ?? '').trim();

    String shown(String url) => url.replaceFirst(RegExp(r'^https?://(www\.)?'), '').replaceFirst(RegExp(r'/$'), '');
    Uri link(String url) => Uri.parse(url.startsWith('http') ? url : 'https://$url');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(border: Border.all(color: _kLine), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('More Info', 'מידע נוסף'), style: _display(20)),
          const SizedBox(height: 24),
          if (website.isNotEmpty)
            _InfoRow(
              icon: '$_kAsset/website.svg',
              label: _t('Website', 'אתר'),
              value: shown(website),
              valueColor: AppColors.midBlue,
              trailing: SvgPicture.asset('$_kAsset/external.svg', width: 16, height: 16),
              onTap: () {
                BusinessStats.record(b.id, BusinessStat.website);
                launchUrl(link(website));
              },
            ),
          if (website.isNotEmpty && phone.isNotEmpty) const SizedBox(height: 20),
          // The number is on the page; the tap offers it to copy or dial
          // too, since `tel:` alone does nothing visible on most computers.
          if (phone.isNotEmpty)
            Builder(
              builder: (anchor) => _InfoRow(
                icon: '$_kAsset/call.svg',
                label: _t('Call', 'טלפון'),
                value: phone,
                onTap: () {
                  BusinessStats.record(b.id, BusinessStat.call);
                  showWebContactMenu(anchor, isHebrew: _isHebrew, phone: phone);
                },
              ),
            ),
          // Five businesses carry a WhatsApp number the page never showed.
          if (whatsapp.isNotEmpty && (website.isNotEmpty || phone.isNotEmpty)) const SizedBox(height: 20),
          if (whatsapp.isNotEmpty)
            _InfoRow(
              icon: 'assets/web/news/share_whatsapp.svg',
              label: 'WhatsApp',
              value: whatsapp,
              onTap: () {
                BusinessStats.record(b.id, BusinessStat.whatsapp);
                var digits = whatsapp.replaceAll(RegExp(r'\D'), '');
                if (digits.startsWith('0')) digits = '972${digits.substring(1)}';
                launchUrl(Uri.parse('https://wa.me/$digits'), webOnlyWindowName: '_blank');
              },
            ),
          // Instagram and Share, which the phone page had and this one did not.
          if (instagram.isNotEmpty) ...[
            const SizedBox(height: 20),
            _InfoRow(
              icon: '$_kAsset/website.svg',
              label: 'Instagram',
              value: shown(instagram),
              valueColor: AppColors.midBlue,
              trailing: SvgPicture.asset('$_kAsset/external.svg', width: 16, height: 16),
              onTap: () {
                BusinessStats.record(b.id, BusinessStat.instagram);
                launchUrl(link(instagram), webOnlyWindowName: '_blank');
              },
            ),
          ],
          const SizedBox(height: 20),
          Builder(
            builder: (anchor) => _InfoRow(
              icon: 'assets/web/news/stat_share.svg',
              label: _t('Share', 'שיתוף'),
              value: _t('Send this page', 'שלחו את העמוד'),
              onTap: () {
                BusinessStats.record(b.id, BusinessStat.share);
                showWebShareMenu(
                  anchor,
                  title: b.name,
                  link: Uri.base.toString(),
                  isHebrew: _isHebrew,
                  message: b.name,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MORE BUSINESSES — others in the same neighbourhood, or the same kind
  // ─────────────────────────────────────────────
  Widget _buildMoreBusinesses() {
    final all = ref.watch(businessesProvider).valueOrNull ?? const <Business>[];
    final kinds = ref.watch(businessPrimaryCategoryProvider).valueOrNull ?? const {};
    final mine = kinds[b.id];

    final others = all.where((x) => x.id != b.id).toList();
    var picked = b.neighborhoodId == null
        ? <Business>[]
        : others.where((x) => x.neighborhoodId == b.neighborhoodId).toList();
    var inNeighborhood = picked.isNotEmpty;
    if (picked.isEmpty && mine != null) {
      picked = others.where((x) => kinds[x.id]?.category.id == mine.category.id).toList();
    }
    if (picked.isEmpty) return const SizedBox.shrink();
    // Those with a photograph first.
    picked = [
      ...picked.where((x) => (x.imageUrl ?? '').isNotEmpty),
      ...picked.where((x) => (x.imageUrl ?? '').isEmpty),
    ].take(5).toList();

    // The design's heading names the neighbourhood. Most rows are filed
    // under none; those show others of the same kind, which are in the same
    // city, and say so in the design's own words.
    final heading = inNeighborhood && b.neighborhood.isNotEmpty
        ? _t('More Businesses in ${b.neighborhood}', 'עסקים נוספים ב${b.neighborhood}')
        : _t('More Businesses in Modiin', 'עסקים נוספים במודיעין');

    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: WebSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title(heading),
            const SizedBox(height: 30),
            LayoutBuilder(
              builder: (context, c) {
                const gap = 24.0;
                final cols = c.maxWidth > 1400 ? 5 : (c.maxWidth > 900 ? 3 : 2);
                final w = (c.maxWidth - (cols - 1) * gap) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final x in picked.take(cols))
                      SizedBox(width: w, child: _SmallBusinessCard(business: x, kind: kinds[x.id], isHebrew: _isHebrew)),
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

/// How the review list is ordered.
enum _ReviewOrder { recent, highest, lowest }

// ═══════════════════════════════════════════════
// PIECES
// ═══════════════════════════════════════════════

/// "Sort By: Most Recent ⌄" — a 40-tall box with a grey ring that opens its
/// choices underneath.
class _DropdownBox<T> extends StatelessWidget {
  final String label;
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;
  const _DropdownBox({required this.label, required this.options, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: '',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      color: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _kLine),
      ),
      onSelected: (i) => onSelected(options[i].$1),
      itemBuilder: (context) => [
        for (var i = 0; i < options.length; i++)
          PopupMenuItem<int>(
            value: i,
            height: 40,
            child: Text(
              options[i].$2,
              style: _inter(14, weight: options[i].$1 == selected ? FontWeight.w600 : FontWeight.w500, color: options[i].$1 == selected ? AppColors.midBlue : _kBody),
            ),
          ),
      ],
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _kLine),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: _inter(14, weight: FontWeight.w500, color: _kBody, height: 1.21),
              ),
              const SizedBox(width: 8),
              SvgPicture.asset('$_kAsset/chevron14.svg', width: 14, height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

/// The business's own logo in a white circle, 140 across; the shop mark where
/// it has none.
class _HeroLogo extends StatelessWidget {
  final String? url;
  final bool isPark;
  const _HeroLogo({required this.url, this.isPark = false});

  @override
  Widget build(BuildContext context) {
    // A park has no logo; its badge carries the Municipal page's park icon
    // rather than the shop front that stands in for a missing business logo.
    if (isPark && (url == null || url!.isEmpty)) {
      return Container(
        width: 140,
        height: 140,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          'assets/icons/m_municipal_parks.svg',
          width: 56,
          height: 56,
          colorFilter: const ColorFilter.mode(AppColors.midBlue, BlendMode.srcIn),
        ),
      );
    }
    return Container(
      width: 140,
      height: 140,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      // The design's logo fills its circle. Most logos here are square, so
      // they are drawn edge to edge and the circle trims their corners; a
      // wide wordmark keeps all its letters on white rather than being cut.
      child: ClipOval(
        child: NetworkPhoto(
          url: url,
          fit: BoxFit.contain,
          gradient: const [Colors.white, Colors.white],
          icon: IconsaxPlusLinear.shop,
          iconSize: 48,
          iconColor: AppColors.midBlue,
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final String icon;
  final String label;
  const _GlassPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(icon, width: 14, height: 14),
          const SizedBox(width: 7),
          Text(label, style: _inter(14, color: Colors.white)),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  const _HeroButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 16, height: 16, child: Center(child: SvgPicture.asset(icon, width: 13.3, height: 13.3))),
              const SizedBox(width: 8),
              Text(label, style: _inter(14, weight: FontWeight.w500, color: _kInk, height: 1.71)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round white arrow over the edge of a carousel.
class _CarouselArrow extends StatelessWidget {
  final bool back;
  final VoidCallback onTap;
  const _CarouselArrow({required this.back, required this.onTap});

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
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF6F6F6)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 5, offset: const Offset(0, 1))],
          ),
          child: Center(
            child: Transform.flip(
              flipX: back != (Directionality.of(context) == TextDirection.rtl),
              child: SvgPicture.asset('$_kAsset/carousel_arrow.svg', width: 20, height: 20),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final int value;
  final double size;
  final double gap;
  const _Stars({required this.value, required this.size, required this.gap});

  @override
  Widget build(BuildContext context) {
    final full = size >= 20 ? '$_kAsset/star24_full.svg' : '$_kAsset/star14_full.svg';
    final empty = size >= 20 ? '$_kAsset/star24_empty.svg' : '$_kAsset/star14_empty.svg';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++) ...[
          if (i > 1) SizedBox(width: gap),
          SvgPicture.asset(i <= value ? full : empty, width: size, height: size),
        ],
      ],
    );
  }
}

/// "5 ★ ▬▬▬▬▬▬▬▬░░ 78%".
class _ShareRow extends StatelessWidget {
  final int score;
  final double share;
  const _ShareRow({required this.score, required this.share});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          height: 22,
          child: Row(
            children: [
              Text('$score', style: _inter(16, weight: FontWeight.w500)),
              const SizedBox(width: 8),
              SvgPicture.asset('$_kAsset/star16.svg', width: 16, height: 16),
            ],
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  const Positioned.fill(child: ColoredBox(color: _kLine)),
                  // heightFactor too: a Stack hands its plain children a
                  // loose height, and a ColoredBox with nothing in it takes
                  // the least it is allowed — none — so the bars drew empty.
                  FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: share.clamp(0.0, 1.0),
                    heightFactor: 1,
                    child: const ColoredBox(color: AppColors.turquoise),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 11),
        SizedBox(
          width: 38,
          child: Text('${(share * 100).round()}%', textAlign: TextAlign.end, style: _inter(14, weight: FontWeight.w500, color: _kMuted)),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final BusinessReview review;
  final bool isHebrew;
  final List<ReviewReply> replies;
  const _ReviewRow({required this.review, required this.isHebrew, this.replies = const []});

  static const _en = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  static const _he = ['ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני', 'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר'];

  String _format(DateTime? at) {
    final d = at?.toLocal();
    if (d == null) return '';
    return isHebrew ? '${d.day} ב${_he[d.month - 1]} ${d.year}' : '${_en[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final date = _format(review.createdAt);
    final author = review.authorName.isEmpty
        ? (isHebrew ? 'תושב' : 'Resident')
        : review.authorName;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _kLine))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppColors.turquoise, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(review.initials.toUpperCase(), style: _inter(14, weight: FontWeight.w600, color: Colors.white)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(author, textDirection: _dirOf(author), style: _inter(16, weight: FontWeight.w500)),
                    const SizedBox(width: 12),
                    Text(date, style: _inter(12, color: _kMuted)),
                  ],
                ),
                const SizedBox(height: 7),
                _Stars(value: review.rating, size: 14, gap: 4),
                if (review.body.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  SizedBox(
                    width: double.infinity,
                    child: Text(review.body, textDirection: _dirOf(review.body), style: _inter(14, color: _kBody, height: 1.4)),
                  ),
                ],
                // Residents' replies (approved only: the website has no
                // accounts, so no one's own pending reply is shown here and
                // there is no reply button). Modiin4u and the businesses do
                // not reply at this stage, so `admin_response` is not shown.
                for (final reply in replies.where((r) => r.isApproved))
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsetsDirectional.only(top: 12),
                    padding: const EdgeInsetsDirectional.only(start: 14),
                    decoration: const BoxDecoration(
                      border: BorderDirectional(start: BorderSide(color: _kLine, width: 2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              reply.authorName.isEmpty
                                  ? lookupL(Locale(isHebrew ? 'he' : 'en')).resident
                                  : reply.authorName,
                              style: _inter(14, weight: FontWeight.w500),
                            ),
                            const SizedBox(width: 12),
                            Text(_format(reply.createdAt), style: _inter(12, color: _kMuted)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(reply.body, textDirection: _dirOf(reply.body), style: _inter(14, color: _kBody, height: 1.4)),
                      ],
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

class _OutlinePill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlinePill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        // A Row that hugs its label, not an aligned Container: given loose
        // room, an aligned Container takes all of it, and the button ran
        // the full width of the list.
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.midBlue),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Text(label, style: _inter(16, weight: FontWeight.w500, color: AppColors.midBlue))],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color valueColor;
  final Widget? trailing;
  final VoidCallback onTap;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.valueColor = Colors.black,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            SvgPicture.asset(icon, width: 20, height: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: _inter(14, color: const Color(0xFF5D5D5D))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(value,
                            textDirection: TextDirection.ltr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _inter(15, weight: FontWeight.w500, color: valueColor)),
                      ),
                      if (trailing != null) ...[const SizedBox(width: 6), trailing!],
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
}

/// A neighbour's card, as the design draws the row under the page: photo,
/// the round badge on its edge, name, kind, address, rating.
class _SmallBusinessCard extends StatelessWidget {
  final Business business;
  final ({BusinessCategory category, String rootSlug})? kind;
  final bool isHebrew;
  const _SmallBusinessCard({required this.business, required this.kind, required this.isHebrew});

  @override
  Widget build(BuildContext context) {
    final x = business;
    final subtitle = kind?.category.name ?? (x.description ?? '');
    final address = x.address.isNotEmpty ? x.address : x.neighborhood;
    final badge = switch (kind?.rootSlug) {
      'cafe-bakery' => ('card_badge_ring.svg', 'card_badge_cafe.svg'),
      'restaurants' => ('card_badge_ring_green.svg', 'card_badge_restaurant.svg'),
      _ => null,
    };

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.push('/business/${x.id}'),
        child: Container(
          height: 348,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _kLine),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 200,
                width: double.infinity,
                child: NetworkPhoto(url: x.imageUrl ?? x.logoUrl, icon: IconsaxPlusLinear.shop, iconSize: 40),
              ),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // The design's 50: a 25 name, 8, a 17 kind. Left to
                          // the font's own line height the pair ran 4 over and
                          // pushed the rating out of the card.
                          SizedBox(
                            height: 50,
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(x.name, textDirection: _dirOf(x.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: _display(20, color: _kInk, height: 1.25)),
                                const SizedBox(height: 8),
                                Text(subtitle, textDirection: _dirOf(subtitle), maxLines: 1, overflow: TextOverflow.ellipsis, style: _inter(14, color: _kGrey, height: 1.21)),
                              ],
                            ),
                          ),
                          if (address.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                SizedBox(width: 16, height: 16, child: Center(child: SvgPicture.asset('$_kHomeAsset/card_pin.svg', width: 12, height: 16))),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(address,
                                      textDirection: _dirOf(address),
                                      // Beside its pin, whichever way the page reads.
                                      textAlign: Directionality.of(context) == TextDirection.rtl ? TextAlign.right : TextAlign.left,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _inter(14, color: _kGrey, height: 1.21)),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (x.reviewCount == 0)
                            Text(isHebrew ? 'אין דירוג עדיין' : 'Not rated yet', style: _inter(14, color: _kMuted, height: 1.21))
                          else
                            Row(
                              children: [
                                SvgPicture.asset('$_kHomeAsset/card_star.svg', width: 16, height: 16),
                                const SizedBox(width: 8),
                                Text(x.rating.toStringAsFixed(1), style: _inter(14, weight: FontWeight.w500, height: 1.21)),
                                const SizedBox(width: 8),
                                Text('(${x.reviewCount})', style: _inter(14, color: _kMuted, height: 1.21)),
                              ],
                            ),
                        ],
                      ),
                    ),
                    if (badge != null)
                      PositionedDirectional(
                        top: -22,
                        end: 14,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SvgPicture.asset('$_kHomeAsset/${badge.$1}', width: 44, height: 44),
                              SvgPicture.asset('$_kHomeAsset/${badge.$2}', width: 20, height: 20),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The photographs, one at a time, over the page.
class _PhotoViewer extends StatefulWidget {
  final List<String> photos;
  final int initial;
  const _PhotoViewer({required this.photos, required this.initial});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final _controller = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = (_index + delta).clamp(0, widget.photos.length - 1);
    _controller.animateToPage(next, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 96, vertical: 64),
              child: Image.network(widget.photos[i], fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
            ),
          ),
          if (_index > 0)
            Positioned(
              left: 24,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: () => _go(-1),
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 48),
                ),
              ),
            ),
          if (_index < widget.photos.length - 1)
            Positioned(
              right: 24,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: () => _go(1),
                  icon: const Icon(Icons.chevron_right, color: Colors.white, size: 48),
                ),
              ),
            ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text('${_index + 1} / ${widget.photos.length}', style: _inter(14, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
