import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../providers/banners_provider.dart';
import '../providers/nav_categories_provider.dart';

/// How the city office is reached. These were already published in the
/// footer as plain text; they are named here so the header's "Contact Us"
/// leads somewhere rather than nowhere, and so a change lands in one place.
const kContactPhone = '058-4770195';
const kContactEmail = 'modiin4uoffice@gmail.com';

/// The same number in international form, which is what wa.me expects.
const kContactWhatsApp = '972584770195';

/// The accounts the client's current site links to, copied from its footer.
/// The design draws YouTube and LinkedIn as well; the client has neither, and
/// a round button that goes nowhere is worse than no button.
const _kFacebookUrl = 'https://www.facebook.com/profile.php?id=61557667173369';
const _kInstagramUrl = 'https://www.instagram.com/modiin4u';
const _kTikTokUrl = 'https://www.tiktok.com/@modiin4u';

/// The language the website was last switched to.
///
/// Every page keeps its own `_isHebrew`, and every one of them started at
/// false — so switching to Hebrew lasted exactly until the next click, and
/// the page after it came up in English again. Pages start from this now,
/// and the navbar's toggle writes it.
final webIsHebrew = ValueNotifier<bool>(false);

const _kWebLanguageKey = 'web_is_hebrew';

/// Keeps a page in the language the navbar was last switched to.
///
/// Each page used to copy [webIsHebrew] when it opened and flip its own copy
/// on the switch, so the page underneath — the list a reader comes Back to —
/// stayed in the language it was opened in. A page with this mixin reads the
/// shared value and draws again whenever it changes, wherever it was changed.
mixin WebLanguageState<T extends StatefulWidget> on State<T> {
  void _languageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    webIsHebrew.addListener(_languageChanged);
  }

  @override
  void dispose() {
    webIsHebrew.removeListener(_languageChanged);
    super.dispose();
  }
}


/// Reads the language the browser was last left in, before the first page
/// draws, and keeps it written down from then on — so a reload, or a link
/// opened in a new tab, comes up in the language the reader chose.
///
/// True when the reader had chosen one, false when the site is on its default.
Future<bool> restoreWebLanguage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_kWebLanguageKey);
    webIsHebrew.value = saved ?? false;
    webIsHebrew.addListener(() => prefs.setBool(_kWebLanguageKey, webIsHebrew.value));
    return saved != null;
  } catch (_) {
    // Storage the browser will not open leaves the site in English.
    return false;
  }
}

// ═══════════════════════════════════════════════════════════
// Shared desktop chrome — the navbar and the footer that every
// web_*_screen.dart page wraps its content in.
//
// Both used to be copy-pasted per page, which meant a phone number
// or a nav link changed in one place and drifted in nine others.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kInk = Color(0xFF0F161E);

/// What opens under a nav link.
enum WebNavMenu {
  /// A link that simply goes somewhere.
  none,

  /// The design's "News Menu": a short card of names.
  news,

  /// The client's site's mega menu: columns of names beside photographs.
  businesses,
  professionals,
}

/// One top-level nav link. [id] is what a page passes as `activeId` to
/// underline itself — routes can't do that job because '/businesses'
/// backs two different links.
class WebNavItem {
  final String id, label, route;
  final WebNavMenu menu;

  bool get hasDropdown => menu != WebNavMenu.none;

  const WebNavItem({
    required this.id,
    required this.label,
    required this.route,
    this.menu = WebNavMenu.none,
  });
}

/// The nav links, in reading order from the logo.
///
/// The design lays the bar out the way a Hebrew site reads: the logo on the
/// right, "Businesses in Modiin" beside it, "Contact Us" at the far left —
/// and it keeps that layout with English labels on it. So the bar is always
/// built right to left and this list starts at the logo.
///
/// [short] drops the "in Modiin" that three of them carry. The full labels
/// are drawn at 1920, which the design is laid out for; below roughly 1700
/// the seven of them stop fitting and every label ellipsises at once — the
/// bar read "Profess…  Modiin …  Real Estat…  Restauran…  Busine…" on a
/// 1440 laptop. The whole site is Modiin, so the shorter forms lose nothing.
List<WebNavItem> webNavItems(bool isHebrew, {bool short = false}) {
  String t(String en, String he) => isHebrew ? he : en;
  String place(String en, String he) =>
      short ? t(en, he) : t('$en in Modiin', '$he במודיעין');

  return [
    WebNavItem(
      id: 'businesses',
      label: place('Businesses', 'עסקים'),
      route: '/businesses',
      menu: WebNavMenu.businesses,
    ),
    WebNavItem(id: 'restaurants', label: place('Restaurants', 'מסעדות'), route: '/restaurants'),
    WebNavItem(id: 'realestate', label: place('Real Estate', 'נדל״ן'), route: '/realestate'),
    WebNavItem(id: 'deals', label: t('Deals', 'מבצעים'), route: '/deals'),
    WebNavItem(id: 'events', label: t('Events', 'אירועים'), route: '/events'),
    WebNavItem(
      id: 'news',
      label: t('Modiin News', 'חדשות מודיעין'),
      route: '/news',
      menu: WebNavMenu.news,
    ),
    WebNavItem(
      id: 'professionals',
      label: t('Professionals', 'בעלי מקצוע'),
      // Professionals are the businesses filed under Services; the page
      // reads a category's slug as well as its id.
      route: '/businesses/category/services',
      menu: WebNavMenu.professionals,
    ),
  ];
}

/// The space at each side of a web page.
///
/// The design is drawn at 1920: a 1600 column with 160 either side. Below
/// that width the gap used to drop straight to 24 — on a 1440 or 1600
/// laptop the navbar, the cards and the footer all ran nearly to the edge of
/// the window, and the page read as cut off. The column still takes all the
/// room it can, but the gap never falls below about four and a half per cent
/// of the window: 65 at 1440, 72 at 1600, 80 from 1780, and the design's 160
/// at 1920. Every page's sections, the navbar and the footer take it from
/// here, so they line up with one another at any width.
double webGutter(double width) =>
    math.max((width - 1600) / 2, (width * 0.045).clamp(24.0, 80.0));

/// The page's content column: 1600 wide at most, [webGutter] either side.
class WebSection extends StatelessWidget {
  final Widget child;
  const WebSection({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: webGutter(MediaQuery.sizeOf(context).width)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          // The column takes the full width it is given, rather than
          // shrink-wrapping its child.
          //
          // `Center` passes loose constraints down, so a section whose
          // content is only text collapsed to the width of that text and
          // sat in the middle of the window. It looked right on every
          // existing page purely because each of them happens to contain a
          // Row with an Expanded in it. Two people building new sections hit
          // this on the same afternoon, which is one more than it deserves.
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

/// The brand mark, in the design's Mid blue.
Widget _logo(BuildContext context, {double width = 90, double height = 48}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: () => context.go('/'),
      child: SvgPicture.asset(
        'assets/images/logo_white.svg',
        width: width,
        height: height,
        colorFilter: const ColorFilter.mode(AppColors.midBlue, BlendMode.srcIn),
      ),
    ),
  );
}

/// The design has no language switch; the site has two languages. It sits
/// beside "Contact Us", small, so the rest of the bar keeps its places.
class _LanguageToggle extends StatelessWidget {
  final bool isHebrew;
  final VoidCallback? onTap;
  const _LanguageToggle({required this.isHebrew, this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          webIsHebrew.value = !isHebrew;
          onTap?.call();
        },
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(60),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(IconsaxPlusLinear.global, size: 16, color: AppColors.midBlue),
                const SizedBox(width: 6),
                Text(
                  isHebrew ? 'EN' : 'עב',
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.midBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
/// The header an auth page wears instead of the site's navigation.
///
/// Sign-in, sign-up and "choose a new password" each carried the full navbar
/// — seven links, three category menus and a "Contact Us" button — above a
/// single card asking for an e-mail address. On the way to the control centre
/// it read as the wrong screen entirely: a person who asked for the admin
/// panel was handed what looked like the front page of the public site.
///
/// The logo stays, and leads back to the site, so there is a way out and the
/// page still says whose it is.
class WebAuthHeader extends StatelessWidget {
  final bool isHebrew;
  /// Anything a page wants done besides — the language itself is
  /// [webIsHebrew], which the switch sets and every page follows.
  final VoidCallback? onToggleLanguage;

  const WebAuthHeader({
    super.key,
    required this.isHebrew,
    this.onToggleLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final gutter = webGutter(c.maxWidth);
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            // Laid out as the navbar is: the logo on the right.
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  _logo(context),
                  const Spacer(),
                  _LanguageToggle(isHebrew: isHebrew, onTap: onToggleLanguage),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NAVBAR — Figma "Header/07"
//
// Two forms of one bar. Inner pages: 1920 wide, white, a hairline under it,
// the current page's link underlined. The home page: a 1600 pill floating
// 32px down over the hero.
// ─────────────────────────────────────────────
class WebNavbar extends ConsumerStatefulWidget {
  /// Which [WebNavItem.id] to underline, or null on pages that aren't in the nav.
  final String? activeId;
  final bool isHebrew;
  /// Anything a page wants done besides — the language itself is
  /// [webIsHebrew], which the switch sets and every page follows.
  final VoidCallback? onToggleLanguage;
  final VoidCallback? onContactTap;

  /// The home page's pill, rather than the full-width bar.
  final bool floating;

  const WebNavbar({
    super.key,
    required this.isHebrew,
    this.onToggleLanguage,
    this.activeId,
    this.onContactTap,
    this.floating = false,
  });

  @override
  ConsumerState<WebNavbar> createState() => _WebNavbarState();
}

class _WebNavbarState extends ConsumerState<WebNavbar> {
  @override
  void initState() {
    super.initState();
    // The two menus' lists start loading with the bar, so the first hover
    // finds them ready; they took a second or two, and the Professionals
    // menu opened empty until they came.
    ref.read(navCategoriesProvider('business'));
    ref.read(navProfessionalsProvider);
  }

  /// The one menu that is open, and where on screen its link sits.
  ///
  /// The bar owns this rather than each link owning its own. When every link
  /// had its own menu, running the pointer along the row opened all three and
  /// left them stacked on top of one another. One panel, one owner.
  ///
  /// It is drawn through an [OverlayPortal] because the bar is the first
  /// child of the page's Column: anything it paints itself is painted over by
  /// the content below it, so the menu came out sliced off at the bar's edge.
  final _portal = OverlayPortalController();
  WebNavItem? _open;
  Rect _anchor = Rect.zero;

  /// Leaving the bar should close the menu, but moving *into* the menu leaves
  /// the bar too. So a close is scheduled and cancelled if the pointer turns
  /// up in either place a moment later.
  Timer? _closing;

  @override
  void dispose() {
    _closing?.cancel();
    super.dispose();
  }

  void _openFor(WebNavItem item, BuildContext itemContext) {
    final box = itemContext.findRenderObject() as RenderBox?;
    if (box == null) return;
    _closing?.cancel();
    final topLeft = box.localToGlobal(Offset.zero);
    setState(() {
      _open = item;
      _anchor = topLeft & box.size;
    });
    if (!_portal.isShowing) _portal.show();
  }

  void _scheduleClose() {
    _closing?.cancel();
    _closing = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(() => _open = null);
      _portal.hide();
    });
  }

  void _closeNow() {
    _closing?.cancel();
    if (_open != null || _portal.isShowing) {
      setState(() => _open = null);
      _portal.hide();
    }
  }

  bool get isHebrew => widget.isHebrew;

  void _go(String route) {
    _closeNow();
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _menu,
      child: MouseRegion(
        onExit: (_) => _scheduleClose(),
        child: LayoutBuilder(
          builder: (context, constraints) => widget.floating
              ? _pill(context, constraints.maxWidth)
              : _bar(context, constraints.maxWidth),
        ),
      ),
    );
  }

  Widget _menu(BuildContext overlayContext) {
    final item = _open;
    if (item == null) return const SizedBox.shrink();
    final screen = MediaQuery.sizeOf(overlayContext).width;

    final Widget panel;
    double left;
    switch (item.menu) {
      case WebNavMenu.news:
        panel = _NewsMenu(isHebrew: isHebrew, onPick: _go);
        // Under its own link, lined up with the link's reading edge.
        left = isHebrew ? _anchor.right - _NewsMenu.width : _anchor.left;
      case WebNavMenu.businesses:
      case WebNavMenu.professionals:
        final width = math.min(_MegaMenu.maxWidth, screen - 48);
        panel = _MegaMenu(
          width: width,
          kind: item.menu,
          isHebrew: isHebrew,
          onPick: _go,
        );
        // The client's site centres its mega menus on the page.
        left = (screen - width) / 2;
      case WebNavMenu.none:
        return const SizedBox.shrink();
    }
    left = left.clamp(12.0, math.max(12.0, screen - 12.0));

    return Positioned(
      left: left,
      top: _anchor.bottom,
      child: MouseRegion(
        onEnter: (_) => _closing?.cancel(),
        onExit: (_) => _scheduleClose(),
        // A few pixels of air the pointer crosses without closing anything.
        child: Padding(
          padding: EdgeInsets.only(top: widget.floating ? 12 : 0),
          child: panel,
        ),
      ),
    );
  }

  /// The links, from the logo outwards. In the pill the design packs them
  /// 16 apart; in the bar, 20.
  Widget _links(double width) {
    final items = webNavItems(isHebrew, short: width < 1700);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: widget.floating ? 16 : 20),
          Builder(
            builder: (itemContext) {
              final item = items[i];
              return _NavLinkButton(
                label: item.label,
                isHebrew: isHebrew,
                isActive: !widget.floating && item.id == widget.activeId,
                height: widget.floating ? 78 : 80,
                hasDropdown: item.hasDropdown,
                onHover: item.hasDropdown ? () => _openFor(item, itemContext) : _closeNow,
                onTap: () => _go(item.route),
              );
            },
          ),
        ],
      ],
    );
  }

  /// Contact Us at the far left, the language switch beside it.
  Widget _contact() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LanguageToggle(isHebrew: isHebrew, onTap: widget.onToggleLanguage),
        const SizedBox(width: 12),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            // It read "Contact Us" and did nothing. The address below is
            // the one the footer has always published.
            onTap: widget.onContactTap ??
                () => launchUrl(Uri(scheme: 'mailto', path: kContactEmail)),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.midBlue,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Text(
                isHebrew ? 'צור קשר' : 'Contact Us',
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Logo — links — contact, spread across the bar with the links centred in
  /// what is left. On a window too narrow for all seven at full size they
  /// shrink a little to fit, rather than running off under the logo.
  Widget _row(double width) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          _logo(context),
          const SizedBox(width: 20),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _links(width),
              ),
            ),
          ),
          const SizedBox(width: 20),
          _contact(),
        ],
      ),
    );
  }

  /// The bar's links line up with the page's content column: [webGutter]
  /// either side, the design's 160 at 1920.
  Widget _bar(BuildContext context, double width) {
    final gutter = webGutter(width);
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      padding: EdgeInsets.symmetric(horizontal: gutter),
      child: _row(width),
    );
  }

  Widget _pill(BuildContext context, double width) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1600),
        margin: EdgeInsets.symmetric(horizontal: webGutter(width)),
        height: 80,
        padding: const EdgeInsets.only(left: 20, right: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          // The design floats it over the dark hero, where no shadow shows.
          // Kept faint for when the page has scrolled white under it.
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _row(width),
      ),
    );
  }
}

class _NavLinkButton extends StatefulWidget {
  final String label;
  final bool isHebrew;
  final bool isActive;
  final bool hasDropdown;
  final double height;
  final VoidCallback onHover;
  final VoidCallback onTap;

  const _NavLinkButton({
    required this.label,
    required this.isHebrew,
    required this.isActive,
    required this.hasDropdown,
    required this.height,
    required this.onHover,
    required this.onTap,
  });

  @override
  State<_NavLinkButton> createState() => _NavLinkButtonState();
}

class _NavLinkButtonState extends State<_NavLinkButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? AppColors.midBlue : _kInk;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        widget.onHover();
      },
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: widget.isActive ? AppColors.midBlue : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: _hovered && !widget.isActive
                  ? Colors.black.withValues(alpha: 0.04)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(40),
            ),
            // Each label reads in its own language: the chevron follows an
            // English word and precedes a Hebrew one.
            child: Directionality(
              textDirection: widget.isHebrew ? TextDirection.rtl : TextDirection.ltr,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 15,
                      height: 1.6,
                      fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                      color: color,
                    ),
                    maxLines: 1,
                  ),
                  if (widget.hasDropdown) ...[
                    const SizedBox(width: 8),
                    SvgPicture.asset(
                      'assets/icons/chevron_down.svg',
                      width: 18,
                      height: 18,
                      colorFilter: widget.isActive
                          ? const ColorFilter.mode(AppColors.midBlue, BlendMode.srcIn)
                          : null,
                    ),
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

/// A white card with the design's menu shadow.
BoxDecoration _menuCard() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 5,
      offset: const Offset(0, 1),
    ),
  ],
);

/// One name in a menu: Inter 14, black, and the brand blue under the pointer.
class _MenuEntry extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _MenuEntry({required this.label, required this.onTap});

  @override
  State<_MenuEntry> createState() => _MenuEntryState();
}

class _MenuEntryState extends State<_MenuEntry> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Text(
          widget.label,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            color: _hovered ? AppColors.midBlue : Colors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// The design's "News Menu": 264 wide, 16 in, a name every 20.
///
/// Only categories with articles in them — five of the article categories
/// are left over from an early guess at the taxonomy and hold nothing.
class _NewsMenu extends ConsumerWidget {
  static const width = 264.0;

  final bool isHebrew;
  final void Function(String route) onPick;
  const _NewsMenu({required this.isHebrew, required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(navCategoriesProvider('article')).valueOrNull ?? const <NavCategory>[];
    if (list.isEmpty) return const SizedBox.shrink();

    // The names are the categories' own, in Hebrew, whichever language the
    // page is in — so the card reads right to left, as the client's does.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: width,
          padding: const EdgeInsets.all(16),
          decoration: _menuCard(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < list.length; i++) ...[
                if (i > 0) const SizedBox(height: 20),
                _MenuEntry(
                  label: list[i].name,
                  onTap: () => onPick('/news/category/${list[i].id}'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The Businesses and Professionals menus.
///
/// Shaped after the client's current site, which the design does not draw:
/// a wide card centred on the page, the names in columns, and beside them
/// photographs of paying businesses fading one into the next. The names come
/// from the directory; the photographs come from campaigns booked for the
/// menu in the control centre, and the column of them is simply not there
/// until one is.
class _MegaMenu extends ConsumerWidget {
  static const maxWidth = 1130.0;

  final double width;
  final WebNavMenu kind;
  final bool isHebrew;
  final void Function(String route) onPick;

  const _MegaMenu({
    required this.width,
    required this.kind,
    required this.isHebrew,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBusinesses = kind == WebNavMenu.businesses;
    final entries = (isBusinesses
                ? ref.watch(navCategoriesProvider('business'))
                : ref.watch(navProfessionalsProvider))
            .valueOrNull ??
        const <NavCategory>[];
    if (entries.isEmpty) return const SizedBox.shrink();

    String route(NavCategory c) =>
        isBusinesses ? '/businesses/category/${c.id}' : '/business/${c.id}';

    final banners = ref
            .watch(activeBannersProvider(isBusinesses ? 'MENU_BUSINESSES' : 'MENU_PROFESSIONALS'))
            .valueOrNull ??
        const <SiteBanner>[];

    // Three columns of businesses, two of professionals, as on the client's
    // site; filled down, then across.
    final columns = isBusinesses ? 3 : 2;
    final perColumn = (entries.length / columns).ceil();
    final chunks = <List<NavCategory>>[
      for (var i = 0; i < entries.length; i += perColumn)
        entries.sublist(i, math.min(i + perColumn, entries.length)),
    ];

    // The businesses menu has one photograph; professionals, two side by side.
    final slides = isBusinesses ? 1 : 2;

    // Hebrew names, so right to left in either language: the first column
    // on the right and the photographs at the far end, as on the client's
    // site.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: width,
          padding: const EdgeInsets.all(32),
          decoration: _menuCard(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final chunk in chunks) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < chunk.length; i++) ...[
                        if (i > 0) const SizedBox(height: 20),
                        _MenuEntry(label: chunk[i].name, onTap: () => onPick(route(chunk[i]))),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 24),
              ],
              if (banners.isNotEmpty)
                for (var s = 0; s < slides; s++) ...[
                  if (s > 0) const SizedBox(width: 20),
                  SizedBox(
                    width: 276,
                    height: 308,
                    child: _BannerSlideshow(
                      // Two panels take turns through the same campaigns,
                      // starting half a round apart.
                      banners: [...banners.skip(s), ...banners.take(s)],
                    ),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Photographs fading one into the next — two seconds of fade, five on each,
/// the timing the client's site uses. A tap follows the campaign's link.
class _BannerSlideshow extends StatefulWidget {
  final List<SiteBanner> banners;
  const _BannerSlideshow({required this.banners});

  @override
  State<_BannerSlideshow> createState() => _BannerSlideshowState();
}

class _BannerSlideshowState extends State<_BannerSlideshow> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) setState(() => _index = (_index + 1) % widget.banners.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = widget.banners[_index % widget.banners.length];
    final link = banner.destinationUrl;
    return MouseRegion(
      cursor: link == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: link == null ? null : () => launchUrl(Uri.parse(link)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AnimatedSwitcher(
            duration: const Duration(seconds: 2),
            child: Image.network(
              banner.imageUrl,
              key: ValueKey(banner.id),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFFF3F5F8)),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FOOTER — Figma "Frame 1171276559", 1920 × 632
// ─────────────────────────────────────────────
class WebFooter extends StatelessWidget {
  final bool isHebrew;
  const WebFooter({super.key, required this.isHebrew});

  String _t(String en, String he) => isHebrew ? he : en;

  static const _white = Colors.white;

  TextStyle _heading() => TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w600, color: _white);
  TextStyle _link() => TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _white);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.midBlue,
      padding: const EdgeInsets.only(top: 64),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1600),
          margin: EdgeInsets.symmetric(horizontal: webGutter(MediaQuery.sizeOf(context).width)),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  // The design's columns sit at fixed places across 1600;
                  // the gaps between them give way first as the window
                  // narrows, and below that the blocks stack.
                  if (constraints.maxWidth >= 1250) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 321, child: _buildContact(context)),
                        const Spacer(flex: 95),
                        SizedBox(
                          width: 171,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLinks(context, _t('Modiin4u', 'מודיעין4u'), _companyLinks, viewAll: false),
                              const SizedBox(height: 47),
                              _buildApps(),
                            ],
                          ),
                        ),
                        const Spacer(flex: 121),
                        SizedBox(width: 171, child: _buildLinks(context, _t('Explore Modiin', 'גלו את מודיעין'), _exploreLinks)),
                        const Spacer(flex: 121),
                        SizedBox(width: 171, child: _buildLinks(context, _t('Popular Categories', 'קטגוריות פופולריות'), _categoryLinks)),
                        const Spacer(flex: 100),
                        SizedBox(width: 328, child: _buildAbout(context)),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContact(context),
                      const SizedBox(height: 40),
                      Wrap(
                        spacing: 48,
                        runSpacing: 40,
                        children: [
                          SizedBox(width: 171, child: _buildLinks(context, _t('Modiin4u', 'מודיעין4u'), _companyLinks, viewAll: false)),
                          SizedBox(width: 171, child: _buildLinks(context, _t('Explore Modiin', 'גלו את מודיעין'), _exploreLinks)),
                          SizedBox(width: 171, child: _buildLinks(context, _t('Popular Categories', 'קטגוריות פופולריות'), _categoryLinks)),
                          SizedBox(width: 171, child: _buildApps()),
                        ],
                      ),
                      const SizedBox(height: 40),
                      _buildAbout(context),
                    ],
                  );
                },
              ),
              const SizedBox(height: 60),
              // Bottom bar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_t('All Rights Reserved to modiin4u.co.il, 2026', 'כל הזכויות שמורות ל-modiin4u.co.il, 2026'),
                        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kBorder)),
                    Row(
                      children: [
                        _FooterLink(
                          label: _t('Terms of Use', 'תנאי שימוש'),
                          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kBorder),
                          onTap: () => context.go('/terms'),
                        ),
                        Text('  |  ', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kBorder)),
                        _FooterLink(
                          label: _t('Privacy Policy', 'מדיניות פרטיות'),
                          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kBorder),
                          onTap: () => context.go('/terms'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Powered by PersonaAI — always LTR, it's an English brand phrase.
              Directionality(
                textDirection: TextDirection.ltr,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => launchUrl(Uri.parse('https://personaai.me/')),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Powered by ', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                          ).createShader(bounds),
                          child: Text('PersonaAI',
                              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Every entry leads somewhere now. They were plain Text: fourteen links
  /// in a footer, and not one of them could be clicked.
  List<(String, String)> get _companyLinks => [
    (_t('Home', 'בית'), '/'),
    (_t('About Us', 'אודותינו'), '/about'),
    (_t('Contact Us', 'צור קשר'), 'mailto:$kContactEmail'),
    (_t('Privacy Policy', 'מדיניות פרטיות'), '/terms'),
    (_t('Terms of Use', 'תנאי שימוש'), '/terms'),
    (_t('Accessibility Statement', 'הצהרת נגישות'), '/accessibility'),
  ];

  List<(String, String)> get _exploreLinks => [
    (_t('News', 'חדשות'), '/news'),
    (_t('Events', 'אירועים'), '/events'),
    (_t('Businesses', 'עסקים'), '/businesses'),
    (_t('Professionals', 'בעלי מקצוע'), '/businesses/category/services'),
    (_t('Real Estate', 'נדל״ן'), '/realestate'),
    (_t('Map', 'מפה'), '/map'),
    (_t('Restaurants', 'מסעדות'), '/restaurants'),
    (_t('Deals', 'מבצעים'), '/deals'),
    (_t('Community', 'קהילה'), '/community'),
  ];

  List<(String, String)> get _categoryLinks => [
    (_t('Restaurants in Modiin', 'מסעדות במודיעין'), '/restaurants'),
    (_t('Coffee Shops', 'בתי קפה'), '/restaurants-map?cuisine=cafe-bakery'),
    (_t('Bars', 'ברים'), '/restaurants-map?cuisine=bars'),
    (_t('Professionals', 'בעלי מקצוע'), '/businesses/category/services'),
    (_t('Real Estate', 'נדל״ן'), '/realestate'),
    (_t('Local Businesses', 'עסקים מקומיים'), '/businesses'),
    (_t('Events', 'אירועים'), '/events'),
    (_t('News', 'חדשות'), '/news'),
  ];

  void _follow(BuildContext context, String target) {
    if (target.startsWith('mailto:')) {
      launchUrl(Uri.parse(target));
    } else {
      context.go(target);
    }
  }

  Widget _buildContact(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('We are here for any questions.', 'אנחנו כאן לכל שאלה.'),
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 32, fontWeight: FontWeight.w500, color: _white, height: 1.21)),
        const SizedBox(height: 40),
        _FooterContactRow(
          icon: Stack(
            alignment: Alignment.center,
            children: [
              SvgPicture.asset('assets/icons/footer/ring40.svg', width: 40, height: 40),
              SvgPicture.asset('assets/icons/footer/phone_glyph.svg', width: 16.6, height: 16.7),
            ],
          ),
          label: _t('Phone', 'טלפון'),
          value: kContactPhone,
          uri: Uri(scheme: 'tel', path: kContactPhone),
        ),
        const SizedBox(height: 34),
        _FooterContactRow(
          icon: SvgPicture.asset('assets/icons/footer/email40.svg', width: 40, height: 40),
          label: _t('Email', 'אימייל'),
          value: kContactEmail,
          uri: Uri(scheme: 'mailto', path: kContactEmail),
        ),
        const SizedBox(height: 34),
        _FooterContactRow(
          icon: SvgPicture.asset('assets/icons/footer/whatsapp40.svg', width: 40, height: 40),
          label: _t('WhatsApp', 'וואטסאפ'),
          value: kContactPhone,
          uri: Uri.parse('https://wa.me/$kContactWhatsApp'),
        ),
        const SizedBox(height: 40),
        Text(_t('Our Socials', 'הרשתות שלנו'), style: _heading()),
        const SizedBox(height: 19),
        Row(
          children: [
            _SocialButton(
              uri: _kFacebookUrl,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SvgPicture.asset('assets/icons/footer/ring38.svg', width: 38, height: 38),
                  SvgPicture.asset('assets/icons/footer/facebook_glyph.svg', width: 8.3, height: 16),
                ],
              ),
            ),
            _SocialButton(
              uri: _kInstagramUrl,
              child: SvgPicture.asset('assets/icons/footer/instagram38.svg', width: 38, height: 38),
            ),
            _SocialButton(
              uri: _kTikTokUrl,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SvgPicture.asset('assets/icons/footer/ring38.svg', width: 38, height: 38),
                  const Icon(IconsaxPlusLinear.music, size: 16, color: _white),
                ],
              ),
            ),
            _SocialButton(
              uri: 'https://wa.me/$kContactWhatsApp',
              child: SvgPicture.asset('assets/icons/footer/whatsapp38.svg', width: 38, height: 38),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLinks(BuildContext context, String title, List<(String, String)> links, {bool viewAll = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _heading()),
        const SizedBox(height: 24),
        for (var i = 0; i < links.length; i++) ...[
          if (i > 0) const SizedBox(height: 20),
          _FooterLink(label: links[i].$1, style: _link(), onTap: () => _follow(context, links[i].$2)),
        ],
        if (viewAll) ...[
          const SizedBox(height: 20),
          _MoreLink(
            label: _t('View all', 'הצג הכל'),
            isHebrew: isHebrew,
            onTap: () => context.go('/businesses'),
          ),
        ],
      ],
    );
  }

  /// White store badges, 120 × 40, as drawn. The app is not in either store
  /// yet, so they are pictures of where it will be rather than links.
  Widget _buildApps() {
    Widget badge({required Widget glyph, required Widget content}) {
      return Container(
        width: 120,
        height: 40,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              const SizedBox(width: 8),
              glyph,
              const SizedBox(width: 8),
              content,
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('Download Our App', 'הורידו את האפליקציה'), style: _heading()),
        const SizedBox(height: 20),
        badge(
          glyph: SvgPicture.asset('assets/icons/footer/apple.svg', width: 20, height: 24),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Download on the', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 9, height: 1, fontWeight: FontWeight.w500, color: Colors.black)),
              Text('App Store', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 17, height: 1.05, fontWeight: FontWeight.w600, letterSpacing: -0.47, color: Colors.black)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        badge(
          glyph: SvgPicture.asset('assets/icons/footer/playstore.svg', width: 21, height: 24),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GET IT ON', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 9, height: 1, color: Colors.black)),
              const SizedBox(height: 3),
              // The wordmark is stored upside down and drawn flipped, as the
              // design does it.
              Transform.flip(
                flipY: true,
                child: SvgPicture.asset('assets/icons/footer/google_play_word.svg', width: 74, height: 15),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The logo, the name, the paragraph and "Read more", flush to the far
  /// edge. The design prints the paragraph twice, one under the other — a
  /// placeholder repeated, not a second paragraph — so it is printed once.
  Widget _buildAbout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SvgPicture.asset('assets/images/logo_white.svg', width: 164, height: 88),
        const SizedBox(height: 23),
        Text(_t('Modiin for You', 'מודיעין בשבילך'),
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: _white),
            textAlign: TextAlign.end),
        const SizedBox(height: 16),
        Text(
          _t('We are not just a news site – we are the beating heart of Modiin! A local media and public relations organization that lives and breathes our city. With a wide range of digital platforms, connected directly to residents, we bring you everything that really matters.',
             'אנחנו לא סתם אתר חדשות – אנחנו הלב הפועם של מודיעין! ארגון מדיה ויחסי ציבור מקומי שחי ונושם את העיר שלנו. עם מגוון רחב של פלטפורמות דיגיטליות, בחיבור ישיר לתושבים, אנחנו מביאים לכם את כל מה שבאמת חשוב.'),
          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: _white, height: 1.4),
          textAlign: TextAlign.end,
        ),
        const SizedBox(height: 24),
        _MoreLink(label: _t('Read more', 'קראו עוד'), isHebrew: isHebrew, onTap: () => context.go('/about')),
      ],
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String label;
  final TextStyle style;
  final VoidCallback onTap;
  const _FooterLink({required this.label, required this.style, required this.onTap});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: widget.style.copyWith(
            decoration: _hovered ? TextDecoration.underline : null,
            decorationColor: widget.style.color,
          ),
        ),
      ),
    );
  }
}

/// "View all →" / "Read more →" in turquoise, with the design's arrow.
class _MoreLink extends StatelessWidget {
  final String label;
  final bool isHebrew;
  final VoidCallback onTap;
  const _MoreLink({required this.label, required this.isHebrew, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.turquoise)),
            const SizedBox(width: 8),
            // The arrow points the way the text reads.
            Transform.flip(
              flipX: isHebrew,
              child: SvgPicture.asset('assets/icons/footer/arrow_right.svg', width: 16, height: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String uri;
  final Widget child;
  const _SocialButton({required this.uri, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 9),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => launchUrl(Uri.parse(uri)),
          child: SizedBox(width: 38, height: 38, child: child),
        ),
      ),
    );
  }
}

class _FooterContactRow extends StatelessWidget {
  final Widget icon;
  final String label, value;

  /// Where tapping it goes. These were printed for people to copy by hand.
  final Uri uri;

  const _FooterContactRow({required this.icon, required this.label, required this.value, required this.uri});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => launchUrl(uri),
        child: Row(
          children: [
            SizedBox(width: 40, height: 40, child: icon),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(value,
                      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: Colors.white),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
