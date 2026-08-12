import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/theme_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _newsNotifications = true;
  bool _dealsNotifications = true;
  bool _neighborhoodNotifications = true;
  bool _realestateAlerts = false;

  void _showInfoSheet(BuildContext context, String title, List<String> items) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(title, style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy)),
              const SizedBox(height: 16),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ', style: TextStyle(color: AppColors.turquoise, fontSize: 16)),
                    Expanded(child: Text(item, style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayText, height: 1.5))),
                  ],
                ),
              )),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('סגירה', style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('הגדרות', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
        ),
        body: ListView(
          children: [
            const SizedBox(height: 8),
            _SectionTitle('התראות'),
            _ToggleItem(
              icon: Icons.newspaper_outlined,
              label: 'חדשות ועדכונים',
              subtitle: 'חדשות מקומיות, עדכוני עירייה',
              value: _newsNotifications,
              onChanged: (v) => setState(() => _newsNotifications = v),
            ),
            _ToggleItem(
              icon: Icons.local_offer_outlined,
              label: 'הטבות ומבצעים',
              subtitle: 'קופונים חדשים מעסקים',
              value: _dealsNotifications,
              onChanged: (v) => setState(() => _dealsNotifications = v),
            ),
            _ToggleItem(
              icon: Icons.location_on_outlined,
              label: 'עדכוני שכונה',
              subtitle: 'אירועים ועדכונים רלוונטיים לשכונה שלך',
              value: _neighborhoodNotifications,
              onChanged: (v) => setState(() => _neighborhoodNotifications = v),
            ),
            _ToggleItem(
              icon: Icons.apartment_outlined,
              label: 'התראות נדל"ן',
              subtitle: 'נכסים חדשים שתואמים לחיפוש שלך',
              value: _realestateAlerts,
              onChanged: (v) => setState(() => _realestateAlerts = v),
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
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    context.go('/');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('התנתקות', style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => Directionality(
                        textDirection: TextDirection.rtl,
                        child: AlertDialog(
                          title: Text('מחיקת חשבון', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
                          content: Text(
                            'פעולה זו תמחק את כל הנתונים שלך לצמיתות. האם להמשיך?',
                            style: GoogleFonts.rubik(fontSize: 14),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text('ביטול', style: GoogleFonts.rubik(color: AppColors.grayMeta)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                ref.read(authProvider.notifier).logout();
                                context.go('/');
                              },
                              child: Text('מחיקה', style: GoogleFonts.rubik(color: AppColors.error, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'מחיקת חשבון',
                    style: GoogleFonts.rubik(fontSize: 13, color: AppColors.error),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            Center(
              child: Text(
                'מודיעין בשבילך · גרסה 1.0.0',
                style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayLight),
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
        style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grayMeta),
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

  const _ToggleItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                Text(label, style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w500, color: context.textPrimary)),
                Text(subtitle, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayMeta)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.turquoise,
          ),
        ],
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
              child: Text(label, style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w500, color: context.textPrimary)),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.grayLight),
          ],
        ),
      ),
    );
  }
}
