import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  String _selectedCategory = 'הכל';

  final _categories = ['הכל', 'מסעדות ובילוי', 'קניות', 'יופי ובריאות', 'פנאי ותרבות'];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('הטבות', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
          backgroundColor: context.cardBg,
          foregroundColor: context.textPrimary,
          elevation: 0,
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final sel = cat == _selectedCategory;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: sel,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                      selectedColor: AppColors.turquoise,
                      labelStyle: GoogleFonts.rubik(
                        fontSize: 13,
                        color: sel ? AppColors.white : context.textPrimary,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _QuickChip('נגמר בקרוב', Icons.timer),
                    const SizedBox(width: 8),
                    _QuickChip('הכי פופולרי', Icons.trending_up),
                    const SizedBox(width: 8),
                    _QuickChip('חדש', Icons.fiber_new),
                    const SizedBox(width: 8),
                    _QuickChip('לרשומים בלבד', Icons.lock_outline),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: 7,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final deals = [
                    ('20% הנחה', 'קפה גרג', 'על כל המשקאות החמים', 'הפרחים', '3 ימים', true),
                    ('1+1', 'פיצה פרגו', 'פיצה אישית שנייה חינם', 'המע"ר', '5 ימים', false),
                    ('15% הנחה', 'אופטיקה הלפרין', 'על מסגרות משקפיים', 'אבני חן', '7 ימים', true),
                    ('משלוח חינם', 'סושי מודיעין', 'בהזמנה מעל 100 ₪', 'נופים', '2 ימים', false),
                    ('30% הנחה', 'סטודיו יוגה מודיעין', 'על כרטיסייה חודשית', 'מוריה', '10 ימים', true),
                    ('קנו 2 קבלו 3', 'המאפייה של שלומי', 'על כל הלחמים', 'הנחלים', '4 ימים', false),
                    ('50 ₪ הנחה', 'בורגרס בר', 'בהזמנה מעל 150 ₪', 'המע"ר', '1 יום', true),
                  ];
                  final (discount, business, description, neighborhood, timeLeft, isExclusive) = deals[index];

                  return GestureDetector(
                    onTap: () => context.push('/deal/demo_$index'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.borderClr, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 90,
                            height: 110,
                            decoration: BoxDecoration(
                              color: AppColors.turquoise.withValues(alpha: 0.08),
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
                            ),
                            child: Center(
                              child: Text(
                                discount,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.rubik(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.turquoise,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          business,
                                          style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimary),
                                        ),
                                      ),
                                      if (isExclusive)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.gold.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.lock, size: 10, color: AppColors.gold),
                                              const SizedBox(width: 3),
                                              Text('רשומים', style: GoogleFonts.rubik(fontSize: 10, color: AppColors.gold, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(description, style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, size: 13, color: AppColors.grayLight),
                                      const SizedBox(width: 4),
                                      Text(neighborhood, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayLight)),
                                      const Spacer(),
                                      Icon(Icons.timer_outlined, size: 13, color: AppColors.error),
                                      const SizedBox(width: 4),
                                      Text(
                                        'עוד $timeLeft',
                                        style: GoogleFonts.rubik(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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

class _QuickChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _QuickChip(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.borderClr),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.grayLight),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.rubik(fontSize: 12, color: context.textPrimary)),
        ],
      ),
    );
  }
}
