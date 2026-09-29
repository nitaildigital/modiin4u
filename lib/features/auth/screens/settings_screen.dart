import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/m_account_widgets.dart';
import '../../settings/models/notification_preferences.dart';
import '../../settings/providers/preferences_provider.dart';
import 'web_settings_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// The switches write to the profile now, so leaving the screen puts the
  /// pending change through rather than dropping it.
  @override
  void deactivate() {
    ref.read(preferencesProvider.notifier).flushNow();
    super.deactivate();
  }

  Future<void> _signOut() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/');
  }

  /// Deleting is irreversible and asked for twice on purpose: once here, and
  /// again by typing, so it cannot happen by a stray tap.
  Future<void> _confirmDelete() async {
    final l = L.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: Directionality.of(context),
        child: AlertDialog(
          title: Text(
            l.deleteAccount,
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            l.deleteAccountConfirm,
            style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                l.cancel,
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  color: AppColors.grayMeta,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                l.delete,
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await ref.read(authProvider.notifier).deleteAccount();
      if (!mounted) return;
      Navigator.of(context).pop(); // the spinner
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.deleteAccountFailed,
            style: TextStyle(fontFamily: AppFonts.rubik),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1100) return const WebSettingsContent();
        return _buildMobile(context);
      },
    );
  }

  /// The phone layout, to the mobile "Settings" frame: grey section labels
  /// over white bordered cards. The design shows one push switch; the topic
  /// and access switches the app already had sit in the same cards, so no
  /// choice a person could make before is lost.
  Widget _buildMobile(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final signedIn = ref.watch(isLoggedInProvider);
    final prefs =
        ref.watch(preferencesProvider) ?? const NotificationPreferences();
    final l = L.of(context);
    final isHebrew = ref.watch(localeProvider).languageCode == 'he';

    void set(NotificationPreferences next) =>
        ref.read(preferencesProvider.notifier).update(next);

    Widget toggle({
      String? svg,
      IconData? icon,
      required String title,
      required String subtitle,
      required bool value,
      required bool enabled,
      required ValueChanged<bool> onChanged,
    }) => MSettingsRow(
      leading: MIconCircle(svg: svg, icon: icon),
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      trailing: MSwitch(value: value, onChanged: enabled ? onChanged : null),
    );

    const gap = SizedBox(height: 20);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            MAccountTopBar(title: l.settings),
            const SizedBox(height: 22),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  30 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  // Signed out there is no row to write a choice to, so the
                  // switches say so rather than appearing to remember anything.
                  if (!signedIn) ...[
                    _SignInPrompt(onTap: () => context.push('/login')),
                    const SizedBox(height: 12),
                  ],

                  MSection(
                    label: l.notifications,
                    children: [
                      toggle(
                        svg: 'assets/icons/m_account_c_bell.svg',
                        title: mTr(context, 'Push Notifications', 'התראות פוש'),
                        subtitle: mTr(
                          context,
                          'Manage push notification preferences',
                          'ניהול העדפות התראות פוש',
                        ),
                        value: prefs.pushEnabled,
                        enabled: signedIn,
                        onChanged: (v) => set(prefs.copyWith(pushEnabled: v)),
                      ),
                      toggle(
                        icon: IconsaxPlusLinear.document_text,
                        title: l.notifyNews,
                        subtitle: l.notifyNewsHint,
                        value: prefs.news,
                        enabled: signedIn && prefs.pushEnabled,
                        onChanged: (v) => set(prefs.copyWith(news: v)),
                      ),
                      toggle(
                        icon: IconsaxPlusLinear.discount_shape,
                        title: l.notifyDeals,
                        subtitle: l.notifyDealsHint,
                        value: prefs.deals,
                        enabled: signedIn && prefs.pushEnabled,
                        onChanged: (v) => set(prefs.copyWith(deals: v)),
                      ),
                      toggle(
                        icon: IconsaxPlusLinear.location,
                        title: l.notifyNeighborhood,
                        subtitle: l.notifyNeighborhoodHint,
                        value: prefs.neighborhood,
                        enabled: signedIn && prefs.pushEnabled,
                        onChanged: (v) => set(prefs.copyWith(neighborhood: v)),
                      ),
                    ],
                  ),
                  gap,

                  MSection(
                    label: l.account,
                    children: [
                      MSettingsRow(
                        leading: const MIconCircle(
                          icon: IconsaxPlusLinear.user,
                        ),
                        title: l.profile,
                        subtitle: mTr(
                          context,
                          'View and edit your profile',
                          'צפייה ועריכה של הפרופיל',
                        ),
                        onTap: () => context.push('/profile'),
                      ),
                      MSettingsRow(
                        leading: const MIconCircle(
                          svg: 'assets/icons/m_account_c_lock.svg',
                        ),
                        title: l.password,
                        subtitle: mTr(
                          context,
                          'Change your password',
                          'שינוי הסיסמה שלך',
                        ),
                        onTap: () => context.push('/change-password'),
                      ),
                    ],
                  ),
                  gap,

                  MSection(
                    label: mTr(context, 'Preferences', 'העדפות'),
                    children: [
                      MSettingsRow(
                        leading: const MIconCircle(
                          svg: 'assets/icons/m_account_c_translate.svg',
                        ),
                        title: l.language,
                        subtitle: mTr(
                          context,
                          'Set your preferred language',
                          'בחירת השפה המועדפת',
                        ),
                        value: isHebrew ? 'עברית' : 'English',
                        onTap: () => context.push('/change-language'),
                      ),
                      MSettingsRow(
                        leading: const MIconCircle(
                          icon: IconsaxPlusLinear.moon,
                        ),
                        title: l.darkMode,
                        subtitle: isDark
                            ? mTr(context, 'Dark mode is on', 'מצב כהה פעיל')
                            : mTr(context, 'Light mode is on', 'מצב בהיר פעיל'),
                        trailing: MSwitch(
                          value: isDark,
                          onChanged: (_) =>
                              ref.read(themeModeProvider.notifier).toggle(),
                        ),
                      ),
                    ],
                  ),
                  gap,

                  MSection(
                    label: l.access,
                    children: [
                      toggle(
                        svg: 'assets/icons/m_account_c_location.svg',
                        title: l.accessLocation,
                        subtitle: l.accessLocationHint,
                        value: prefs.locationEnabled,
                        enabled: signedIn,
                        onChanged: (v) =>
                            set(prefs.copyWith(locationEnabled: v)),
                      ),
                      toggle(
                        icon: IconsaxPlusLinear.activity,
                        title: l.accessHealth,
                        subtitle: l.accessHealthHint,
                        value: prefs.healthEnabled,
                        enabled: signedIn,
                        onChanged: (v) => set(prefs.copyWith(healthEnabled: v)),
                      ),
                    ],
                  ),
                  gap,

                  MSection(
                    label: mTr(context, 'Support', 'תמיכה'),
                    children: [
                      MSettingsRow(
                        leading: const MIconCircle(
                          svg: 'assets/icons/m_account_c_help.svg',
                        ),
                        title: l.helpSupport,
                        subtitle: mTr(
                          context,
                          'Get help and contact support',
                          'עזרה ופנייה לתמיכה',
                        ),
                        onTap: () => context.push('/help-support'),
                      ),
                      MSettingsRow(
                        leading: const MIconCircle(
                          svg: 'assets/icons/m_account_c_terms.svg',
                        ),
                        title: mTr(
                          context,
                          'Terms & Conditions',
                          'תנאים והגבלות',
                        ),
                        subtitle: mTr(
                          context,
                          'Read our terms and conditions',
                          'קריאת התנאים וההגבלות',
                        ),
                        onTap: () => context.push('/terms'),
                      ),
                    ],
                  ),
                  gap,

                  MSection(
                    label: mTr(context, 'About', 'אודות'),
                    children: [
                      MSettingsRow(
                        leading: const MIconCircle(
                          svg: 'assets/icons/m_account_c_info.svg',
                        ),
                        title: mTr(
                          context,
                          'About Modiin4u',
                          'אודות מודיעין בשבילך',
                        ),
                        subtitle: mTr(
                          context,
                          'App version 1.0.0',
                          'גרסה 1.0.0',
                        ),
                        showChevron: false,
                      ),
                    ],
                  ),

                  if (signedIn) ...[
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: _signOut,
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.error),
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Text(
                          l.signOut,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _confirmDelete,
                        child: Text(
                          l.deleteAccount,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 13,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown above the switches when nobody is signed in.
class _SignInPrompt extends StatelessWidget {
  final VoidCallback onTap;
  const _SignInPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.midBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              IconsaxPlusLinear.info_circle,
              size: 18,
              color: AppColors.midBlue,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                L.of(context).signInToSavePrefs,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 13,
                  color: AppColors.midBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
