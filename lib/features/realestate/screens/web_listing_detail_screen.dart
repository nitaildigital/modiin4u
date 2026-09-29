import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/web_map_tiles.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../models/listing.dart';
import '../providers/detail_providers.dart';
import '../providers/listing_providers.dart';
import '../widgets/web_detail_parts.dart';
import 'my_apartments_screen.dart' show formatShekels;

// ═══════════════════════════════════════════════════════════
// Web Listing Detail — desktop layout for /listing/:id
//
// Built to the Figma frame "Appartments" (123:2271). The file carries a
// second frame of the same name (282:3075) that is a copy of it, node for
// node — the same page placed again further along the canvas.
//
// The whole page was once one invented flat: a fixed ₪4,350,000 at HaShvatim
// St 7, four bedrooms, a paragraph about a mini penthouse in Avni Chen, a
// specification table that answered "Yes" to everything, an agent called
// Zeev Schumacher and a row of "businesses" that were in fact neighbourhood
// names. Everything below is read from the listing row, its agent and its
// neighbourhood.
// ═══════════════════════════════════════════════════════════

class WebListingDetailContent extends ConsumerStatefulWidget {
  final String listingId;
  const WebListingDetailContent({super.key, required this.listingId});

  @override
  ConsumerState<WebListingDetailContent> createState() =>
      _WebListingDetailContentState();
}

class _WebListingDetailContentState extends ConsumerState<WebListingDetailContent>
    with WebLanguageState<WebListingDetailContent> {
  bool get _isHebrew => webIsHebrew.value;
  final _contactKey = GlobalKey();

  String _t(String en, String he) => _isHebrew ? he : en;

  /// The cover and the gallery are one list, the cover first.
  List<String> _photos(Listing l) => [
    if (l.coverUrl != null && l.coverUrl!.isNotEmpty) l.coverUrl!,
    ...l.gallery.where((u) => u.isNotEmpty && u != l.coverUrl),
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
            ),
            Expanded(
              child: SingleChildScrollView(
                child: async.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 160),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => _buildNotice(
                    icon: IconsaxPlusLinear.wifi_square,
                    title: _t('This property could not be loaded', 'לא ניתן לטעון את הנכס'),
                    body: _t('Check your connection and try again.', 'בדקו את החיבור לאינטרנט ונסו שוב.'),
                    actionLabel: _t('Try again', 'נסו שוב'),
                    onAction: () => ref.invalidate(listingByIdProvider(widget.listingId)),
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
                          actionLabel: _t('Back to Real Estate', 'חזרה לנדל״ן'),
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
    return Column(
      children: [
        const SizedBox(height: 32),
        DetailColumn(maxWidth: 1200, child: _buildTitleBlock(l)),
        const SizedBox(height: 32),
        DetailColumn(
          maxWidth: 1200,
          child: DetailPhotoMosaic(
            photos: _photos(l),
            height: 514,
            radius: 12,
            gap: 10,
            fourUp: true,
            buttonInset: 16,
            showAllLabel: _t('Show all photos', 'כל התמונות'),
            fallbackIcon: IconsaxPlusBold.home_2,
          ),
        ),
        const SizedBox(height: 28),
        DetailColumn(maxWidth: 1200, child: _buildMainContent(l)),
        _buildNearbySection(l),
        _buildBusinessesSection(l),
        const SizedBox(height: 167),
        WebFooter(isHebrew: _isHebrew),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // TITLE — back, title, address, kind
  // ─────────────────────────────────────────────
  /// The heart the design draws at the end of this row is not here: saving
  /// a listing needs an account, and accounts are the app's.
  Widget _buildTitleBlock(Listing l) {
    final where = l.address ?? l.neighborhoodName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.canPop() ? context.pop() : context.go('/realestate'),
                  child: Transform.flip(
                    flipX: _isHebrew,
                    child: SvgPicture.asset('$kDetailAsset/detail_back.svg', width: 24, height: 24),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DetailText(
                  l.title,
                  style: detailDisplay(28, color: AppColors.navy, height: 34 / 28),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 27,
          child: Row(
            children: [
              if (where != null) ...[
                Flexible(child: DetailPlace(where, style: detailInter(14))),
                const SizedBox(width: 16),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0033AC).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  l.kind == ListingKind.rent ? _t('For Rent', 'להשכרה') : _t('For Sale', 'למכירה'),
                  style: detailInter(12, weight: FontWeight.w500, color: const Color(0xFF0033AC)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // MAIN CONTENT — the listing on the left, whom to call on the right
  // ─────────────────────────────────────────────
  Widget _buildMainContent(Listing l) {
    final about = (l.description ?? '').trim();
    final highlights = _highlights(l);
    final hoodAbout = _hoodAbout(l);

    // Each section with the space the design leaves above it. A section with
    // nothing to say is left out, and its gap with it.
    final sections = <(double, Widget)>[
      (0, _buildPrice(l)),
      if (highlights.isNotEmpty) (48, _buildHighlights(highlights)),
      if (about.isNotEmpty) (63, _buildAboutProperty(about)),
      (63, _buildSpecs(l)),
      if (l.latitude != null && l.longitude != null) (64, _buildMap(l)),
      if (l.neighborhoodName != null && hoodAbout.isNotEmpty) (64, _buildAboutHood(l, hoodAbout)),
    ];

    final contact = _buildContactCard(l);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (gap, section) in sections) ...[
                    if (gap > 0) SizedBox(height: gap),
                    section,
                  ],
                ],
              ),
            ),
          ),
        ),
        if (contact != null) ...[
          const SizedBox(width: 32),
          Padding(padding: const EdgeInsets.only(top: 6), child: contact),
        ],
      ],
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
        if (price == null)
          Text(
            _t('Price on request', 'מחיר לפי בקשה'),
            style: detailInter(22, weight: FontWeight.w600, color: AppColors.navy),
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatShekels(price),
                textDirection: TextDirection.ltr,
                style: detailInter(32, weight: FontWeight.w600, color: AppColors.navy),
              ),
              if (l.kind == ListingKind.rent) ...[
                const SizedBox(width: 8),
                Text(_t('/ In the month', '/ לחודש'), style: detailInter(16, color: kDetailGrey)),
              ],
            ],
          ),
        if (where != null) ...[
          const SizedBox(height: 16),
          DetailPlace(where, style: detailInter(14)),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────
  // HIGHLIGHTS
  // ─────────────────────────────────────────────
  /// Only the figures the row carries, two to a row.
  ///
  /// The design's first figure is "Bedrooms". A listing here records rooms —
  /// the Israeli count, which includes the living room — and no separate
  /// bedroom figure, so the first cell says "Rooms" with the bed the design
  /// draws beside it rather than passing one number off as the other.
  List<({String label, String value, String icon})> _highlights(Listing l) {
    final floor = l.floor;
    return [
      if (l.rooms != null)
        (label: _t('Rooms', 'חדרים'), value: detailRooms(l.rooms!), icon: 'detail_hl_rooms.svg'),
      if (l.bathrooms != null)
        (label: _t('Bathrooms', 'חדרי רחצה'), value: '${l.bathrooms}', icon: 'detail_hl_bath.svg'),
      if (l.sqm != null)
        (label: _t('Built-up Area', 'שטח בנוי'), value: _t('${l.sqm} m²', '${l.sqm} מ״ר'), icon: 'detail_hl_area.svg'),
      if (floor != null)
        (
          label: _t('Floor', 'קומה'),
          value: floor == 0 ? _t('Ground Floor', 'קומת קרקע') : _t('$floor Floor', 'קומה $floor'),
          icon: 'detail_hl_floor.svg',
        ),
    ];
  }

  Widget _buildHighlights(List<({String label, String value, String icon})> items) {
    Widget cell(({String label, String value, String icon}) h) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset('$kDetailAsset/${h.icon}', width: 32, height: 32),
        const SizedBox(width: 16),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(h.label, style: detailInter(12, color: kDetailGrey)),
              const SizedBox(height: 6),
              Text(h.value, style: detailInter(18, weight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );

    return SizedBox(
      width: 683,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('Highlights', 'נקודות בולטות'), style: detailDisplay(24)),
          const SizedBox(height: 32),
          for (var i = 0; i < items.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cell(items[i])),
                const SizedBox(width: 20),
                Expanded(child: i + 1 < items.length ? cell(items[i + 1]) : const SizedBox.shrink()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ABOUT THIS PROPERTY
  // ─────────────────────────────────────────────
  Widget _buildAboutProperty(String about) {
    final paragraphs = detailParagraphs(about);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('About This Property', 'על הנכס'), style: detailDisplay(24)),
        const SizedBox(height: 24),
        SizedBox(
          width: 620,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < paragraphs.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: DetailText(
                    paragraphs[i],
                    maxLines: null,
                    style: detailInter(16, color: kDetailBody, height: 1.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // PROPERTY SPECIFICATIONS
  // ─────────────────────────────────────────────
  /// The design's four — balcony, parking, lift, protected room — with the
  /// row's answer under each, then any further feature the flat has.
  ///
  /// The four were once drawn "Yes" on every property. They are the
  /// listing's own booleans now, so a flat without parking says "No"; the
  /// form a resident fills in asks each of them as a yes-or-no question. The
  /// features the design does not draw are shown only when they are true,
  /// since a card announcing that a flat is not furnished says little.
  List<({String label, bool value, String? asset, IconData? icon})> _specs(Listing l) => [
    (label: _t('Balcony', 'מרפסת'), value: l.hasBalcony, asset: 'detail_spec_balcony.svg', icon: null),
    (label: _t('Parking', 'חניה'), value: l.hasParking, asset: 'detail_spec_parking.svg', icon: null),
    (label: _t('Elevator', 'מעלית'), value: l.hasElevator, asset: 'detail_spec_elevator.svg', icon: null),
    (label: _t('Protected Space', 'ממ״ד'), value: l.hasMamad, asset: 'detail_spec_mamad.svg', icon: null),
    if (l.hasStorage) (label: _t('Storage', 'מחסן'), value: true, asset: null, icon: IconsaxPlusLinear.box_1),
    if (l.isFurnished) (label: _t('Furnished', 'מרוהטת'), value: true, asset: null, icon: IconsaxPlusLinear.home_hashtag),
    if (l.isAccessible) (label: _t('Accessible', 'נגישה'), value: true, asset: null, icon: IconsaxPlusLinear.profile_2user),
    if (l.isRenovated) (label: _t('Renovated', 'משופצת'), value: true, asset: null, icon: IconsaxPlusLinear.brush_2),
  ];

  Widget _buildSpecs(Listing l) {
    final specs = _specs(l);

    Widget card(({String label, bool value, String? asset, IconData? icon}) s) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kDetailLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: s.asset != null
                  ? SvgPicture.asset('$kDetailAsset/${s.asset}')
                  : Icon(s.icon, size: 30, color: AppColors.midBlue),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            s.label,
            style: detailInter(14, weight: FontWeight.w500),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(s.value ? _t('Yes', 'יש') : _t('No', 'אין'), style: detailInter(14)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('Property Specifications', 'מפרט הנכס'), style: detailDisplay(24)),
        const SizedBox(height: 23),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 16.0;
            final width = (constraints.maxWidth - 3 * gap) / 4;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [for (final s in specs) SizedBox(width: width, child: card(s))],
            );
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // WHERE YOU'LL BE
  // ─────────────────────────────────────────────
  /// The listing on the map, only when it has coordinates.
  ///
  /// The design's map is a pale, grey street plan; OpenStreetMap's tiles are
  /// brighter, so they are drawn with most of their colour taken out. The
  /// wheel scrolls the page over the map rather than zooming it — the map
  /// sits in the middle of a long page and would otherwise catch the reader
  /// mid-scroll.
  Widget _buildMap(Listing l) {
    final point = LatLng(l.latitude!, l.longitude!);
    const s = 0.35; // saturation left in the tiles
    const r = 0.2126 * (1 - s), g = 0.7152 * (1 - s), b = 0.0722 * (1 - s);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('Where You’ll Be', 'איפה זה'), style: detailDisplay(24)),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 320,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.scrollWheelZoom & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                WebMapTiles(tileBuilder: (context, tiles, _) => ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      r + s, g, b, 0, 12, //
                      r, g + s, b, 0, 12, //
                      r, g, b + s, 0, 12, //
                      0, 0, 0, 1, 0, //
                    ]),
                    child: tiles,
                  )),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 48,
                      height: 52,
                      // The pin's tip, not its middle, marks the spot.
                      alignment: Alignment.topCenter,
                      child: const _MapPin(),
                    ),
                  ],
                ),
                const WebMapCredit(),
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
  /// What the client wrote about the listing's neighbourhood, less its
  /// opening line.
  ///
  /// The neighbourhood page opens with the first paragraph of the same text
  /// as a one-line introduction under its name, and the design's "About
  /// Moriah" here carries the paragraphs after it. A description of a single
  /// paragraph is all introduction, and is shown whole.
  List<String> _hoodAbout(Listing l) {
    final paragraphs = detailParagraphs(l.neighborhoodDescription);
    return paragraphs.length > 1 ? paragraphs.sublist(1) : paragraphs;
  }

  /// A taste of the neighbourhood, faded out under a "Read More" button that
  /// opens the neighbourhood's own page.
  ///
  /// The design shows about two paragraphs here, the lower half dissolving
  /// into white, with the button over the fade. The full text, and the
  /// neighbourhood's photographs, figures, flats and businesses, are on the
  /// neighbourhood page, so that is where "Read More" leads — rather than
  /// unfolding the same text in place. A description too short to fade is
  /// shown as it is, and the heading still leads to the page.
  Widget _buildAboutHood(Listing l, List<String> paragraphs) {
    final id = l.neighborhoodId;
    final style = detailInter(16, color: kDetailBody, height: 1.6);
    void openHood() => context.push('/neighborhood/$id');

    Widget text() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paragraphs.length; i++) ...[
          if (i > 0) const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: DetailText(paragraphs[i], maxLines: null, style: style),
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          cursor: id == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: id == null ? null : openHood,
            child: Text(
              _t('About ${l.neighborhoodName}', 'על ${l.neighborhoodName}'),
              style: detailDisplay(24),
            ),
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            // The design's block: 232px of text under the heading, the fade
            // starting 10px in and the button 7px off the bottom.
            final full = _measure(paragraphs, style, constraints.maxWidth, gap: 24);
            if (id == null || full < 120) return text();
            final height = full < 232 ? full : 232.0;

            return SizedBox(
              height: height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        maxHeight: double.infinity,
                        child: text(),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: height - 10,
                    child: const IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00FFFFFF), Colors.white],
                            stops: [0, 0.98],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 7,
                    child: Center(child: _outlineButton(_t('Read More', 'קראו עוד'), openHood)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  double _measure(List<String> paragraphs, TextStyle style, double width, {required double gap}) {
    final scaler = MediaQuery.textScalerOf(context);
    var height = 0.0;
    for (var i = 0; i < paragraphs.length; i++) {
      final painter = TextPainter(
        text: TextSpan(text: paragraphs[i], style: style),
        textDirection: detailDirOf(paragraphs[i]),
        textScaler: scaler,
      )..layout(maxWidth: width);
      height += painter.height + (i > 0 ? gap : 0);
      painter.dispose();
    }
    return height;
  }

  Widget _outlineButton(String label, VoidCallback onTap) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      // Sized by its label: 32px either side of it, 11px above and below.
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.midBlue),
          borderRadius: BorderRadius.circular(60),
        ),
        child: Text(label, style: detailInter(16, weight: FontWeight.w500, color: AppColors.midBlue, height: 1.5)),
      ),
    ),
  );

  // ─────────────────────────────────────────────
  // CONTACT CARD
  // ─────────────────────────────────────────────
  /// Whoever to call about this listing.
  ///
  /// A listing can arrive with no agent and no contact at all — the client
  /// enters ones that come in by telephone — and the card is absent then
  /// rather than invented. "Get in touch with our real estate expert" is
  /// only said of an agent; a private seller is not one.
  Widget? _buildContactCard(Listing l) {
    final name = l.contactDisplayName;
    final phone = l.contactDisplayPhone;
    if (name == null && phone == null) return null;
    final isAgent = l.agentName != null;

    return Container(
      width: 374,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kDetailLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('Contact This Property', 'צרו קשר לגבי הנכס'),
            style: detailInter(18, weight: FontWeight.w600, color: AppColors.navy),
          ),
          if (isAgent) ...[
            const SizedBox(height: 8),
            Text(
              _t('Get in touch with our real estate expert', 'דברו עם מומחה הנדל״ן שלנו'),
              style: detailInter(14, color: kDetailBody),
            ),
          ],
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
                    DetailText(name ?? phone!, style: detailInter(16, weight: FontWeight.w600)),
                    if (l.agentAgency != null) ...[
                      const SizedBox(height: 8),
                      DetailText(l.agentAgency!, style: detailInter(12, color: kDetailMuted)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (phone != null || l.agentId != null) ...[
            const SizedBox(height: 26),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                key: _contactKey,
                onTap: () => _openContact(l),
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.midBlue,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _t('Contact', 'צרו קשר'),
                    style: detailInter(16, weight: FontWeight.w500, color: Colors.white, height: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The ways to reach this contact, in a menu under the button.
  ///
  /// The button had no handler in the design's first build, and dialling
  /// straight away does nothing on most desktops; the menu shows the number
  /// itself, so it can be read off as well as called, and adds WhatsApp and
  /// email where the agent has them.
  Future<void> _openContact(Listing l) async {
    final agent = l.agentId == null ? null : await ref.read(listingAgentContactProvider(l.agentId!).future);
    if (!mounted) return;

    final phone = agent?.phone ?? l.contactDisplayPhone;
    final whatsapp = agent?.whatsapp ?? phone;
    final email = agent?.email;

    final options = <({IconData icon, String label, Uri uri})>[
      if (phone != null)
        (icon: IconsaxPlusLinear.call, label: phone, uri: Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), ''))),
      if (whatsapp != null && _waNumber(whatsapp) != null)
        (icon: IconsaxPlusLinear.message, label: 'WhatsApp', uri: Uri.parse('https://wa.me/${_waNumber(whatsapp)}')),
      if (email != null) (icon: IconsaxPlusLinear.sms, label: email, uri: Uri(scheme: 'mailto', path: email)),
    ];
    if (options.isEmpty) return;

    final box = _contactKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    // Under the button, or over it when the window has no room below —
    // never across it, where it would hide what was just clicked.
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    final menuHeight = options.length * 48.0 + 16;
    final below = origin.dy + box.size.height + 8;
    final top = below + menuHeight <= overlay.size.height ? below : origin.dy - 8 - menuHeight;
    final anchor = Rect.fromLTWH(origin.dx, top, box.size.width, 0);
    // The menu is drawn in the app's overlay, outside this page's own
    // Directionality, so it is told the page's direction explicitly.
    final direction = _isHebrew ? TextDirection.rtl : TextDirection.ltr;

    final chosen = await showMenu<Uri>(
      context: context,
      color: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      constraints: BoxConstraints(minWidth: box.size.width, maxWidth: box.size.width),
      position: RelativeRect.fromRect(anchor, Offset.zero & overlay.size),
      items: [
        for (final o in options)
          PopupMenuItem<Uri>(
            value: o.uri,
            height: 48,
            child: Directionality(
              textDirection: direction,
              child: Row(
                children: [
                  Icon(o.icon, size: 20, color: AppColors.midBlue),
                  const SizedBox(width: 12),
                  Expanded(child: DetailText(o.label, style: detailInter(15, weight: FontWeight.w500, color: AppColors.navy))),
                ],
              ),
            ),
          ),
      ],
    );
    if (chosen != null) {
      await launchUrl(chosen, mode: LaunchMode.externalApplication);
    }
  }

  /// A number as wa.me wants it: digits only, with Israel's code in place of
  /// the leading nought. Null when there are not enough digits to be one.
  static String? _waNumber(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = '972${digits.substring(1)}';
    return digits.length >= 9 ? digits : null;
  }

  // ─────────────────────────────────────────────
  // PROPERTIES IN THE SAME NEIGHBOURHOOD
  // ─────────────────────────────────────────────
  /// Other active listings filed under the same neighbourhood; the strip is
  /// left out when there are none.
  Widget _buildNearbySection(Listing l) {
    final nearby = ref.watch(nearbyListingsProvider(l.id)).valueOrNull;
    final hood = l.neighborhoodName;
    if (nearby == null || nearby.isEmpty || hood == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: DetailStrip(
        maxWidth: 1200,
        title: _t('Properties in $hood', 'נכסים ב$hood'),
        titleGap: 24,
        carousel: DetailCarousel(
          itemCount: nearby.length,
          height: 261,
          gap: 16,
          perView: (_) => 4,
          arrowTop: 111,
          itemBuilder: (context, i) => DetailListingCard(listing: nearby[i], isHebrew: _isHebrew),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUSINESSES IN THE SAME NEIGHBOURHOOD
  // ─────────────────────────────────────────────
  /// The design fills this strip with neighbourhood names — HaNahalim,
  /// Keremim, The Birds — each subtitled "Neighborhood, Modiin", under the
  /// heading "Businesses in Moriah". The heading is what it means: these are
  /// the active businesses filed under the listing's neighbourhood, with
  /// what each one is beneath its name. Absent when there are none.
  Widget _buildBusinessesSection(Listing l) {
    final id = l.neighborhoodId;
    final hood = l.neighborhoodName;
    if (id == null || hood == null) return const SizedBox.shrink();
    final businesses = ref.watch(neighborhoodBusinessesProvider(id)).valueOrNull;
    if (businesses == null || businesses.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: DetailStrip(
        maxWidth: 1200,
        title: _t('Businesses in $hood', 'עסקים ב$hood'),
        titleGap: 24,
        carousel: DetailCarousel(
          itemCount: businesses.length,
          height: 248,
          gap: 16,
          perView: (_) => 4,
          arrowTop: 104,
          itemBuilder: (context, i) => DetailBusinessCard(business: businesses[i], isHebrew: _isHebrew),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // NOTICES — missing and failed states
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
      child: DetailColumn(
        maxWidth: 1200,
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

/// The design's map pin: a white drop with a blue house in it, and a soft
/// shadow under it. The shadow in the exported SVG is a filter, which the
/// SVG renderer ignores, so it is drawn here from the same shape.
class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    const asset = '$kDetailAsset/detail_map_marker.svg';
    return Stack(
      children: [
        Transform.translate(
          offset: const Offset(0, 2.74),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 1.4, sigmaY: 1.4),
            child: SvgPicture.asset(
              asset,
              width: 48,
              height: 52,
              colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.25), BlendMode.srcIn),
            ),
          ),
        ),
        SvgPicture.asset(asset, width: 48, height: 52),
      ],
    );
  }
}
