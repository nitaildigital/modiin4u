import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// Web Events Category — three-panel layout from the Figma
// export "Event Category" (1920 × 960).
// Left: filter sidebar 294 | Center: results 900 | Right: map 726
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kSidebarBg = Color(0xFFF7F8FA);
const _kTextDark = Color(0xFF3D3D3D);
const _kTextGrey = Color(0xFF6D6D6D);
const _kSubtitle = Color(0xFF5F5E5A);
const _kCheckBorder = Color(0xFF7B899A);
const _kSaveBg = Color(0xFFF2F3F8);
const _kPinPurple = Color(0xFF9032E1);

class WebEventsCategoryContent extends StatefulWidget {
  const WebEventsCategoryContent({super.key});

  @override
  State<WebEventsCategoryContent> createState() =>
      _WebEventsCategoryContentState();
}

class _WebEventsCategoryContentState extends State<WebEventsCategoryContent> {
  bool _isHebrew = false;
  final _searchController = TextEditingController();
  final _listController = ScrollController();
  final _mapController = MapController();

  String _query = '';
  /// Empty ⇒ "All Events". The export ships with Music pre-selected.
  String _category = 'music';
  String _price = 'all'; // all | free | paid
  int? _selectedPin;
  final Set<int> _saved = {};

  static const _center = LatLng(31.8928, 35.0104);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _query = _searchController.text.trim()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listController.dispose();
    super.dispose();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  List<_NavItem> get _navItems => [
    _NavItem(label: _t('Professionals', 'בעלי מקצוע'), route: '/businesses', hasDropdown: true),
    _NavItem(label: _t('Modiin News', 'חדשות מודיעין'), route: '/news', hasDropdown: true),
    _NavItem(label: _t('Events', 'אירועים'), route: '/events', isActive: true),
    _NavItem(label: _t('Deals', 'מבצעים'), route: '/deals'),
    _NavItem(label: _t('Real Estate in Modiin', 'נדל"ן במודיעין'), route: '/realestate'),
    _NavItem(label: _t('Restaurants in Modiin', 'מסעדות במודיעין'), route: '/restaurants'),
    _NavItem(label: _t('Businesses in Modiin', 'עסקים במודיעין'), route: '/businesses', hasDropdown: true),
  ];

  // ── Filter definitions (counts come from the export) ──
  List<_Option> get _categoryOptions => [
    _Option('all', _t('All Events', 'כל האירועים'), 157),
    _Option('municipal', _t('Municipal & Community', 'עירוני וקהילתי'), 32),
    _Option('music', _t('Music', 'מוזיקה'), 24),
    _Option('kids', _t('Kids & Family', 'ילדים ומשפחה'), 45),
    _Option('sports', _t('Sports', 'ספורט'), 15),
  ];

  List<_Option> get _priceOptions => [
    _Option('all', _t('All', 'הכל'), 157),
    _Option('free', _t('Free', 'חינם'), 117),
    _Option('paid', _t('Paid', 'בתשלום'), 40),
  ];

  String get _categoryLabel =>
      _categoryOptions.firstWhere((o) => o.key == _category).label;

  // ── Results ──
  List<_EventRow> get _allEvents => [
    _EventRow(
      month: _t('AUG', 'אוג'), day: '21', category: 'music',
      title: _t('Summer Music Night', 'ערב מוזיקה קיצי'),
      time: '8:00 PM – 11:00 PM',
      address: _t("21 Sderot El Melachot, Modi'in Maccabim-Re'ut",
          'שדרות אל המלאכות 21, מודיעין מכבים רעות'),
      price: '₪50', interested: 124,
      position: const LatLng(31.8932, 35.0145),
      imageBg: const Color(0xFF3B2B63),
    ),
    _EventRow(
      month: _t('AUG', 'אוג'), day: '27', category: 'music',
      title: _t('Live Jazz Evening', 'ערב ג\'אז חי'),
      time: '6:30 PM – 9:30 PM',
      address: _t('Local Cultural Center, Modiin', 'מרכז התרבות המקומי, מודיעין'),
      price: '₪60', interested: 51,
      position: const LatLng(31.8905, 35.0126),
      imageBg: const Color(0xFF4A2F55),
    ),
    _EventRow(
      month: _t('AUG', 'אוג'), day: '28', category: 'music',
      title: _t('Open Air Music & Movie', 'מוזיקה וסרט בחוץ'),
      time: '8:30 PM – 11:00 PM',
      address: _t('Modiin Park, Modiin', 'פארק מודיעין, מודיעין'),
      price: _t('FREE', 'חינם'), interested: 93,
      position: const LatLng(31.8960, 35.0080),
      imageBg: const Color(0xFF2E4E8C),
    ),
    _EventRow(
      month: _t('AUG', 'אוג'), day: '29', category: 'music',
      title: _t('Indie Music Night', 'ערב אינדי'),
      time: '9:00 PM – 12:00 AM',
      address: _t('Anava Live Club, Modiin', 'מועדון ענבה לייב, מודיעין'),
      price: '₪40', interested: 72,
      position: const LatLng(31.8892, 35.0058),
      imageBg: const Color(0xFF39304F),
    ),
    _EventRow(
      month: _t('AUG', 'אוג'), day: '30', category: 'music',
      title: _t('Acoustic Sunset Session', 'סשן אקוסטי בשקיעה'),
      time: '7:00 PM – 9:30 PM',
      address: _t('Anava Park, Modiin', 'פארק ענבה, מודיעין'),
      price: _t('FREE', 'חינם'), interested: 86,
      position: const LatLng(31.8948, 35.0188),
      imageBg: const Color(0xFFB4715A),
    ),
    _EventRow(
      month: _t('SEP', 'ספט'), day: '01', category: 'music',
      title: _t('Modiin Rock Festival', 'פסטיבל הרוק של מודיעין'),
      time: '7:30 PM – 11:30 PM',
      address: _t('Modiin Amphitheater, Modiin', 'האמפיתאטרון, מודיעין'),
      price: '₪75', interested: 168,
      position: const LatLng(31.8975, 35.0112),
      imageBg: const Color(0xFF7A2C3A),
    ),
    _EventRow(
      month: _t('SEP', 'ספט'), day: '03', category: 'music',
      title: _t('Classical Evening Under the Stars', 'ערב קלאסי תחת הכוכבים'),
      time: '7:00 PM – 9:00 PM',
      address: _t('Modiin Cultural Hall', 'היכל התרבות מודיעין'),
      price: '₪45', interested: 43,
      position: const LatLng(31.8918, 35.0035),
      imageBg: const Color(0xFF2F4858),
    ),
    // ── Other categories, so the sidebar filters have something to show ──
    _EventRow(
      month: _t('AUG', 'אוג'), day: '22', category: 'municipal',
      title: _t('Modiin Community Festival', 'פסטיבל הקהילה של מודיעין'),
      time: '10:00 AM – 4:00 PM',
      address: _t('Modiin City Center', 'מרכז העיר מודיעין'),
      price: _t('FREE', 'חינם'), interested: 86,
      position: const LatLng(31.8945, 35.0120),
      imageBg: const Color(0xFF2F6B4F),
    ),
    _EventRow(
      month: _t('AUG', 'אוג'), day: '23', category: 'kids',
      title: _t('Family Fun Day', 'יום כיף משפחתי'),
      time: '11:00 AM – 3:00 PM',
      address: _t('Anava Park, Modiin', 'פארק ענבה, מודיעין'),
      price: '₪20', interested: 64,
      position: const LatLng(31.8900, 35.0165),
      imageBg: const Color(0xFFCB8B3E),
    ),
    _EventRow(
      month: _t('AUG', 'אוג'), day: '29', category: 'kids',
      title: _t('Kids Cooking Workshop', 'סדנת בישול לילדים'),
      time: '10:30 AM – 12:30 PM',
      address: _t('Community Center, Modiin', 'מרכז קהילתי, מודיעין'),
      price: '₪30', interested: 35,
      position: const LatLng(31.8938, 35.0052),
      imageBg: const Color(0xFFB4715A),
    ),
    _EventRow(
      month: _t('AUG', 'אוג'), day: '29', category: 'sports',
      title: _t('Community Football Match', 'משחק כדורגל קהילתי'),
      time: '10:30 AM – 12:00 PM',
      address: _t('Community Center, Modiin', 'מרכז קהילתי, מודיעין'),
      price: _t('FREE', 'חינם'), interested: 68,
      position: const LatLng(31.8968, 35.0158),
      imageBg: const Color(0xFF2F6B4F),
    ),
    _EventRow(
      month: _t('SEP', 'ספט'), day: '05', category: 'sports',
      title: _t('Modiin City Run', 'מרוץ העיר מודיעין'),
      time: '6:30 AM – 10:00 AM',
      address: _t('Modiin City Center', 'מרכז העיר מודיעין'),
      price: '₪65', interested: 212,
      position: const LatLng(31.8888, 35.0098),
      imageBg: const Color(0xFF17627A),
    ),
  ];

  List<_EventRow> get _events {
    final q = _query.toLowerCase();
    return _allEvents.where((e) {
      if (q.isNotEmpty &&
          !e.title.toLowerCase().contains(q) &&
          !e.address.toLowerCase().contains(q)) {
        return false;
      }
      if (_category != 'all' && e.category != _category) return false;
      if (_price == 'free' && !e.isFree) return false;
      if (_price == 'paid' && e.isFree) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _buildNavbar(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFilterSidebar(),
                  Expanded(flex: 900, child: _buildResultsPanel()),
                  Expanded(flex: 726, child: _buildMapPanel()),
                ],
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
  Widget _buildNavbar() {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 160),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/'),
              child: SvgPicture.asset(
                'assets/images/logo_white.svg',
                width: 90,
                height: 48,
                colorFilter: const ColorFilter.mode(AppColors.midBlue, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Row(
              children: _navItems
                  .map((item) => Expanded(
                        child: _NavLinkButton(
                          label: item.label,
                          isActive: item.isActive,
                          hasDropdown: item.hasDropdown,
                          onTap: () => context.go(item.route),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(width: 20),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _isHebrew = !_isHebrew),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsetsDirectional.only(end: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(IconsaxPlusLinear.global, size: 18, color: AppColors.midBlue),
                    const SizedBox(width: 6),
                    Text(_isHebrew ? 'עב | EN' : 'EN | עב',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.midBlue)),
                  ],
                ),
              ),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.midBlue,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Text(_t('Contact Us', 'צור קשר'),
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FILTER SIDEBAR — 294px
  // ─────────────────────────────────────────────
  Widget _buildFilterSidebar() {
    return Container(
      width: 294,
      decoration: const BoxDecoration(
        color: _kSidebarBg,
        border: BorderDirectional(end: BorderSide(color: _kBorder)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBox(),
            const SizedBox(height: 16),
            _buildFilterGroup(
              title: _t('Event Category', 'קטגוריית אירוע'),
              options: _categoryOptions,
              isChecked: (o) => _category == o.key,
              onTap: (o) => setState(() => _category = o.key),
            ),
            const SizedBox(height: 24),
            _buildFilterGroup(
              title: _t('Price', 'מחיר'),
              options: _priceOptions,
              isChecked: (o) => _price == o.key,
              onTap: (o) => setState(() => _price = o.key),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(IconsaxPlusLinear.search_normal_1, size: 16, color: AppColors.midBlue),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.navy),
              decoration: InputDecoration(
                hintText: _t('Search by location...', 'חיפוש לפי מיקום...'),
                hintStyle: GoogleFonts.inter(fontSize: 14, color: _kTextGrey),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterGroup({
    required String title,
    required List<_Option> options,
    required bool Function(_Option) isChecked,
    required void Function(_Option) onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
        const SizedBox(height: 17),
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _checkboxRow(
            option: options[i],
            checked: isChecked(options[i]),
            onTap: () => onTap(options[i]),
          ),
        ],
      ],
    );
  }

  Widget _checkboxRow({
    required _Option option,
    required bool checked,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: checked ? AppColors.midBlue : Colors.white,
                border: Border.all(
                  color: checked ? AppColors.midBlue : _kCheckBorder,
                  width: checked ? 1 : 0.89,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(option.label,
                  style: GoogleFonts.inter(fontSize: 13, color: _kTextDark, height: 16 / 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Text('${option.count}',
                style: GoogleFonts.inter(fontSize: 13, color: _kTextDark, height: 16 / 13)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // RESULTS PANEL — 900px
  // ─────────────────────────────────────────────
  Widget _buildResultsPanel() {
    final events = _events;
    return Container(
      decoration: const BoxDecoration(
        border: BorderDirectional(end: BorderSide(color: _kBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _buildResultsHeader(events.length),
          ),
          const SizedBox(height: 26),
          Expanded(
            child: events.isEmpty
                ? _buildEmptyState()
                : Scrollbar(
                    controller: _listController,
                    child: ListView.builder(
                      controller: _listController,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: events.length,
                      itemBuilder: (context, i) => _EventListRow(
                        event: events[i],
                        isHebrew: _isHebrew,
                        selected: _selectedPin == i,
                        saved: _saved.contains(i),
                        onSave: () => setState(() =>
                            _saved.contains(i) ? _saved.remove(i) : _saved.add(i)),
                        onTap: () => context.push('/event/demo_$i'),
                        onHover: (hovering) => setState(() {
                          if (hovering) {
                            _selectedPin = i;
                          } else if (_selectedPin == i) {
                            _selectedPin = null;
                          }
                        }),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(int count) {
    final headline = _category == 'all'
        ? _t('$count Events found', '$count אירועים נמצאו')
        : _t('$count $_categoryLabel Events found',
            '$count אירועי $_categoryLabel נמצאו');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(headline,
                  style: GoogleFonts.nunito(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      height: 34 / 28,
                      color: AppColors.midBlue)),
              const SizedBox(height: 8),
              Text(_t('in Modiin Maccabim Reut', 'במודיעין מכבים רעות'),
                  style: GoogleFonts.inter(fontSize: 14, color: _kSubtitle)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _buildSortBox(),
      ],
    );
  }

  Widget _buildSortBox() {
    return Container(
      width: 166,
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(_t('Sort by: Newest', 'מיון: חדש ביותר'),
                style: GoogleFonts.inter(fontSize: 14, color: Colors.black),
                overflow: TextOverflow.ellipsis),
          ),
          const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF4F4F4F)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(IconsaxPlusLinear.search_status,
                size: 48, color: _kCheckBorder.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              _t('No events match your filters', 'אין אירועים שתואמים את הסינון'),
              style: GoogleFonts.nunito(
                  fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.navy),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _t('Try clearing a filter or searching for something else.',
                  'נסו להסיר סינון או לחפש משהו אחר.'),
              style: GoogleFonts.inter(fontSize: 14, color: _kSubtitle),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MAP PANEL — 726px, purple event pins
  // ─────────────────────────────────────────────
  Widget _buildMapPanel() {
    final events = _events;
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 14.2,
        onTap: (_, _) => setState(() => _selectedPin = null),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.modiin4u.app',
        ),
        MarkerLayer(
          markers: List.generate(events.length, (i) {
            return Marker(
              point: events[i].position,
              width: 40,
              height: 44,
              alignment: Alignment.topCenter,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _selectedPin = i),
                onExit: (_) => setState(() {
                  if (_selectedPin == i) _selectedPin = null;
                }),
                child: GestureDetector(
                  onTap: () => context.push('/event/demo_$i'),
                  child: _MapPin(selected: _selectedPin == i),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// RESULT ROW — 851 × 203
// ═══════════════════════════════════════════════
class _EventListRow extends StatefulWidget {
  final _EventRow event;
  final bool isHebrew, selected, saved;
  final VoidCallback onSave, onTap;
  final ValueChanged<bool> onHover;
  const _EventListRow({
    required this.event,
    required this.isHebrew,
    required this.selected,
    required this.saved,
    required this.onSave,
    required this.onTap,
    required this.onHover,
  });

  @override
  State<_EventListRow> createState() => _EventListRowState();
}

class _EventListRowState extends State<_EventListRow> {
  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => widget.onHover(true),
      onExit: (_) => widget.onHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: widget.selected ? _kSidebarBg : Colors.transparent,
            border: const Border(bottom: BorderSide(color: _kBorder)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail 261 × 162 with date badge ──
              SizedBox(
                width: 261,
                height: 162,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _imagePlaceholder(e.imageBg,
                            radius: BorderRadius.zero, glyph: 30),
                      ),
                    ),
                    PositionedDirectional(
                      start: 8,
                      top: 8,
                      child: Container(
                        width: 52,
                        height: 57,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(e.month,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.midBlue,
                                    height: 15 / 12)),
                            const SizedBox(height: 4),
                            Text(e.day,
                                style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                    height: 22 / 18)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // ── Detail column ──
              Expanded(
                child: SizedBox(
                  height: 162,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.title,
                                    style: GoogleFonts.nunito(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.navy,
                                        height: 22 / 18),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 12),
                                _metaRow(IconsaxPlusLinear.clock, e.time,
                                    forceLtr: true),
                                const SizedBox(height: 12),
                                _metaRow(IconsaxPlusLinear.location, e.address),
                              ],
                            ),
                          ),
                          const SizedBox(width: 22),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: widget.onSave,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                    color: _kSaveBg, shape: BoxShape.circle),
                                child: Icon(
                                  widget.saved
                                      ? IconsaxPlusBold.archive_1
                                      : IconsaxPlusLinear.archive_1,
                                  size: 20,
                                  color: AppColors.midBlue,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 100,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(widget.isHebrew ? 'מחיר' : 'Price',
                                    style: GoogleFonts.inter(
                                        fontSize: 14, color: _kSubtitle, height: 17 / 14)),
                                const SizedBox(height: 4),
                                Text(e.price,
                                    style: GoogleFonts.nunito(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color: e.isFree ? AppColors.midBlue : AppColors.navy,
                                        height: 27 / 22)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 146,
                            child: Row(
                              children: [
                                const Icon(IconsaxPlusLinear.star_1,
                                    size: 14, color: AppColors.turquoise),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.isHebrew
                                        ? '${e.interested} מתעניינים'
                                        : '${e.interested} people interested',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.black,
                                        height: 15 / 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          _viewDetailButton(),
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

  Widget _metaRow(IconData icon, String text, {bool forceLtr = false}) {
    Widget label = Text(text,
        style: GoogleFonts.inter(fontSize: 12, color: _kTextDark, height: 15 / 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis);
    // Clock ranges stay left-to-right even in the Hebrew layout.
    if (forceLtr) {
      label = Align(
        alignment: AlignmentDirectional.centerStart,
        child: Directionality(textDirection: TextDirection.ltr, child: label),
      );
    }
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.turquoise),
        const SizedBox(width: 8),
        Expanded(child: label),
      ],
    );
  }

  Widget _viewDetailButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.midBlue),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(IconsaxPlusLinear.export_3, size: 16, color: AppColors.midBlue),
              const SizedBox(width: 8),
              Text(widget.isHebrew ? 'לפרטים' : 'View Detail',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.midBlue)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// MAP PIN — Ellipse 521 · #9032E1
// ═══════════════════════════════════════════════
class _MapPin extends StatelessWidget {
  final bool selected;
  const _MapPin({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 150),
      scale: selected ? 1.15 : 1.0,
      child: SizedBox(
        width: 40,
        height: 44,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            const Icon(
              IconsaxPlusBold.location,
              size: 40,
              color: Colors.white,
              shadows: [
                Shadow(color: Color(0x40000000), blurRadius: 2.29, offset: Offset(0, 2.29)),
              ],
            ),
            Positioned(
              top: 5.8,
              child: Container(
                width: 21.4,
                height: 21.4,
                decoration: const BoxDecoration(color: _kPinPurple, shape: BoxShape.circle),
                child: const Center(
                  child: Icon(IconsaxPlusLinear.calendar, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════

class _NavItem {
  final String label, route;
  final bool hasDropdown, isActive;
  const _NavItem({required this.label, required this.route, this.hasDropdown = false, this.isActive = false});
}

class _Option {
  final String key, label;
  final int count;
  const _Option(this.key, this.label, this.count);
}

class _EventRow {
  final String month, day, category, title, time, address, price;
  final int interested;
  final LatLng position;
  final Color imageBg;
  const _EventRow({
    required this.month,
    required this.day,
    required this.category,
    required this.title,
    required this.time,
    required this.address,
    required this.price,
    required this.interested,
    required this.position,
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

class _NavLinkButton extends StatefulWidget {
  final String label;
  final bool isActive, hasDropdown;
  final VoidCallback onTap;
  const _NavLinkButton({required this.label, this.isActive = false, this.hasDropdown = false, required this.onTap});

  @override
  State<_NavLinkButton> createState() => _NavLinkButtonState();
}

class _NavLinkButtonState extends State<_NavLinkButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(
              color: widget.isActive ? AppColors.midBlue : Colors.transparent,
              width: 3,
            )),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              decoration: BoxDecoration(
                color: _hovered && !widget.isActive ? Colors.black.withValues(alpha: 0.04) : Colors.transparent,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                        color: widget.isActive ? AppColors.midBlue : const Color(0xFF0F161E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.hasDropdown) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF21272A)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
