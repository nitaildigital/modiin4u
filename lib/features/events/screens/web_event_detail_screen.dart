import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_photo.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../auth/providers/auth_provider.dart';
import '../../favorites/providers/favorite_providers.dart';
import '../../favorites/repositories/favorite_repository.dart';
import '../../favorites/widgets/favorite_button.dart';
import '../models/event.dart';
import '../providers/event_providers.dart';

// ═══════════════════════════════════════════════════════════
// Web Event Detail — from the Figma export "Event Detail"
// (1920 × 3065).  Hero 1920×550 · left content column 1011 ·
// RSVP card 463 (Event Card / Stage 1 + Stage 2) · You May
// Also Like carousel 1600 · footer 1920×632.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF5F5E5A);
const _kBodyText = Color(0xFF3D3D3D);
const _kIconGrey = Color(0xFF6D6D6D);
const _kGoingBg = Color(0xFFE6F6E9);
const _kGoingFg = Color(0xFF31AC4E);
const _kPinPurple = Color(0xFF9032E1);

/// The desktop event page.
///
/// It took an `eventId` and read nothing with it: every word on screen was the
/// mockup's "Summer Music Night" — its date, its 8:00 PM start, its address on
/// Sderot El Melachot, "124 people interested", a five-line "What's Included"
/// list, an "Organized by" card naming "Modiin Community Events", four
/// attendee faces, a map pinned to a fixed coordinate, and four related events
/// linking to `/event/demo_$i`. All of it showed the same for every id.
///
/// It reads `events` now, and the RSVP writes to `event_attendees`.
class WebEventDetailContent extends ConsumerStatefulWidget {
  final String eventId;
  const WebEventDetailContent({super.key, required this.eventId});

  @override
  ConsumerState<WebEventDetailContent> createState() =>
      _WebEventDetailContentState();
}

class _WebEventDetailContentState
    extends ConsumerState<WebEventDetailContent> {
  bool _isHebrew = false;
  bool _rsvpBusy = false;
  final _carousel = ScrollController();

  String _t(String en, String he) => _isHebrew ? he : en;

  @override
  void dispose() {
    _carousel.dispose();
    super.dispose();
  }

  // ── Dates and times, in whichever language is showing ──

  static const _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _monthsHe = [
    'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
    'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
  ];
  static const _weekdaysEn = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  static const _weekdaysHe = [
    'יום שני', 'יום שלישי', 'יום רביעי', 'יום חמישי',
    'יום שישי', 'שבת', 'יום ראשון',
  ];

  String _shortMonth(DateTime date) =>
      _isHebrew ? _monthsHe[date.month - 1] : _monthsEn[date.month - 1].substring(0, 3).toUpperCase();

  String _longDate(DateTime date) {
    final weekday = (_isHebrew ? _weekdaysHe : _weekdaysEn)[date.weekday - 1];
    final month = (_isHebrew ? _monthsHe : _monthsEn)[date.month - 1];
    return _isHebrew
        ? '$weekday, ${date.day} ב$month ${date.year}'
        : '$weekday, $month ${date.day}, ${date.year}';
  }

  /// "20:00 – 22:30", or just the start when the row has no end time, or null
  /// when it has no time at all. The mockup's fixed "8:00 PM – 11:00 PM" stood
  /// here whatever the row said.
  String? _timeRange(Event e) {
    if (e.isAllDay) return _t('All day', 'כל היום');
    final start = e.displayTime;
    if (start == null) return null;
    final endParts = (e.endTime ?? '').split(':');
    if (endParts.length < 2) return start;
    return '$start – ${endParts[0]}:${endParts[1]}';
  }

  /// What the ticket costs, or null when the row does not say.
  ///
  /// `Event.displayPrice` answers in Hebrew only, and this page is shown in
  /// both languages.
  String? _price(Event e) {
    if (e.isFree) return _t('Free', 'חינם');
    final p = e.price;
    if (p == null || p.isEmpty) return null;
    return p.startsWith('₪') ? p : '₪$p';
  }

  String? _place(Event e) {
    if (e.isOnline) return _t('Online', 'אונליין');
    return e.venueName ?? (e.address.isEmpty ? null : e.address);
  }

  bool _hasCoordinates(Event e) =>
      !e.isOnline && e.latitude != 0 && e.longitude != 0;

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
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
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
                          const SizedBox(height: 56),
                          _buildRelatedSection(e),
                          const SizedBox(height: 80),
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
    return Skeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(height: 550, radius: 0),
          Padding(
            padding: const EdgeInsets.fromLTRB(160, 56, 160, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
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
      padding: const EdgeInsets.symmetric(horizontal: 160, vertical: 120),
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
              _cardOutlineButton(IconsaxPlusLinear.refresh,
                  _t('Try again', 'נסו שוב'), onRetry),
              const SizedBox(width: 16),
              _cardOutlineButton(IconsaxPlusLinear.calendar,
                  _t('All events', 'כל האירועים'), () => context.go('/events')),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SAVE · SHARE
  // ─────────────────────────────────────────────
  /// Saving needs an account, so a signed-out tap offers one rather than
  /// quietly doing nothing. Both Save controls on the page go through here.
  Future<void> _toggleSave(Event event) async {
    try {
      final signedIn = await ref
          .read(favoritesProvider.notifier)
          .toggle(FavoriteKind.event, event.id);
      if (signedIn || !mounted) return;
      _toast(
        _t('Sign in to save this event', 'התחברו כדי לשמור את האירוע'),
        actionLabel: _t('Sign in', 'התחברות'),
        onAction: () => context.push('/login'),
      );
    } catch (_) {
      if (mounted) _toast(_t('Could not save. Try again.', 'לא ניתן היה לשמור. נסו שוב.'));
    }
  }

  /// Share sent nothing at all — the button was `onTap: () {}`.
  void _share(Event event) {
    final place = _place(event);
    final date = event.startDate;
    Share.share(
      [
        event.title,
        if (date != null) _longDate(date),
        ?place,
        event.shortDescription,
      ].whereType<String>().where((s) => s.isNotEmpty).join('\n'),
      subject: event.title,
    );
  }

  void _toast(String message, {String? actionLabel, VoidCallback? onAction}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: AppFonts.inter)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: actionLabel == null || onAction == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: onAction),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HERO — 1920 × 550
  // ─────────────────────────────────────────────
  Widget _buildHero(Event event) {
    final date = event.startDate;
    final time = _timeRange(event);
    final place = _place(event);

    return SizedBox(
      width: double.infinity,
      height: 550,
      child: Stack(
        children: [
          Positioned.fill(
            child: NetworkPhoto(
              url: event.imageUrl,
              icon: IconsaxPlusBold.calendar_1,
              iconSize: 56,
            ),
          ),
          // Rectangle 14510 — 50%-wide black wash so the copy stays readable
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                    stops: const [0.012, 0.523, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Frame 2071857379 — date badge + title block
          PositionedDirectional(
            start: 160,
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
                    style: TextStyle(fontFamily: AppFonts.nunito,
                        fontSize: 48, fontWeight: FontWeight.w600, color: Colors.white, height: 59 / 48),
                  ),
                  // A turquoise "Music" pill sat under the title. Events carry
                  // no category, so it said Music whatever the event was.
                  const SizedBox(height: 24),
                  if (time != null) ...[
                    _heroMetaRow(IconsaxPlusLinear.clock, time, forceLtr: true),
                    const SizedBox(height: 24),
                  ],
                  if (place != null)
                    _heroMetaRow(
                      event.isOnline
                          ? IconsaxPlusLinear.global
                          : IconsaxPlusLinear.location,
                      place,
                    ),
                  // "124 people interested" used to sit here on every event.
                  // The real count only appears once there is one.
                  if (event.rsvpCount > 0) ...[
                    const SizedBox(height: 24),
                    _heroMetaRow(IconsaxPlusLinear.star_1,
                        _t('${event.rsvpCount} people interested',
                            '${event.rsvpCount} מתעניינים')),
                  ],
                ],
              ),
            ),
          ),
          // Frame 2071857321 — Share / Save
          PositionedDirectional(
            end: 160,
            top: 486,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _heroPillButton(IconsaxPlusLinear.share, _t('Share', 'שיתוף'),
                    () => _share(event)),
                const SizedBox(width: 12),
                _heroSaveButton(event),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroDateBadge(DateTime date) {
    return Container(
      width: 81,
      padding: const EdgeInsets.all(11.37),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11.37),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_shortMonth(date),
              style: TextStyle(fontFamily: AppFonts.inter,
                  fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.midBlue, height: 22 / 18)),
          const SizedBox(height: 5.68),
          Text('${date.day}',
              style: TextStyle(fontFamily: AppFonts.inter,
                  fontSize: 32, fontWeight: FontWeight.w600, color: Colors.black, height: 39 / 32)),
        ],
      ),
    );
  }

  Widget _heroMetaRow(IconData icon, String text, {bool forceLtr = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.turquoise),
        const SizedBox(width: 8),
        Expanded(
          child: _maybeLtr(
            forceLtr,
            Text(text,
                style: TextStyle(fontFamily: AppFonts.inter,
                    fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white, height: 17 / 14)),
          ),
        ),
      ],
    );
  }

  /// Clock ranges stay left-to-right even inside the Hebrew layout.
  Widget _maybeLtr(bool forceLtr, Widget child) {
    if (!forceLtr) return child;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    );
  }

  Widget _heroPillButton(IconData icon, String label, VoidCallback onTap) {
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
              Icon(icon, size: 16, color: AppColors.midBlue),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(fontFamily: AppFonts.inter,
                      fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.navy)),
            ],
          ),
        ),
      ),
    );
  }

  /// The hero's Save pill. It held a local `bool`, so it forgot the event on
  /// the next load; it reads and writes `favorites` now.
  Widget _heroSaveButton(Event event) {
    final saved = ref.watch(
      isFavoriteProvider((kind: FavoriteKind.event, id: event.id)),
    );
    return _heroPillButton(
      saved ? IconsaxPlusBold.heart : IconsaxPlusLinear.heart,
      saved ? _t('Saved', 'נשמר') : _t('Save', 'שמירה'),
      () => _toggleSave(event),
    );
  }

  // ─────────────────────────────────────────────
  // BODY — 1011 content column + 463 RSVP card
  // ─────────────────────────────────────────────
  Widget _buildBody(Event event) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1920),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(160, 56, 160, 0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 1011 + 126 + 463 = 1600 at the 1920 reference width.
              const cardWidth = 463.0;
              const gap = 126.0;
              final columnWidth =
                  (constraints.maxWidth - gap - cardWidth).clamp(420.0, 1011.0);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      width: columnWidth,
                      child: _buildContentColumn(event, columnWidth)),
                  const Spacer(),
                  SizedBox(width: cardWidth, child: _buildRsvpCard(event)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // RSVP CARD — "Event Card" component, 463 wide.
  // Stage 1: "I'm Going".  Stage 2: "Going" + green banner.
  // ─────────────────────────────────────────────
  Widget _buildRsvpCard(Event event) {
    final time = _timeRange(event);
    final place = _place(event);
    final attending =
        ref.watch(isAttendingProvider(event.id)).valueOrNull ?? false;
    // A full event cannot take another name, so the button says so rather than
    // accepting a tap that would mean nothing.
    final soldOut = event.isSoldOut && !attending;
    final enabled = !soldOut && !_rsvpBusy;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t("You're Invited!", 'אתם מוזמנים!'),
              style: TextStyle(fontFamily: AppFonts.nunito,
                  fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.midBlue, height: 30 / 24)),
          const SizedBox(height: 15),
          // Cover + title + meta
          NetworkPhoto(
            url: event.imageUrl,
            height: 180,
            radius: BorderRadius.circular(12),
            icon: IconsaxPlusBold.calendar_1,
            iconSize: 34,
          ),
          const SizedBox(height: 16),
          Text(event.title,
              style: TextStyle(fontFamily: AppFonts.inter,
                  fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black, height: 27 / 22)),
          if (time != null) ...[
            const SizedBox(height: 16),
            _cardMetaRow(IconsaxPlusLinear.clock, time, forceLtr: true),
          ],
          if (place != null) ...[
            const SizedBox(height: 16),
            _cardMetaRow(
              event.isOnline
                  ? IconsaxPlusLinear.global
                  : IconsaxPlusLinear.location,
              place,
            ),
          ],
          if (event.rsvpCount > 0) ...[
            const SizedBox(height: 16),
            _cardMetaRow(IconsaxPlusLinear.star_1,
                _t('${event.rsvpCount} people interested',
                    '${event.rsvpCount} מתעניינים')),
          ],
          const SizedBox(height: 24),
          // ── Primary RSVP button ──
          //
          // It was `setState(() => _isGoing = !_isGoing)`: it changed a word on
          // screen, wrote nothing to `event_attendees`, and reset to "not
          // going" on every open, so someone who had already signed up was
          // told they had not.
          MouseRegion(
            cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
            child: GestureDetector(
              onTap: enabled ? () => _toggleRsvp(event, attending) : null,
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: enabled ? AppColors.midBlue : const Color(0xFFB9C0CE),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: _rsvpBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            attending
                                ? IconsaxPlusBold.tick_circle
                                : IconsaxPlusLinear.tick_circle,
                            size: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            soldOut
                                ? _t('Sold Out', 'אזל')
                                : attending
                                    ? _t('Going', 'מגיע/ה')
                                    : _t("I'm Going", 'אני מגיע/ה'),
                            style: TextStyle(fontFamily: AppFonts.inter,
                                fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white, height: 1.5),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          // ── Stage 2 confirmation banner ──
          if (attending) ...[
            const SizedBox(height: 20),
            Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _kGoingBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(IconsaxPlusLinear.tick_circle, size: 24, color: _kGoingFg),
                  const SizedBox(width: 12),
                  Text(_t("You're going to this event!", 'אתם מגיעים לאירוע הזה!'),
                      style: TextStyle(fontFamily: AppFonts.inter,
                          fontSize: 16, fontWeight: FontWeight.w500, color: _kGoingFg, height: 19 / 16)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          // ── Save / Share ──
          Row(
            children: [
              Expanded(child: _cardSaveButton(event)),
              const SizedBox(width: 16),
              Expanded(
                child: _cardOutlineButton(IconsaxPlusLinear.share,
                    _t('Share', 'שיתוף'), () => _share(event)),
              ),
            ],
          ),
          // A row of four attendee faces sat below, with "124 people
          // interested" beside it. Nothing names who is coming — the owner
          // policy on `event_attendees` lets a reader see only their own row —
          // so the faces were four coloured circles and the count was fixed.
          //
          // An "Organized by" card followed, naming "Modiin Community Events"
          // under the strapline "Community & Municipal Events" on every event.
          // `events` has `organizer_id` and `business_id`; neither is filled on
          // any row yet, so the card is gone until one of them is.
        ],
      ),
    );
  }

  Future<void> _toggleRsvp(Event event, bool attending) async {
    if (ref.read(authProvider) == null) {
      _toast(
        _t('Sign in to RSVP', 'התחברו כדי לאשר הגעה'),
        actionLabel: _t('Sign in', 'התחברות'),
        onAction: () => context.push('/login'),
      );
      return;
    }

    setState(() => _rsvpBusy = true);
    try {
      final repo = ref.read(eventRepositoryProvider);
      attending
          ? await repo.cancelAttendance(event.id)
          : await repo.attend(event.id);

      // The trigger from migration 00024 recounts `rsvp_count`, so the count
      // beside the button has to be re-read as well as the button's own state.
      ref.invalidate(isAttendingProvider(event.id));
      ref.invalidate(eventByIdProvider(event.id));
    } catch (_) {
      if (mounted) {
        _toast(_t('Your RSVP could not be saved.',
            'לא ניתן היה לשמור את אישור ההגעה.'));
      }
    } finally {
      if (mounted) setState(() => _rsvpBusy = false);
    }
  }

  Widget _cardMetaRow(IconData icon, String text, {bool forceLtr = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.turquoise),
        const SizedBox(width: 8),
        Expanded(
          child: _maybeLtr(
            forceLtr,
            Text(text,
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kBodyText, height: 17 / 14)),
          ),
        ),
      ],
    );
  }

  Widget _cardSaveButton(Event event) {
    final saved = ref.watch(
      isFavoriteProvider((kind: FavoriteKind.event, id: event.id)),
    );
    return _cardOutlineButton(
      saved ? IconsaxPlusBold.heart : IconsaxPlusLinear.heart,
      saved ? _t('Saved', 'נשמר') : _t('Save', 'שמירה'),
      () => _toggleSave(event),
    );
  }

  Widget _cardOutlineButton(IconData icon, String label, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.midBlue),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: AppColors.midBlue),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(fontFamily: AppFonts.inter,
                      fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.midBlue, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentColumn(Event event, double columnWidth) {
    // The mockup's two paragraphs about "Summer Music Night" were printed
    // under every event, whatever its own description said.
    final about = event.fullDescription ?? event.shortDescription;
    final textWidth = columnWidth.clamp(0.0, 896.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (about != null && about.isNotEmpty) ...[
          _sectionTitle(_t('About This Event', 'על האירוע')),
          const SizedBox(height: 24),
          SizedBox(
            width: textWidth,
            child: Text(
              about,
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: _kBodyText, height: 1.6),
            ),
          ),
          const SizedBox(height: 56),
        ],
        _sectionTitle(_t('Event Details', 'פרטי האירוע')),
        const SizedBox(height: 24),
        _buildDetailsBox(event),
        // A "What's Included" list stood here — live music, food and
        // refreshments, outdoor seating — on every event alike. No column
        // holds it, so the section is gone rather than invented per event.
        if (_hasCoordinates(event)) ...[
          const SizedBox(height: 56),
          _sectionTitle(_t('Where Is It?', 'איפה זה?')),
          const SizedBox(height: 24),
          _buildMiniMap(event),
        ],
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: TextStyle(fontFamily: AppFonts.nunito,
            fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.midBlue, height: 30 / 24));
  }

  /// Frame 2071857385 — bordered box of divided cells.
  ///
  /// The four cells were fixed text: a Thursday in August, an 8:00 PM start,
  /// the amphitheatre, ₪50. A cell is only drawn now when the row carries what
  /// goes in it, so an event with no price shows three cells rather than a
  /// made-up fourth.
  Widget _buildDetailsBox(Event event) {
    final date = event.startDate;
    final time = _timeRange(event);
    final place = _place(event);
    final price = _price(event);

    final cells = <(IconData, String, String, bool)>[
      if (date != null)
        (IconsaxPlusLinear.calendar, _t('Date', 'תאריך'), _longDate(date), false),
      if (time != null)
        (IconsaxPlusLinear.clock, _t('Time', 'שעה'), time, true),
      if (place != null)
        (
          event.isOnline ? IconsaxPlusLinear.global : IconsaxPlusLinear.location,
          _t('Location', 'מיקום'),
          place,
          false,
        ),
      if (price != null)
        (IconsaxPlusLinear.ticket, _t('Price', 'מחיר'), price, false),
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
            final isFirst = i == 0;
            final isLast = i == cells.length - 1;
            return Expanded(
              child: Container(
                padding: EdgeInsetsDirectional.fromSTEB(
                    isFirst ? 0 : 16, 16, isLast ? 0 : 16, 16),
                decoration: isLast
                    ? null
                    : const BoxDecoration(
                        border: BorderDirectional(end: BorderSide(color: _kBorder))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(cells[i].$1, size: 24, color: AppColors.midBlue),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cells[i].$2,
                              style: TextStyle(fontFamily: AppFonts.inter,
                                  fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
                          const SizedBox(height: 4),
                          _maybeLtr(
                            cells[i].$4, // the time range stays LTR
                            Text(cells[i].$3,
                                style: TextStyle(fontFamily: AppFonts.inter,
                                    fontSize: 14, color: _kIconGrey, height: 17 / 14)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Frame 2071857240 — 720 × 320 map with a single purple venue pin.
  ///
  /// The pin was a constant, so every event was at 31.8932, 35.0145. It sits
  /// on the row's own coordinates now, and the section is hidden altogether
  /// for an online event or one that has none.
  Widget _buildMiniMap(Event event) {
    final venue = LatLng(event.latitude, event.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 720,
        height: 320,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: venue,
            initialZoom: 15,
            interactionOptions:
                const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.modiin4u.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: venue,
                  width: 48,
                  height: 48,
                  alignment: Alignment.topCenter,
                  child: const _EventMapPin(size: 48),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // YOU MAY ALSO LIKE — 1600-wide carousel of 382 cards
  // ─────────────────────────────────────────────
  Widget _buildRelatedSection(Event event) {
    // Four invented events sat here, each linking to `/event/demo_$i`.
    final all = ref.watch(eventsProvider).valueOrNull ?? const <Event>[];
    final related = all.where((e) => e.id != event.id).take(4).toList();
    if (related.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(_t('You May Also Like', 'אולי יעניין אתכם גם')),
          const SizedBox(height: 62),
          SizedBox(
            height: 364,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ListView.separated(
                  controller: _carousel,
                  scrollDirection: Axis.horizontal,
                  itemCount: related.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 24),
                  itemBuilder: (context, i) => SizedBox(
                    width: 382,
                    child: _RelatedCard(
                      event: related[i],
                      month: related[i].startDate == null
                          ? null
                          : _shortMonth(related[i].startDate!),
                      time: _timeRange(related[i]),
                      place: _place(related[i]),
                      price: _price(related[i]),
                      interestedLabel: _t('interested', 'מתעניינים'),
                      onTap: () => context.push('/event/${related[i].id}'),
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: -19,
                  top: 162,
                  child: _carouselArrow(isNext: false),
                ),
                PositionedDirectional(
                  end: -19,
                  top: 162,
                  child: _carouselArrow(isNext: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _carouselArrow({required bool isNext}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (!_carousel.hasClients) return;
          final delta = (382.0 + 24.0) * (isNext ? 1 : -1);
          _carousel.animateTo(
            (_carousel.offset + delta)
                .clamp(0.0, _carousel.position.maxScrollExtent),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
          );
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFF6F6F6)),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 1)),
            ],
          ),
          child: Icon(
            isNext ? IconsaxPlusLinear.arrow_right_3 : IconsaxPlusLinear.arrow_left_2,
            size: 20,
            color: AppColors.midBlue,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FOOTER
  // ─────────────────────────────────────────────
}

// ═══════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════

/// Purple teardrop pin used on the "Where Is It?" map (Ellipse 521 · #9032E1).
class _EventMapPin extends StatelessWidget {
  final double size;
  const _EventMapPin({this.size = 48});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Icon(
            IconsaxPlusBold.location,
            size: size,
            color: Colors.white,
            shadows: const [
              Shadow(color: Color(0x40000000), blurRadius: 2.74, offset: Offset(0, 2.74)),
            ],
          ),
          Positioned(
            top: size * 0.1449,
            child: Container(
              width: size * 0.5362,
              height: size * 0.5362,
              decoration: const BoxDecoration(color: _kPinPurple, shape: BoxShape.circle),
              child: Center(
                child: Icon(IconsaxPlusLinear.calendar, size: size * 0.29, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// RELATED EVENT CARD — 382 × 364
// ─────────────────────────────────────────────
class _RelatedCard extends StatefulWidget {
  final Event event;
  final String? month, time, place, price;
  final String interestedLabel;
  final VoidCallback onTap;
  const _RelatedCard({
    required this.event,
    required this.month,
    required this.time,
    required this.place,
    required this.price,
    required this.interestedLabel,
    required this.onTap,
  });

  @override
  State<_RelatedCard> createState() => _RelatedCardState();
}

class _RelatedCardState extends State<_RelatedCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final month = widget.month;
    final price = widget.price;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 364,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _hovered ? AppColors.midBlue : _kBorder),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: NetworkPhoto(
                        url: e.imageUrl,
                        radius: const BorderRadius.vertical(top: Radius.circular(11)),
                        icon: IconsaxPlusBold.calendar_1,
                        iconSize: 34,
                      ),
                    ),
                    PositionedDirectional(
                      start: 12,
                      top: 12,
                      child: FavoriteButton(
                        kind: FavoriteKind.event,
                        id: e.id,
                        size: 40,
                        iconSize: 20,
                      ),
                    ),
                    if (month != null)
                      PositionedDirectional(
                        start: 12,
                        bottom: 12,
                        child: Container(
                          width: 57,
                          height: 57,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(month,
                                  style: TextStyle(fontFamily: AppFonts.inter,
                                      fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.midBlue, height: 1.25)),
                              const SizedBox(height: 4),
                              Text('${e.startDate!.day}',
                                  style: TextStyle(fontFamily: AppFonts.inter,
                                      fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black, height: 1.22)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title,
                        style: TextStyle(fontFamily: AppFonts.nunito,
                            fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.navy, height: 1.25),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),
                      if (widget.time != null) ...[
                        _metaRow(IconsaxPlusBold.clock, widget.time!),
                        const SizedBox(height: 8),
                      ],
                      if (widget.place != null)
                        _metaRow(
                          e.isOnline ? IconsaxPlusBold.global : IconsaxPlusBold.location,
                          widget.place!,
                        ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (price != null)
                            Flexible(
                              child: Text(
                                price,
                                style: TextStyle(fontFamily: AppFonts.nunito,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: e.isFree ? AppColors.midBlue : AppColors.navy,
                                  height: 1.25,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (e.rsvpCount > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(IconsaxPlusBold.star_1, size: 18, color: AppColors.turquoise),
                                const SizedBox(width: 4),
                                Text('${e.rsvpCount} ${widget.interestedLabel}',
                                    style: TextStyle(fontFamily: AppFonts.inter,
                                        fontSize: 14, fontWeight: FontWeight.w500, color: _kBodyText, height: 1.21)),
                              ],
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

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.turquoise),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kGreyText, height: 1.21),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
