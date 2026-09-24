import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/web_chrome.dart';

// ═══════════════════════════════════════════════════════════
// Web Municipal — desktop city-services hub
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF5F5E5A);
const _kHeading = Color(0xFF1C1C1E);
const _kIconGrey = Color(0xFF6D6D6D);

const _kShabbatBg = Color(0xFFFEF8EF);
const _kShabbatAccent = Color(0xFFD68200);
const _kParkingBg = Color(0xFFF0F7FD);
const _kParkingBorder = Color(0xFFD9E8F4);
const _kHotlineBg = Color(0xFFEFF9F3);
const _kHotlineAccent = Color(0xFF12855A);

class WebMunicipalContent extends StatefulWidget {
  const WebMunicipalContent({super.key});

  @override
  State<WebMunicipalContent> createState() => _WebMunicipalContentState();
}

class _WebMunicipalContentState extends State<WebMunicipalContent> {
  bool _isHebrew = false;
  String _query = '';
  final _searchCtrl = TextEditingController();
  final _servicesKey = GlobalKey();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  // ── The 9 service categories, same set as the mobile grid ──
  List<_Service> get _services => [
    _Service(
      label: _t('Parking', 'חניה'),
      blurb: _t('Zones, permits and payment', 'אזורים, תווים ותשלום'),
      icon: IconsaxPlusLinear.clock,
      route: '/parking',
    ),
    _Service(
      label: _t('Shabbat & Holidays', 'שבת וחגים'),
      blurb: _t('Candle lighting and closures', 'הדלקת נרות וסגירות'),
      icon: IconsaxPlusLinear.candle,
    ),
    _Service(
      label: _t('Public Institutions', 'מוסדות ציבור'),
      blurb: _t('City hall, libraries, centres', 'עירייה, ספריות ומתנ"סים'),
      icon: IconsaxPlusLinear.bank,
    ),
    _Service(
      label: _t('Health', 'בריאות'),
      blurb: _t(
        'Clinics, pharmacies, dentists',
        'מרפאות, בתי מרקחת ורופאי שיניים',
      ),
      icon: IconsaxPlusLinear.health,
    ),
    _Service(
      label: _t('Education', 'חינוך'),
      blurb: _t('Schools, kindergartens, registration', 'בתי ספר, גנים ורישום'),
      icon: IconsaxPlusLinear.book_1,
    ),
    _Service(
      label: _t('Transportation', 'תחבורה'),
      blurb: _t('Bus lines, train and routes', 'קווי אוטובוס, רכבת ומסלולים'),
      icon: IconsaxPlusLinear.bus,
    ),
    _Service(
      label: _t('Emergency', 'חירום'),
      blurb: _t('Hotlines and shelters', 'מוקדי חירום ומקלטים'),
      icon: IconsaxPlusLinear.danger,
    ),
    _Service(
      label: _t('Parks', 'פארקים'),
      blurb: _t('Green spaces and playgrounds', 'שטחים ירוקים וגני שעשועים'),
      icon: IconsaxPlusLinear.tree,
    ),
    _Service(
      label: _t('Forms', 'טפסים'),
      blurb: _t('Applications and permits', 'בקשות ואישורים'),
      icon: IconsaxPlusLinear.document_text,
    ),
  ];

  List<_Service> get _visibleServices {
    final q = _query.toLowerCase();
    if (q.isEmpty) return _services;
    return _services
        .where(
          (s) =>
              s.label.toLowerCase().contains(q) ||
              s.blurb.toLowerCase().contains(q),
        )
        .toList();
  }

  // ── Emergency and service numbers ──
  List<_Contact> get _contacts => [
    _Contact(
      name: _t('Police', 'משטרה'),
      number: '100',
      icon: IconsaxPlusLinear.shield_tick,
    ),
    _Contact(
      name: _t('Ambulance (MDA)', 'מגן דוד אדום'),
      number: '101',
      icon: IconsaxPlusLinear.health,
    ),
    _Contact(
      name: _t('Fire & Rescue', 'כבאות והצלה'),
      number: '102',
      icon: IconsaxPlusLinear.danger,
    ),
    _Contact(
      name: _t('Home Front Command', 'פיקוד העורף'),
      number: '104',
      icon: IconsaxPlusLinear.shield_security,
    ),
    _Contact(
      name: _t('Municipal Hotline', 'מוקד עירוני'),
      number: '106',
      icon: IconsaxPlusLinear.call,
    ),
    _Contact(
      name: _t('Electric Company', 'חברת החשמל'),
      number: '103',
      icon: IconsaxPlusLinear.flash_1,
    ),
  ];

  void _scrollToServices() {
    final ctx = _servicesKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      alignment: 0.05,
    );
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
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeroSection(),
                    _buildQuickInfoSection(),
                    _buildServicesSection(),
                    _buildContactsSection(),
                    _buildCityHallSection(),
                    const SizedBox(height: 100),
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
  // HERO
  // ─────────────────────────────────────────────
  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          Text(
            _t('Municipal Services in Modiin', 'שירותים עירוניים במודיעין'),
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 44,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              height: 1.23,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            _t(
              'Parking, Shabbat times, city departments and emergency numbers — everything the city offers, in one place.',
              'חניה, זמני שבת, מחלקות העירייה ומספרי חירום – כל מה שהעיר מציעה, במקום אחד.',
            ),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 16,
              color: _kIconGrey,
              height: 1.19,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildSearchBar(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 24),
          const Icon(
            IconsaxPlusLinear.search_normal_1,
            size: 20,
            color: _kIconGrey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              onSubmitted: (_) => _scrollToServices(),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 16,
                color: _kHeading,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: _t(
                  'Search municipal services...',
                  'חפשו שירותים עירוניים...',
                ),
                hintStyle: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  color: _kIconGrey,
                ),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    IconsaxPlusLinear.close_circle,
                    size: 20,
                    color: _kIconGrey,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _scrollToServices,
              child: Container(
                height: 48,
                margin: const EdgeInsetsDirectional.only(end: 8),
                padding: const EdgeInsets.symmetric(horizontal: 32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.midBlue,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  _t('Search', 'חיפוש'),
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
    );
  }

  // ─────────────────────────────────────────────
  // QUICK INFO — Shabbat, parking, hotline
  // ─────────────────────────────────────────────
  Widget _buildQuickInfoSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: WebSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('Quick Info', 'במבט מהיר'),
              style: TextStyle(
                fontFamily: AppFonts.nunito,
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppColors.midBlue,
              ),
            ),
            const SizedBox(height: 24),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildShabbatCard()),
                  const SizedBox(width: 24),
                  Expanded(child: _buildParkingCard()),
                  const SizedBox(width: 24),
                  Expanded(child: _buildHotlineCard()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickCard({
    required Color background,
    required Color borderColor,
    required Color accent,
    required IconData icon,
    required String title,
    required List<Widget> body,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _kBorder)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Center(child: Icon(icon, size: 26, color: accent)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _kHeading,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...body,
        ],
      ),
    );
    if (onTap == null) return card;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: card),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _kIconGrey),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: _kGreyText,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kHeading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShabbatCard() {
    return _quickCard(
      background: _kShabbatBg,
      borderColor: _kShabbatAccent.withValues(alpha: 0.2),
      accent: _kShabbatAccent,
      icon: IconsaxPlusLinear.candle,
      title: _t('Upcoming Shabbat', 'שבת הקרובה'),
      body: [
        Text(
          _t('Sep 18–19, 2026', 'י"ח–י"ט אלול, 18–19 בספטמבר'),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            color: _kGreyText,
          ),
        ),
        const SizedBox(height: 16),
        _infoRow(
          IconsaxPlusLinear.clock,
          _t('Candle lighting', 'כניסת שבת'),
          '18:42',
        ),
        _infoRow(IconsaxPlusLinear.moon, _t('Havdalah', 'צאת שבת'), '19:38'),
      ],
    );
  }

  Widget _buildParkingCard() {
    return _quickCard(
      background: _kParkingBg,
      borderColor: _kParkingBorder,
      accent: AppColors.midBlue,
      icon: IconsaxPlusLinear.car,
      title: _t('Parking in Modiin', 'חניה במודיעין'),
      onTap: () => context.push('/parking'),
      body: [
        Text(
          _t(
            'Blue-and-white is free for residents with a valid permit.',
            'כחול-לבן חינם לתושבים עם תו חניה בתוקף.',
          ),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            color: _kGreyText,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        _infoRow(
          IconsaxPlusLinear.clock,
          _t('Paid hours', 'שעות תשלום'),
          '08:00–19:00',
        ),
        Row(
          children: [
            Text(
              _t('Open parking map', 'למפת החניה'),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.midBlue,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.midBlue),
          ],
        ),
      ],
    );
  }

  Widget _buildHotlineCard() {
    return _quickCard(
      background: _kHotlineBg,
      borderColor: _kHotlineAccent.withValues(alpha: 0.2),
      accent: _kHotlineAccent,
      icon: IconsaxPlusLinear.call,
      title: _t('Municipal Hotline', 'המוקד העירוני'),
      body: [
        Text(
          _t(
            'Report a fault, a pothole or a street light — 24/7.',
            'דיווח על תקלה, מפגע או פנס רחוב – 24/7.',
          ),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            color: _kGreyText,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            '106',
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: _kHotlineAccent,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _t('or 08-9726000', 'או 08-9726000'),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 13,
            color: _kGreyText,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // SERVICES — searchable grid
  // ─────────────────────────────────────────────
  Widget _buildServicesSection() {
    final services = _visibleServices;
    return Padding(
      key: _servicesKey,
      padding: const EdgeInsets.only(top: 80),
      child: WebSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('Municipal Services', 'שירותי העירייה'),
              style: TextStyle(
                fontFamily: AppFonts.nunito,
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppColors.midBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _query.isEmpty
                  ? _t('Explore services and information', 'גלו שירותים ומידע')
                  : (services.length == 1
                        ? _t(
                            '1 service matches "$_query"',
                            'שירות אחד תואם ל"$_query"',
                          )
                        : _t(
                            '${services.length} services match "$_query"',
                            '${services.length} שירותים תואמים ל"$_query"',
                          )),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                color: _kGreyText,
                height: 1.21,
              ),
            ),
            const SizedBox(height: 32),
            if (services.isEmpty)
              _buildEmptyServices()
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 20.0;
                  const perRow = 3;
                  final cardWidth =
                      (constraints.maxWidth - gap * (perRow - 1)) / perRow;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: services.map((s) {
                      return SizedBox(
                        width: cardWidth,
                        // Fixed height so a card without a "coming soon" badge
                        // still lines up with the rest of its row.
                        height: 128,
                        child: _ServiceCard(
                          service: s,
                          comingSoonLabel: _t('Coming soon', 'בקרוב'),
                          onTap: s.route == null
                              ? null
                              : () => context.push(s.route!),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyServices() {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            IconsaxPlusLinear.bank,
            size: 44,
            color: _kGreyText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _t('No service matches your search', 'לא נמצא שירות שתואם לחיפוש'),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _kHeading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t(
              'Try a different word, or call the municipal hotline on 106.',
              'נסו מילה אחרת, או התקשרו למוקד העירוני 106.',
            ),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: _kGreyText,
            ),
          ),
          const SizedBox(height: 20),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.midBlue,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  _t('Clear search', 'נקו חיפוש'),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EMERGENCY & SERVICE NUMBERS
  // ─────────────────────────────────────────────
  Widget _buildContactsSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: WebSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('Emergency & Service Numbers', 'מספרי חירום ושירות'),
              style: TextStyle(
                fontFamily: AppFonts.nunito,
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppColors.midBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _t(
                'Keep these close — they work from any phone in Israel.',
                'שמרו אותם בהישג יד – הם פועלים מכל טלפון בישראל.',
              ),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                color: _kGreyText,
                height: 1.21,
              ),
            ),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 20.0;
                const perRow = 3;
                final cardWidth =
                    (constraints.maxWidth - gap * (perRow - 1)) / perRow;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: _contacts.map((c) {
                    return SizedBox(
                      width: cardWidth,
                      child: _ContactCard(contact: c),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CITY HALL — address and opening hours
  // ─────────────────────────────────────────────
  Widget _buildCityHallSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: WebSection(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(
                        'Modiin-Maccabim-Reut City Hall',
                        'עיריית מודיעין-מכבים-רעות',
                      ),
                      style: TextStyle(
                        fontFamily: AppFonts.nunito,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          IconsaxPlusLinear.location,
                          size: 18,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _t(
                            '1 Dam HaMaccabim St., Modiin',
                            'רחוב דם המכבים 1, מודיעין',
                          ),
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          IconsaxPlusLinear.global,
                          size: 18,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'modiin.muni.il',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('Reception Hours', 'שעות קבלת קהל'),
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _hoursRow(_t('Sun, Tue, Thu', 'א׳, ג׳, ה׳'), '08:30–13:00'),
                    _hoursRow(
                      _t('Monday', 'יום ב׳'),
                      '08:30–13:00, 16:00–18:30',
                    ),
                    _hoursRow(
                      _t('Wednesday', 'יום ד׳'),
                      _t('Closed to the public', 'סגור לקהל'),
                    ),
                    _hoursRow(_t('Friday', 'יום ו׳'), _t('Closed', 'סגור')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hoursRow(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              day,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
          Expanded(
            child: Text(
              hours,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════

class _Service {
  final String label, blurb;
  final IconData icon;
  final String? route;
  const _Service({
    required this.label,
    required this.blurb,
    required this.icon,
    this.route,
  });
}

class _Contact {
  final String name, number;
  final IconData icon;
  const _Contact({
    required this.name,
    required this.number,
    required this.icon,
  });
}

// ═══════════════════════════════════════════════
// CARDS
// ═══════════════════════════════════════════════

class _ServiceCard extends StatefulWidget {
  final _Service service;
  final String comingSoonLabel;
  final VoidCallback? onTap;
  const _ServiceCard({
    required this.service,
    required this.comingSoonLabel,
    this.onTap,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final live = widget.onTap != null;
    return MouseRegion(
      cursor: live ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: _hovered && live ? AppColors.midBlue : _kBorder,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.midBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(s.icon, size: 26, color: AppColors.midBlue),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.label,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _kHeading,
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.blurb,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 14,
                        color: _kGreyText,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!live) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.comingSoonLabel,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _kGreyText,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (live)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: _hovered ? AppColors.midBlue : _kIconGrey,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final _Contact contact;
  const _ContactCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.midBlue.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(contact.icon, size: 22, color: AppColors.midBlue),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              contact.name,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _kHeading,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              contact.number,
              style: TextStyle(
                fontFamily: AppFonts.nunito,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.midBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
