import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('משחקים', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.navy,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('הניקוד שלך', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.white.withValues(alpha: 0.8))),
                        const SizedBox(height: 4),
                        Text('1,240', style: GoogleFonts.rubik(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.white)),
                        Text('מקום #8 בדירוג', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.white.withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.leaderboard, color: AppColors.gold, size: 28),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('משחקים', style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: [
                _GameCard('טריוויית מודיעין', Icons.quiz, AppColors.turquoise, false),
                _GameCard('חידון שכונות', Icons.map, AppColors.midBlue, false),
                _GameCard('נחשו את העסק', Icons.store, AppColors.navy, true),
                _GameCard('זיכרון מודיעין', Icons.grid_view, AppColors.gold, true),
                _GameCard('בקרוב...', Icons.lock_clock, AppColors.grayLight, false),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final bool isNew;

  const _GameCard(this.name, this.icon, this.color, this.isNew);

  @override
  Widget build(BuildContext context) {
    final isLocked = name == 'בקרוב...';
    return GestureDetector(
      onTap: isLocked
          ? null
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$name — בקרוב! 🎮', style: GoogleFonts.rubik()),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isLocked ? 0.05 : 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 32, color: color.withValues(alpha: isLocked ? 0.3 : 1)),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: GoogleFonts.rubik(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isLocked ? AppColors.grayLight : AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                if (!isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('שחקו', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.white)),
                  ),
              ],
            ),
            if (isNew)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('חדש', style: GoogleFonts.rubik(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
