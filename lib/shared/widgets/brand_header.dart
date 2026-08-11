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
    this.height = 260,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/hero_anaba.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.navy.withValues(alpha: 0.75),
                    AppColors.midBlue.withValues(alpha: 0.65),
                    AppColors.turquoise.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'מודיעין בשבילך',
                      style: GoogleFonts.rubik(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'הכל על העיר שלך — במקום אחד',
                      style: GoogleFonts.rubik(
                        fontSize: 14,
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    if (searchHint != null) ...[
                      const SizedBox(height: 18),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
          ],
        ),
      ),
    );
  }
}
