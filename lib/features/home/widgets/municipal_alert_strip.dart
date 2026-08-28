import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class MunicipalAlertStrip extends StatefulWidget {
  const MunicipalAlertStrip({super.key});

  @override
  State<MunicipalAlertStrip> createState() => _MunicipalAlertStripState();
}

class _MunicipalAlertStripState extends State<MunicipalAlertStrip> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEDFC8), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9C8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.traffic_outlined, size: 18, color: Color(0xFFD48806)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'עבודות תשתית ברחוב הפלמ"ח — חסימה חלקית עד 15.8',
                  style: GoogleFonts.rubik(fontSize: 13, color: const Color(0xFF5C4A1E), height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => context.push('/municipal'),
                  child: Text(
                    'פרטים נוספים',
                    style: GoogleFonts.rubik(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFD48806),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _dismissed = true),
            child: const Icon(Icons.close, size: 18, color: Color(0xFFA89060)),
          ),
        ],
      ),
    );
  }
}
