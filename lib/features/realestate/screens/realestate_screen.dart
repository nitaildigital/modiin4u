import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class RealEstateScreen extends StatefulWidget {
  const RealEstateScreen({super.key});

  @override
  State<RealEstateScreen> createState() => _RealEstateScreenState();
}

class _RealEstateScreenState extends State<RealEstateScreen> {
  bool _isSale = true;
  bool _isMapView = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('נדל"ן', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.navy,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(_isMapView ? Icons.list : Icons.map_outlined),
              onPressed: () => setState(() => _isMapView = !_isMapView),
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isSale = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isSale ? AppColors.turquoise : AppColors.white,
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                            border: Border.all(color: _isSale ? AppColors.turquoise : AppColors.border),
                          ),
                          child: Center(
                            child: Text(
                              'למכירה',
                              style: GoogleFonts.rubik(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _isSale ? AppColors.white : AppColors.grayText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isSale = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isSale ? AppColors.turquoise : AppColors.white,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                            border: Border.all(color: !_isSale ? AppColors.turquoise : AppColors.border),
                          ),
                          child: Center(
                            child: Text(
                              'להשכרה',
                              style: GoogleFonts.rubik(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: !_isSale ? AppColors.white : AppColors.grayText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  children: [
                    _FilterButton('חדרים', Icons.bed_outlined),
                    const SizedBox(width: 8),
                    _FilterButton('מחיר', Icons.attach_money),
                    const SizedBox(width: 8),
                    _FilterButton('שכונה', Icons.location_on_outlined),
                    const SizedBox(width: 8),
                    _FilterButton('סוג נכס', Icons.home_outlined),
                    const SizedBox(width: 8),
                    _QuickChip('ללא תיווך'),
                    const SizedBox(width: 8),
                    _FilterButton('עוד סינון', Icons.tune),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.turquoise.withValues(alpha: 0.06),
                      AppColors.midBlue.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, color: AppColors.turquoise, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'מחיר ממוצע למ"ר בהמע"ר: 29,500 ₪',
                            style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy),
                          ),
                          Text(
                            'עלייה של 3.2% ברבעון האחרון',
                            style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: AppColors.gold, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'שמרו חיפוש וקבלו התראה כשעולה נכס חדש תואם',
                        style: GoogleFonts.rubik(fontSize: 12, color: AppColors.navy),
                      ),
                    ),
                    Text('הגדרה', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.turquoise, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: 8,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final listings = [
                    ('4 חדרים · 110 מ"ר · קומה 3', 'הפרחים (מירומי)', '2,450,000 ₪', 'פרטי'),
                    ('5 חדרים · 140 מ"ר · קומה 7', 'אבני חן (קייזר)', '3,100,000 ₪', 'תיווך'),
                    ('3 חדרים · 85 מ"ר · קומה 2', 'מרכז העיר (המע"ר)', '1,950,000 ₪', 'פרטי'),
                    ('דופלקס · 6 חדרים · 180 מ"ר', 'נופים', '4,200,000 ₪', 'בלעדיות'),
                    ('פנטהאוז · 5 חדרים · 160 מ"ר', 'מוריה (בוכמן דרום)', '3,800,000 ₪', 'תיווך'),
                    ('4 חדרים · 120 מ"ר · קומה 5', 'הנחלים (ספדיה)', '2,700,000 ₪', 'פרטי'),
                    ('3 חדרים · 90 מ"ר · קומה 1', 'משואה (גבעת C)', '2,100,000 ₪', 'פרויקט חדש'),
                    ('גן · 5 חדרים · 130 מ"ר', 'הכרמים (ציפור)', '3,300,000 ₪', 'פרטי'),
                  ];
                  final (specs, neighborhood, price, sellerType) = listings[index];
                  final isPrivate = sellerType == 'פרטי';

                  return GestureDetector(
                    onTap: () => context.push('/listing/demo_$index'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color: AppColors.midBlue.withValues(alpha: 0.06),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Icon(Icons.apartment, size: 48, color: AppColors.midBlue.withValues(alpha: 0.2)),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPrivate ? AppColors.success : AppColors.midBlue,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      sellerType,
                                      style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  price,
                                  style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  specs,
                                  style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayText),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 14, color: AppColors.grayLight),
                                    const SizedBox(width: 4),
                                    Text(
                                      neighborhood,
                                      style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight),
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

class _FilterButton extends StatelessWidget {
  final String label;
  final IconData icon;

  const _FilterButton(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.grayLight),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.rubik(fontSize: 13, color: AppColors.navy)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.grayLight),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;

  const _QuickChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.rubik(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
