import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/business_card.dart';

class BusinessesScreen extends StatefulWidget {
  const BusinessesScreen({super.key});

  @override
  State<BusinessesScreen> createState() => _BusinessesScreenState();
}

class _BusinessesScreenState extends State<BusinessesScreen> {
  String _selectedCategory = 'הכל';
  final _selectedFilters = <String>{};

  final _categories = [
    'הכל',
    'מסעדות',
    'ברים',
    'קפה',
    'חנויות',
    'מקצוענים',
    'נדל"ן',
  ];

  final _quickFilters = [
    'פתוח עכשיו',
    'משלוחים',
    'ישיבה בחוץ',
    'כשר',
    'חניה',
    'נגישות',
    '4+',
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 130,
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.navy,
            title: Text(
              'עסקים ושירותים',
              style: GoogleFonts.rubik(fontWeight: FontWeight.w700),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                height: 56,
                padding: const EdgeInsets.only(bottom: 10),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final selected = cat == _selectedCategory;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = cat),
                      selectedColor: AppColors.turquoise,
                      labelStyle: GoogleFonts.rubik(
                        color: selected ? AppColors.white : AppColors.navy,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'חפשו בשפה חופשית... "סושי כשר פתוח עכשיו"',
                    hintTextDirection: TextDirection.rtl,
                    prefixIcon: const Icon(
                      Icons.auto_awesome,
                      color: AppColors.turquoise,
                    ),
                    suffixIcon: const Icon(Icons.search, color: AppColors.grayLight),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                itemCount: _quickFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final filter = _quickFilters[index];
                  final selected = _selectedFilters.contains(filter);
                  return FilterChip(
                    label: Text(
                      filter,
                      style: GoogleFonts.rubik(fontSize: 12),
                    ),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedFilters.add(filter);
                        } else {
                          _selectedFilters.remove(filter);
                        }
                      });
                    },
                    selectedColor: AppColors.turquoise.withValues(alpha: 0.1),
                    checkmarkColor: AppColors.turquoise,
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '42 תוצאות',
                    style: GoogleFonts.rubik(
                      fontSize: 13,
                      color: AppColors.grayText,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'מיון:',
                        style: GoogleFonts.rubik(
                          fontSize: 13,
                          color: AppColors.grayText,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'מומלץ AI',
                        style: GoogleFonts.rubik(
                          fontSize: 13,
                          color: AppColors.turquoise,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: AppColors.turquoise,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: 10,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return BusinessCard(
                  name: [
                    'מסעדת נאיתאי',
                    'פיצה פרגו',
                    'קפה גרג',
                    'בורגרס בר',
                    'סושי מודיעין',
                    'המאפייה של שלומי',
                    'ביסטרו 770',
                    'מסעדת ג\'ויה',
                    'הסטייקיה',
                    'בית הפלאפל'
                  ][index],
                  category: [
                    'תאילנדי',
                    'פיצה',
                    'בית קפה',
                    'המבורגרים',
                    'סושי',
                    'מאפייה',
                    'איטלקי',
                    'ים תיכוני',
                    'בשרים',
                    'ישראלי'
                  ][index],
                  rating: 4.0 + (index % 10) / 10,
                  reviewCount: 15 + index * 7,
                  isOpen: index % 3 != 2,
                  kosher: index % 2 == 0 ? 'כשר' : null,
                  neighborhood: [
                    'המע"ר',
                    'הפרחים',
                    'נופים',
                    'מוריה',
                    'אבני חן',
                    'המע"ר',
                    'הנחלים',
                    'משואה',
                    'המגינים',
                    'השבטים'
                  ][index],
                  onTap: () => context.push('/business/demo_$index'),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}
