import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/network_photo.dart';
import '../models/event.dart';
import '../providers/event_providers.dart';
import 'web_event_detail_screen.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../../../shared/widgets/app_map.dart';
import '../../../shared/widgets/web_share_menu.dart';
import '../../../core/theme/app_colors.dart';
import '../models/event_labels.dart';
import '../widgets/m_event_card.dart';

/// Event detail screen — responsive wrapper.
/// Desktop (> 1100px) renders the web detail layout; mobile keeps the app UI.
class EventDetailScreen extends ConsumerWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) {
          return WebEventDetailContent(eventId: eventId);
        }

        final provider = eventByIdProvider(eventId);
        return ref
            .watch(provider)
            .when(
              loading: () => const _EventDetailSkeleton(),
              error: (error, _) => Scaffold(
                backgroundColor: Colors.white,
                body: SafeArea(
                  child: ErrorRetry(onRetry: () => ref.invalidate(provider)),
                ),
              ),
              data: (event) => _MobileEventDetailContent(event: event),
            );
      },
    );
  }
}

/// Mobile layout (Figma mobile "Event Detail"): hero with back, share and
/// heart; the date tile over its edge and the category pill; title, time,
/// place, interest and price; organizer; about; what's included; the map;
/// "You May Also Like"; and the RSVP bar.
class _MobileEventDetailContent extends ConsumerStatefulWidget {
  final Event event;
  const _MobileEventDetailContent({required this.event});

  @override
  ConsumerState<_MobileEventDetailContent> createState() =>
      _MobileEventDetailContentState();
}

class _MobileEventDetailContentState
    extends ConsumerState<_MobileEventDetailContent> {
  bool _rsvpBusy = false;

  Event get event => widget.event;
  EventLabels get _labels => EventLabels(mEventsIsHebrew(context));

  static const _heading = TextStyle(
    fontFamily: AppFonts.inter,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1F1F1F),
  );
  static const _grey500 = Color(0xFF6D6D6D);
  static const _grey900 = Color(0xFF3D3D3D);

  @override
  Widget build(BuildContext context) {
    final organizer =
        ref.watch(eventOrganizerProvider(event.businessId)).valueOrNull;
    final about = EventDescription.parse(
      (event.fullDescription?.trim().isNotEmpty ?? false)
          ? event.fullDescription
          : event.shortDescription,
    );
    final hasMap = event.latitude != 0 && event.longitude != 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHero(context),
                        _buildInfoSection(),
                        if (organizer != null) ...[
                          const SizedBox(height: 20),
                          _buildOrganizer(organizer),
                        ],
                        if (about.paragraphs.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          _buildAbout(about.paragraphs),
                        ],
                        if (about.included.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          _buildIncluded(about.included),
                        ],
                        if (hasMap) ...[
                          const SizedBox(height: 32),
                          _buildWhereIsIt(event),
                        ],
                        _buildYouMayAlsoLike(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                // Going needs an account, and accounts belong to the app —
                // in a browser the bar is not drawn, as the heart is not.
                if (!kIsWeb) _buildBottomBar(event),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Hero (260) with back / share / heart, the date tile and category pill
  // ═══════════════════════════════════════════════
  Widget _buildHero(BuildContext context) {
    final start = event.startDate;
    final category = (ref
                .watch(eventCategoriesByEventProvider)
                .valueOrNull?[event.id] ??
            const [])
        .firstOrNull;
    final top = MediaQuery.of(context).padding.top + 7;

    return SizedBox(
      height: 309,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: double.infinity,
            height: 260,
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetworkPhoto(
                  url: event.imageUrl,
                  icon: IconsaxPlusBold.calendar_1,
                  iconSize: 60,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0x66000000), Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
          ),
          PositionedDirectional(
            start: 12,
            top: top,
            child: _circleButton(
              onTap: () => context.canPop() ? context.pop() : context.go('/events'),
              child: Transform.flip(
                flipX: Directionality.of(context) == TextDirection.rtl,
                child: const Icon(
                  IconsaxPlusLinear.arrow_left,
                  size: 20,
                  color: _grey900,
                ),
              ),
            ),
          ),
          PositionedDirectional(
            end: 68,
            top: top,
            child: Builder(
              builder: (anchor) => _circleButton(
                onTap: () => _share(anchor),
                child: SvgPicture.asset(
                  'assets/web/events/share20.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(_grey900, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            end: 12,
            top: top,
            child: FavoriteButton(
              kind: FavoriteKind.event,
              id: event.id,
              size: 40,
              iconSize: 20,
              color: _grey900,
            ),
          ),
          if (start != null)
            PositionedDirectional(
              start: 12,
              top: 215,
              child: Container(
                width: 81,
                padding: const EdgeInsets.all(11.37),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.midBlue, width: 2),
                  borderRadius: BorderRadius.circular(11.37),
                ),
                child: Column(
                  children: [
                    Text(
                      _labels.shortMonth(start),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.midBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${start.day}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (category != null)
            PositionedDirectional(
              end: 13,
              top: 272,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.turquoise,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  _labels.category(category),
                  style: const TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _circleButton({required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  /// The system share sheet on a device; the site's share menu in a browser,
  /// as the website's event page does.
  Future<void> _share(BuildContext anchor) async {
    final date = event.startDate;
    final message = [
      event.title,
      if (date != null) _labels.longDate(date),
      _labels.venue(event),
    ].whereType<String>().where((s) => s.isNotEmpty).join('\n');
    // On a device, what the business page shares: the words, no link —
    // the app has no public address for an event to point at.
    if (!kIsWeb) {
      await Share.share(message, subject: event.title);
      return;
    }
    await showWebShareMenu(
      anchor,
      title: event.title,
      link: Uri.base.toString(),
      message: message,
      isHebrew: mEventsIsHebrew(context),
    );
  }

  /// Directions: the editor's Waze link, else Google Maps to the venue.
  void _directions() {
    final waze = event.wazeUrl?.trim() ?? '';
    final uri = waze.isNotEmpty
        ? Uri.parse(waze)
        : Uri.https('www.google.com', '/maps/dir/', {
            'api': '1',
            'destination': '${event.latitude},${event.longitude}',
          });
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ═══════════════════════════════════════════════
  // Title, time, place, interest, price
  // ═══════════════════════════════════════════════
  Widget _buildInfoSection() {
    final time = _labels.timeRange(event);
    final place = [event.venueName?.trim(), event.address.trim()]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(', ');
    final price = _labels.price(event, upper: false);

    Widget row(String icon, Widget text) => Row(
      children: [
        SvgPicture.asset(
          icon,
          width: 16,
          height: 16,
          colorFilter: const ColorFilter.mode(Color(0xFF888888), BlendMode.srcIn),
        ),
        const SizedBox(width: 8),
        Expanded(child: text),
      ],
    );
    const meta = TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _grey500);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: const TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              height: 34 / 28,
              color: Colors.black,
            ),
          ),
          if (time != null) ...[
            const SizedBox(height: 12),
            row('assets/web/events/clock16.svg', Text(time, style: meta, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
          if (place.isNotEmpty) ...[
            const SizedBox(height: 12),
            row('assets/web/events/pin16.svg', Text(place, style: meta, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
          // Only once somebody has said they are coming — "0 people
          // interested" reads as a fact about the event.
          if (event.rsvpCount > 0) ...[
            const SizedBox(height: 12),
            row(
              'assets/web/events/people16.svg',
              Text.rich(
                TextSpan(
                  style: meta,
                  children: [
                    TextSpan(
                      text: '${event.rsvpCount}',
                      style: const TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text: L.of(context).peopleInterestedSuffix,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (price != null) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontFamily: AppFonts.nunito,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    height: 34 / 28,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 4),
                Text(L.of(context).price, style: meta),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Organized by — the business in `business_id`
  // ═══════════════════════════════════════════════
  Widget _buildOrganizer(EventOrganizer organizer) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L.of(context).organizedBy, style: _heading),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/business/${organizer.id}'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipOval(
                    child: NetworkPhoto(
                      url: organizer.logoUrl,
                      width: 40,
                      height: 40,
                      icon: IconsaxPlusBold.shop,
                      iconSize: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          organizer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        if (organizer.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            organizer.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 12,
                              color: _grey500,
                            ),
                          ),
                        ],
                      ],
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

  // ═══════════════════════════════════════════════
  // About This Event / What's Included — from the description
  // ═══════════════════════════════════════════════
  Widget _buildAbout(List<String> paragraphs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L.of(context).aboutThisEvent, style: _heading),
          for (final p in paragraphs) ...[
            const SizedBox(height: 12),
            Text(
              p,
              style: const TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                height: 1.6,
                color: _grey900,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIncluded(List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_labels.t("What's Included", 'מה כלול'), style: _heading),
          const SizedBox(height: 20),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1.5),
                  child: SvgPicture.asset(
                    'assets/web/events/included_check.svg',
                    width: 16,
                    height: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    items[i],
                    style: const TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      color: _grey900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Where Is It? (mini FlutterMap)
  // ═══════════════════════════════════════════════
  Widget _buildWhereIsIt(Event event) {
    final venuePosition = LatLng(event.latitude, event.longitude);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L.of(context).whereIsIt, style: _heading),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 230,
              child: Stack(
                children: [
                  // Google's map of the venue, still (AppMap, not
                  // interactive), with the frame's pin over its centre —
                  // which is the venue — tip down on the spot.
                  IgnorePointer(
                    child: AppMap(
                      center: venuePosition,
                      zoom: 15.5,
                      interactive: false,
                      pins: const [],
                    ),
                  ),
                  IgnorePointer(
                    child: Center(
                      child: Transform.translate(
                        offset: const Offset(0, -26),
                        child: SvgPicture.asset(
                          'assets/icons/m_events_pin.svg',
                          width: 48,
                          height: 52,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 17,
                    child: Center(
                      child: GestureDetector(
                        onTap: _directions,
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/icons/m_events_map.svg',
                                width: 16,
                                height: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                L.of(context).viewOnMapBtn,
                                style: const TextStyle(
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // You May Also Like
  // ═══════════════════════════════════════════════
  /// Other upcoming events, those sharing this one's category first. The
  /// section is left out when there are none.
  Widget _buildYouMayAlsoLike() {
    final all = ref.watch(upcomingEventsProvider).valueOrNull ?? const <Event>[];
    final byEvent =
        ref.watch(eventCategoriesByEventProvider).valueOrNull ?? const {};
    final mine = (byEvent[event.id] ?? const []).map((c) => c.id).toSet();
    bool shares(Event e) =>
        (byEvent[e.id] ?? const []).any((c) => mine.contains(c.id));
    final others = all.where((e) => e.id != event.id).toList();
    final related = [
      ...others.where(shares),
      ...others.where((e) => !shares(e)),
    ].take(4).toList();
    if (related.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L.of(context).youMayAlsoLike, style: _heading),
          const SizedBox(height: 16),
          for (var i = 0; i < related.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            MEventCard(
              event: related[i],
              category: (byEvent[related[i].id] ?? const [])
                  .map(_labels.category)
                  .firstOrNull,
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Bottom RSVP bar (Figma "RSVP": I'm Going / Going)
  // ═══════════════════════════════════════════════
  /// Writes to `event_attendees` and reads back what it wrote; signed out,
  /// it asks the person to sign in.
  Widget _buildBottomBar(Event event) {
    final l = L.of(context);
    final signedIn = ref.watch(authProvider) != null;
    final attending =
        ref.watch(isAttendingProvider(event.id)).valueOrNull ?? false;
    // A full event cannot take another name, so the button says so rather
    // than accepting a tap that would mean nothing.
    final soldOut = event.isSoldOut && !attending;
    final enabled = !soldOut && !_rsvpBusy;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE7E7E7))),
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: enabled ? () => _toggleRsvp(event, signedIn, attending) : null,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: enabled || _rsvpBusy
                  ? AppColors.midBlue
                  : const Color(0xFFB9C0CE),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Center(
              child: _rsvpBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!soldOut) ...[
                          SvgPicture.asset(
                            'assets/web/events/included_check.svg',
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          soldOut
                              ? l.eventSoldOut
                              : attending
                              ? l.going
                              : l.imGoing,
                          style: const TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 24 / 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleRsvp(Event event, bool signedIn, bool attending) async {
    final l = L.of(context);
    if (!signedIn) {
      _rsvpToast(l.signInToRsvp);
      return;
    }

    setState(() => _rsvpBusy = true);
    try {
      final repo = ref.read(eventRepositoryProvider);
      attending
          ? await repo.cancelAttendance(event.id)
          : await repo.attend(event.id);

      // The trigger from migration 00024 recounts `rsvp_count`, so the
      // number on the page has to be re-read too.
      ref.invalidate(isAttendingProvider(event.id));
      ref.invalidate(eventByIdProvider(event.id));
    } catch (_) {
      if (mounted) _rsvpToast(l.rsvpFailed);
    } finally {
      if (mounted) setState(() => _rsvpBusy = false);
    }
  }

  void _rsvpToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: AppFonts.inter)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Placeholder for the event page: the banner, the date tile that overlaps
/// it, then the title and the time, place and interest lines.
class _EventDetailSkeleton extends StatelessWidget {
  const _EventDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Skeleton(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            const SkeletonBox(height: 260, radius: 0),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 81, height: 86, radius: 11),
                  SizedBox(height: 20),
                  SkeletonLine(width: 250, fontSize: 24),
                  SizedBox(height: 16),
                  SkeletonLine(width: 160, fontSize: 14),
                  SizedBox(height: 12),
                  SkeletonLine(width: 240, fontSize: 14),
                  SizedBox(height: 12),
                  SkeletonLine(width: 120, fontSize: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
