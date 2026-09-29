import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/month_names.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/m_account_widgets.dart';
import 'web_profile_screen.dart';

/// Profile screen – blurred-photo header with avatar, name & badge, the
/// person's details, the "Edit Profile" CTA and the ACCOUNT menu card.
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

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) return const WebProfileContent();
        return _buildMobile(context, l, user);
      },
    );
  }

  /// The phone layout, to the mobile "Profile" frame: the header is the
  /// person's own photo, blurred and darkened, under a wide round bottom; the
  /// avatar, name and role badge; their details from the profile row; the
  /// "Edit Profile" button; and the account menu, which is the phone's only
  /// way to Favorites, Settings, My Apartments and the rest.
  Widget _buildMobile(BuildContext context, L l, UserModel user) {
    final topInset = MediaQuery.paddingOf(context).top;
    // The frame is drawn under a 44px status bar; follow the real one.
    final shift = topInset - 44;
    final hasPhoto = (user.avatarUrl ?? '').isNotEmpty;
    final dob = user.dateOfBirth;
    String orDash(String? v) => (v == null || v.trim().isEmpty) ? '-' : v;

    final details = <Widget>[
      MInfoRow(
        leading: const MIconTile(svg: 'assets/icons/m_account_user.svg'),
        label: l.fullName,
        value: orDash(user.name),
      ),
      MInfoRow(
        leading: const MIconTile(svg: 'assets/icons/m_account_mail.svg'),
        label: l.email,
        value: orDash(user.email),
      ),
      MInfoRow(
        leading: const MIconTile(svg: 'assets/icons/m_account_rings.svg'),
        label: l.familyStatus,
        value: switch (user.familyStatus) {
          'single' => l.single,
          'married' => l.married,
          'divorced' => l.divorced,
          'widowed' => l.widowed,
          _ => '-',
        },
      ),
      MInfoRow(
        leading: const MIconTile(svg: 'assets/icons/m_account_phone.svg'),
        label: l.phone,
        value: orDash(user.phone),
      ),
      MInfoRow(
        leading: const MIconTile(svg: 'assets/icons/m_account_pet.svg'),
        label: l.doYouHaveAPet,
        value: user.hasPet == null ? '-' : (user.hasPet! ? l.yes : l.no),
      ),
      MInfoRow(
        leading: const MIconTile(svg: 'assets/icons/m_account_calendar.svg'),
        label: l.dateOfBirth,
        value: dob == null
            ? '-'
            : '${dob.day} ${l.monthShort(dob.month)} ${dob.year}',
      ),
      MInfoRow(
        leading: const MIconTile(svg: 'assets/icons/m_account_location.svg'),
        label: l.neighborhood,
        value: orDash(user.neighborhood),
      ),
    ];

    final menu = [
      ..._menuItems(l),
      // Web only: the panel is not in the mobile build at all.
      if (kIsWeb && user.isAdmin) _adminItem(l),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Stack(
            children: [
              // ── Header: blurred photo under a 50% black veil ──
              Positioned(
                top: -225 + shift,
                left: -28,
                right: -28,
                height: 397,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(168.5),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasPhoto)
                        ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                          child: CachedNetworkImage(
                            imageUrl: user.avatarUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) =>
                                const ColoredBox(color: AppColors.midBlue),
                          ),
                        )
                      else
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.midBlue, AppColors.navy],
                            ),
                          ),
                        ),
                      const ColoredBox(color: Color(0x80000000)),
                    ],
                  ),
                ),
              ),

              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    MAccountTopBar(title: l.profile, color: Colors.white),
                    const SizedBox(height: 28),

                    // ── Avatar ──
                    Container(
                      width: 120,
                      height: 120,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0058B5), Color(0xFF010A36)],
                        ),
                      ),
                      child: hasPhoto
                          ? CachedNetworkImage(
                              imageUrl: user.avatarUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => _Initials(user),
                            )
                          : _Initials(user),
                    ),
                    const SizedBox(height: 16),

                    // ── Name ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        user.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Role badge ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD67E00).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          user.isBroker
                              ? SvgPicture.asset(
                                  'assets/icons/m_account_briefcase.svg',
                                  width: 14,
                                  height: 14,
                                )
                              : const Icon(
                                  IconsaxPlusLinear.user,
                                  size: 14,
                                  color: Color(0xFFD47D00),
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

                    // ── Scrolling part ──
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          24 + MediaQuery.paddingOf(context).bottom,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            MSection(
                              label: mTr(
                                context,
                                'Personal Information',
                                'מידע אישי',
                              ),
                              gap: 8,
                              children: details,
                            ),
                            const SizedBox(height: 24),
                            MPrimaryButton(
                              label: l.editProfile,
                              svgIcon: 'assets/icons/m_account_edit.svg',
                              onTap: () => context.push('/edit-profile'),
                            ),
                            const SizedBox(height: 24),
                            MSection(
                              label: l.account,
                              gap: 8,
                              children: [
                                for (final item in menu) _MenuRow(item: item),
                              ],
                            ),
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

/// The initials on the brand gradient, for a profile without a photo.
class _Initials extends StatelessWidget {
  final UserModel user;
  const _Initials(this.user);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        user.initials,
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 42,
          fontWeight: FontWeight.w600,
          color: Colors.white,
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
  const _MenuRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(item.route),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            MIconTile(icon: item.icon),
            const SizedBox(width: 13),
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
                      color: MAccountColors.label,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: MAccountColors.value,
                    ),
                  ),
                ],
              ),
            ),
            const MChevron(),
          ],
        ),
      ),
    );
  }
}
