import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.navy,
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
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
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
                  color: AppColors.navy,
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
                _CategoryTile(Icons.local_parking, 'חניה וחניונים'),
                _CategoryTile(Icons.nightlight_round, 'שבת וחגים'),
                _CategoryTile(Icons.account_balance, 'מוסדות ציבור'),
                _CategoryTile(Icons.local_hospital, 'בריאות'),
                _CategoryTile(Icons.school, 'חינוך'),
                _CategoryTile(Icons.directions_bus, 'תחבורה'),
                _CategoryTile(Icons.shield, 'חירום ומיגון'),
                _CategoryTile(Icons.park, 'פארקים'),
                _CategoryTile(Icons.description, 'טפסים ושירותים'),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'עדכונים אחרונים',
                style: GoogleFonts.rubik(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
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
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 0.5),
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
                                color: AppColors.navy,
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
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
              color: AppColors.navy,
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

  const _CategoryTile(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
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
              color: AppColors.navy,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
