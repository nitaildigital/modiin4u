import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../providers/auth_provider.dart';

/// Profile screen – dark rounded header with avatar, name & badge,
/// "Edit Profile" CTA, and a scrollable ACCOUNT menu card.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // ── Menu items ──
  static final _menuItems = [
    _MenuItem(IconsaxPlusLinear.user, 'Personal details', 'Edit Profile',
        '/edit-profile'),
    _MenuItem(IconsaxPlusLinear.notification, 'Manage your alerts',
        'Notifications', '/notifications'),
    _MenuItem(IconsaxPlusLinear.heart, 'Saved places & listings', 'Favorites',
        '/favorites'),
    _MenuItem(
        IconsaxPlusLinear.setting_2, 'App preferences', 'Settings', '/settings'),
    _MenuItem(IconsaxPlusLinear.activity, 'Steps, reviews & rewards',
        'My Activity', '/steps'),
    _MenuItem(IconsaxPlusLinear.building_3, 'Properties you posted',
        'My Apartments', '/my-apartments'),
    _MenuItem(IconsaxPlusLinear.info_circle, 'FAQs & contact us',
        'Help & Support', '/help-support'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    if (user == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => context.go('/login'));
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
                                'Profile',
                                style: GoogleFonts.inter(
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
                          style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Badge pill ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFD47D00).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            IconsaxPlusLinear.crown_1,
                            size: 14,
                            color: Color(0xFFD47D00),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Real Estate Broker',
                            style: GoogleFonts.inter(
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
                                      'Edit Profile',
                                      style: GoogleFonts.inter(
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
                              'ACCOUNT',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6D6D6D),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // ── Menu card ──
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color: const Color(0xFFE7E7E7)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: List.generate(
                                    _menuItems.length, (i) {
                                  final item = _menuItems[i];
                                  final isLast =
                                      i == _menuItems.length - 1;
                                  return _MenuRow(
                                    item: item,
                                    showBorder: !isLast,
                                  );
                                }),
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
              ? const Border(
                  bottom: BorderSide(color: Color(0xFFE7E7E7)),
                )
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
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6D6D6D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: GoogleFonts.inter(
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
