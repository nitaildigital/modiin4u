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
  _CategoryItem(Icons.nightlife, 'לבלות', '/businesses'),
  _CategoryItem(Icons.map, 'מפה', '/map'),
  _CategoryItem(Icons.apartment, 'נדל"ן', '/businesses'),
  _CategoryItem(Icons.build, 'מקצוענים', '/businesses'),
  _CategoryItem(Icons.local_offer, 'הטבות', '/businesses'),
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
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return GestureDetector(
            onTap: () => context.go(cat.route),
            child: SizedBox(
              width: 70,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.midBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(cat.icon, color: AppColors.midBlue, size: 28),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.label,
                    style: GoogleFonts.rubik(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.navy,
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
