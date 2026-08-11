import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class BusinessCard extends StatelessWidget {
  final String name;
  final String category;
  final double rating;
  final int reviewCount;
  final bool isOpen;
  final String? kosher;
  final String neighborhood;
  final String? imageUrl;
  final VoidCallback? onTap;

  const BusinessCard({
    super.key,
    required this.name,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.isOpen,
    this.kosher,
    required this.neighborhood,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.midBlue.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(12),
                ),
              ),
              child: Icon(
                Icons.restaurant,
                size: 36,
                color: AppColors.midBlue.withValues(alpha: 0.3),
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
                            name,
                            style: GoogleFonts.rubik(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _StatusTag(isOpen: isOpen),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$category · $neighborhood',
                      style: GoogleFonts.rubik(
                        fontSize: 13,
                        color: AppColors.grayText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: AppColors.gold),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.rubik(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($reviewCount)',
                          style: GoogleFonts.rubik(
                            fontSize: 12,
                            color: AppColors.grayLight,
                          ),
                        ),
                        if (kosher != null) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.midBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              kosher!,
                              style: GoogleFonts.rubik(
                                fontSize: 11,
                                color: AppColors.midBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
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
  }
}

class _StatusTag extends StatelessWidget {
  final bool isOpen;

  const _StatusTag({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOpen
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isOpen ? 'פתוח' : 'סגור',
        style: GoogleFonts.rubik(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isOpen ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}
