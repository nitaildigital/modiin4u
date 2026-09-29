import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../../shared/widgets/web_share_menu.dart';
import '../models/event.dart';
import '../models/event_category.dart';
import '../models/event_labels.dart';
import '../providers/event_providers.dart';
import '../../../shared/widgets/web_map_tiles.dart';
import 'web_events_screen.dart'
    show WebEventCard, WebEventCategoryPill, kWebEventGridGap, webEventCardWidth, webEventGridColumns;

// ═══════════════════════════════════════════════════════════
// Web Event Detail — from the Figma frame "Event Detail"
// (1920 × 3065).  Hero 1920×550 · left content column 1011 ·
// invitation card 463 ("Event Card") · You May Also Like
// carousel 1600 · footer.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF5F5E5A);
const _kBodyText = Color(0xFF3D3D3D);
const _kGrey500 = Color(0xFF6D6D6D);

/// The desktop event page.
///
/// It took an `eventId` and once read nothing with it: every word on screen
/// was the mockup's "Summer Music Night" — its date, its 8:00 PM start, its
/// address on Sderot El Melachot, "124 people interested", a five-line
/// "What's Included" list, an "Organized by" card naming "Modiin Community
/// Events", four attendee faces, a map pinned to a fixed coordinate, and four
/// related events linking to `/event/demo_$i`. All of it showed the same for
/// every id.
///
/// It reads the event's own row now, its category from `entity_categories`,
/// its organiser from `business_id`, and its neighbours from `events`.
class WebEventDetailContent extends ConsumerStatefulWidget {
  final String eventId;
  const WebEventDetailContent({super.key, required this.eventId});

  @override
  ConsumerState<WebEventDetailContent> createState() =>
      _WebEventDetailContentState();
}

class _WebEventDetailContentState extends ConsumerState<WebEventDetailContent>
    with WebLanguageState<WebEventDetailContent> {
  bool get _isHebrew => webIsHebrew.value;
  final _carousel = ScrollController();

  String _t(String en, String he) => _isHebrew ? he : en;
  EventLabels get _labels => EventLabels(_isHebrew);

  @override
  void dispose() {
    _carousel.dispose();
    super.dispose();
  }

  bool _hasCoordinates(Event e) =>
      !e.isOnline && e.latitude != 0 && e.longitude != 0;

  EventCategory? _categoryOf(Event e) {
    final byEvent = ref.watch(eventCategoriesByEventProvider).valueOrNull;
    return (byEvent?[e.id] ?? const []).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final provider = eventByIdProvider(widget.eventId);
    final event = ref.watch(provider);

    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: 'events',
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    event.when(
                      loading: _buildLoading,
                      // A bad id reaches this branch as well as a dropped
                      // connection, so the message covers both.
                      error: (_, _) => _buildError(() => ref.invalidate(provider)),
                      data: (e) => Column(
                        children: [
                          _buildHero(e),
                          _buildBody(e),
                          _buildRelatedSection(e),
                          const SizedBox(height: 159),
                        ],
                      ),
                    ),
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
  // LOADING · ERROR
  // ─────────────────────────────────────────────
  Widget _buildLoading() {
    final gutter = webGutter(MediaQuery.sizeOf(context).width);
    return Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(height: 550, radius: 0),
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, 56, gutter, 0),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 260, fontSize: 24),
                SizedBox(height: 24),
                SkeletonLine(width: 760),
                SizedBox(height: 12),
                SkeletonLine(width: 700),
                SizedBox(height: 48),
                SkeletonBox(height: 123, radius: 12),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildError(VoidCallback onRetry) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: webGutter(MediaQuery.sizeOf(context).width), vertical: 120),
      child: Column(
        children: [
          Icon(IconsaxPlusLinear.calendar_remove,
              size: 48, color: _kGreyText.withValues(alpha: 0.5)),
          const SizedBox(height: 20),
          Text(_t('This event could not be loaded',
                  'לא ניתן לטעון את האירוע'),
              style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.navy),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(_t('It may have been removed, or the connection dropped.',
                  'ייתכן שהאירוע הוסר, או שהחיבור נקטע.'),
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: _kGreyText),
              textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _outlineButton(null, _t('Try again', 'נסו שוב'), onRetry),
              const SizedBox(width: 16),
              _outlineButton(null, _t('All events', 'כל האירועים'), () => context.go('/events')),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SHARE · DIRECTIONS
  // ─────────────────────────────────────────────
  /// Share sent nothing at all once — the button was `onTap: () {}`, and
  /// then it only copied the address.
  ///
  /// In a browser it opens the site's share menu under the button —
  /// WhatsApp, Facebook, X, e-mail, Copy link — which works on any page,
  /// secure or not. On a device the system sheet opens. [anchor] is the
  /// button's context, so the menu sits beneath it.
  Future<void> _share(Event event, BuildContext anchor) async {
    final link = Uri.base.toString();
    final date = event.startDate;
    final message = [
      event.title,
      if (date != null) _labels.longDate(date),
      _labels.venue(event),
    ].whereType<String>().where((s) => s.isNotEmpty).join('\n');
    if (!kIsWeb) {
      await Share.share('$message\n$link', subject: event.title);
      return;
    }
    await showWebShareMenu(anchor, title: event.title, link: link, message: message, isHebrew: _isHebrew);
  }

  /// Directions to the venue, in a new tab: the editor's Waze link when the
  /// row has one, Google Maps to the coordinates otherwise.
  void _directions(Event event) {
    final waze = event.wazeUrl?.trim() ?? '';
    final uri = waze.isNotEmpty
        ? Uri.parse(waze)
        : Uri.https('www.google.com', '/maps/dir/', {
            'api': '1',
            'destination': '${event.latitude},${event.longitude}',
          });
    launchUrl(uri, webOnlyWindowName: '_blank');
  }

  // ─────────────────────────────────────────────
  // HERO — 1920 × 550
  // ─────────────────────────────────────────────
  Widget _buildHero(Event event) {
    final date = event.startDate;
    final time = _labels.timeRange(event);
    final place = _labels.address(event);
    final category = _categoryOf(event);
    final gutter = webGutter(MediaQuery.sizeOf(context).width);

    return SizedBox(
      width: double.infinity,
      height: 550,
      child: Stack(
        children: [
          Positioned.fill(
            child: NetworkPhoto(
              url: event.imageUrl,
              icon: null,
            ),
          ),
          // Rectangle 14510 — the start half darkened, at 80% of a 0.8 black,
          // so the copy stays readable over any photograph.
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 0.5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [
                      Colors.black.withValues(alpha: 0.64),
                      Colors.black.withValues(alpha: 0.64),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                    stops: const [0.012, 0.523, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Frame 2071857379 — date badge, title, category, meta
          PositionedDirectional(
            start: gutter,
            top: 106,
            child: SizedBox(
              width: 528,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (date != null) ...[
                    _heroDateBadge(date),
                    const SizedBox(height: 26),
                  ],
                  Text(
                    event.title,
                    style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 48, fontWeight: FontWeight.w600, color: Colors.white, height: 59 / 48),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (category != null) ...[
                    const SizedBox(height: 12),
                    WebEventCategoryPill(
                      label: _labels.category(category),
                      fontSize: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    ),
                  ],
                  if (time != null) ...[
                    const SizedBox(height: 24),
                    _heroMetaRow('assets/web/events/clock16.svg', time, ltr: true),
                  ],
                  if (place != null) ...[
                    const SizedBox(height: 24),
                    _heroMetaRow('assets/web/events/pin16.svg', place),
                  ],
                  // "124 people interested" once stood here on every event.
                  // The real count only appears once there is one.
                  if (event.rsvpCount > 0) ...[
                    const SizedBox(height: 24),
                    _heroMetaRow('assets/web/events/people16.svg', _labels.peopleInterested(event.rsvpCount)),
                  ],
                ],
              ),
            ),
          ),
          // Frame 2071857321 — Share. Save sat beside it; it needs an
          // account, which is the app's.
          PositionedDirectional(
            end: gutter,
            bottom: 28,
            child: Builder(builder: (b) => _heroPillButton(_t('Share', 'שיתוף'), () => _share(event, b))),
          ),
        ],
      ),
    );
  }

  Widget _heroDateBadge(DateTime date) {
    return Container(
      width: 81,
      padding: const EdgeInsets.all(11.368),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11.368),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_labels.shortMonth(date),
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.midBlue, height: 22 / 18),
              maxLines: 1),
          const SizedBox(height: 5.684),
          Text(date.day.toString().padLeft(2, '0'),
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 32, fontWeight: FontWeight.w600, color: Colors.black, height: 39 / 32)),
        ],
      ),
    );
  }

  Widget _heroMetaRow(String icon, String text, {bool ltr = false}) {
    return Row(
      children: [
        SvgPicture.asset(icon, width: 16, height: 16),
        const SizedBox(width: 8),
        Flexible(
          child: _maybeLtr(
            ltr,
            Text(text,
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white, height: 17 / 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }

  /// Clock ranges stay left to right even inside the Hebrew layout.
  Widget _maybeLtr(bool ltr, Widget child) {
    if (!ltr) return child;
    return Directionality(textDirection: TextDirection.ltr, child: child);
  }

  Widget _heroPillButton(String label, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset('assets/web/events/share16.svg', width: 16, height: 16),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.navy, height: 24 / 14)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BODY — 1011 content column + 463 invitation card
  // ─────────────────────────────────────────────
  Widget _buildBody(Event event) {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: WebSection(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 1011 + 126 + 463 = 1600 at the 1920 reference width. On a
            // narrower window the gap gives way first, and the card narrows a
            // little so the details box keeps room for its four cells.
            final cardWidth = (constraints.maxWidth * 463 / 1600).clamp(380.0, 463.0);
            final gap = (constraints.maxWidth - 1011 - cardWidth).clamp(40.0, 126.0);
            final columnWidth = (constraints.maxWidth - gap - cardWidth).clamp(420.0, 1011.0);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: columnWidth, child: _buildContentColumn(event, columnWidth)),
                const Spacer(),
                SizedBox(width: cardWidth, child: _buildInviteCard(event)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContentColumn(Event event, double columnWidth) {
    // The mockup's two paragraphs about "Summer Music Night" were printed
    // under every event once, whatever its own description said.
    final about = EventDescription.parse(
      (event.fullDescription?.trim().isNotEmpty ?? false)
          ? event.fullDescription
          : event.shortDescription,
    );
    final paragraphs = about.paragraphs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (paragraphs.isNotEmpty) ...[
          _sectionTitle(_t('About This Event', 'על האירוע')),
          for (final p in paragraphs) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: columnWidth.clamp(0.0, 896.0),
              child: Text(p,
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: _kBodyText, height: 1.6)),
            ),
          ],
          const SizedBox(height: 56),
        ],
        _sectionTitle(_t('Event Details', 'פרטי האירוע')),
        const SizedBox(height: 24),
        _buildDetailsBox(event),
        // "What's Included" once listed live music, food and refreshments
        // and outdoor seating under every event alike. It lists what the
        // event's own description does now — see [EventDescription] — and is
        // left out when the description has no such list.
        if (about.included.isNotEmpty) ...[
          const SizedBox(height: 56),
          _sectionTitle(_t("What's Included", 'מה כלול')),
          const SizedBox(height: 24),
          for (var i = 0; i < about.included.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1.5),
                  child: SvgPicture.asset('assets/web/events/included_check.svg', width: 16, height: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(about.included[i],
                      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: _kBodyText, height: 19 / 16)),
                ),
              ],
            ),
          ],
        ],
        if (_hasCoordinates(event)) ...[
          const SizedBox(height: 56),
          _sectionTitle(_t('Where Is It?', 'איפה זה?')),
          const SizedBox(height: 24),
          _buildMiniMap(event, columnWidth),
        ],
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.midBlue, height: 30 / 24));
  }

  /// Frame 2071857385 — a bordered box of four divided cells.
  ///
  /// The cells were fixed text once: a Thursday in August, an 8:00 PM start,
  /// the amphitheatre, ₪50. A cell is drawn only when the row carries what
  /// goes in it, so an event with no price shows three cells rather than a
  /// made-up fourth. The location cell opens directions.
  Widget _buildDetailsBox(Event event) {
    final date = event.startDate;
    final time = _labels.timeRange(event);
    final place = _labels.venue(event);
    final price = _labels.price(event, upper: false);

    final cells = <({String icon, String label, String value, bool ltr, VoidCallback? onTap})>[
      if (date != null)
        (icon: 'assets/web/events/det_date.svg', label: _t('Date', 'תאריך'), value: _labels.longDate(date), ltr: false, onTap: null),
      if (time != null)
        (icon: 'assets/web/events/det_time.svg', label: _t('Time', 'שעה'), value: time, ltr: true, onTap: null),
      if (place != null)
        (
          icon: 'assets/web/events/det_location.svg',
          label: _t('Location', 'מיקום'),
          value: place,
          ltr: false,
          onTap: _hasCoordinates(event) || (event.wazeUrl?.isNotEmpty ?? false) ? () => _directions(event) : null,
        ),
      if (price != null)
        (icon: 'assets/web/events/det_price.svg', label: _t('Price', 'מחיר'), value: price, ltr: false, onTap: null),
    ];
    if (cells.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(cells.length, (i) {
            final cell = cells[i];
            final isFirst = i == 0;
            final isLast = i == cells.length - 1;
            Widget body = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(cell.icon, width: 24, height: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cell.label,
                          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black, height: 19 / 16)),
                      const SizedBox(height: 4),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _maybeLtr(
                          cell.ltr,
                          Text(cell.value,
                              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kGrey500, height: 17 / 14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            if (cell.onTap != null) {
              body = MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(onTap: cell.onTap, behavior: HitTestBehavior.opaque, child: body),
              );
            }
            return Expanded(
              child: Container(
                padding: EdgeInsetsDirectional.fromSTEB(isFirst ? 0 : 16, 16, isLast ? 0 : 16, 16),
                decoration: isLast
                    ? null
                    : const BoxDecoration(border: BorderDirectional(end: BorderSide(color: _kBorder))),
                child: body,
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Frame 2071857240 — 720 × 320 map with the venue's purple pin.
  ///
  /// The pin was a constant once, so every event was at 31.8932, 35.0145. It
  /// sits on the row's own coordinates, and a click opens directions there.
  Widget _buildMiniMap(Event event, double columnWidth) {
    final venue = LatLng(event.latitude, event.longitude);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: columnWidth.clamp(0.0, 720.0),
          height: 320,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: venue,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              onTap: (_, _) => _directions(event),
            ),
            children: [
              const WebMapTiles(),
              MarkerLayer(
                markers: [
                  Marker(
                    point: venue,
                    width: 48,
                    height: 52,
                    alignment: Alignment.topCenter,
                    child: SvgPicture.asset('assets/web/events/map_pin.svg', width: 48, height: 52),
                  ),
                ],
              ),
              const WebMapCredit(),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // INVITATION CARD — "Event Card", 463 wide
  // ─────────────────────────────────────────────
  Widget _buildInviteCard(Event event) {
    final time = _labels.timeRange(event);
    final place = _labels.address(event);
    final organizer = ref.watch(eventOrganizerProvider(event.businessId)).valueOrNull;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t("You're Invited!", 'אתם מוזמנים!'),
              style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.midBlue, height: 30 / 24)),
          const SizedBox(height: 15),
          NetworkPhoto(
            url: event.imageUrl,
            height: 180,
            width: double.infinity,
            radius: BorderRadius.circular(12),
            icon: IconsaxPlusBold.calendar_1,
            iconSize: 34,
          ),
          const SizedBox(height: 16),
          Text(event.title,
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black, height: 27 / 22)),
          if (time != null) ...[
            const SizedBox(height: 16),
            _cardMetaRow('assets/web/events/clock16.svg', time, ltr: true),
          ],
          if (place != null) ...[
            const SizedBox(height: 16),
            _cardMetaRow('assets/web/events/pin16.svg', place),
          ],
          if (event.rsvpCount > 0) ...[
            const SizedBox(height: 16),
            _cardMetaRow('assets/web/events/people16.svg', _labels.peopleInterested(event.rsvpCount)),
          ],
          const SizedBox(height: 24),
          // "I'm Going" and "Save" sat above this, and a green "You're going
          // to this event!" banner after the tap. Both need an account, and
          // accounts belong to the app — the client's decision — so on the
          // website the card says what, when and where, and Share stands in
          // the row alone.
          SizedBox(
            width: double.infinity,
            child: Builder(builder: (b) => _outlineButton('assets/web/events/share20.svg', _t('Share', 'שיתוף'), () => _share(event, b))),
          ),
          // A row of four attendee faces sat below, with "124 people
          // interested" beside it. Nothing names who is coming — the owner
          // policy on `event_attendees` lets a reader see only their own row —
          // so the faces were stock photographs and the count was fixed.
          if (organizer != null) ...[
            const SizedBox(height: 23),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 24),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: _kBorder))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_t('Organized by', 'מארגנים'),
                      style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.midBlue, height: 20 / 16)),
                  const SizedBox(height: 16),
                  _organizerRow(organizer),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The business putting the event on, opening its page.
  Widget _organizerRow(EventOrganizer organizer) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.push('/business/${organizer.id}'),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _kBorder),
              ),
              child: ClipOval(
                child: NetworkPhoto(
                  url: organizer.logoUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  icon: IconsaxPlusBold.shop,
                  iconSize: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(organizer.name,
                      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w600, color: _kBodyText, height: 19 / 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (organizer.subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(organizer.subtitle!,
                        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: _kGrey500, height: 15 / 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardMetaRow(String icon, String text, {bool ltr = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 0.5),
          child: SvgPicture.asset(icon, width: 16, height: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: _maybeLtr(
              ltr,
              Text(text,
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kBodyText, height: 17 / 14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _outlineButton(String? icon, String label, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.midBlue),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                SvgPicture.asset(icon, width: 20, height: 20),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.midBlue, height: 24 / 16)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // YOU MAY ALSO LIKE — carousel of the events page's cards
  // ─────────────────────────────────────────────
  /// Other upcoming events, those in the same category first. Four invented
  /// events once sat here, each linking to `/event/demo_$i`.
  Widget _buildRelatedSection(Event event) {
    final all = ref.watch(upcomingEventsProvider).valueOrNull ?? const <Event>[];
    final byEvent = ref.watch(eventCategoriesByEventProvider).valueOrNull ?? const {};
    final mine = {for (final c in byEvent[event.id] ?? const <EventCategory>[]) c.id};

    final others = all.where((e) => e.id != event.id).toList();
    bool shares(Event e) => (byEvent[e.id] ?? const []).any((c) => mine.contains(c.id));
    final related = [
      ...others.where(shares),
      ...others.where((e) => !shares(e)),
    ].take(8).toList();
    if (related.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: WebSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(_t('You May Also Like', 'אולי יעניין אתכם גם')),
            const SizedBox(height: 32),
            LayoutBuilder(builder: (context, constraints) {
              final cols = webEventGridColumns(constraints.maxWidth);
              final cardWidth = webEventCardWidth(constraints.maxWidth, cols);
              final scrolls = related.length > cols;
              return SizedBox(
                height: 364,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ListView.separated(
                      controller: _carousel,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      itemCount: related.length,
                      separatorBuilder: (_, _) => const SizedBox(width: kWebEventGridGap),
                      itemBuilder: (context, i) => SizedBox(
                        width: cardWidth,
                        child: WebEventCard(
                          event: related[i],
                          labels: _labels,
                          category: (byEvent[related[i].id] ?? const []).firstOrNull,
                          onTap: () => context.push('/event/${related[i].id}'),
                        ),
                      ),
                    ),
                    if (scrolls) ...[
                      PositionedDirectional(
                        start: -19,
                        top: 162,
                        child: _carouselArrow(isNext: false, step: cardWidth + kWebEventGridGap),
                      ),
                      PositionedDirectional(
                        end: -19,
                        top: 162,
                        child: _carouselArrow(isNext: true, step: cardWidth + kWebEventGridGap),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _carouselArrow({required bool isNext, required double step}) {
    // The arrows point along the reading direction: in Hebrew "next" is to
    // the left.
    final pointsRight = isNext != _isHebrew;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (!_carousel.hasClients) return;
          _carousel.animateTo(
            (_carousel.offset + step * (isNext ? 1 : -1))
                .clamp(0.0, _carousel.position.maxScrollExtent),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
          );
        },
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFF6F6F6)),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 5, offset: const Offset(0, 1)),
            ],
          ),
          // The design draws one right-pointing arrow and turns it round for
          // the other side.
          child: Transform.flip(
            flipX: !pointsRight,
            child: SvgPicture.asset('assets/web/events/carousel_arrow.svg', width: 20, height: 20),
          ),
        ),
      ),
    );
  }
}
