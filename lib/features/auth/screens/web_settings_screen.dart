import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/web_chrome.dart';
import '../../settings/models/notification_preferences.dart';
import '../../settings/providers/preferences_provider.dart';
import '../providers/auth_provider.dart';

// ═══════════════════════════════════════════════════════════
// Web Settings — desktop preferences
//
// One long ListView on the phone. Here the same rows are grouped into four
// cards in a 720 column: a switch 1600px from its own label would be a
// worse control, not a better one.
// ═══════════════════════════════════════════════════════════

const _kBorder = Color(0xFFE7E7E7);
const _kGreyText = Color(0xFF5F5E5A);
const _kHeading = Color(0xFF1C1C1E);
const _kIconGrey = Color(0xFF6D6D6D);

class WebSettingsContent extends ConsumerStatefulWidget {
  const WebSettingsContent({super.key});

  @override
  ConsumerState<WebSettingsContent> createState() => _WebSettingsContentState();
}

class _WebSettingsContentState extends ConsumerState<WebSettingsContent> {
  bool _isHebrew = false;

  /// The switches write to the profile, so leaving the page puts the pending
  /// change through rather than dropping it.
  @override
  void deactivate() {
    ref.read(preferencesProvider.notifier).flushNow();
    super.deactivate();
  }

  String _t(String en, String he) => _isHebrew ? he : en;

  Future<void> _signOut() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/');
  }

  /// Deleting is irreversible and asked for twice on purpose, so it cannot
  /// happen by a stray click.
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: _isHebrew ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(
            _t('Delete account', 'מחיקת חשבון'),
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            _t(
              'This permanently deletes all of your data. Continue?',
              'פעולה זו תמחק את כל הנתונים שלך לצמיתות. האם להמשיך?',
            ),
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                _t('Cancel', 'ביטול'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  color: AppColors.grayMeta,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                _t('Delete', 'מחיקה'),
                style: TextStyle(
                  fontFamily: AppFonts.inter,
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
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Could not delete the account. Try again later.',
              'לא ניתן היה למחוק את החשבון. נסו שוב מאוחר יותר.',
            ),
            style: TextStyle(fontFamily: AppFonts.inter),
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
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final signedIn = ref.watch(isLoggedInProvider);
    final prefs =
        ref.watch(preferencesProvider) ?? const NotificationPreferences();

    void set(NotificationPreferences next) =>
        ref.read(preferencesProvider.notifier).update(next);

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
                    const SizedBox(height: 56),
                    WebSection(
                      child: Center(
                        child: SizedBox(
                          width: 720,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 32),
                              _buildNotificationsCard(prefs, signedIn, set),
                              const SizedBox(height: 20),
                              _buildAccessCard(prefs, signedIn, set),
                              const SizedBox(height: 20),
                              _buildDisplayCard(isDark),
                              const SizedBox(height: 20),
                              _buildAccountCard(),
                              if (signedIn) ...[
                                const SizedBox(height: 20),
                                _buildDangerCard(),
                              ],
                              const SizedBox(height: 32),
                              Center(
                                child: Text(
                                  _t(
                                    'Modiin for You · version 1.0.0',
                                    'מודיעין בשבילך · גרסה 1.0.0',
                                  ),
                                  style: TextStyle(
                                    fontFamily: AppFonts.inter,
                                    fontSize: 12,
                                    color: AppColors.grayLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Settings', 'הגדרות'),
          style: TextStyle(
            fontFamily: AppFonts.nunito,
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: _kHeading,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _t(
            'What we tell you about, what the app may use, and your account.',
            'על מה נעדכן אתכם, במה האפליקציה יכולה להשתמש, והחשבון שלכם.',
          ),
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 14,
            color: _kGreyText,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // CARDS
  // ─────────────────────────────────────────────
  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Text(
              title,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.midBlue,
              ),
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNotificationsCard(
    NotificationPreferences prefs,
    bool signedIn,
    void Function(NotificationPreferences) set,
  ) {
    return _buildCard(
      title: _t('Notifications', 'התראות'),
      children: [
        // Signed out there is no row to write a choice to, so the switches say
        // so rather than appearing to remember anything.
        if (!signedIn)
          _SignInPrompt(
            label: _t(
              'Sign in to save your preferences.',
              'התחברו כדי לשמור את ההעדפות שלכם.',
            ),
            actionLabel: _t('Sign In', 'התחברות'),
            onTap: () => context.push('/login'),
          ),
        _ToggleRow(
          icon: Icons.notifications_active_outlined,
          label: _t('Receive notifications', 'קבלת התראות'),
          subtitle: _t(
            'The master switch for everything below.',
            'המפסק הראשי לכל מה שמופיע מתחת.',
          ),
          value: prefs.pushEnabled,
          enabled: signedIn,
          onChanged: (v) => set(prefs.copyWith(pushEnabled: v)),
        ),
        _ToggleRow(
          icon: Icons.newspaper_outlined,
          label: _t('News', 'חדשות'),
          subtitle: _t('Headlines from around the city.', 'כתבות מכל העיר.'),
          value: prefs.news,
          enabled: signedIn && prefs.pushEnabled,
          onChanged: (v) => set(prefs.copyWith(news: v)),
        ),
        _ToggleRow(
          icon: Icons.local_offer_outlined,
          label: _t('Deals', 'מבצעים'),
          subtitle: _t(
            'Offers from local businesses.',
            'הצעות מעסקים מקומיים.',
          ),
          value: prefs.deals,
          enabled: signedIn && prefs.pushEnabled,
          onChanged: (v) => set(prefs.copyWith(deals: v)),
        ),
        _ToggleRow(
          icon: Icons.location_on_outlined,
          label: _t('My neighbourhood', 'השכונה שלי'),
          subtitle: _t(
            'What happens where you live.',
            'מה קורה במקום שבו אתם גרים.',
          ),
          value: prefs.neighborhood,
          enabled: signedIn && prefs.pushEnabled,
          onChanged: (v) => set(prefs.copyWith(neighborhood: v)),
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildAccessCard(
    NotificationPreferences prefs,
    bool signedIn,
    void Function(NotificationPreferences) set,
  ) {
    return _buildCard(
      title: _t('Access', 'הרשאות'),
      children: [
        _ToggleRow(
          icon: Icons.my_location_outlined,
          label: _t('Location', 'מיקום'),
          subtitle: _t(
            'To show what is near you.',
            'כדי להציג את מה שנמצא בסביבתכם.',
          ),
          value: prefs.locationEnabled,
          enabled: signedIn,
          onChanged: (v) => set(prefs.copyWith(locationEnabled: v)),
        ),
        _ToggleRow(
          icon: Icons.directions_walk_outlined,
          label: _t('Health data', 'נתוני בריאות'),
          subtitle: _t(
            'To count your steps into the leaderboards.',
            'כדי לספור את הצעדים שלכם בטבלאות.',
          ),
          value: prefs.healthEnabled,
          enabled: signedIn,
          onChanged: (v) => set(prefs.copyWith(healthEnabled: v)),
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildDisplayCard(bool isDark) {
    return _buildCard(
      title: _t('Display', 'תצוגה'),
      children: [
        _ToggleRow(
          icon: Icons.dark_mode_outlined,
          label: _t('Dark mode', 'מצב כהה'),
          subtitle: isDark
              ? _t('Dark mode is on.', 'מצב כהה פעיל.')
              : _t('Light mode is on.', 'מצב בהיר פעיל.'),
          value: isDark,
          onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildAccountCard() {
    return _buildCard(
      title: _t('Account', 'החשבון'),
      children: [
        _ActionRow(
          icon: Icons.lock_outline,
          label: _t('Change password', 'שינוי סיסמה'),
          onTap: () => context.push('/change-password'),
        ),
        _ActionRow(
          icon: Icons.translate,
          label: _t('Language', 'שפה'),
          onTap: () => context.push('/change-language'),
        ),
        _ActionRow(
          icon: Icons.description_outlined,
          label: _t('Terms of Service', 'תנאי השימוש'),
          onTap: () => context.push('/terms'),
        ),
        _ActionRow(
          icon: Icons.help_outline,
          label: _t('Help & Support', 'עזרה ותמיכה'),
          onTap: () => context.push('/help-support'),
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildDangerCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Sign out or delete', 'התנתקות או מחיקה'),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kHeading,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _t(
                    'Signing out leaves everything saved. Deleting cannot be undone.',
                    'התנתקות שומרת את הכל. מחיקה אינה ניתנת לביטול.',
                  ),
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 13,
                    color: _kGreyText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          OutlinedButton(
            onPressed: _signOut,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: Text(
              _t('Sign Out', 'התנתקות'),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _confirmDelete,
            child: Text(
              _t('Delete account', 'מחיקת חשבון'),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 13,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// ROWS
// ═══════════════════════════════════════════════

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Dimmed and inert when there is nowhere to save the choice, or when the
  /// master switch is off and the topic underneath it cannot apply.
  final bool enabled;
  final bool isLast;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: _kBorder)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppColors.midBlue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _kHeading,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 13,
                      color: _kGreyText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
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

class _ActionRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLast;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLast = false,
  });

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceLight : Colors.white,
            border: widget.isLast
                ? null
                : const Border(bottom: BorderSide(color: _kBorder)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, size: 20, color: AppColors.midBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _kHeading,
                  ),
                ),
              ),
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

/// Shown above the switches when nobody is signed in.
class _SignInPrompt extends StatelessWidget {
  final String label, actionLabel;
  final VoidCallback onTap;
  const _SignInPrompt({
    required this.label,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.midBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.midBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 13,
                color: AppColors.midBlue,
              ),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                actionLabel,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.midBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
