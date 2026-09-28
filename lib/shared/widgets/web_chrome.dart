import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../providers/nav_categories_provider.dart';

/// How the city office is reached. These were already published in the
/// footer as plain text; they are named here so the header's "Contact Us"
/// leads somewhere rather than nowhere, and so a change lands in one place.
const kContactPhone = '058-4770195';
const kContactEmail = 'modiin4uoffice@gmail.com';

/// The same number in international form, which is what wa.me expects.
const kContactWhatsApp = '972584770195';

// ═══════════════════════════════════════════════════════════
// Shared desktop chrome — the sticky navbar and the footer that
// every web_*_screen.dart page wraps its content in.
//
// Both used to be copy-pasted per page, which meant a phone number
// or a nav link changed in one place and drifted in nine others.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);

/// One top-level nav link. [id] is what a page passes as `activeId` to
/// underline itself — routes can't do that job because '/businesses'
/// backs two different links.
class WebNavItem {
  final String id, label, route;

  /// The category scope this link's menu lists — 'article' or 'business'.
  /// Null for a link that simply goes somewhere.
  final String? menuScope;

  /// Where a menu entry leads, given a category id.
  final String Function(String categoryId)? menuRoute;

  bool get hasDropdown => menuScope != null;

  const WebNavItem({
    required this.id,
    required this.label,
    required this.route,
    this.menuScope,
    this.menuRoute,
  });
}

/// The canonical nav, in display order.
/// The nav links.
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
      id: 'professionals',
      label: t('Professionals', 'בעלי מקצוע'),
      route: '/businesses',
      menuScope: 'business',
      menuRoute: (id) => '/businesses/category/$id',
    ),
    WebNavItem(
      id: 'news',
      label: t('Modiin News', 'חדשות מודיעין'),
      route: '/news',
      menuScope: 'article',
      menuRoute: (id) => '/news/category/$id',
    ),
    WebNavItem(id: 'events', label: t('Events', 'אירועים'), route: '/events'),
    WebNavItem(id: 'deals', label: t('Deals', 'מבצעים'), route: '/deals'),
    WebNavItem(id: 'realestate', label: place('Real Estate', 'נדל״ן'), route: '/realestate'),
    WebNavItem(id: 'restaurants', label: place('Restaurants', 'מסעדות'), route: '/restaurants'),
    WebNavItem(
      id: 'businesses',
      label: place('Businesses', 'עסקים'),
      route: '/businesses',
      menuScope: 'business',
      menuRoute: (id) => '/businesses/category/$id',
    ),
  ];
}

/// The 1600px content column every web page lays its sections out in.
class WebSection extends StatelessWidget {
  final Widget child;
  const WebSection({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1648), // 1600 content + 24 padding each side
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
  final VoidCallback onToggleLanguage;

  const WebAuthHeader({
    super.key,
    required this.isHebrew,
    required this.onToggleLanguage,
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
          final gutter = ((c.maxWidth - 1600) / 2).clamp(24.0, 160.0);
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
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
                      colorFilter: const ColorFilter.mode(
                        AppColors.midBlue,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onToggleLanguage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: _kBorder),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            IconsaxPlusLinear.global,
                            size: 16,
                            color: Color(0xFF0F161E),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isHebrew ? 'עב | EN' : 'EN | עב',
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 13,
                              color: const Color(0xFF0F161E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STICKY NAVBAR — 1920 × 80
// ─────────────────────────────────────────────
class WebNavbar extends StatefulWidget {
  /// Which [WebNavItem.id] to underline, or null on pages that aren't in the nav.
  final String? activeId;
  final bool isHebrew;
  final VoidCallback onToggleLanguage;
  final VoidCallback? onContactTap;

  const WebNavbar({
    super.key,
    required this.isHebrew,
    required this.onToggleLanguage,
    this.activeId,
    this.onContactTap,
  });

  @override
  State<WebNavbar> createState() => _WebNavbarState();
}

class _WebNavbarState extends State<WebNavbar> {
  /// The one menu that is open, and where on screen to draw it.
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
  Offset _menuAt = Offset.zero;

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
    setState(() {
      _open = item;
      _menuAt = box.localToGlobal(Offset(0, box.size.height));
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
  String? get activeId => widget.activeId;
  VoidCallback get onToggleLanguage => widget.onToggleLanguage;
  VoidCallback? get onContactTap => widget.onContactTap;

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (overlayContext) {
        final item = _open;
        if (item == null) return const SizedBox.shrink();
        return Positioned(
          left: _menuAt.dx,
          top: _menuAt.dy,
          child: MouseRegion(
            onEnter: (_) => _closing?.cancel(),
            onExit: (_) => _scheduleClose(),
            child: _NavMenuPanel(
              item: item,
              isHebrew: isHebrew,
              onPick: (route) {
                _closeNow();
                context.go(route);
              },
            ),
          ),
        );
      },
      child: MouseRegion(
        onExit: (_) => _scheduleClose(),
        child: LayoutBuilder(
          builder: (context, constraints) => _bar(context, constraints.maxWidth),
        ),
      ),
    );
  }

  /// The design is drawn at 1920 with a 160px gutter. Held fixed, that gutter
  /// takes a fifth of a 1440 laptop and the seven links truncate to "Pr…",
  /// "M…", "Resta…". It shrinks with the window instead, down to 24.
  Widget _bar(BuildContext context, double width) {
    final gutter = ((width - 1600) / 2).clamp(24.0, 160.0);

    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      padding: EdgeInsets.symmetric(horizontal: gutter),
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
          // Each link takes the room its own label needs, rather than an
          // equal share that forces every one of them to ellipsise at once.
          // The row scrolls if they genuinely do not fit.
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: webNavItems(isHebrew, short: width < 1700)
                    .map(
                      (item) => Builder(
                        builder: (itemContext) => _NavLinkButton(
                          label: item.label,
                          isActive: item.id == activeId,
                          item: item,
                          onHover: item.hasDropdown
                              ? () => _openFor(item, itemContext)
                              : _closeNow,
                          onTap: () {
                            _closeNow();
                            context.go(item.route);
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Language toggle
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onToggleLanguage,
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
                    Text(isHebrew ? 'עב | EN' : 'EN | עב',
                        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.midBlue)),
                  ],
                ),
              ),
            ),
          ),
          // CTA
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              // It read "Contact Us" and did nothing. The address below is
              // the one the footer has always published.
              onTap: onContactTap ??
                  () => launchUrl(Uri(scheme: 'mailto', path: kContactEmail)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.midBlue,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Text(isHebrew ? 'צור קשר' : 'Contact Us',
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavLinkButton extends StatefulWidget {
  final String label;
  final bool isActive;
  final WebNavItem item;
  final VoidCallback onHover;
  final VoidCallback onTap;

  const _NavLinkButton({
    required this.label,
    this.isActive = false,
    required this.item,
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
          height: 80,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: widget.isActive ? AppColors.midBlue : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              decoration: BoxDecoration(
                color: _hovered && !widget.isActive
                    ? Colors.black.withValues(alpha: 0.04)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 15,
                        fontWeight:
                            widget.isActive ? FontWeight.w600 : FontWeight.w500,
                        color: widget.isActive
                            ? AppColors.midBlue
                            : const Color(0xFF0F161E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.item.hasDropdown) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: Color(0xFF21272A),
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

/// The panel under a nav link, listing that link's categories.
///
/// Shaped after the site this replaces: names only, no counts, generous rows,
/// and nothing above them. Counts were an early flourish of mine — the real
/// menu does not carry them and they made a plain list look like a report.
class _NavMenuPanel extends ConsumerWidget {
  final WebNavItem item;
  final bool isHebrew;
  final void Function(String route) onPick;

  const _NavMenuPanel({
    required this.item,
    required this.isHebrew,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(navCategoriesProvider(item.menuScope!));
    final list = cats.valueOrNull ?? const <NavCategory>[];
    if (list.isEmpty) return const SizedBox.shrink();

    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 260,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final c in list)
              _NavMenuRow(
                label: c.name,
                onTap: () => onPick(item.menuRoute!(c.id)),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavMenuRow extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _NavMenuRow({required this.label, required this.onTap});

  @override
  State<_NavMenuRow> createState() => _NavMenuRowState();
}

class _NavMenuRowState extends State<_NavMenuRow> {
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
          color: _hovered ? const Color(0xFFF3F5F8) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: const Color(0xFF0F161E),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FOOTER — 1920 × 632
// ─────────────────────────────────────────────
class WebFooter extends StatelessWidget {
  final bool isHebrew;
  const WebFooter({super.key, required this.isHebrew});

  String _t(String en, String he) => isHebrew ? he : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.midBlue,
      padding: const EdgeInsets.only(top: 64),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1600),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildContact()),
                        const SizedBox(width: 40),
                        Expanded(flex: 2, child: _buildLinks(_t('Modiin4u', 'מודיעין4u'), _companyLinks)),
                        const SizedBox(width: 40),
                        Expanded(flex: 2, child: _buildLinks(_t('Explore Modiin', 'גלו את מודיעין'), _exploreLinks)),
                        const SizedBox(width: 40),
                        Expanded(flex: 2, child: _buildLinks(_t('Popular Categories', 'קטגוריות פופולריות'), _categoryLinks)),
                        const SizedBox(width: 40),
                        Expanded(flex: 3, child: _buildAbout()),
                      ],
                    );
                  }
                  // Narrow: contact, a condensed two-column link block, then about.
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContact(),
                      const SizedBox(height: 40),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildLinks(_t('Modiin4u', 'מודיעין4u'), _companyLinks.take(4).toList())),
                          Expanded(child: _buildLinks(_t('Explore', 'גלו'), _exploreLinks.take(5).toList())),
                        ],
                      ),
                      const SizedBox(height: 40),
                      _buildAbout(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
              // Bottom bar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white24))),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_t('All Rights Reserved to modiin4u.co.il, 2026', 'כל הזכויות שמורות ל-modiin4u.co.il, 2026'),
                            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kBorder)),
                        Row(
                          children: [
                            Text(_t('Terms of Use', 'תנאי שימוש'), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kBorder)),
                            const SizedBox(width: 4),
                            const Text('|', style: TextStyle(color: _kBorder)),
                            const SizedBox(width: 4),
                            Text(_t('Privacy Policy', 'מדיניות פרטיות'), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: _kBorder)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> get _companyLinks => [
    _t('Home', 'בית'),
    _t('About Us', 'אודותינו'),
    _t('Contact Us', 'צור קשר'),
    _t('Privacy Policy', 'מדיניות פרטיות'),
    _t('Terms of Use', 'תנאי שימוש'),
    _t('Accessibility Statement', 'הצהרת נגישות'),
  ];

  List<String> get _exploreLinks => [
    _t('News', 'חדשות'),
    _t('Events', 'אירועים'),
    _t('Businesses', 'עסקים'),
    _t('Professionals', 'בעלי מקצוע'),
    _t('Real Estate', 'נדל״ן'),
    _t('Map', 'מפה'),
    _t('Restaurants', 'מסעדות'),
    _t('Deals', 'מבצעים'),
  ];

  List<String> get _categoryLinks => [
    _t('Restaurants', 'מסעדות'),
    _t('Coffee Shops', 'בתי קפה'),
    _t('Bars', 'ברים'),
    _t('Professionals', 'בעלי מקצוע'),
    _t('Real Estate', 'נדל״ן'),
    _t('Local Businesses', 'עסקים מקומיים'),
    _t('Events', 'אירועים'),
    _t('News', 'חדשות'),
  ];

  Widget _buildContact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('We are here for\nany questions.', 'אנחנו כאן\nלכל שאלה.'),
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 32, fontWeight: FontWeight.w500, color: Colors.white, height: 1.22)),
        const SizedBox(height: 40),
        _FooterContactRow(icon: IconsaxPlusLinear.call, label: _t('Phone', 'טלפון'), value: kContactPhone,
            uri: Uri(scheme: 'tel', path: kContactPhone)),
        _FooterContactRow(icon: IconsaxPlusLinear.sms, label: _t('Email', 'אימייל'), value: kContactEmail,
            uri: Uri(scheme: 'mailto', path: kContactEmail)),
        _FooterContactRow(icon: IconsaxPlusLinear.message, label: _t('WhatsApp', 'וואטסאפ'), value: kContactPhone,
            uri: Uri.parse('https://wa.me/$kContactWhatsApp')),
        const SizedBox(height: 16),
        Text(_t('Our Socials', 'הרשתות שלנו'),
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 19),
        Row(
          children: [
            _socialIcon(child: Text('f', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
            _socialIcon(child: Text('X', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
            _socialIcon(child: Text('in', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))),
            _socialIcon(child: const Icon(IconsaxPlusLinear.instagram, size: 18, color: Colors.white)),
            _socialIcon(child: const Icon(IconsaxPlusLinear.music, size: 18, color: Colors.white)),
          ],
        ),
      ],
    );
  }

  Widget _socialIcon({required Widget child}) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 9),
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white38)),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildLinks(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 24),
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(link, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: Colors.white.withValues(alpha: 0.9))),
        )),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_t('View all', 'הצג הכל'),
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.turquoise)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.turquoise),
          ],
        ),
      ],
    );
  }

  Widget _buildAbout() {
    final alignment = isHebrew ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final textAlign = isHebrew ? TextAlign.start : TextAlign.end;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        SvgPicture.asset('assets/images/logo_white.svg', width: 164, height: 88),
        const SizedBox(height: 24),
        Text(_t('Modiin for You', 'מודיעין בשבילך'),
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
            textAlign: textAlign),
        const SizedBox(height: 16),
        Text(
          _t('We are not just a news site – we are the beating heart of Modiin! A local media and public relations organization that lives and breathes our city.',
             'אנחנו לא סתם אתר חדשות – אנחנו הלב הפועם של מודיעין! ארגון מדיה ויחסי ציבור מקומי שחי ונושם את העיר שלנו.'),
          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: Colors.white.withValues(alpha: 0.85), height: 1.4),
          textAlign: textAlign,
        ),
        const SizedBox(height: 24),
        Text(_t('Download Our App', 'הורידו את האפליקציה'),
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            textAlign: textAlign),
        const SizedBox(height: 16),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Wrap(
            spacing: 12, runSpacing: 8, alignment: WrapAlignment.end,
            children: const [
              _AppStoreBtn(store: 'App Store', label: 'Download on the', svgAsset: 'assets/images/apple_logo.svg', isApple: true),
              _AppStoreBtn(store: 'Google Play', label: 'GET IT ON', svgAsset: 'assets/images/google_play.svg'),
            ],
          ),
        ),
      ],
    );
  }
}

class _FooterContactRow extends StatelessWidget {
  final IconData icon;
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
        child: _row(),
      ),
    );
  }

  Widget _row() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 34),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white38)),
            child: Center(child: Icon(icon, size: 16, color: Colors.white)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: Colors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppStoreBtn extends StatelessWidget {
  final String store, label, svgAsset;
  final bool isApple;
  const _AppStoreBtn({required this.store, required this.label, required this.svgAsset, this.isApple = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(svgAsset, width: 24, height: 24,
              colorFilter: isApple ? const ColorFilter.mode(Colors.white, BlendMode.srcIn) : null),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 10, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.8))),
              const SizedBox(height: 1),
              Text(store, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}
