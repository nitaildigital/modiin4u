import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/osm_attribution.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../models/business.dart';
import '../models/business_review.dart';
import '../providers/business_providers.dart';

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

class _WebBusinessDetailContentState extends ConsumerState<WebBusinessDetailContent> {
  bool _isHebrew = webIsHebrew.value;
  final _galleryController = ScrollController();
  final _hoursKey = GlobalKey();
  int _reviewsShown = 5;

  Business get b => widget.business;
  String _t(String en, String he) => _isHebrew ? he : en;

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gallery = ref.watch(businessGalleryProvider(b.id)).valueOrNull ?? const <String>[];
    final reviews = ref.watch(businessReviewsProvider(b.id)).valueOrNull ?? const <BusinessReview>[];
    final kind = (ref.watch(businessPrimaryCategoryProvider).valueOrNull ?? const {})[b.id];

    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: 'businesses',
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
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
                        _HeroLogo(url: b.logoUrl),
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

    final sections = <Widget>[
      if (about.isNotEmpty) _buildAbout(about),
      if (highlights.isNotEmpty) _buildHighlights(highlights),
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
        SizedBox(
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
              if (photos.length > 5) ...[
                PositionedDirectional(start: -20, top: 81, child: _CarouselArrow(back: true, onTap: () => scroll(_isHebrew ? 1 : -1))),
                PositionedDirectional(end: -20, top: 81, child: _CarouselArrow(back: false, onTap: () => scroll(_isHebrew ? -1 : 1))),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Reviews ──
  Widget _buildReviews(List<BusinessReview> reviews) {
    final summary = ReviewSummary.of(reviews);
    final shown = reviews.take(_reviewsShown).toList();

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
            Text(
              _t('No reviews yet. Reviews are written by residents in the Modiin4u app.',
                  'עדיין אין ביקורות. תושבים כותבים ביקורות באפליקציית מודיעין בשבילך.'),
              style: _inter(16, color: _kBody),
            )
          else ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 240,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(border: BorderDirectional(end: BorderSide(color: _kLine))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(summary.average.toStringAsFixed(1), style: _inter(48, weight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        _Stars(value: summary.average.round(), size: 24, gap: 7),
                        const SizedBox(height: 16),
                        Text(_t('Based on ${summary.total} reviews', 'מבוסס על ${summary.total} ביקורות'),
                            style: _inter(16, color: _kBody)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 81),
                  SizedBox(
                    width: 393,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var score = 5; score >= 1; score--) ...[
                          if (score < 5) const SizedBox(height: 12),
                          _ShareRow(score: score, share: summary.shareOf(score)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            for (final r in shown) _ReviewRow(review: r, isHebrew: _isHebrew),
            if (reviews.length > shown.length) ...[
              const SizedBox(height: 24),
              Center(
                child: _OutlinePill(
                  label: _t('Load More', 'טען עוד'),
                  onTap: () => setState(() => _reviewsShown += 5),
                ),
              ),
            ],
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
                  onTap: (_, _) => launchUrl(Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=${b.latitude},${b.longitude}')),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.modiin4u.app',
                    maxZoom: 19,
                  ),
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
                  const OsmAttribution(),
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
    if (website.isEmpty && phone.isEmpty) return const SizedBox.shrink();

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
              onTap: () => launchUrl(link(website)),
            ),
          if (website.isNotEmpty && phone.isNotEmpty) const SizedBox(height: 20),
          if (phone.isNotEmpty)
            _InfoRow(
              icon: '$_kAsset/call.svg',
              label: _t('Call', 'טלפון'),
              value: phone,
              onTap: () => launchUrl(Uri(scheme: 'tel', path: phone)),
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

    final heading = inNeighborhood && b.neighborhood.isNotEmpty
        ? _t('More Businesses in ${b.neighborhood}', 'עסקים נוספים ב${b.neighborhood}')
        : _t('More Like This', 'עסקים דומים');

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

// ═══════════════════════════════════════════════
// PIECES
// ═══════════════════════════════════════════════

/// The business's own logo in a white circle, 140 across; the shop mark where
/// it has none.
class _HeroLogo extends StatelessWidget {
  final String? url;
  const _HeroLogo({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: NetworkPhoto(
            url: url,
            fit: BoxFit.contain,
            gradient: const [Colors.white, Colors.white],
            icon: IconsaxPlusLinear.shop,
            iconSize: 48,
            iconColor: AppColors.midBlue,
          ),
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
                  FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: share.clamp(0.0, 1.0),
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
  const _ReviewRow({required this.review, required this.isHebrew});

  static const _en = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  static const _he = ['ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני', 'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר'];

  @override
  Widget build(BuildContext context) {
    final d = review.createdAt?.toLocal();
    final date = d == null ? '' : (isHebrew ? '${d.day} ב${_he[d.month - 1]} ${d.year}' : '${_en[d.month - 1]} ${d.day}, ${d.year}');
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
                    Text(review.authorName, textDirection: _dirOf(review.authorName), style: _inter(16, weight: FontWeight.w500)),
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
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.midBlue),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Text(label, style: _inter(16, weight: FontWeight.w500, color: AppColors.midBlue)),
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
                          Text(x.name, textDirection: _dirOf(x.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: _display(20, color: _kInk)),
                          const SizedBox(height: 8),
                          Text(subtitle, textDirection: _dirOf(subtitle), maxLines: 1, overflow: TextOverflow.ellipsis, style: _inter(14, color: _kGrey)),
                          if (address.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                SizedBox(width: 16, height: 16, child: Center(child: SvgPicture.asset('$_kHomeAsset/card_pin.svg', width: 12, height: 16))),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(address, textDirection: _dirOf(address), maxLines: 1, overflow: TextOverflow.ellipsis, style: _inter(14, color: _kGrey)),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (x.reviewCount == 0)
                            Text(isHebrew ? 'אין דירוג עדיין' : 'Not rated yet', style: _inter(14, color: _kMuted))
                          else
                            Row(
                              children: [
                                SvgPicture.asset('$_kHomeAsset/card_star.svg', width: 16, height: 16),
                                const SizedBox(width: 8),
                                Text(x.rating.toStringAsFixed(1), style: _inter(14, weight: FontWeight.w500)),
                                const SizedBox(width: 8),
                                Text('(${x.reviewCount})', style: _inter(14, color: _kMuted)),
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
