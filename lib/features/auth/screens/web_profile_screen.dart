import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../providers/auth_provider.dart';

// ═══════════════════════════════════════════════════════════
// Web Profile — desktop account home
//
// The phone stacks the avatar, the name and then seven menu rows in one
// column. Here the person sits along the top of a gradient banner with the
// edit button beside them, and the seven destinations become a grid, so the
// whole account fits above the fold on a 1440 laptop.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF5F5E5A);
const _kHeading = Color(0xFF1C1C1E);
const _kIconGrey = Color(0xFF6D6D6D);

/// The header gradient the mobile screen draws behind the avatar.
const _kHeaderGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0058B5), Color(0xFF010A36)],
);

class WebProfileContent extends ConsumerStatefulWidget {
  const WebProfileContent({super.key});

  @override
  ConsumerState<WebProfileContent> createState() => _WebProfileContentState();
}

class _WebProfileContentState extends ConsumerState<WebProfileContent> {
  bool _isHebrew = false;

  String _t(String en, String he) => _isHebrew ? he : en;

  List<_MenuItem> get _menuItems => [
    _MenuItem(
      IconsaxPlusLinear.user,
      _t('Edit Profile', 'עריכת פרופיל'),
      _t('Your personal details', 'הפרטים האישיים שלכם'),
      '/edit-profile',
    ),
    _MenuItem(
      IconsaxPlusLinear.notification,
      _t('Notifications', 'התראות'),
      _t('Manage your alerts', 'ניהול ההתראות שלכם'),
      '/notifications',
    ),
    _MenuItem(
      IconsaxPlusLinear.heart,
      _t('Favorites', 'מועדפים'),
      _t('Saved places and listings', 'מקומות ומודעות ששמרתם'),
      '/favorites',
    ),
    _MenuItem(
      IconsaxPlusLinear.setting_2,
      _t('Settings', 'הגדרות'),
      _t('App preferences', 'העדפות האפליקציה'),
      '/settings',
    ),
    _MenuItem(
      IconsaxPlusLinear.activity,
      _t('My Activity', 'הפעילות שלי'),
      _t('Steps, reviews and rewards', 'צעדים, ביקורות ופרסים'),
      '/steps',
    ),
    _MenuItem(
      IconsaxPlusLinear.building_3,
      _t('My Apartments', 'הדירות שלי'),
      _t('Properties you posted', 'נכסים שפרסמתם'),
      '/my-apartments',
    ),
    _MenuItem(
      IconsaxPlusLinear.info_circle,
      _t('Help & Support', 'עזרה ותמיכה'),
      _t('FAQs and contact us', 'שאלות נפוצות ויצירת קשר'),
      '/help-support',
    ),
  ];

  /// Appended for administrators only, exactly as the mobile list does. This
  /// page only ever runs on the web, so the platform check the phone screen
  /// carries is not repeated.
  _MenuItem get _adminItem => _MenuItem(
    IconsaxPlusLinear.setting_4,
    _t('Control Center', 'מרכז הבקרה'),
    _t('Manage content and users', 'ניהול תכנים ומשתמשים'),
    '/admin',
  );

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    // The wrapper screen has already sent a signed-out visitor to sign in, so
    // a null here means that redirect is still a frame away.
    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final items = [..._menuItems, if (user.isAdmin) _adminItem];

    return Directionality(
      textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            WebNavbar(
              isHebrew: _isHebrew,
              activeId: null,
              onToggleLanguage: () => setState(() => _isHebrew = !_isHebrew),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    WebSection(
                      child: _buildHeader(
                        user.initials,
                        user.name,
                        user.email,
                        user.isBroker,
                      ),
                    ),
                    const SizedBox(height: 56),
                    WebSection(child: _buildMenuGrid(items)),
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
  // HEADER — avatar, name and the edit button, along the top
  // ─────────────────────────────────────────────
  Widget _buildHeader(
    String initials,
    String name,
    String email,
    bool isBroker,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      decoration: BoxDecoration(
        gradient: _kHeaderGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: AppFonts.nunito,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                _buildBadge(isBroker),
              ],
            ),
          ),
          const SizedBox(width: 32),
          _buildEditButton(),
        ],
      ),
    );
  }

  Widget _buildBadge(bool isBroker) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBroker ? IconsaxPlusLinear.crown_1 : IconsaxPlusLinear.user,
            size: 14,
            color: AppColors.gold,
          ),
          const SizedBox(width: 6),
          Text(
            isBroker
                ? _t('Real Estate Broker', 'מתווך נדל"ן')
                : _t('Resident', 'תושב'),
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.push('/edit-profile'),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(60),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                IconsaxPlusLinear.edit_2,
                size: 18,
                color: AppColors.midBlue,
              ),
              const SizedBox(width: 8),
              Text(
                _t('Edit Profile', 'עריכת פרופיל'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.midBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ACCOUNT — the menu, as a grid
  // ─────────────────────────────────────────────
  Widget _buildMenuGrid(List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Account', 'החשבון'),
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
            'Everything about your account, in one place.',
            'כל מה שקשור לחשבון שלכם, במקום אחד.',
          ),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            color: _kGreyText,
          ),
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 20.0;
            // Three across at 1440 as well as 1920; the column is never
            // narrower than roughly 1050 at this breakpoint, so a card is
            // never squeezed below 330.
            const perRow = 3;
            final cardWidth =
                (constraints.maxWidth - gap * (perRow - 1)) / perRow;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: cardWidth,
                      // Fixed so a two-line blurb does not make one card in a
                      // row taller than its neighbours.
                      height: 112,
                      child: _MenuCard(item: item),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════

class _MenuItem {
  final IconData icon;
  final String title, blurb, route;
  const _MenuItem(this.icon, this.title, this.blurb, this.route);
}

// ═══════════════════════════════════════════════
// CARD
// ═══════════════════════════════════════════════

class _MenuCard extends StatefulWidget {
  final _MenuItem item;
  const _MenuCard({required this.item});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push(item.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _hovered ? AppColors.midBlue : _kBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7ECF7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(item.icon, size: 24, color: AppColors.midBlue),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: _kHeading,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.blurb,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 13,
                        color: _kGreyText,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: _hovered ? AppColors.midBlue : _kIconGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
