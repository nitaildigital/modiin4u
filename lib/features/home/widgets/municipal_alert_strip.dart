import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class MunicipalAlertStrip extends StatelessWidget {
  const MunicipalAlertStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.turquoise.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.turquoise.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 20,
            color: AppColors.midBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'עדכון עירוני: עבודות תשתית ברחוב הפלמ"ח — צפויה חסימה חלקית עד 15.8',
              style: GoogleFonts.rubik(
                fontSize: 13,
                color: AppColors.navy,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
