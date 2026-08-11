import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/review_card.dart';

class BusinessDetailScreen extends StatelessWidget {
  final String businessId;

  const BusinessDetailScreen({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: AppColors.midBlue.withValues(alpha: 0.1),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.restaurant,
                          size: 80,
                          color: AppColors.midBlue.withValues(alpha: 0.2),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 20,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.restaurant,
                            color: AppColors.turquoise,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {},
                ),
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
                        Expanded(
                          child: Text(
                            'מסעדת נאיתאי',
                            style: GoogleFonts.rubik(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'פתוח עכשיו',
                            style: GoogleFonts.rubik(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'מטבח תאילנדי · ₪₪₪ · המע"ר',
                      style: GoogleFonts.rubik(
                        fontSize: 14,
                        color: AppColors.grayText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 18, color: AppColors.gold),
                        const SizedBox(width: 4),
                        Text(
                          '4.6',
                          style: GoogleFonts.rubik(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(87 ביקורות)',
                          style: GoogleFonts.rubik(
                            fontSize: 13,
                            color: AppColors.grayLight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.midBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'כשר',
                            style: GoogleFonts.rubik(
                              fontSize: 12,
                              color: AppColors.midBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _ActionBar(),
                    const SizedBox(height: 24),
                    _Section(
                      title: 'אודות',
                      child: Text(
                        'מסעדה תאילנדית אותנטית בלב מודיעין. '
                        'התפריט שלנו כולל מגוון מנות מהמטבח התאילנדי המסורתי, '
                        'מוכנות מחומרי גלם טריים ותבלינים מיובאים.',
                        style: GoogleFonts.rubik(
                          fontSize: 14,
                          color: AppColors.grayText,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _Section(
                      title: 'שעות פעילות',
                      child: Column(
                        children: [
                          _HoursRow('ראשון - חמישי', '11:00 - 23:00'),
                          _HoursRow('שישי', '11:00 - 15:00'),
                          _HoursRow('שבת', 'סגור'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _Section(
                      title: 'מאפיינים',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Tag('כשר'),
                          _Tag('משלוחים'),
                          _Tag('ישיבה בחוץ'),
                          _Tag('חניה'),
                          _Tag('נגישות'),
                          _Tag('Wi-Fi'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _Section(
                      title: 'מיקום',
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppColors.midBlue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map,
                                size: 40,
                                color: AppColors.midBlue.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'רח׳ הלוטוס 5, המע"ר',
                                style: GoogleFonts.rubik(
                                  fontSize: 13,
                                  color: AppColors.grayText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _Section(
                      title: 'ביקורות',
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.turquoise.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.verified_user,
                                  size: 18,
                                  color: AppColors.turquoise,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'רק תושבים רשומים ומאומתים יכולים לדרג ולכתוב ביקורת',
                                    style: GoogleFonts.rubik(
                                      fontSize: 12,
                                      color: AppColors.midBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const ReviewCard(
                            userName: 'יעל כ.',
                            rating: 5,
                            text:
                                'אוכל מדהים! הקארי האדום הכי טוב שאכלתי. שירות מצוין ואווירה נעימה.',
                            date: 'לפני 3 ימים',
                            isVerified: true,
                          ),
                          const SizedBox(height: 12),
                          const ReviewCard(
                            userName: 'דני מ.',
                            rating: 4,
                            text:
                                'מסעדה טובה עם אוכל איכותי. קצת יקר אבל שווה את זה.',
                            date: 'לפני שבוע',
                            isVerified: true,
                            ownerReply:
                                'תודה דני! שמחים שנהנית. מוזמן לחזור ולנסות את התפריט החדש.',
                          ),
                          const SizedBox(height: 12),
                          const ReviewCard(
                            userName: 'מיכל ש.',
                            rating: 5,
                            text:
                                'המקום האהוב עלינו! הילדים אוהבים את הפד תאי.',
                            date: 'לפני שבועיים',
                            isVerified: true,
                          ),
                        ],
                      ),
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

class _ActionBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ActionButton(Icons.phone, 'התקשרו', AppColors.turquoise, true),
          const SizedBox(width: 8),
          _ActionButton(Icons.calendar_today, 'הזמנת מקום', AppColors.midBlue, false),
          const SizedBox(width: 8),
          _ActionButton(Icons.delivery_dining, 'משלוח', AppColors.midBlue, false),
          const SizedBox(width: 8),
          _ActionButton(Icons.chat, 'וואטסאפ', AppColors.midBlue, false),
          const SizedBox(width: 8),
          _ActionButton(Icons.language, 'אתר', AppColors.midBlue, false),
          const SizedBox(width: 8),
          _ActionButton(Icons.navigation, 'ניווט', AppColors.midBlue, false),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isPrimary;

  const _ActionButton(this.icon, this.label, this.color, this.isPrimary);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isPrimary ? color : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isPrimary ? AppColors.white : color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.rubik(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isPrimary ? AppColors.white : color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.rubik(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _HoursRow extends StatelessWidget {
  final String day;
  final String hours;

  const _HoursRow(this.day, this.hours);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayText),
          ),
          Text(
            hours,
            style: GoogleFonts.rubik(
              fontSize: 14,
              color: hours == 'סגור' ? AppColors.error : AppColors.navy,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.midBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.midBlue.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.rubik(
          fontSize: 13,
          color: AppColors.midBlue,
        ),
      ),
    );
  }
}
