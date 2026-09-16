import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';

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
  final bool hasDropdown;
  const WebNavItem({
    required this.id,
    required this.label,
    required this.route,
    this.hasDropdown = false,
  });
}

/// The canonical nav, in display order.
List<WebNavItem> webNavItems(bool isHebrew) {
  String t(String en, String he) => isHebrew ? he : en;
  return [
    WebNavItem(id: 'professionals', label: t('Professionals', 'בעלי מקצוע'), route: '/businesses', hasDropdown: true),
    WebNavItem(id: 'news', label: t('Modiin News', 'חדשות מודיעין'), route: '/news', hasDropdown: true),
    WebNavItem(id: 'events', label: t('Events', 'אירועים'), route: '/events'),
    WebNavItem(id: 'deals', label: t('Deals', 'מבצעים'), route: '/deals'),
    WebNavItem(id: 'realestate', label: t('Real Estate in Modiin', 'נדל"ן במודיעין'), route: '/realestate'),
    WebNavItem(id: 'restaurants', label: t('Restaurants in Modiin', 'מסעדות במודיעין'), route: '/restaurants'),
    WebNavItem(id: 'businesses', label: t('Businesses in Modiin', 'עסקים במודיעין'), route: '/businesses', hasDropdown: true),
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
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STICKY NAVBAR — 1920 × 80
// ─────────────────────────────────────────────
class WebNavbar extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
              children: webNavItems(isHebrew).map((item) {
                return Expanded(
                  child: _NavLinkButton(
                    label: item.label,
                    isActive: item.id == activeId,
                    hasDropdown: item.hasDropdown,
                    onTap: () => context.go(item.route),
                  ),
                );
              }).toList(),
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
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.midBlue)),
                  ],
                ),
              ),
            ),
          ),
          // CTA
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onContactTap ?? () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.midBlue,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Text(isHebrew ? 'צור קשר' : 'Contact Us',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
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
                            style: GoogleFonts.inter(fontSize: 14, color: _kBorder)),
                        Row(
                          children: [
                            Text(_t('Terms of Use', 'תנאי שימוש'), style: GoogleFonts.inter(fontSize: 14, color: _kBorder)),
                            const SizedBox(width: 4),
                            const Text('|', style: TextStyle(color: _kBorder)),
                            const SizedBox(width: 4),
                            Text(_t('Privacy Policy', 'מדיניות פרטיות'), style: GoogleFonts.inter(fontSize: 14, color: _kBorder)),
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
                              Text('Powered by ', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [Color(0xFF9333EA), Color(0xFFEC4899)],
                                ).createShader(bounds),
                                child: Text('PersonaAI',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
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
    _t('Real Estate', 'נדל"ן'),
    _t('Map', 'מפה'),
    _t('Restaurants', 'מסעדות'),
    _t('Deals', 'מבצעים'),
  ];

  List<String> get _categoryLinks => [
    _t('Restaurants', 'מסעדות'),
    _t('Coffee Shops', 'בתי קפה'),
    _t('Bars', 'ברים'),
    _t('Professionals', 'בעלי מקצוע'),
    _t('Real Estate', 'נדל"ן'),
    _t('Local Businesses', 'עסקים מקומיים'),
    _t('Events', 'אירועים'),
    _t('News', 'חדשות'),
  ];

  Widget _buildContact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('We are here for\nany questions.', 'אנחנו כאן\nלכל שאלה.'),
            style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w500, color: Colors.white, height: 1.22)),
        const SizedBox(height: 40),
        _FooterContactRow(icon: IconsaxPlusLinear.call, label: _t('Phone', 'טלפון'), value: '058-4770195'),
        _FooterContactRow(icon: IconsaxPlusLinear.sms, label: _t('Email', 'אימייל'), value: 'modiin4uoffice@gmail.com'),
        _FooterContactRow(icon: IconsaxPlusLinear.message, label: _t('WhatsApp', 'וואטסאפ'), value: '058-4770195'),
        const SizedBox(height: 16),
        Text(_t('Our Socials', 'הרשתות שלנו'),
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 19),
        Row(
          children: [
            _socialIcon(child: Text('f', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
            _socialIcon(child: Text('X', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
            _socialIcon(child: Text('in', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))),
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
        Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 24),
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(link, style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.9))),
        )),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_t('View all', 'הצג הכל'),
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.turquoise)),
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
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
            textAlign: textAlign),
        const SizedBox(height: 16),
        Text(
          _t('We are not just a news site – we are the beating heart of Modiin! A local media and public relations organization that lives and breathes our city.',
             'אנחנו לא סתם אתר חדשות – אנחנו הלב הפועם של מודיעין! ארגון מדיה ויחסי ציבור מקומי שחי ונושם את העיר שלנו.'),
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.85), height: 1.4),
          textAlign: textAlign,
        ),
        const SizedBox(height: 24),
        Text(_t('Download Our App', 'הורידו את האפליקציה'),
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
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
  const _FooterContactRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
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
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 4),
                Text(value,
                    style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
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
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.8))),
              const SizedBox(height: 1),
              Text(store, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}
