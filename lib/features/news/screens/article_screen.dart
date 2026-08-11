import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class ArticleScreen extends StatelessWidget {
  final String articleId;

  const ArticleScreen({super.key, required this.articleId});

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
                  color: AppColors.navy.withValues(alpha: 0.85),
                  child: Center(
                    child: Icon(
                      Icons.article,
                      size: 60,
                      color: AppColors.white.withValues(alpha: 0.2),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.turquoise.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'עירייה',
                        style: GoogleFonts.rubik(
                          fontSize: 12,
                          color: AppColors.turquoise,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'פרויקט הרכבת הקלה: כך ייראה הקו החדש שיחבר את מודיעין למרכז',
                      style: GoogleFonts.rubik(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              AppColors.midBlue.withValues(alpha: 0.1),
                          child: Text(
                            'מ',
                            style: GoogleFonts.rubik(
                              fontWeight: FontWeight.w600,
                              color: AppColors.midBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'מערכת מודיעין בשבילך',
                          style: GoogleFonts.rubik(
                            fontSize: 13,
                            color: AppColors.grayText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '·  לפני שעה',
                          style: GoogleFonts.rubik(
                            fontSize: 13,
                            color: AppColors.grayLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'עיריית מודיעין מכבים רעות פרסמה היום את התוכנית המעודכנת '
                      'לקו הרכבת הקלה שיחבר את העיר למרכז הארץ. '
                      'הפרויקט, שאושר בוועדה המחוזית לתכנון ובנייה, '
                      'צפוי לכלול שלוש תחנות בתוך העיר.\n\n'
                      'התחנה המרכזית תוקם באזור המע"ר, '
                      'ותחנות נוספות בשכונת הפרחים ובכניסה הדרומית לעיר. '
                      'לפי ההערכות, הקו יקצר את זמן הנסיעה לתל אביב '
                      'לכ-25 דקות בלבד.\n\n'
                      'ראש העיר הגיב: "זהו צעד היסטורי עבור תושבי מודיעין. '
                      'הרכבת הקלה תשנה את פני התחבורה הציבורית בעיר '
                      'ותחבר אותנו למרכזי התעסוקה והלימודים הגדולים."',
                      style: GoogleFonts.rubik(
                        fontSize: 15,
                        color: AppColors.grayText,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'כתבות קשורות',
                      style: GoogleFonts.rubik(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _RelatedArticle('תכנון קו אוטובוס מהיר חדש לירושלים'),
                    const SizedBox(height: 8),
                    _RelatedArticle('עדכון חניה: חניון חדש ייפתח ליד התחנה'),
                    const SizedBox(height: 8),
                    _RelatedArticle('סקר תושבים: 78% תומכים בפרויקט'),
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

class _RelatedArticle extends StatelessWidget {
  final String title;

  const _RelatedArticle(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.rubik(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.navy,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: AppColors.grayLight,
          ),
        ],
      ),
    );
  }
}
