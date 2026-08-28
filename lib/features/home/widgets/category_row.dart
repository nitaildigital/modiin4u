import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class _CategoryItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final String route;
  final Color accent;

  const _CategoryItem(this.icon, this.label, this.subtitle, this.route, this.accent);
}

const _categories = [
  _CategoryItem(Icons.article_outlined, 'חדשות', 'עדכונים שוטפים', '/news', Color(0xFF3B82F6)),
  _CategoryItem(Icons.event_outlined, 'אירועים', 'מה קורה בעיר', '/events', Color(0xFFF59E0B)),
  _CategoryItem(Icons.people_outlined, 'קהילה', 'קהילה מקומית', '/community', Color(0xFF10B981)),
  _CategoryItem(Icons.engineering_outlined, 'מקצוענים', 'שירותים מקצועיים', '/businesses', Color(0xFF8B5CF6)),
  _CategoryItem(Icons.map_outlined, 'מפות', 'גלו את העיר', '/map', Color(0xFFEC4899)),
  _CategoryItem(Icons.store_outlined, 'עסקים', 'המקומות האהובים', '/businesses', Color(0xFF06B6D4)),
  _CategoryItem(Icons.apartment_outlined, 'נדל"ן', 'מצאו את הבית', '/realestate', Color(0xFFEF4444)),
];

class CategoryRow extends StatelessWidget {
  const CategoryRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return GestureDetector(
            onTap: () => context.go(cat.route),
            child: Container(
              width: 110,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderClr, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: context.isDark ? Colors.black12 : AppColors.cardShadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: cat.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(cat.icon, size: 18, color: cat.accent),
                  ),
                  const Spacer(),
                  Text(
                    cat.label,
                    style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary),
                  ),
                  Text(
                    cat.subtitle,
                    style: GoogleFonts.rubik(fontSize: 10, color: AppColors.grayMeta),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
