import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../models/listing.dart';
import '../providers/listing_providers.dart';
import 'my_apartments_screen.dart' show formatShekels;

// ═══════════════════════════════════════════════════════════
// Web Listing Detail — desktop layout for /listing/:id
//
// The whole page was one invented flat: a fixed ₪4,350,000 at HaShvatim St 7,
// four bedrooms, two bathrooms, 140 m², a paragraph about a mini penthouse in
// Avni Chen with an 18 m² balcony and a 20/80 payment schedule, a specification
// table that answered "Yes" to balcony, parking, lift and protected room, three
// paragraphs about the Moriah neighbourhood, an agent called Zeev Schumacher of
// RGF Properties, four nearby properties and a row of "businesses" that were in
// fact neighbourhood names. The id the route carried was never read.
// ═══════════════════════════════════════════════════════════

class WebListingDetailContent extends ConsumerStatefulWidget {
  final String listingId;
  const WebListingDetailContent({super.key, required this.listingId});

  @override
  ConsumerState<WebListingDetailContent> createState() =>
      _WebListingDetailContentState();
}

class _WebListingDetailContentState
    extends ConsumerState<WebListingDetailContent> {
  bool _isHebrew = false;
  bool _aboutExpanded = false;
  final _scrollController = ScrollController();
  final _nearbyController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    _nearbyController.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  /// The cover and the gallery are one list, largest first.
  List<String> _photos(Listing l) => [
    if (l.coverUrl != null && l.coverUrl!.isNotEmpty) l.coverUrl!,
    ...l.gallery.where((u) => u.isNotEmpty),
  ];

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(listingByIdProvider(widget.listingId));

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
                child: async.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 160),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => _buildNotice(
                    icon: IconsaxPlusLinear.wifi_square,
                    title: _t(
                      'This property could not be loaded',
                      'לא ניתן לטעון את הנכס',
                    ),
                    body: _t(
                      'Check your connection and try again.',
                      'בדקו את החיבור לאינטרנט ונסו שוב.',
                    ),
                    actionLabel: _t('Try again', 'נסו שוב'),
                    onAction: () =>
                        ref.invalidate(listingByIdProvider(widget.listingId)),
                  ),
                  // Null when the id matches no row, or when the row is not
                  // active and does not belong to whoever is asking.
                  data: (listing) => listing == null
                      ? _buildNotice(
                          icon: IconsaxPlusLinear.home_2,
                          title: _t('Property not found', 'הנכס לא נמצא'),
                          body: _t(
                            'This listing is no longer published, or the address is wrong.',
                            'הנכס הזה אינו מפורסם עוד, או שהכתובת שגויה.',
                          ),
                          actionLabel: _t('Back to Real Estate', 'חזרה לנדל"ן'),
                          onAction: () => context.go('/realestate'),
                        )
                      : _buildBody(listing),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Listing l) {
    final photos = _photos(l);

    return Column(
      children: [
        const SizedBox(height: 32),
        _buildBreadcrumb(l),
        const SizedBox(height: 32),
        _buildPhotoGallery(photos),
        const SizedBox(height: 28),
        _buildMainContent(l),
        _buildNearbySection(l),
        const SizedBox(height: 64),
        WebFooter(isHebrew: _isHebrew),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // BREADCRUMB — back, title, heart, address, kind badge
  // ─────────────────────────────────────────────
  Widget _buildBreadcrumb(Listing l) {
    final where = l.address ?? l.neighborhoodName;

    return _Section(
      maxWidth: 1200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.title,
                  style: TextStyle(
                    fontFamily: AppFonts.nunito,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ),
              // The heart was a local bool that the next page load forgot.
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF2F3F8),
                ),
                child: Center(
                  child: FavoriteButton(
                    kind: FavoriteKind.listing,
                    id: l.id,
                    iconSize: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (where != null) ...[
                const Icon(
                  IconsaxPlusBold.location,
                  size: 16,
                  color: AppColors.turquoise,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    where,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0033AC).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  l.kind == ListingKind.rent
                      ? _t('For Rent', 'להשכרה')
                      : _t('For Sale', 'למכירה'),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0033AC),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PHOTO GALLERY
  // ─────────────────────────────────────────────
  /// As many panels as the listing has photographs.
  ///
  /// Four were always drawn, three of them flat pastel rectangles, with a
  /// "Show all photos" button that had no handler. The grid now follows the
  /// count, and a listing with no pictures gets one brand panel rather than
  /// four empty ones.
  Widget _buildPhotoGallery(List<String> photos) {
    Widget panel(int index) => NetworkPhoto(
      url: index < photos.length ? photos[index] : null,
      icon: IconsaxPlusBold.home_2,
      iconSize: index == 0 ? 80 : 32,
    );

    Widget grid;
    if (photos.length <= 1) {
      grid = panel(0);
    } else if (photos.length == 2) {
      grid = Row(
        children: [
          Expanded(child: panel(0)),
          const SizedBox(width: 10),
          Expanded(child: panel(1)),
        ],
      );
    } else if (photos.length == 3) {
      grid = Row(
        children: [
          Expanded(child: panel(0)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                Expanded(child: panel(1)),
                const SizedBox(height: 10),
                Expanded(child: panel(2)),
              ],
            ),
          ),
        ],
      );
    } else {
      grid = Row(
        children: [
          Expanded(child: panel(0)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                Expanded(child: panel(1)),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: panel(2)),
                      const SizedBox(width: 10),
                      Expanded(child: panel(3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return _Section(
      maxWidth: 1200,
      child: SizedBox(
        height: 514,
        child: ClipRRect(borderRadius: BorderRadius.circular(12), child: grid),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MAIN CONTENT — detail on the left, contact on the right
  // ─────────────────────────────────────────────
  Widget _buildMainContent(Listing l) {
    final sections = <Widget>[
      // Always drawn: it says what the price is, or that there is none on
      // file, and both are worth saying.
      _buildPrice(l),
      if (_highlights(l).isNotEmpty) _buildHighlights(l),
      if ((l.description ?? '').trim().isNotEmpty) _buildAboutProperty(l),
      if (_specs(l).isNotEmpty) _buildPropertySpecs(l),
      if (l.latitude != null && l.longitude != null) _buildWhereYoullBe(l),
      if (l.neighborhoodName != null) _buildAboutNeighborhood(l),
    ];

    final contactCard = _buildContactCard(l);

    return _Section(
      maxWidth: 1200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < sections.length; i++) ...[
                  if (i > 0) const SizedBox(height: 56),
                  sections[i],
                ],
              ],
            ),
          ),
          const Spacer(),
          ?contactCard,
        ],
      ),
    );
  }

  Widget _buildPrice(Listing l) {
    final price = l.effectivePrice;
    final where = l.address ?? l.neighborhoodName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A listing with no price is not a free one, so "Price on request"
        // stands in rather than ₪0.
        Text(
          price == null
              ? _t('Price on request', 'מחיר לפי בקשה')
              : l.kind == ListingKind.rent
              ? _t(
                  '${formatShekels(price)} / month',
                  '${formatShekels(price)} לחודש',
                )
              : formatShekels(price),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: price == null ? 22 : 32,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
        if (where != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                IconsaxPlusBold.location,
                size: 16,
                color: AppColors.turquoise,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  where,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────
  // HIGHLIGHTS
  // ─────────────────────────────────────────────
  /// Only the figures the row carries.
  ///
  /// Four were printed for every listing — 4 bedrooms, 2 bathrooms, 140 m²,
  /// floor 4 — and the grid assumed there would always be exactly four.
  List<({String label, String value, IconData icon})> _highlights(Listing l) {
    String rooms(double r) =>
        r == r.roundToDouble() ? '${r.toInt()}' : r.toString();

    return [
      if (l.rooms != null)
        (
          label: _t('Rooms', 'חדרים'),
          value: rooms(l.rooms!),
          icon: IconsaxPlusLinear.building_3,
        ),
      if (l.bathrooms != null)
        (
          label: _t('Bathrooms', 'חדרי אמבטיה'),
          value: '${l.bathrooms}',
          icon: IconsaxPlusLinear.courthouse,
        ),
      if (l.sqm != null)
        (
          label: _t('Built-up Area', 'שטח בנוי'),
          value: _t('${l.sqm} m²', '${l.sqm} מ"ר'),
          icon: IconsaxPlusLinear.maximize_3,
        ),
      if (l.floor != null)
        (
          label: _t('Floor', 'קומה'),
          value: l.totalFloors == null
              ? '${l.floor}'
              : '${l.floor} / ${l.totalFloors}',
          icon: IconsaxPlusLinear.building_4,
        ),
    ];
  }

  Widget _buildHighlights(Listing l) {
    final items = _highlights(l);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(_t('Highlights', 'דגשים')),
        const SizedBox(height: 32),
        SizedBox(
          width: 683,
          child: Column(
            children: [
              // Two to a row, however many there are.
              for (var i = 0; i < items.length; i += 2) ...[
                if (i > 0) const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: _highlightItem(items[i])),
                    const SizedBox(width: 20),
                    if (i + 1 < items.length)
                      Expanded(child: _highlightItem(items[i + 1]))
                    else
                      const Expanded(child: SizedBox.shrink()),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _highlightItem(({String label, String value, IconData icon}) h) {
    return Row(
      children: [
        Icon(h.icon, size: 32, color: const Color(0xFF5D5D5D)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              h.label,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 12,
                color: const Color(0xFF5F5E5A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              h.value,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // ABOUT THIS PROPERTY
  // ─────────────────────────────────────────────
  Widget _buildAboutProperty(Listing l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(_t('About This Property', 'על הנכס')),
        const SizedBox(height: 24),
        SizedBox(
          width: 620,
          child: Text(
            l.description!.trim(),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              color: const Color(0xFF3D3D3D),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // PROPERTY SPECIFICATIONS
  // ─────────────────────────────────────────────
  /// The features the listing actually has.
  ///
  /// The table listed balcony, parking, lift and protected room and answered
  /// "Yes" to all four on every property. These are the booleans from the row,
  /// and the value beside the name is gone: a card that is drawn at all is a
  /// feature the flat has.
  List<({String label, IconData icon})> _specs(Listing l) => [
    if (l.hasBalcony)
      (label: _t('Balcony', 'מרפסת'), icon: IconsaxPlusLinear.element_3),
    if (l.hasParking)
      (label: _t('Parking', 'חניה'), icon: IconsaxPlusLinear.car),
    if (l.hasElevator)
      (label: _t('Elevator', 'מעלית'), icon: IconsaxPlusLinear.arrow_3),
    if (l.hasStorage)
      (label: _t('Storage', 'מחסן'), icon: IconsaxPlusLinear.box_1),
    if (l.hasMamad)
      (
        label: _t('Protected Space', 'ממ"ד'),
        icon: IconsaxPlusLinear.shield_tick,
      ),
    if (l.isFurnished)
      (label: _t('Furnished', 'מרוהטת'), icon: IconsaxPlusLinear.home_hashtag),
    if (l.isAccessible)
      (label: _t('Accessible', 'נגישה'), icon: IconsaxPlusLinear.profile_2user),
    if (l.isRenovated)
      (label: _t('Renovated', 'משופצת'), icon: IconsaxPlusLinear.brush_2),
  ];

  Widget _buildPropertySpecs(Listing l) {
    final specs = _specs(l);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(_t('Property Specifications', 'מפרט הנכס')),
        const SizedBox(height: 24),
        SizedBox(
          width: 721,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final spec in specs)
                SizedBox(
                  // Four to a row at the column's full width, and a shorter
                  // list simply takes fewer places. The old row divided the
                  // width by the count, so three cards came out a third wider
                  // than four and one filled the page.
                  width: (721 - 3 * 16) / 4,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 132),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE7E7E7)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(spec.icon, size: 32, color: AppColors.midBlue),
                        const SizedBox(height: 16),
                        Text(
                          spec.label,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // WHERE YOU'LL BE
  // ─────────────────────────────────────────────
  Future<void> _openInMaps(Listing l) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query='
      '${l.latitude},${l.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// The listing on the map.
  ///
  /// A pale blue box with a faint map glyph stood here, drawn whether or not
  /// the listing had coordinates. `flutter_map` was already used elsewhere in
  /// this feature, and the section is only built when there is a point to show.
  Widget _buildWhereYoullBe(Listing l) {
    final point = LatLng(l.latitude!, l.longitude!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(_t("Where You'll Be", 'היכן תהיו')),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 720,
            height: 320,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(initialCenter: point, initialZoom: 15.5),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.modiin4u.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 48,
                          height: 48,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 2.74,
                                  offset: const Offset(0, 2.74),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF006BF6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  IconsaxPlusBold.home_2,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: 16,
                  child: Center(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _openInMaps(l),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                IconsaxPlusLinear.map_1,
                                size: 16,
                                color: AppColors.navy,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _t('Open in Maps', 'פתחו במפות'),
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // ABOUT THE NEIGHBOURHOOD
  // ─────────────────────────────────────────────
  /// The neighbourhood this listing is filed under.
  ///
  /// Two paragraphs about Moriah were printed under every listing, whatever
  /// its neighbourhood. This is the description the client wrote for the
  /// neighbourhood, and the heading alone when none was written — the heading
  /// is worth keeping either way, because it is the way to the neighbourhood
  /// page.
  Widget _buildAboutNeighborhood(Listing l) {
    final about = (l.neighborhoodDescription ?? '').trim();
    final id = l.neighborhoodId;

    return SizedBox(
      width: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MouseRegion(
            cursor: id == null
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            child: GestureDetector(
              onTap: id == null
                  ? null
                  : () => context.push('/neighborhood/$id'),
              child: Row(
                children: [
                  Flexible(
                    child: _SectionHeading(
                      _t(
                        'About ${l.neighborhoodName}',
                        'על שכונת ${l.neighborhoodName}',
                      ),
                    ),
                  ),
                  if (id != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      _isHebrew
                          ? IconsaxPlusLinear.arrow_left_2
                          : IconsaxPlusLinear.arrow_right_3,
                      size: 20,
                      color: AppColors.midBlue,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (about.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              about,
              maxLines: _aboutExpanded ? null : 6,
              overflow: _aboutExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 16,
                color: const Color(0xFF3D3D3D),
                height: 1.6,
              ),
            ),
            // Only worth offering when there is more to show. The button was
            // drawn whatever the length of the text.
            if (about.length > 420) ...[
              const SizedBox(height: 16),
              Center(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _aboutExpanded = !_aboutExpanded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
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
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CONTACT CARD
  // ─────────────────────────────────────────────
  /// Whoever to call about this listing.
  ///
  /// The card named Zeev Schumacher of RGF Properties, Modiin, with an avatar
  /// and a Contact button that had no handler, on every listing. A listing can
  /// arrive with no agent and no contact at all — the client enters ones that
  /// come in by telephone — so the card is absent then rather than invented.
  Widget? _buildContactCard(Listing l) {
    final name = l.contactDisplayName;
    final phone = l.contactDisplayPhone;
    if (name == null && phone == null) return null;

    return Container(
      width: 374,
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
            _t('Contact This Property', 'צרו קשר בנוגע לנכס'),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              NetworkPhoto(
                url: l.agentPhotoUrl,
                width: 56,
                height: 56,
                radius: BorderRadius.circular(28),
                icon: IconsaxPlusBold.user,
                iconSize: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? phone!,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    if (l.agentAgency != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        l.agentAgency!,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          color: const Color(0xFF6D6D6D),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (phone != null) ...[
            const SizedBox(height: 26),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _launchPhone(phone),
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.midBlue,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Center(
                    child: Text(
                      phone,
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
            ),
          ],
        ],
      ),
    );
  }

  /// A number that cannot be dialled is left alone rather than reported, since
  /// there is nothing the reader could do about it.
  static Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ─────────────────────────────────────────────
  // OTHER PROPERTIES IN THE SAME NEIGHBOURHOOD
  // ─────────────────────────────────────────────
  /// Four invented flats sat here, all "Moriah, Modiin". The strip is left out
  /// entirely when the neighbourhood has nothing else on file.
  ///
  /// A row of cards headed "Businesses in Moriah" followed it, whose five
  /// entries were in fact neighbourhood names — HaNahalim, Keremim, The Birds
  /// — each subtitled "Neighborhood, Modiin". It is gone; the neighbourhood
  /// page is where a neighbourhood's businesses belong.
  Widget _buildNearbySection(Listing l) {
    final nearby = ref.watch(nearbyListingsProvider(l.id)).valueOrNull;
    final hood = l.neighborhoodName;
    if (nearby == null || nearby.isEmpty || hood == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: _Section(
        maxWidth: 1200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeading(_t('Properties in $hood', 'נכסים ב$hood')),
            const SizedBox(height: 24),
            SizedBox(
              height: 275,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ListView.separated(
                    controller: _nearbyController,
                    scrollDirection: Axis.horizontal,
                    itemCount: nearby.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 16),
                    itemBuilder: (context, index) => SizedBox(
                      width: 288,
                      child: _NearbyPropertyCard(
                        listing: nearby[index],
                        isHebrew: _isHebrew,
                      ),
                    ),
                  ),
                  // Only worth drawing when the strip is wider than the row.
                  if (nearby.length > 4) ...[
                    PositionedDirectional(
                      start: -20,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _CarouselArrow(
                          isBack: true,
                          isHebrew: _isHebrew,
                          onTap: () => _nearbyController.animateTo(
                            _nearbyController.offset - 304,
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
                          onTap: () => _nearbyController.animateTo(
                            _nearbyController.offset + 304,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // NOTICES — loading, missing and failed states
  // ─────────────────────────────────────────────
  Widget _buildNotice({
    required IconData icon,
    required String title,
    required String body,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: _Section(
        maxWidth: 1200,
        child: Container(
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
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════

class _SectionHeading extends StatelessWidget {
  final String text;
  const _SectionHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppFonts.nunito,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.midBlue,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const _Section({required this.child, this.maxWidth = 1600});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
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

class _NearbyPropertyCard extends StatefulWidget {
  final Listing listing;
  final bool isHebrew;
  const _NearbyPropertyCard({required this.listing, required this.isHebrew});

  @override
  State<_NearbyPropertyCard> createState() => _NearbyPropertyCardState();
}

class _NearbyPropertyCardState extends State<_NearbyPropertyCard> {
  bool _hovered = false;

  String _t(String en, String he) => widget.isHebrew ? he : en;

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final isRent = l.kind == ListingKind.rent;
    final price = l.effectivePrice;
    final where = l.address ?? l.neighborhoodName;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        // The card was not tappable at all.
        onTap: () => context.push('/listing/${l.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
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
                    height: 150,
                    width: double.infinity,
                    child: NetworkPhoto(
                      url: l.coverUrl,
                      radius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      icon: IconsaxPlusBold.home_2,
                      iconSize: 36,
                    ),
                  ),
                  PositionedDirectional(
                    start: 10,
                    top: 10,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: FavoriteButton(
                          kind: FavoriteKind.listing,
                          id: l.id,
                          iconSize: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            price == null
                                ? _t('Price on request', 'מחיר לפי בקשה')
                                : isRent
                                ? _t(
                                    '${formatShekels(price)} / month',
                                    '${formatShekels(price)} לחודש',
                                  )
                                : formatShekels(price),
                            style: TextStyle(
                              fontFamily: AppFonts.nunito,
                              fontSize: price == null ? 14 : 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                    const SizedBox(height: 14),
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
                    const SizedBox(height: 14),
                    if (where != null)
                      Row(
                        children: [
                          const Icon(
                            IconsaxPlusBold.location,
                            size: 16,
                            color: AppColors.turquoise,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              where,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
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
            ],
          ),
        ),
      ),
    );
  }

  /// Half rooms are normal here, so 3.5 must not print as 3.
  static String _rooms(double rooms) =>
      rooms == rooms.roundToDouble() ? '${rooms.toInt()}' : '$rooms';

  Widget _miniStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6D6D6D)),
        const SizedBox(width: 8),
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
