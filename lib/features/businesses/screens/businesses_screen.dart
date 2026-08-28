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
  String _searchQuery = '';

  static const _allBusinesses = [
    (name: 'מסעדת נאיתאי', category: 'תאילנדי', catGroup: 'מסעדות', rating: 4.6, reviews: 87, isOpen: true, kosher: 'כשר', neighborhood: 'המע"ר', hasDelivery: false, hasOutdoor: true, hasParking: true, accessible: true),
    (name: 'פיצה פרגו', category: 'פיצה', catGroup: 'מסעדות', rating: 4.5, reviews: 64, isOpen: true, kosher: 'כשר', neighborhood: 'הפרחים', hasDelivery: true, hasOutdoor: false, hasParking: false, accessible: true),
    (name: 'קפה גרג', category: 'בית קפה', catGroup: 'קפה', rating: 4.3, reviews: 42, isOpen: true, kosher: null, neighborhood: 'נופים', hasDelivery: false, hasOutdoor: true, hasParking: true, accessible: true),
    (name: 'בורגרס בר', category: 'המבורגרים', catGroup: 'מסעדות', rating: 4.7, reviews: 95, isOpen: false, kosher: null, neighborhood: 'מוריה', hasDelivery: true, hasOutdoor: true, hasParking: false, accessible: false),
    (name: 'סושי מודיעין', category: 'סושי', catGroup: 'מסעדות', rating: 4.4, reviews: 58, isOpen: true, kosher: 'כשר', neighborhood: 'אבני חן', hasDelivery: true, hasOutdoor: false, hasParking: true, accessible: true),
    (name: 'המאפייה של שלומי', category: 'מאפייה', catGroup: 'חנויות', rating: 4.8, reviews: 112, isOpen: true, kosher: 'כשר', neighborhood: 'המע"ר', hasDelivery: false, hasOutdoor: false, hasParking: false, accessible: true),
    (name: 'ביסטרו 770', category: 'איטלקי', catGroup: 'מסעדות', rating: 4.2, reviews: 34, isOpen: false, kosher: null, neighborhood: 'הנחלים', hasDelivery: false, hasOutdoor: true, hasParking: true, accessible: true),
    (name: 'מסעדת ג\'ויה', category: 'ים תיכוני', catGroup: 'מסעדות', rating: 4.5, reviews: 76, isOpen: true, kosher: 'כשר', neighborhood: 'משואה', hasDelivery: true, hasOutdoor: true, hasParking: true, accessible: true),
    (name: 'הסטייקיה', category: 'בשרים', catGroup: 'מסעדות', rating: 4.1, reviews: 48, isOpen: true, kosher: null, neighborhood: 'המגינים', hasDelivery: false, hasOutdoor: false, hasParking: true, accessible: false),
    (name: 'בית הפלאפל', category: 'ישראלי', catGroup: 'מסעדות', rating: 4.6, reviews: 156, isOpen: true, kosher: 'כשר', neighborhood: 'השבטים', hasDelivery: true, hasOutdoor: true, hasParking: false, accessible: true),
  ];

  List<int> get _filteredIndices {
    final indices = <int>[];
    for (var i = 0; i < _allBusinesses.length; i++) {
      final b = _allBusinesses[i];
      if (_selectedCategory != 'הכל' && b.catGroup != _selectedCategory && b.category != _selectedCategory) continue;
      if (_searchQuery.isNotEmpty && !b.name.contains(_searchQuery) && !b.category.contains(_searchQuery) && !b.neighborhood.contains(_searchQuery)) continue;
      if (_selectedFilters.contains('פתוח עכשיו') && !b.isOpen) continue;
      if (_selectedFilters.contains('משלוחים') && !b.hasDelivery) continue;
      if (_selectedFilters.contains('ישיבה בחוץ') && !b.hasOutdoor) continue;
      if (_selectedFilters.contains('כשר') && b.kosher == null) continue;
      if (_selectedFilters.contains('חניה') && !b.hasParking) continue;
      if (_selectedFilters.contains('נגישות') && !b.accessible) continue;
      if (_selectedFilters.contains('4+') && b.rating < 4.0) continue;
      indices.add(i);
    }
    return indices;
  }

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
      child: RefreshIndicator(
        onRefresh: () async { await Future.delayed(const Duration(milliseconds: 800)); },
        color: AppColors.turquoise,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 130,
            backgroundColor: context.cardBg,
            foregroundColor: context.textPrimary,
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
                        color: selected ? AppColors.white : context.textPrimary,
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
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderClr),
                ),
                child: TextField(
                  textDirection: TextDirection.rtl,
                  onChanged: (val) => setState(() => _searchQuery = val),
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
                    '${_filteredIndices.length} תוצאות',
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
          _filteredIndices.isEmpty
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 56, color: AppColors.grayLight.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text('לא נמצאו עסקים', style: GoogleFonts.rubik(fontSize: 16, color: AppColors.grayMeta)),
                      const SizedBox(height: 8),
                      Text('נסו לשנות את הסינון או החיפוש', style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayLight)),
                    ],
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: _filteredIndices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final i = _filteredIndices[idx];
                    final b = _allBusinesses[i];
                    return BusinessCard(
                      name: b.name,
                      category: b.category,
                      rating: b.rating,
                      reviewCount: b.reviews,
                      isOpen: b.isOpen,
                      kosher: b.kosher,
                      neighborhood: b.neighborhood,
                      onTap: () => context.push('/business/demo_$i'),
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
