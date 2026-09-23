import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../../settings/models/notification_preferences.dart';
import '../../settings/providers/preferences_provider.dart';

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

  void _showInfoSheet(BuildContext context, String title, List<String> items) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 16),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '•  ',
                        style: TextStyle(
                          color: AppColors.turquoise,
                          fontSize: 16,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 14,
                            color: AppColors.grayText,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'סגירה',
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final signedIn = ref.watch(isLoggedInProvider);
    final prefs =
        ref.watch(preferencesProvider) ?? const NotificationPreferences();

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
            _SectionTitle('התראות'),

            // Signed out there is no row to write a choice to, so the
            // switches say so rather than appearing to remember anything.
            if (!signedIn) _SignInPrompt(onTap: () => context.push('/login')),

            _ToggleItem(
              icon: Icons.notifications_active_outlined,
              label: 'קבלת התראות',
              subtitle: 'כבו כדי להפסיק לקבל התראות',
              value: prefs.pushEnabled,
              enabled: signedIn,
              onChanged: (v) => set(prefs.copyWith(pushEnabled: v)),
            ),
            _ToggleItem(
              icon: Icons.newspaper_outlined,
              label: 'חדשות ועדכונים',
              subtitle: 'חדשות מקומיות, עדכוני עירייה',
              value: prefs.news,
              enabled: signedIn && prefs.pushEnabled,
              onChanged: (v) => set(prefs.copyWith(news: v)),
            ),
            _ToggleItem(
              icon: Icons.local_offer_outlined,
              label: 'הטבות ומבצעים',
              subtitle: 'קופונים חדשים מעסקים',
              value: prefs.deals,
              enabled: signedIn && prefs.pushEnabled,
              onChanged: (v) => set(prefs.copyWith(deals: v)),
            ),
            _ToggleItem(
              icon: Icons.location_on_outlined,
              label: 'עדכוני שכונה',
              subtitle: 'אירועים ועדכונים רלוונטיים לשכונה שלך',
              value: prefs.neighborhood,
              enabled: signedIn && prefs.pushEnabled,
              onChanged: (v) => set(prefs.copyWith(neighborhood: v)),
            ),
            const Divider(color: AppColors.border, indent: 20, endIndent: 20),

            _SectionTitle('גישה'),
            _ToggleItem(
              icon: Icons.my_location_outlined,
              label: 'מיקום',
              subtitle: 'למציאת עסקים ואירועים קרובים אליכם',
              value: prefs.locationEnabled,
              enabled: signedIn,
              onChanged: (v) => set(prefs.copyWith(locationEnabled: v)),
            ),
            _ToggleItem(
              icon: Icons.directions_walk_outlined,
              label: 'נתוני כושר',
              subtitle: 'לספירת צעדים ואתגרים',
              value: prefs.healthEnabled,
              enabled: signedIn,
              onChanged: (v) => set(prefs.copyWith(healthEnabled: v)),
            ),
            const Divider(color: AppColors.border, indent: 20, endIndent: 20),

            _SectionTitle('תצוגה'),
            _ToggleItem(
              icon: Icons.dark_mode_outlined,
              label: 'מצב כהה',
              subtitle: isDark ? 'מצב כהה פעיל' : 'מצב בהיר פעיל',
              value: isDark,
              onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
            ),

            const Divider(color: AppColors.border, indent: 20, endIndent: 20),

            _SectionTitle('חשבון'),
            _ActionItem(
              icon: Icons.lock_outline,
              label: 'פרטיות ואבטחה',
              onTap: () => _showInfoSheet(context, 'פרטיות ואבטחה', [
                'הנתונים שלכם מאוחסנים בצורה מאובטחת בשרתי Supabase.',
                'אנחנו לא משתפים מידע אישי עם צדדים שלישיים.',
                'ניתן למחוק את החשבון ואת כל הנתונים בכל עת.',
                'אימות דו-שלבי באמצעות SMS.',
              ]),
            ),
            _ActionItem(
              icon: Icons.description_outlined,
              label: 'תנאי שימוש',
              onTap: () => _showInfoSheet(context, 'תנאי שימוש', [
                'השימוש באפליקציה מותנה בהסכמה לתנאים אלו.',
                'התכנים באפליקציה מסופקים "כמות שהם" (AS IS).',
                'חל איסור על שימוש לרעה, פרסום תוכן פוגעני או הטעיית משתמשים.',
                'מודיעין בשבילך שומרת לעצמה את הזכות לעדכן תנאים אלו.',
              ]),
            ),
            _ActionItem(
              icon: Icons.shield_outlined,
              label: 'מדיניות פרטיות',
              onTap: () => _showInfoSheet(context, 'מדיניות פרטיות', [
                'אנו אוספים: שם, טלפון, שכונה ופעילות באפליקציה.',
                'המידע משמש לשיפור החוויה ולהתאמת תוכן רלוונטי.',
                'אין שיתוף מידע עם מפרסמים ללא הסכמתכם.',
                'ניתן לבקש עותק של כל המידע שנאסף או למחוק אותו.',
              ]),
            ),
            _ActionItem(
              icon: Icons.help_outline,
              label: 'עזרה ותמיכה',
              onTap: () => _showInfoSheet(context, 'עזרה ותמיכה', [
                'אימייל: support@modiin4u.co.il',
                'טלפון: 08-9000000 (א׳-ה׳ 9:00-17:00)',
                'ניתן לדווח על בעיה טכנית דרך הכפתור למטה.',
                'זמן תגובה ממוצע: עד 24 שעות.',
              ]),
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
                  'התחברו כדי לשמור את ההעדפות שלכם',
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
