import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../businesses/widgets/review_card.dart';

class ProfessionalDetailScreen extends StatelessWidget {
  final String professionalId;

  const ProfessionalDetailScreen({super.key, required this.professionalId});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.midBlue, AppColors.turquoise.withValues(alpha: 0.7)],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.white,
                          child: Text(
                            'יר',
                            style: GoogleFonts.rubik(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.midBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'יוסי רביבו',
                          style: GoogleFonts.rubik(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                        Text(
                          'אינסטלטור',
                          style: GoogleFonts.rubik(
                            fontSize: 14,
                            color: AppColors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(icon: const Icon(Icons.share), onPressed: () {}),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'זמין עכשיו',
                                style: GoogleFonts.rubik(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.timer_outlined, size: 16, color: AppColors.grayLight),
                        const SizedBox(width: 4),
                        Text(
                          'משיב תוך כ-15 דק׳',
                          style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 18, color: AppColors.gold),
                        const SizedBox(width: 4),
                        Text(
                          '4.8',
                          style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(43 ביקורות)',
                          style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.phone),
                            label: Text('התקשרו', style: GoogleFonts.rubik(fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.chat, size: 18),
                            label: Text('וואטסאפ', style: GoogleFonts.rubik(fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            child: Text('הצעת מחיר', style: GoogleFonts.rubik(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'תחומי התמחות',
                      style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navy),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SpecTag('פתיחת סתימות'),
                        _SpecTag('התקנת דודים'),
                        _SpecTag('תיקוני אינסטלציה'),
                        _SpecTag('שירות חירום 24/7'),
                        _SpecTag('ברזים וסוללות'),
                        _SpecTag('דוד שמש'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'אזור שירות',
                      style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navy),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.midBlue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.radar, size: 40, color: AppColors.turquoise.withValues(alpha: 0.4)),
                            const SizedBox(height: 6),
                            Text(
                              'רדיוס 15 ק"מ ממודיעין',
                              style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'עבודות אחרונות',
                      style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navy),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          return Container(
                            width: 120,
                            decoration: BoxDecoration(
                              color: AppColors.midBlue.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.plumbing,
                                size: 32,
                                color: AppColors.midBlue.withValues(alpha: 0.25),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'ביקורות',
                      style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navy),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'רק מי שהזמין שירות בפועל יכול לכתוב ביקורת',
                      style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayLight),
                    ),
                    const SizedBox(height: 12),
                    const ReviewCard(
                      userName: 'אורי ל.',
                      rating: 5,
                      text: 'הגיע תוך שעה, תיקן סתימה קשה בלי בעיה. מחיר הוגן ועבודה מקצועית.',
                      date: 'לפני 5 ימים',
                      isVerified: true,
                    ),
                    const SizedBox(height: 10),
                    const ReviewCard(
                      userName: 'שרית כ.',
                      rating: 5,
                      text: 'החליף דוד שמש. עבודה מצוינת, ניקה אחריו. ממליצה בחום!',
                      date: 'לפני שבועיים',
                      isVerified: true,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecTag extends StatelessWidget {
  final String label;

  const _SpecTag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.turquoise.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: GoogleFonts.rubik(fontSize: 13, color: AppColors.midBlue),
      ),
    );
  }
}
