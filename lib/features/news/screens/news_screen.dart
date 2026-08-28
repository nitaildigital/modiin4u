import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  String _selectedTab = 'הכל';

  final _tabs = [
    'הכל',
    'עירייה',
    'עסקים',
    'נדל"ן',
    'ספורט',
    'אנשים',
    'קולינריה',
    'אטרקציות',
    'ביטחון',
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RefreshIndicator(
        onRefresh: () async { await Future.delayed(const Duration(milliseconds: 800)); },
        color: AppColors.turquoise,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: context.cardBg,
            foregroundColor: context.textPrimary,
            title: Text(
              'חדשות מודיעין',
              style: GoogleFonts.rubik(fontWeight: FontWeight.w700),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'מבזק',
                      style: GoogleFonts.rubik(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'שינויים בקווי התחבורה הציבורית — פרטים מלאים',
                      style: GoogleFonts.rubik(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.turquoise.withValues(alpha: 0.08),
                    AppColors.midBlue.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: AppColors.turquoise,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'העיקר ב-60 שניות',
                          style: GoogleFonts.rubik(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          'סיכום AI של כל מה שקורה היום במודיעין',
                          style: GoogleFonts.rubik(
                            fontSize: 12,
                            color: AppColors.grayText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.turquoise,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tab = _tabs[index];
                  final selected = tab == _selectedTab;
                  return ChoiceChip(
                    label: Text(tab),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedTab = tab),
                    selectedColor: AppColors.turquoise,
                    labelStyle: GoogleFonts.rubik(
                      fontSize: 13,
                      color: selected ? AppColors.white : context.textPrimary,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: _HeroArticle(
              onTap: () => context.push('/article/hero'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: 8,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final titles = [
                  'העירייה אישרה תקציב חדש לפיתוח שכונת הנביאים',
                  'מסעדה חדשה: "ביסטרו 770" נפתח בקניון עזריאלי',
                  'דירות חדשות בפרויקט "גבעת שר" — מחירים ופרטים',
                  'הפועל מודיעין: ניצחון דרמטי בדקה ה-90',
                  'ד"ר רונית כהן מונתה לראש מחלקת החינוך',
                  'פסטיבל האוכל השנתי — כל הפרטים והמסעדות המשתתפות',
                  'טיול משפחתי: 5 מסלולים מומלצים סביב אגם ענבה',
                  'תרגיל חירום עירוני יתקיים ביום ג\' הקרוב',
                ];
                final cats = [
                  'עירייה',
                  'קולינריה',
                  'נדל"ן',
                  'ספורט',
                  'אנשים',
                  'קולינריה',
                  'אטרקציות',
                  'ביטחון'
                ];
                final times = [
                  '2 שעות',
                  '3 שעות',
                  '5 שעות',
                  '8 שעות',
                  'אתמול',
                  'אתמול',
                  'יומיים',
                  'יומיים'
                ];

                return GestureDetector(
                  onTap: () => context.push('/article/demo_$index'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.borderClr, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 100,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppColors.midBlue.withValues(alpha: 0.08),
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(12),
                            ),
                          ),
                          child: Icon(
                            Icons.article,
                            size: 32,
                            color: AppColors.midBlue.withValues(alpha: 0.25),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.turquoise
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    cats[index],
                                    style: GoogleFonts.rubik(
                                      fontSize: 10,
                                      color: AppColors.turquoise,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  titles[index],
                                  style: GoogleFonts.rubik(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimary,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'לפני ${times[index]}',
                                  style: GoogleFonts.rubik(
                                    fontSize: 11,
                                    color: AppColors.grayLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
      ),
    );
  }
}

class _HeroArticle extends StatelessWidget {
  final VoidCallback? onTap;

  const _HeroArticle({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.navy.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.navy.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.turquoise,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'כתבה ראשית',
                      style: GoogleFonts.rubik(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'פרויקט הרכבת הקלה: כך ייראה הקו החדש שיחבר את מודיעין למרכז',
                    style: GoogleFonts.rubik(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'לפני שעה · עירייה',
                    style: GoogleFonts.rubik(
                      fontSize: 12,
                      color: AppColors.white.withValues(alpha: 0.7),
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
