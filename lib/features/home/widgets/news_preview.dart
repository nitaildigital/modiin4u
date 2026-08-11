import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class NewsPreview extends StatelessWidget {
  const NewsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final articles = [
      ('מסעדה חדשה נפתחה במרכז המסחרי', 'קולינריה', '2 שעות'),
      ('העירייה מקימה פארק חדש בשכונת נופים', 'עירייה', '4 שעות'),
      ('תוצאות הגביע: הפועל מודיעין ניצחה 2-0', 'ספורט', '6 שעות'),
    ];

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: articles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final (title, category, time) = articles[index];
          return GestureDetector(
            onTap: () => context.push('/article/demo_$index'),
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.turquoise.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category,
                      style: GoogleFonts.rubik(
                        fontSize: 11,
                        color: AppColors.turquoise,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: GoogleFonts.rubik(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    'לפני $time',
                    style: GoogleFonts.rubik(
                      fontSize: 12,
                      color: AppColors.grayLight,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
