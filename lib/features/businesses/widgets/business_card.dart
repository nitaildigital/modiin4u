import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/skeleton.dart';

class BusinessCard extends StatelessWidget {
  final String name;
  final String category;
  final double rating;
  final int reviewCount;
  /// Null when the business has no opening hours on record, in which case
  /// no open/closed tag is shown rather than claiming it is closed.
  final bool? isOpen;
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
    this.isOpen,
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
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderClr, width: 0.5),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(12),
              ),
              child: _Thumbnail(url: imageUrl),
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
                            style: TextStyle(fontFamily: AppFonts.rubik, 
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOpen != null) _StatusTag(isOpen: isOpen!),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$category · $neighborhood',
                      style: TextStyle(fontFamily: AppFonts.rubik, 
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
                          style: TextStyle(fontFamily: AppFonts.rubik, 
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($reviewCount)',
                          style: TextStyle(fontFamily: AppFonts.rubik, 
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
                              style: TextStyle(fontFamily: AppFonts.rubik, 
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
        style: TextStyle(fontFamily: AppFonts.rubik, 
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isOpen ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}

/// The placeholder for [BusinessCard], built to the same geometry — the same
/// 110px thumbnail, the same line positions — so the list does not shift when
/// the businesses arrive.
class BusinessCardSkeleton extends StatelessWidget {
  const BusinessCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderClr, width: 0.5),
      ),
      child: Skeleton(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 110, height: 110, radius: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonLine(width: 150, fontSize: 15),
                    const SizedBox(height: 8),
                    const SkeletonLine(width: 190, fontSize: 13),
                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        SkeletonLine(width: 54, fontSize: 13),
                        SizedBox(width: 10),
                        SkeletonBox(width: 52, height: 16, radius: 4),
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

/// The 110px square on the leading edge of the card.
///
/// Fades the photo in once it arrives and falls back to the brand tint when a
/// business has no picture — 71 of the 200 in the directory do not.
class _Thumbnail extends StatelessWidget {
  final String? url;

  const _Thumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    const size = 110.0;

    final fallback = Container(
      width: size,
      height: size,
      color: AppColors.midBlue.withValues(alpha: 0.08),
      child: Icon(
        Icons.storefront_outlined,
        size: 34,
        color: AppColors.midBlue.withValues(alpha: 0.3),
      ),
    );

    final src = url;
    if (src == null || src.isEmpty) return fallback;

    return CachedNetworkImage(
      imageUrl: src,
      width: size,
      height: size,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}
