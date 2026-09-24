import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

/// Profile screen – dark rounded header with avatar, name & badge,
/// "Edit Profile" CTA, and a scrollable ACCOUNT menu card.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // ── Menu items ──
  //
  // Built per call rather than held in a static, because the labels come from
  // the translations and those depend on the locale in effect.
  static List<_MenuItem> _menuItems(L l) => [
    _MenuItem(
      IconsaxPlusLinear.user,
      l.personalDetails,
      l.editProfile,
      '/edit-profile',
    ),
    _MenuItem(
      IconsaxPlusLinear.notification,
      l.manageYourAlerts,
      l.notifications,
      '/notifications',
    ),
    _MenuItem(
      IconsaxPlusLinear.heart,
      l.savedPlacesListings,
      l.favorites,
      '/favorites',
    ),
    _MenuItem(
      IconsaxPlusLinear.setting_2,
      l.appPreferences,
      l.settings,
      '/settings',
    ),
    _MenuItem(
      IconsaxPlusLinear.activity,
      l.stepsReviewsRewards,
      l.myActivity,
      '/steps',
    ),
    _MenuItem(
      IconsaxPlusLinear.building_3,
      l.propertiesYouPosted,
      l.myApartments,
      '/my-apartments',
    ),
    _MenuItem(
      IconsaxPlusLinear.info_circle,
      l.faqsContactUs,
      l.helpSupport,
      '/help-support',
    ),
  ];

  /// Appended for administrators only. The admin area had no way in from the
  /// app at all; a resident never sees this row, and the gate on the route
  /// turns them away even if they reach it another way.
  static _MenuItem _adminItem(L l) => _MenuItem(
    IconsaxPlusLinear.setting_4,
    l.manageContentUsers,
    l.controlCenter,
    '/admin',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final user = ref.watch(authProvider);

    // The stored session takes a moment to read back, so a null here does not
    // yet mean signed out.
    if (user == null && ref.watch(authRestoringProvider)) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.pushReplacement('/login'),
      );
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Stack(
            children: [
              // ═══════════════════════════════════
              // Dark rounded header background
              // ═══════════════════════════════════
              Container(
                height: 172,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0058B5), Color(0xFF010A36)],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(60),
                  ),
                ),
              ),

              // ═══════════════════════════════════
              // Content
              // ═══════════════════════════════════
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // ── Back button + title ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: const SizedBox(
                              width: 24,
                              height: 24,
                              child: Icon(
                                IconsaxPlusLinear.arrow_left,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                l.profile,
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── Avatar circle ──
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0058B5), Color(0xFF010A36)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          user.initials,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 42,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Name ──
                    Text(
                      user.name,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Badge pill ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD47D00).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            user.isBroker
                                ? IconsaxPlusLinear.crown_1
                                : IconsaxPlusLinear.user,
                            size: 14,
                            color: const Color(0xFFD47D00),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user.isBroker ? l.realEstateBroker : l.resident,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFD47D00),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ═══════════════════════════════════
                    // Scrollable content
                    // ═══════════════════════════════════
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── "Edit Profile" button ──
                            GestureDetector(
                              onTap: () => context.push('/edit-profile'),
                              child: Container(
                                width: double.infinity,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF123A72),
                                  borderRadius: BorderRadius.circular(60),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      IconsaxPlusLinear.edit_2,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l.editProfile,
                                      style: TextStyle(
                                        fontFamily: AppFonts.inter,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Section header ──
                            Text(
                              l.account.toUpperCase(),
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6D6D6D),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // ── Menu card ──
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFE7E7E7),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Builder(
                                builder: (_) {
                                  final items = [
                                    ..._menuItems(l),
                                    // Web only: the panel is not in the
                                    // mobile build at all.
                                    if (kIsWeb && user.isAdmin) _adminItem(l),
                                  ];
                                  return Column(
                                    children: List.generate(items.length, (i) {
                                      return _MenuRow(
                                        item: items[i],
                                        showBorder: i != items.length - 1,
                                      );
                                    }),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
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
}

// ═══════════════════════════════════════════════
// Data model
// ═══════════════════════════════════════════════
class _MenuItem {
  final IconData icon;
  final String subtitle;
  final String title;
  final String route;
  const _MenuItem(this.icon, this.subtitle, this.title, this.route);
}

// ═══════════════════════════════════════════════
// Menu row – 36px icon square + subtitle/title
// ═══════════════════════════════════════════════
class _MenuRow extends StatelessWidget {
  final _MenuItem item;
  final bool showBorder;
  const _MenuRow({required this.item, this.showBorder = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(item.route),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: showBorder
              ? const Border(bottom: BorderSide(color: Color(0xFFE7E7E7)))
              : null,
        ),
        child: Row(
          children: [
            // Icon square
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE7ECF7),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Icon(
                  item.icon,
                  size: 20,
                  color: const Color(0xFF123A72),
                ),
              ),
            ),
            const SizedBox(width: 13),

            // Subtitle + title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6D6D6D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3D3D3D),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
