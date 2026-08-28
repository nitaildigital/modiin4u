import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

class MunicipalScreen extends StatelessWidget {
  const MunicipalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: context.cardBg,
            foregroundColor: context.textPrimary,
            title: Text(
              'מידע עירוני',
              style: GoogleFonts.rubik(fontWeight: FontWeight.w700),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderClr),
                ),
                child: TextField(
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'חפשו מידע עירוני...',
                    hintTextDirection: TextDirection.rtl,
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.grayLight),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _QuickInfoCard(
                    icon: Icons.nightlight_round,
                    title: 'כניסת שבת',
                    value: '19:12',
                    subtitle: 'יציאה 20:17',
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _QuickInfoCard(
                    icon: Icons.local_parking,
                    title: 'חניה במע"ר',
                    value: 'זמין',
                    subtitle: '~340 מקומות פנויים',
                  )),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'קטגוריות מידע',
                style: GoogleFonts.rubik(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.count(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
              children: [
                _CategoryTile(Icons.local_parking, 'חניה וחניונים', () => context.push('/parking')),
                _CategoryTile(Icons.nightlight_round, 'שבת וחגים', () => _showInfoSheet(context, 'שבת וחגים', ['כניסת שבת: 19:12', 'יציאת שבת: 20:17', 'חג קרוב: ראש השנה — 22.09'])),
                _CategoryTile(Icons.account_balance, 'מוסדות ציבור', () => _showInfoSheet(context, 'מוסדות ציבור', ['עיריית מודיעין: 08-9726000', 'ביטוח לאומי: 08-9261111', 'דואר מודיעין: 08-9260222'])),
                _CategoryTile(Icons.local_hospital, 'בריאות', () => _showInfoSheet(context, 'בריאות', ['מד"א: 101', 'טרם מודיעין: 08-9500900', 'מכבי: *3555', 'כללית: *2700'])),
                _CategoryTile(Icons.school, 'חינוך', () => _showInfoSheet(context, 'חינוך', ['מנהל חינוך: 08-9726100', 'מתנ"ס מודיעין: 08-9728500', 'ספריה עירונית: 08-9726200'])),
                _CategoryTile(Icons.directions_bus, 'תחבורה', () => _showInfoSheet(context, 'תחבורה', ['קו 1: המע"ר ↔ נופים (כל 15 דק)', 'קו 2: רכבת ↔ מרכז (כל 20 דק)', 'מוקד תחבורה: *8787'])),
                _CategoryTile(Icons.shield, 'חירום ומיגון', () => _showInfoSheet(context, 'חירום ומיגון', ['משטרה: 100', 'מד"א: 101', 'כיבוי: 102', 'עורף: 104', 'מוקד עירוני: 106'])),
                _CategoryTile(Icons.park, 'פארקים', () => _showInfoSheet(context, 'פארקים', ['פארק ענבה — פתוח 24/7', 'פארק אפק — 06:00-22:00', 'גן הכלבים — מרכז העיר'])),
                _CategoryTile(Icons.description, 'טפסים ושירותים', () => _showInfoSheet(context, 'טפסים ושירותים', ['ארנונה: 08-9726050', 'רישוי עסקים: 08-9726070', 'בנייה והיתרים: 08-9726060'])),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showReportSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.report_problem_outlined, size: 18, color: AppColors.error),
                            const SizedBox(width: 6),
                            Text('דיווח תקלה', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.error)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final uri = Uri(scheme: 'tel', path: '106');
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.turquoise.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.phone, size: 18, color: AppColors.turquoise),
                            const SizedBox(width: 6),
                            Text('מוקד 106', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.turquoise)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'עדכונים אחרונים',
                style: GoogleFonts.rubik(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final updates = [
                  (
                    Icons.construction,
                    'עבודות תשתית ברחוב הפלמ"ח',
                    'חסימה חלקית עד 15.8 · עירייה',
                  ),
                  (
                    Icons.water_drop,
                    'הפסקת מים מתוכננת — שכונת נופים',
                    'יום ד\' 13.8, 09:00-14:00 · מים',
                  ),
                  (
                    Icons.delete_outline,
                    'שינוי מועד פינוי אשפה — הפרחים',
                    'ניקוי מיוחד ביום ה\' · פינוי',
                  ),
                  (
                    Icons.event,
                    'ישיבת מועצה פתוחה לציבור',
                    'יום ב\' 18.8, 19:30 · עירייה',
                  ),
                ];

                final (icon, title, subtitle) = updates[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderClr, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.midBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 20, color: AppColors.midBlue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.rubik(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: GoogleFonts.rubik(
                                fontSize: 12,
                                color: AppColors.grayLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}

void _showInfoSheet(BuildContext context, String title, List<String> items) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(title, style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy)),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.turquoise, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item, style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayText, height: 1.4))),
                ],
              ),
            )),
          ],
        ),
      ),
    ),
  );
}

void _showReportSheet(BuildContext context) {
  final categories = ['תאורה', 'כבישים ומדרכות', 'ניקיון', 'גינון', 'מפגע בטיחותי', 'אחר'];
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('דיווח תקלה', style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy)),
            const SizedBox(height: 4),
            Text('בחרו קטגוריה ותארו את התקלה', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((c) => ChoiceChip(
                label: Text(c),
                selected: false,
                onSelected: (_) {},
              )).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              textDirection: TextDirection.rtl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'תארו את התקלה...',
                hintTextDirection: TextDirection.rtl,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('הדיווח נשלח בהצלחה!', textDirection: TextDirection.rtl)),
                  );
                },
                icon: const Icon(Icons.send),
                label: Text('שליחת דיווח', style: GoogleFonts.rubik(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.turquoise,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _QuickInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _QuickInfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderClr, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.midBlue),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.rubik(
                  fontSize: 12,
                  color: AppColors.grayText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.rubik(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.rubik(
              fontSize: 11,
              color: AppColors.grayLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _CategoryTile(this.icon, this.label, [this.onTap]);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderClr, width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.midBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: AppColors.midBlue),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.rubik(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: context.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
