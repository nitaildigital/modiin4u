import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class ReviewCard extends StatelessWidget {
  final String userName;
  final int rating;
  final String text;
  final String date;
  final bool isVerified;
  final String? ownerReply;

  const ReviewCard({
    super.key,
    required this.userName,
    required this.rating,
    required this.text,
    required this.date,
    this.isVerified = false,
    this.ownerReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderClr, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.midBlue.withValues(alpha: 0.1),
                child: Text(
                  userName.characters.first,
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.midBlue,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          userName,
                          style: GoogleFonts.rubik(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.turquoise.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: AppColors.turquoise,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'תושב מאומת',
                                  style: GoogleFonts.rubik(
                                    fontSize: 10,
                                    color: AppColors.turquoise,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: GoogleFonts.rubik(
                        fontSize: 12,
                        color: AppColors.grayLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < rating ? Icons.star : Icons.star_border,
                size: 16,
                color: AppColors.gold,
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.rubik(
              fontSize: 14,
              color: AppColors.grayText,
              height: 1.4,
            ),
          ),
          if (ownerReply != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.midBlue.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  right: BorderSide(
                    color: AppColors.midBlue.withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'תגובת בעל העסק',
                    style: GoogleFonts.rubik(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.midBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ownerReply!,
                    style: GoogleFonts.rubik(
                      fontSize: 13,
                      color: AppColors.grayText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
