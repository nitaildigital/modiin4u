import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class _CategoryItem {
  final IconData icon;
  final String label;
  final String route;

  const _CategoryItem(this.icon, this.label, this.route);
}

const _categories = [
  _CategoryItem(Icons.restaurant, 'לאכול', '/businesses'),
  _CategoryItem(Icons.nightlife, 'לבלות', '/events'),
  _CategoryItem(Icons.map, 'מפה', '/map'),
  _CategoryItem(Icons.apartment, 'נדל"ן', '/realestate'),
  _CategoryItem(Icons.build, 'מקצוענים', '/businesses'),
  _CategoryItem(Icons.local_offer, 'הטבות', '/deals'),
  _CategoryItem(Icons.people, 'קהילה', '/community'),
  _CategoryItem(Icons.sports_esports, 'משחקים', '/games'),
  _CategoryItem(Icons.directions_walk, 'צעדים', '/steps'),
  _CategoryItem(Icons.local_parking, 'חניה', '/parking'),
];

class CategoryRow extends StatelessWidget {
  const CategoryRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return GestureDetector(
            onTap: () => context.go(cat.route),
            child: SizedBox(
              width: 64,
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Icon(cat.icon, color: AppColors.midBlue, size: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.label,
                    style: GoogleFonts.rubik(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grayMeta,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
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
