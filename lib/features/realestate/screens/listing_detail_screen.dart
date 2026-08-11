import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class ListingDetailScreen extends StatelessWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: AppColors.midBlue.withValues(alpha: 0.08),
                      child: Center(
                        child: Icon(Icons.apartment, size: 80, color: AppColors.midBlue.withValues(alpha: 0.15)),
                      ),
                    ),
                    Positioned(
                      top: 90,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ללא תיווך · פרטי',
                          style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('1/12', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
                IconButton(icon: const Icon(Icons.share), onPressed: () {}),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '2,450,000 ₪',
                      style: GoogleFonts.rubik(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.navy),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'רח׳ הנרקיס 12, הפרחים (מירומי)',
                      style: GoogleFonts.rubik(fontSize: 15, color: AppColors.grayText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '4 חדרים · 110 מ"ר · קומה 3',
                      style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayText),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _SpecIcon(Icons.bed_outlined, '4', 'חדרים'),
                        _SpecIcon(Icons.square_foot, '110', 'מ"ר'),
                        _SpecIcon(Icons.stairs, '3', 'קומה'),
                        _SpecIcon(Icons.shield_outlined, '✓', 'ממ"ד'),
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
                            label: Text('התקשרו למוכר', style: GoogleFonts.rubik(fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
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
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('מאפייני הנכס', style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navy)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PropTag('מרפסת שמש'),
                        _PropTag('חניה פרטית'),
                        _PropTag('מעלית'),
                        _PropTag('מחסן'),
                        _PropTag('משופצת'),
                        _PropTag('מיזוג מרכזי'),
                        _PropTag('סורגים'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('תיאור', style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navy)),
                    const SizedBox(height: 8),
                    Text(
                      'דירת 4 חדרים מרווחת ומוארת בשכונת הפרחים. '
                      'הדירה עברה שיפוץ מלא לפני שנתיים וכוללת מטבח חדש, '
                      'שני חדרי רחצה, ממ"ד, מרפסת שמש גדולה וחניה פרטית.\n\n'
                      'קרובה לבתי ספר, גנים, מרכז מסחרי ותחבורה ציבורית. '
                      'מיקום שקט ומשפחתי.',
                      style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayText, height: 1.6),
                    ),
                    const SizedBox(height: 24),
                    Text('מיקום', style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navy)),
                    const SizedBox(height: 8),
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.midBlue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Icon(Icons.map, size: 40, color: AppColors.midBlue.withValues(alpha: 0.3)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('מחשבון משכנתא', style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navy)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.turquoise.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('סכום מימון (75%)', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText)),
                              Text('1,837,500 ₪', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ריבית משוערת', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText)),
                              Text('4.5%', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(color: AppColors.border),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('החזר חודשי משוער', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
                              Text(
                                '~7,200 ₪',
                                style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.turquoise),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('פרטי איש קשר', style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navy)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.success.withValues(alpha: 0.1),
                            child: const Icon(Icons.person, color: AppColors.success),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('דוד כהן', style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('בעלים פרטי', style: GoogleFonts.rubik(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('נכסים דומים בשכונה', style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navy)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 170,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final similar = [
                            ('3 חדרים · 90 מ"ר', '2,100,000 ₪'),
                            ('4 חדרים · 115 מ"ר', '2,550,000 ₪'),
                            ('5 חדרים · 135 מ"ר', '2,900,000 ₪'),
                          ];
                          final (specs, price) = similar[index];
                          return Container(
                            width: 180,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border, width: 0.5),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.midBlue.withValues(alpha: 0.06),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    ),
                                    child: Center(
                                      child: Icon(Icons.apartment, size: 36, color: AppColors.midBlue.withValues(alpha: 0.2)),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(price, style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy)),
                                      Text(specs, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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

class _SpecIcon extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SpecIcon(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.midBlue.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.midBlue),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
            Text(label, style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayLight)),
          ],
        ),
      ),
    );
  }
}

class _PropTag extends StatelessWidget {
  final String label;

  const _PropTag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.midBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: GoogleFonts.rubik(fontSize: 13, color: AppColors.midBlue)),
    );
  }
}
