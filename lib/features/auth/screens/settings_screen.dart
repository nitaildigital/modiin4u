import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            'מחיקת חשבון',
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'פעולה זו תמחק את כל הנתונים שלך לצמיתות. האם להמשיך?',
            style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'ביטול',
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  color: AppColors.grayMeta,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'מחיקה',
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
            'לא ניתן היה למחוק את החשבון. נסו שוב מאוחר יותר.',
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

  Widget _buildMobile(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final signedIn = ref.watch(isLoggedInProvider);
    final prefs =
        ref.watch(preferencesProvider) ?? const NotificationPreferences();
    final l = L.of(context);

    void set(NotificationPreferences next) =>
        ref.read(preferencesProvider.notifier).update(next);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'הגדרות',
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: ListView(
          children: [
            const SizedBox(height: 8),
            _SectionTitle(l.notifications),

            // Signed out there is no row to write a choice to, so the
            // switches say so rather than appearing to remember anything.
            if (!signedIn) _SignInPrompt(onTap: () => context.push('/login')),

            _ToggleItem(
              icon: Icons.notifications_active_outlined,
              label: l.receiveNotifications,
              subtitle: l.receiveNotificationsHint,
              value: prefs.pushEnabled,
              enabled: signedIn,
              onChanged: (v) => set(prefs.copyWith(pushEnabled: v)),
            ),
            _ToggleItem(
              icon: Icons.newspaper_outlined,
              label: l.notifyNews,
              subtitle: l.notifyNewsHint,
              value: prefs.news,
              enabled: signedIn && prefs.pushEnabled,
              onChanged: (v) => set(prefs.copyWith(news: v)),
            ),
            _ToggleItem(
              icon: Icons.local_offer_outlined,
              label: l.notifyDeals,
              subtitle: l.notifyDealsHint,
              value: prefs.deals,
              enabled: signedIn && prefs.pushEnabled,
              onChanged: (v) => set(prefs.copyWith(deals: v)),
            ),
            _ToggleItem(
              icon: Icons.location_on_outlined,
              label: l.notifyNeighborhood,
              subtitle: l.notifyNeighborhoodHint,
              value: prefs.neighborhood,
              enabled: signedIn && prefs.pushEnabled,
              onChanged: (v) => set(prefs.copyWith(neighborhood: v)),
            ),
            const Divider(color: AppColors.border, indent: 20, endIndent: 20),

            _SectionTitle(l.access),
            _ToggleItem(
              icon: Icons.my_location_outlined,
              label: l.accessLocation,
              subtitle: l.accessLocationHint,
              value: prefs.locationEnabled,
              enabled: signedIn,
              onChanged: (v) => set(prefs.copyWith(locationEnabled: v)),
            ),
            _ToggleItem(
              icon: Icons.directions_walk_outlined,
              label: l.accessHealth,
              subtitle: l.accessHealthHint,
              value: prefs.healthEnabled,
              enabled: signedIn,
              onChanged: (v) => set(prefs.copyWith(healthEnabled: v)),
            ),
            const Divider(color: AppColors.border, indent: 20, endIndent: 20),

            _SectionTitle(l.display),
            _ToggleItem(
              icon: Icons.dark_mode_outlined,
              label: l.darkMode,
              subtitle: isDark ? 'מצב כהה פעיל' : 'מצב בהיר פעיל',
              value: isDark,
              onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
            ),

            const Divider(color: AppColors.border, indent: 20, endIndent: 20),

            _SectionTitle(l.account),

            // These four opened bottom sheets with four hardcoded bullet
            // points each, while `ChangePasswordScreen`,
            // `ChangeLanguageScreen`, `HelpSupportScreen` and
            // `TermsConditionsScreen` all existed and were routed — and were
            // reachable from nowhere in the app.
            _ActionItem(
              icon: Icons.lock_outline,
              label: l.changePasswordRow,
              onTap: () => context.push('/change-password'),
            ),
            _ActionItem(
              icon: Icons.translate,
              label: l.language,
              onTap: () => context.push('/change-language'),
            ),
            _ActionItem(
              icon: Icons.description_outlined,
              label: l.termsOfService,
              onTap: () => context.push('/terms'),
            ),
            _ActionItem(
              icon: Icons.help_outline,
              label: l.helpSupport,
              onTap: () => context.push('/help-support'),
            ),

            const Divider(color: AppColors.border, indent: 20, endIndent: 20),
            const SizedBox(height: 8),

            if (ref.watch(isLoggedInProvider)) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton(
                  onPressed: _signOut,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'התנתקות',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _confirmDelete,
                  child: Text(
                    'מחיקת חשבון',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 13,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            Center(
              child: Text(
                'מודיעין בשבילך · גרסה 1.0.0',
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 12,
                  color: AppColors.grayLight,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.grayMeta,
        ),
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Dimmed and inert when there is nowhere to save the choice, or when the
  /// master switch is off and the topic underneath it cannot apply.
  final bool enabled;

  const _ToggleItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.surfaceDim,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppColors.midBlue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 12,
                      color: AppColors.grayMeta,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: AppColors.turquoise,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.midBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 18,
                color: AppColors.midBlue,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  L.of(context).signInToSavePrefs,
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 13,
                    color: AppColors.midBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.surfaceDim,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppColors.midBlue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.grayLight,
            ),
          ],
        ),
      ),
    );
  }
}
