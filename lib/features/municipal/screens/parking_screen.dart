import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class ParkingScreen extends StatelessWidget {
  const ParkingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('חניה וחניונים', style: GoogleFonts.rubik(fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.navy,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.turquoise.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.turquoise),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'תושבים עם תו חניה עירוני תקף פטורים מתשלום ומקבלים שעתיים ראשונות חינם בכל חניון בעיר',
                      style: GoogleFonts.rubik(fontSize: 13, color: AppColors.midBlue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ParkingLot('חניון היכל התרבות', '~600 מקומות', 'חינם', 0.65, true),
            const SizedBox(height: 10),
            _ParkingLot('חניון הרכבת (סמוך לקניון)', '~450 מקומות', 'חינם', 0.45, true),
            const SizedBox(height: 10),
            _ParkingLot('חניון תת-קרקעי "גריי"', '~500 מקומות', 'חינם ל-2 שעות ראשונות', 0.82, false),
            const SizedBox(height: 10),
            _ParkingLot('חניון מרכז הספורט', '~300 מקומות', 'חינם', 0.3, true),
            const SizedBox(height: 10),
            _ParkingLot('חניון עמק זבולון צפון', '~200 מקומות', 'חינם', 0.2, true),
            const SizedBox(height: 10),
            _ParkingLot('חניון ליד קופת חולים מכבי', '55 מקומות', 'חינם', 0.9, false),
            const SizedBox(height: 10),
            _ParkingLot('חניון ליד צומת תלתן/דפנה', '21 מקומות', 'חינם', 0.5, true),
            const SizedBox(height: 10),
            _ParkingLot('חניוני תחנת הרכבת', '—', '70 ₪ ליממה', 0.6, false),
            const SizedBox(height: 20),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.midBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 40, color: AppColors.midBlue.withValues(alpha: 0.3)),
                    const SizedBox(height: 8),
                    Text('מפת חניונים', style: GoogleFonts.rubik(fontSize: 14, color: AppColors.grayText)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _ParkingLot extends StatelessWidget {
  final String name;
  final String capacity;
  final String rate;
  final double occupancy;
  final bool hasAvailability;

  const _ParkingLot(this.name, this.capacity, this.rate, this.occupancy, this.hasAvailability);

  @override
  Widget build(BuildContext context) {
    final availColor = occupancy > 0.8
        ? AppColors.error
        : occupancy > 0.5
            ? AppColors.gold
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_parking, size: 20, color: AppColors.midBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(name, style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy)),
              ),
              if (hasAvailability)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: availColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    occupancy > 0.8 ? 'כמעט מלא' : occupancy > 0.5 ? 'זמין' : 'פנוי',
                    style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: availColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasAvailability) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: occupancy,
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(availColor),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Text(capacity, style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText)),
              const Spacer(),
              Text(rate, style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.navy)),
            ],
          ),
        ],
      ),
    );
  }
}
