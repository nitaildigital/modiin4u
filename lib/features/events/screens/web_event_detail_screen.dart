import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/web_chrome.dart';

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

class WebEventDetailContent extends StatefulWidget {
  final String eventId;
  const WebEventDetailContent({super.key, required this.eventId});

  @override
  State<WebEventDetailContent> createState() => _WebEventDetailContentState();
}

class _WebEventDetailContentState extends State<WebEventDetailContent> {
  bool _isHebrew = false;
  bool _isGoing = false;
  bool _isSaved = false;
  final _carousel = ScrollController();

  static const _venue = LatLng(31.8932, 35.0145);

  String _t(String en, String he) => _isHebrew ? he : en;

  @override
  void dispose() {
    _carousel.dispose();
    super.dispose();
  }

  // ── What's Included ──
  List<String> get _included => [
    _t('Live music performances', 'הופעות מוזיקה חיה'),
    _t('Food & refreshments', 'אוכל וכיבוד'),
    _t('Outdoor seating', 'ישיבה בחוץ'),
    _t('Family-friendly atmosphere', 'אווירה משפחתית'),
    _t('Local artists', 'אמנים מקומיים'),
  ];

  // ── You May Also Like ──
  List<_Related> get _related => [
    _Related(
      month: _t('AUG', 'אוג'), day: '27',
      category: _t('Music', 'מוזיקה'),
      title: _t('Live Jazz Evening', 'ערב ג\'אז חי'),
      time: '8:30 PM',
      venue: _t('Local Cultural Center', 'מרכז התרבות המקומי'),
      price: '₪60', interested: 51,
      imageBg: const Color(0xFF3B2B63),
    ),
    _Related(
      month: _t('AUG', 'אוג'), day: '28',
      category: _t('Municipal & Community', 'עירוני וקהילתי'),
      title: _t('Open Air Movie Night', 'ערב סרט תחת כיפת השמיים'),
      time: '8:30 PM',
      venue: _t('Modiin Park', 'פארק מודיעין'),
      price: _t('FREE', 'חינם'), interested: 93,
      imageBg: const Color(0xFF2E4E8C),
    ),
    _Related(
      month: _t('AUG', 'אוג'), day: '29',
      category: _t('Kids & Family', 'ילדים ומשפחה'),
      title: _t('Kids Cooking Workshop', 'סדנת בישול לילדים'),
      time: '10:30 AM',
      venue: _t('Community Center', 'מרכז קהילתי'),
      price: '₪30', interested: 35,
      imageBg: const Color(0xFFB4715A),
    ),
    _Related(
      month: _t('AUG', 'אוג'), day: '29',
      category: _t('Sports', 'ספורט'),
      title: _t('Community Football Match', 'משחק כדורגל קהילתי'),
      time: '10:30 AM',
      venue: _t('Community Center', 'מרכז קהילתי'),
      price: _t('FREE', 'חינם'), interested: 68,
      imageBg: const Color(0xFF2F6B4F),
    ),
  ];

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
              activeId: 'events',
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHero(),
                    _buildBody(),
                    const SizedBox(height: 56),
                    _buildRelatedSection(),
                    const SizedBox(height: 80),
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
  // NAVBAR — 1920 × 80
  // ─────────────────────────────────────────────
  // ─────────────────────────────────────────────
  // HERO — 1920 × 550
  // ─────────────────────────────────────────────
  Widget _buildHero() {
    return SizedBox(
      width: double.infinity,
      height: 550,
      child: Stack(
        children: [
          // Cover photo stand-in
          Positioned.fill(
            child: _imagePlaceholder(const Color(0xFF3B2B63),
                radius: BorderRadius.zero, glyph: 56),
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
                  _heroDateBadge(),
                  const SizedBox(height: 26),
                  Text(
                    _t('Summer Music Night', 'ערב מוזיקה קיצי'),
                    style: TextStyle(fontFamily: AppFonts.nunito, 
                        fontSize: 48, fontWeight: FontWeight.w600, color: Colors.white, height: 59 / 48),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.turquoise,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(_t('Music', 'מוזיקה'),
                        style: TextStyle(fontFamily: AppFonts.inter, 
                            fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white, height: 17 / 14)),
                  ),
                  const SizedBox(height: 24),
                  _heroMetaRow(IconsaxPlusLinear.clock, '8:00 PM – 11:00 PM', forceLtr: true),
                  const SizedBox(height: 24),
                  _heroMetaRow(IconsaxPlusLinear.location,
                      _t("21 Sderot El Melachot, Modi'in Maccabim-Re'ut",
                          'שדרות אל המלאכות 21, מודיעין מכבים רעות')),
                  const SizedBox(height: 24),
                  _heroMetaRow(IconsaxPlusLinear.star_1,
                      _t('124 people interested', '124 מתעניינים')),
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
                _heroPillButton(IconsaxPlusLinear.share, _t('Share', 'שיתוף'), () {}),
                const SizedBox(width: 12),
                _heroPillButton(
                  _isSaved ? IconsaxPlusBold.archive_1 : IconsaxPlusLinear.archive_1,
                  _t('Save', 'שמירה'),
                  () => setState(() => _isSaved = !_isSaved),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroDateBadge() {
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
          Text(_t('AUG', 'אוג'),
              style: TextStyle(fontFamily: AppFonts.inter, 
                  fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.midBlue, height: 22 / 18)),
          const SizedBox(height: 5.68),
          Text('21',
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

  // ─────────────────────────────────────────────
  // BODY — 1011 content column + 463 RSVP card
  // ─────────────────────────────────────────────
  Widget _buildBody() {
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
                  SizedBox(width: columnWidth, child: _buildContentColumn()),
                  const Spacer(),
                  SizedBox(width: cardWidth, child: _buildRsvpCard()),
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
  Widget _buildRsvpCard() {
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _imagePlaceholder(const Color(0xFF3B2B63),
                height: 180, radius: BorderRadius.zero, glyph: 34),
          ),
          const SizedBox(height: 16),
          Text(_t('Summer Music Night', 'ערב מוזיקה קיצי'),
              style: TextStyle(fontFamily: AppFonts.inter, 
                  fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black, height: 27 / 22)),
          const SizedBox(height: 16),
          _cardMetaRow(IconsaxPlusLinear.clock, '8:00 PM – 11:00 PM', forceLtr: true),
          const SizedBox(height: 16),
          _cardMetaRow(IconsaxPlusLinear.location,
              _t("21 Sderot El Melachot, Modi'in Maccabim-Re'ut",
                  'שדרות אל המלאכות 21, מודיעין מכבים רעות')),
          const SizedBox(height: 16),
          _cardMetaRow(IconsaxPlusLinear.star_1,
              _t('124 people interested', '124 מתעניינים')),
          const SizedBox(height: 24),
          // ── Primary RSVP button ──
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _isGoing = !_isGoing),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.midBlue,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(IconsaxPlusLinear.tick_circle, size: 20, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(_isGoing ? _t('Going', 'מגיע/ה') : _t("I'm Going", 'אני מגיע/ה'),
                        style: TextStyle(fontFamily: AppFonts.inter, 
                            fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white, height: 1.5)),
                  ],
                ),
              ),
            ),
          ),
          // ── Stage 2 confirmation banner ──
          if (_isGoing) ...[
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
              Expanded(
                child: _cardOutlineButton(
                  _isSaved ? IconsaxPlusBold.archive_1 : IconsaxPlusLinear.archive_1,
                  _t('Save', 'שמירה'),
                  () => setState(() => _isSaved = !_isSaved),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _cardOutlineButton(IconsaxPlusLinear.share, _t('Share', 'שיתוף'), () {}),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // ── Attendee avatars ──
          Row(
            children: [
              SizedBox(
                width: 144,
                height: 40,
                child: Stack(
                  children: List.generate(4, (i) {
                    const faces = [
                      Color(0xFFB4715A), Color(0xFF2E4E8C),
                      Color(0xFF2F6B4F), Color(0xFF6E5A9E),
                    ];
                    return PositionedDirectional(
                      start: i * 34.0,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: ClipOval(child: _imagePlaceholder(faces[i], glyph: 14)),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_t('124 people interested', '124 מתעניינים'),
                    style: TextStyle(fontFamily: AppFonts.inter, 
                        fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black, height: 17 / 14)),
              ),
            ],
          ),
          const SizedBox(height: 23),
          // ── Organized by ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _kBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_t('Organized by', 'מארגן האירוע'),
                    style: TextStyle(fontFamily: AppFonts.nunito, 
                        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.midBlue, height: 20 / 16)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _kBorder),
                      ),
                      child: ClipOval(child: _imagePlaceholder(const Color(0xFF2E4E8C), glyph: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_t('Modiin Community Events', 'אירועי קהילה מודיעין'),
                              style: TextStyle(fontFamily: AppFonts.inter, 
                                  fontSize: 16, fontWeight: FontWeight.w600, color: _kBodyText, height: 19 / 16)),
                          const SizedBox(height: 6),
                          Text(_t('Community & Municipal Events', 'אירועים קהילתיים ועירוניים'),
                              style: TextStyle(fontFamily: AppFonts.inter, 
                                  fontSize: 12, color: _kIconGrey, height: 15 / 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _cardOutlineButton(IconData icon, String label, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
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

  Widget _buildContentColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(_t('About This Event', 'על האירוע')),
        const SizedBox(height: 24),
        SizedBox(
          width: 896,
          child: Text(
            _t('Get ready for an unforgettable evening of live music under the stars in Modiin. '
                'Enjoy performances from local artists, great music, food, and a vibrant community atmosphere.',
                'התכוננו לערב בלתי נשכח של מוזיקה חיה תחת כיפת השמיים במודיעין. '
                'תיהנו מהופעות של אמנים מקומיים, מוזיקה נהדרת, אוכל ואווירה קהילתית תוססת.'),
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: _kBodyText, height: 1.6),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 896,
          child: Text(
            _t("Whether you're coming with friends, family, or simply looking for a great night out, "
                'Summer Music Night is the perfect way to enjoy the summer evening.',
                'בין אם אתם מגיעים עם חברים, עם המשפחה או פשוט מחפשים ערב מוצלח בחוץ — '
                'ערב מוזיקה קיצי הוא הדרך המושלמת ליהנות מערב הקיץ.'),
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: _kBodyText, height: 1.6),
          ),
        ),
        const SizedBox(height: 56),
        _sectionTitle(_t('Event Details', 'פרטי האירוע')),
        const SizedBox(height: 24),
        _buildDetailsBox(),
        const SizedBox(height: 56),
        _sectionTitle(_t("What's Included", 'מה כלול')),
        const SizedBox(height: 24),
        for (var i = 0; i < _included.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          Row(
            children: [
              const Icon(IconsaxPlusLinear.tick_circle, size: 16, color: AppColors.turquoise),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_included[i],
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: _kBodyText, height: 19 / 16)),
              ),
            ],
          ),
        ],
        const SizedBox(height: 56),
        _sectionTitle(_t('Where Is It?', 'איפה זה?')),
        const SizedBox(height: 24),
        _buildMiniMap(),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: TextStyle(fontFamily: AppFonts.nunito, 
            fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.midBlue, height: 30 / 24));
  }

  /// Frame 2071857385 — 1011 × 123 bordered box with four divided cells.
  Widget _buildDetailsBox() {
    final cells = [
      (IconsaxPlusLinear.calendar, _t('Date', 'תאריך'),
          _t('Thursday, August 21, 2026', 'יום חמישי, 21 באוגוסט 2026')),
      (IconsaxPlusLinear.clock, _t('Time', 'שעה'), '8:00 PM – 11:00 PM'),
      (IconsaxPlusLinear.location, _t('Location', 'מיקום'),
          _t('Modiin Amphitheater, Modiin', 'האמפיתאטרון, מודיעין')),
      (IconsaxPlusLinear.ticket, _t('Price', 'מחיר'), '₪50'),
    ];
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
                            i == 1, // the time range stays LTR
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
  Widget _buildMiniMap() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 720,
        height: 320,
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: _venue,
            initialZoom: 15,
            interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.modiin4u.app',
            ),
            const MarkerLayer(
              markers: [
                Marker(
                  point: _venue,
                  width: 48,
                  height: 48,
                  alignment: Alignment.topCenter,
                  child: _EventMapPin(size: 48),
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
  Widget _buildRelatedSection() {
    final related = _related;
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
                      interestedLabel: _t('interested', 'מתעניינים'),
                      onTap: () => context.push('/event/demo_$i'),
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
// DATA MODELS
// ═══════════════════════════════════════════════

class _Related {
  final String month, day, category, title, time, venue, price;
  final int interested;
  final Color imageBg;
  const _Related({
    required this.month,
    required this.day,
    required this.category,
    required this.title,
    required this.time,
    required this.venue,
    required this.price,
    required this.interested,
    required this.imageBg,
  });

  bool get isFree => !price.contains('₪');
}

// ═══════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════

/// Gradient stand-in for a photo that has no asset yet.
Widget _imagePlaceholder(Color base, {double? width, double? height, BorderRadius? radius, double glyph = 28}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: radius,
      shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [base, Color.lerp(base, Colors.black, 0.22)!],
      ),
    ),
    child: Center(
      child: Icon(IconsaxPlusLinear.image, size: glyph, color: Colors.white.withValues(alpha: 0.35)),
    ),
  );
}

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
  final _Related event;
  final String interestedLabel;
  final VoidCallback onTap;
  const _RelatedCard({required this.event, required this.interestedLabel, required this.onTap});

  @override
  State<_RelatedCard> createState() => _RelatedCardState();
}

class _RelatedCardState extends State<_RelatedCard> {
  bool _hovered = false;
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
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
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                        child: _imagePlaceholder(e.imageBg, radius: BorderRadius.zero, glyph: 34),
                      ),
                    ),
                    PositionedDirectional(
                      start: 12,
                      top: 12,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => setState(() => _saved = !_saved),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Icon(
                              _saved ? IconsaxPlusBold.archive_1 : IconsaxPlusLinear.archive_1,
                              size: 20,
                              color: AppColors.midBlue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      end: 14,
                      top: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.turquoise,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(e.category,
                            style: TextStyle(fontFamily: AppFonts.inter, 
                                fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white, height: 1.25)),
                      ),
                    ),
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
                            Text(e.month,
                                style: TextStyle(fontFamily: AppFonts.inter, 
                                    fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.midBlue, height: 1.25)),
                            const SizedBox(height: 4),
                            Text(e.day,
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
                      _metaRow(IconsaxPlusBold.clock, e.time),
                      const SizedBox(height: 8),
                      _metaRow(IconsaxPlusBold.location, e.venue),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              e.price,
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
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(IconsaxPlusBold.star_1, size: 18, color: AppColors.turquoise),
                              const SizedBox(width: 4),
                              Text('${e.interested} ${widget.interestedLabel}',
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
