import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class BrandHeader extends StatelessWidget {
  final String? searchHint;
  final ValueChanged<String>? onSearch;
  final double height;

  const BrandHeader({
    super.key,
    this.searchHint,
    this.onSearch,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'מודיעין בשבילך',
                style: GoogleFonts.rubik(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'הכל על העיר שלך — במקום אחד',
                style: GoogleFonts.rubik(
                  fontSize: 14,
                  color: AppColors.white.withValues(alpha: 0.85),
                ),
              ),
              if (searchHint != null) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    textDirection: TextDirection.rtl,
                    onSubmitted: onSearch,
                    decoration: InputDecoration(
                      hintText: searchHint,
                      hintTextDirection: TextDirection.rtl,
                      prefixIcon: const Icon(
                        Icons.auto_awesome,
                        color: AppColors.turquoise,
                      ),
                      suffixIcon: const Icon(
                        Icons.search,
                        color: AppColors.grayLight,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
