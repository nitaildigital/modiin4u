import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class NewsPreview extends StatelessWidget {
  const NewsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _HeroNewsCard(
            title: 'מסעדה חדשה נפתחה במרכז המסחרי — שף מוביל מתל אביב',
            category: 'קולינריה',
            onTap: () => context.push('/article/demo_0'),
          ),
          const SizedBox(height: 12),
          _ListNewsCard(
            title: 'העירייה מקימה פארק חדש בשכונת נופים',
            category: 'עירייה',
            time: 'לפני 4 שעות',
            onTap: () => context.push('/article/demo_1'),
          ),
          const Divider(height: 1, color: AppColors.border),
          _ListNewsCard(
            title: 'תוצאות הגביע: הפועל מודיעין ניצחה 2-0',
            category: 'ספורט',
            time: 'לפני 6 שעות',
            onTap: () => context.push('/article/demo_2'),
          ),
        ],
      ),
    );
  }
}

class _HeroNewsCard extends StatelessWidget {
  final String title;
  final String category;
  final VoidCallback onTap;

  const _HeroNewsCard({
    required this.title,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.midBlue.withValues(alpha: 0.12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.4, 1.0],
                    colors: [
                      Colors.transparent,
                      AppColors.navy.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'עדכני',
                    style: GoogleFonts.rubik(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
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
                    Text(
                      category,
                      style: GoogleFonts.rubik(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.turquoise,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: GoogleFonts.rubik(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListNewsCard extends StatelessWidget {
  final String title;
  final String category;
  final String time;
  final VoidCallback onTap;

  const _ListNewsCard({
    required this.title,
    required this.category,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.article_outlined,
                size: 24,
                color: AppColors.midBlue.withValues(alpha: 0.3),
              ),
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
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        category,
                        style: GoogleFonts.rubik(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.turquoise,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: GoogleFonts.rubik(
                          fontSize: 12,
                          color: AppColors.grayMeta,
                        ),
                      ),
                    ],
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
