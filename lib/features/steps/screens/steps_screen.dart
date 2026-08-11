import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class StepsScreen extends StatelessWidget {
  const StepsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('מד צעדים', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.navy,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DailyProgress(),
            const SizedBox(height: 20),
            _WeeklyChart(),
            const SizedBox(height: 20),
            _NeighborhoodCompetition(),
            const SizedBox(height: 20),
            _PersonalLeaderboard(),
            const SizedBox(height: 20),
            _WalkingRoutes(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _DailyProgress extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: 0.72,
                    strokeWidth: 12,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.turquoise),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('7,200', style: GoogleFonts.rubik(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.navy)),
                    Text('מתוך 10,000', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('צעדים היום', style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.navy)),
          const SizedBox(height: 4),
          Text('7.2 נקודות נצברו', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.turquoise)),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final days = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'];
    final values = [0.8, 0.6, 0.9, 0.72, 0.5, 0.3, 0.1];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('השבוע', style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final isToday = i == 3;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${(values[i] * 10).toInt()}K',
                          style: GoogleFonts.rubik(fontSize: 10, color: AppColors.grayLight),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 80 * values[i],
                          decoration: BoxDecoration(
                            color: isToday ? AppColors.turquoise : AppColors.turquoise.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          days[i],
                          style: GoogleFonts.rubik(
                            fontSize: 12,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                            color: isToday ? AppColors.turquoise : AppColors.grayText,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeighborhoodCompetition extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rankings = [
      ('הפרחים', '2,340,000', 1),
      ('נופים', '2,180,000', 2),
      ('אבני חן', '1,950,000', 3),
      ('מרכז העיר', '1,820,000', 4),
      ('מוריה', '1,650,000', 5),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: AppColors.gold, size: 22),
              const SizedBox(width: 8),
              Text('תחרות שכונות — אוגוסט', style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
            ],
          ),
          const SizedBox(height: 14),
          ...rankings.map((r) {
            final (name, steps, rank) = r;
            final isTop3 = rank <= 3;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$rank',
                      style: GoogleFonts.rubik(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isTop3 ? AppColors.gold : AppColors.grayLight,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(name, style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.navy)),
                  ),
                  Text(
                    '$steps צעדים',
                    style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PersonalLeaderboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.turquoise.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Text('📍', style: GoogleFonts.rubik(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('המיקום שלך', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
                Text('#23 בשכונת הפרחים · 72,000 צעדים החודש', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalkingRoutes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final routes = [
      ('טיילת אגם ענבה', '3.5 ק"מ', 'קל'),
      ('מסלול פארק ענבה', '5.2 ק"מ', 'בינוני'),
      ('הליכה עירונית — המע"ר', '2.8 ק"מ', 'קל'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('מסלולי הליכה מומלצים', style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
        const SizedBox(height: 12),
        ...routes.map((r) {
          final (name, distance, difficulty) = r;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
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
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.directions_walk, color: AppColors.success, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
                        Text('$distance · $difficulty', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
                      ],
                    ),
                  ),
                  const Icon(Icons.navigation_outlined, size: 18, color: AppColors.turquoise),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
