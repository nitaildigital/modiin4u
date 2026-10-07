import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../core/push/push_unread.dart';
import '../../core/theme/app_fonts.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import 'network_photo.dart';
import '../../features/auth/widgets/m_account_widgets.dart' show mTr;
import '../../features/business_owner/data/owner_data.dart' show myBusinessProvider;
import '../../features/messages/data/messages.dart' show unreadMessagesProvider;

/// The app's side menu, opened from the ☰ on the home screen.
///
/// The design's "Side Menu" frame: the resident's photo, name, e-mail and
/// account type at the top with an Edit button, then Home, Favorites, Step
/// Counter, My Apartments, Settings and Logout. The client asked for the
/// profile, support and the step counter to be reachable from the ☰; the
/// header opens the profile, and Help & Support sits after Settings.
/// Notifications, after Favorites, is ours: the bell the client was promised
/// has nowhere else to live on the phone.
///
/// This is the app's menu. A phone browser keeps the site's own menu
/// (`showWebMobileMenu`), where nobody signs in.
Future<void> showAppSideMenu(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'menu',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 240),
    // The screen that opened the menu does the navigating, so a route is
    // pushed after the menu has closed rather than on top of it.
    pageBuilder: (_, _, _) => _SideMenuPanel(host: context),
    transitionBuilder: (context, anim, _, child) {
      // The panel sits on the reading side — the right in Hebrew, the left in
      // English — as the design draws it against the English home screen.
      final rtl = Directionality.of(context) == TextDirection.rtl;
      final offset = Tween(
        begin: Offset(rtl ? 1 : -1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
      return SlideTransition(position: offset, child: child);
    },
  );
}

// ── Design tokens from the frame ──
const _kIconGrey = Color(0xFF5D5D5D);
const _kLabel = Color(0xFF3D3D3D);
const _kDivider = Color(0xFFE7E7E7);
const _kName = Color(0xFF0F0F0F);
const _kEmail = Color(0xFF6C7072);
const _kEditBg = Color(0xFFCCD6EE);
const _kEditText = Color(0xFF0033AC);
const _kBadge = Color(0xFFD47D00);

class _SideMenuPanel extends ConsumerWidget {
  final BuildContext host;

  const _SideMenuPanel({required this.host});

  void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    if (!host.mounted) return;
    if (route == '/') {
      host.go('/');
    } else {
      host.push(route);
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    // Read before closing: the menu's ref goes with it.
    final auth = ref.read(authProvider.notifier);
    Navigator.of(context).pop();
    await auth.logout();
    if (host.mounted) host.go('/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final user = ref.watch(authProvider);
    final isBusiness = user?.isBusinessOwner ?? false;
    final business = isBusiness ? ref.watch(myBusinessProvider).valueOrNull : null;
    // 334 of the frame's 393.
    final width = (MediaQuery.sizeOf(context).width * 0.85).clamp(0.0, 334.0);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Material(
        color: Colors.white,
        child: SizedBox(
          width: width,
          height: double.infinity,
          child: SafeArea(
            child: SingleChildScrollView(
              // The frame puts the photo 72px down; under a notch the safe
              // area already covers most of that.
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (user != null)
                    _ProfileHeader(
                      user: user,
                      businessName: business?.name,
                      businessLogo: business?.logoUrl,
                      onProfile: () => _go(context, isBusiness ? '/my-business' : '/profile'),
                      // The design's Edit: the business's page for a business
                      // account, My Profile (the job profile, whose pencil
                      // opens name and photo) for a resident.
                      onEdit: () => _go(context, isBusiness ? '/my-business' : '/my-profile'),
                    )
                  else
                    _SignedOutHeader(onSignIn: () => _go(context, '/login')),
                  const SizedBox(height: 16),
                  _MenuRow(
                    svg: 'assets/icons/m_menu_home.svg',
                    label: l.navHome,
                    onTap: () => _go(context, '/'),
                  ),
                  if (isBusiness) ...[
                    // The business menu frame: My Jobs, Deals, Favorites,
                    // Messages.
                    _MenuRow(
                      icon: IconsaxPlusLinear.briefcase,
                      label: mTr(context, 'My Jobs', 'המשרות שלי'),
                      onTap: () => _go(context, '/business-jobs'),
                    ),
                    _MenuRow(
                      icon: IconsaxPlusLinear.ticket_discount,
                      label: l.deals,
                      onTap: () => _go(context, '/business-deals'),
                    ),
                    _MenuRow(
                      svg: 'assets/icons/m_menu_heart.svg',
                      label: l.favorites,
                      onTap: () => _go(context, '/favorites'),
                    ),
                    _MenuRow(
                      icon: IconsaxPlusLinear.message_text,
                      label: mTr(context, 'Messages', 'הודעות'),
                      count: ref.watch(unreadMessagesProvider).valueOrNull ?? 0,
                      onTap: () => _go(context, '/messages'),
                    ),
                  ] else ...[
                    _MenuRow(
                      svg: 'assets/icons/m_menu_heart.svg',
                      label: l.favorites,
                      onTap: () => _go(context, '/favorites'),
                    ),
                    // The resident menu frame adds My Jobs after Favorites.
                    if (user != null)
                      _MenuRow(
                        icon: IconsaxPlusLinear.briefcase,
                        label: mTr(context, 'My Jobs', 'המשרות שלי'),
                        onTap: () => _go(context, '/my-jobs'),
                      ),
                  ],
                  // The notifications sent so far (the bell). The design has
                  // no bell on the phone's home screen, and Profile — the
                  // only other way there — needs an account, which
                  // notifications do not.
                  _MenuRow(
                    icon: IconsaxPlusLinear.notification,
                    label: l.notifications,
                    count: ref.watch(pushUnreadCountProvider),
                    onTap: () => _go(context, '/notifications'),
                  ),
                  if (!isBusiness) ...[
                    _MenuRow(
                      svg: 'assets/icons/m_menu_steps.svg',
                      label: l.stepCounter,
                      onTap: () => _go(context, '/steps'),
                    ),
                    _MenuRow(
                      svg: 'assets/icons/m_menu_building.svg',
                      label: l.myApartments,
                      onTap: () => _go(context, '/my-apartments'),
                    ),
                  ],
                  _MenuRow(
                    svg: 'assets/icons/m_menu_settings.svg',
                    label: l.settings,
                    onTap: () => _go(context, '/settings'),
                  ),
                  _MenuRow(
                    icon: IconsaxPlusLinear.message_question,
                    label: l.helpSupport,
                    onTap: () => _go(context, '/help-support'),
                  ),
                  if (user != null)
                    _MenuRow(
                      svg: 'assets/icons/m_menu_logout.svg',
                      label: l.signOut,
                      chevron: false,
                      onTap: () => _signOut(context, ref),
                    )
                  else
                    _MenuRow(
                      icon: IconsaxPlusLinear.login,
                      label: l.signIn,
                      chevron: false,
                      onTap: () => _go(context, '/login'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Photo and Edit, then name, e-mail and the account-type badge, over a
/// hairline — the frame's top block. The name block opens the profile.
class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final VoidCallback onProfile;
  final VoidCallback onEdit;

  /// A business account's menu shows the business — its logo and name — as
  /// the design's business menu does; the e-mail stays the account's.
  final String? businessName;
  final String? businessLogo;

  const _ProfileHeader({
    required this.user,
    required this.onProfile,
    required this.onEdit,
    this.businessName,
    this.businessLogo,
  });

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kDivider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onProfile,
                child: _Avatar(user: user, imageUrl: businessLogo, name: businessName),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _kEditBg,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/m_menu_edit.svg',
                        width: 12,
                        height: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        L.of(context).edit,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _kEditText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onProfile,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  businessName ?? user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _kName,
                    height: 16 / 18,
                  ),
                ),
                if (user.email.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: _kEmail,
                      height: 16 / 14,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _kBadge.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      user.isBusinessOwner || user.isBroker
                          ? SvgPicture.asset(
                              'assets/icons/m_menu_briefcase.svg',
                              width: 14,
                              height: 14,
                            )
                          : const Icon(
                              IconsaxPlusLinear.user,
                              size: 14,
                              color: _kBadge,
                            ),
                      const SizedBox(width: 6),
                      Text(
                        // "Business Account", as the design's business menu.
                        user.isBusinessOwner
                            ? mTr(context, 'Business Account', 'חשבון עסקי')
                            : user.isBroker
                            ? l.realEstateBroker
                            : l.resident,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _kBadge,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final UserModel user;
  final String? imageUrl;
  final String? name;

  const _Avatar({required this.user, this.imageUrl, this.name});

  @override
  Widget build(BuildContext context) {
    final url = name != null ? imageUrl : user.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: NetworkPhoto(url: url, width: 68, height: 68, icon: null),
      );
    }
    // No photo: the initials on the brand gradient, as the profile draws it.
    return Container(
      width: 68,
      height: 68,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0058B5), Color(0xFF010A36)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        name != null && name!.trim().isNotEmpty ? name!.trim().characters.first : user.initials,
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Signed out there is no one to show, so the header is a way to sign in.
/// The design draws only the signed-in menu.
class _SignedOutHeader extends StatelessWidget {
  final VoidCallback onSignIn;

  const _SignedOutHeader({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kDivider)),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF1F4FA),
            ),
            child: const Icon(
              IconsaxPlusLinear.user,
              size: 30,
              color: _kIconGrey,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSignIn,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _kEditBg,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                l.signIn,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _kEditText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One row: 24px icon, 20px gap, the label in Inter Medium 16, and a chevron
/// at the far end — 16px above and below.
class _MenuRow extends StatelessWidget {
  final String? svg;
  final IconData? icon;
  final String label;
  final bool chevron;
  final VoidCallback onTap;

  /// Unread notifications, as a red count before the chevron; 0 shows none.
  final int count;

  const _MenuRow({
    this.svg,
    this.icon,
    required this.label,
    this.chevron = true,
    required this.onTap,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: svg != null
                  ? SvgPicture.asset(svg!, width: 24, height: 24)
                  : Icon(icon, size: 24, color: _kIconGrey),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _kLabel,
                ),
              ),
            ),
            if (count > 0) ...[
              PushCountPill(count: count),
              const SizedBox(width: 12),
            ],
            if (chevron)
              // The chevron points onward: right in English, left in Hebrew.
              Transform.flip(
                flipX: rtl,
                child: SvgPicture.asset(
                  'assets/icons/m_menu_chevron.svg',
                  width: 20,
                  height: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
