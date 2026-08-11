import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class LogoWidget extends StatelessWidget {
  final double fontSize;
  final bool onDark;

  const LogoWidget({
    super.key,
    this.fontSize = 28,
    this.onDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = onDark ? AppColors.white : AppColors.navy;
    return Text(
      'מודיעין\nבשבילך',
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: GoogleFonts.rubik(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.15,
        letterSpacing: -0.5,
      ),
    );
  }
}

class LogoWithBackground extends StatelessWidget {
  final double size;

  const LogoWithBackground({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.18),
      ),
      child: Center(
        child: LogoWidget(fontSize: size * 0.2),
      ),
    );
  }
}
