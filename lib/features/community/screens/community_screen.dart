import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('קהילה', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.navy,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 8),
            _PointsCard(),
            const SizedBox(height: 16),
            _StoriesRow(),
            const SizedBox(height: 16),
            _ResidentOfMonth(),
            const SizedBox(height: 16),
            _ReportIssueButton(),
            const SizedBox(height: 16),
            _SurveyCard(),
            const SizedBox(height: 16),
            _WeeklyDigest(),
            const SizedBox(height: 16),
            _PhotoGallery(),
            const SizedBox(height: 16),
            _WeeklyChallenge(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _PointsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text('הנקודות שלך', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.white.withValues(alpha: 0.8))),
                const SizedBox(height: 4),
                Text('340', style: GoogleFonts.rubik(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.white)),
                Text('דירוג #23 בשכונת הפרחים', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.white.withValues(alpha: 0.7))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Icon(Icons.emoji_events, color: AppColors.gold, size: 28),
                const SizedBox(height: 4),
                Text('רמה 3', style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoriesRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stories = ['העירייה', 'קפה גרג', 'פיצה פרגו', 'סושי מודיעין', 'הסטייקיה', 'ביסטרו'];
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isFirst = index == 0;
          return Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isFirst ? null : AppColors.brandGradient,
                  color: isFirst ? AppColors.midBlue : null,
                  border: Border.all(
                    color: isFirst ? AppColors.midBlue : AppColors.turquoise,
                    width: 2.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    isFirst ? Icons.account_balance : Icons.store,
                    color: AppColors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                stories[index],
                style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayText),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ResidentOfMonth extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events, color: AppColors.gold, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('תושב/ת החודש', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.w600)),
                Text('מיכל ל. — שכונת נופים', style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy)),
                Text('42 ביקורות, 8 דיווחי תקלות השנה', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportIssueButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.report_problem_outlined, color: AppColors.error, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('דיווח תקלה', style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy)),
                Text('בור בכביש, תאורה, ניקיון...', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.grayLight),
        ],
      ),
    );
  }
}

class _SurveyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.turquoise.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.how_to_vote, color: AppColors.turquoise, size: 20),
              const SizedBox(width: 8),
              Text('קול התושב', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'מה חשוב לכם יותר בפארק החדש בשכונת הנביאים?',
            style: GoogleFonts.rubik(fontSize: 14, color: AppColors.navy),
          ),
          const SizedBox(height: 12),
          _SurveyOption('מתקני ספורט וכושר', 0.45),
          const SizedBox(height: 6),
          _SurveyOption('גן משחקים לילדים', 0.32),
          const SizedBox(height: 6),
          _SurveyOption('שטחי דשא ופיקניק', 0.23),
          const SizedBox(height: 10),
          Text('187 הצביעו', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayLight)),
        ],
      ),
    );
  }
}

class _SurveyOption extends StatelessWidget {
  final String label;
  final double percentage;

  const _SurveyOption(this.label, this.percentage);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
        ),
        Container(
          height: 40,
          width: MediaQuery.of(context).size.width * percentage * 0.85,
          decoration: BoxDecoration(
            color: AppColors.turquoise.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: GoogleFonts.rubik(fontSize: 13, color: AppColors.navy)),
                Text('${(percentage * 100).round()}%', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.turquoise)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeeklyDigest extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.turquoise.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.turquoise, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('דיגסט שבועי', style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy)),
                Text('מה קורה השבוע במודיעין — סיכום AI', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('חדש', style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.gold)),
          ),
        ],
      ),
    );
  }
}

class _PhotoGallery extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('מודיעין בעדשתך', style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
            TextButton(
              onPressed: () {},
              child: Text('לכל הגלריה', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.turquoise)),
            ),
          ],
        ),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final colors = [AppColors.turquoise, AppColors.midBlue, AppColors.gold, AppColors.navy, AppColors.success];
              return Container(
                width: 120,
                decoration: BoxDecoration(
                  color: colors[index].withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(Icons.photo_camera, size: 30, color: colors[index].withValues(alpha: 0.3)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WeeklyChallenge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.turquoise.withValues(alpha: 0.06), AppColors.gold.withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag, color: AppColors.turquoise, size: 20),
              const SizedBox(width: 8),
              Text('אתגר השבוע', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy)),
            ],
          ),
          const SizedBox(height: 8),
          Text('בקרו ב-3 עסקים חדשים וכתבו ביקורת', style: GoogleFonts.rubik(fontSize: 14, color: AppColors.navy)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: 0.33,
                    minHeight: 8,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.turquoise),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('1/3', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.turquoise)),
            ],
          ),
          const SizedBox(height: 6),
          Text('פרס: 50 נקודות + קופון הנחה', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
        ],
      ),
    );
  }
}
