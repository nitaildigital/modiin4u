import 'package:flutter/material.dart';

extension DarkAware on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get cardBg => isDark ? const Color(0xFF1E1E1E) : AppColors.white;
  Color get textPrimary => isDark ? const Color(0xFFE0E0E0) : AppColors.navy;
  Color get surfaceDim => isDark ? const Color(0xFF2C2C2C) : AppColors.surfaceLight;
  Color get borderClr => isDark ? const Color(0xFF2C2C2C) : AppColors.border;
  Color get scaffoldBg => isDark ? const Color(0xFF121212) : AppColors.white;
}

class AppColors {
  static const navy = Color(0xFF0A1230);
  static const midBlue = Color(0xFF123A72);
  static const turquoise = Color(0xFF17A9D0);
  static const gold = Color(0xFFFAC775);
  static const white = Color(0xFFFFFFFF);
  static const grayText = Color(0xFF5F5E5A);
  static const grayMeta = Color(0xFF6B7280);
  static const grayLight = Color(0xFF888780);
  static const border = Color(0xFFE5E7EB);
  static const background = Color(0xFFF9F9F7);
  static const surfaceLight = Color(0xFFF7F8FA);
  static const cardShadow = Color(0x0F000000);
  static const success = Color(0xFF2ECC71);
  static const error = Color(0xFFE74C3C);

  static const brandGradient = LinearGradient(
    colors: [navy, midBlue, turquoise],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cyanGradient = LinearGradient(
    colors: [Color(0xFF00EEFF), Color(0xFF00FBA9)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const heroOrangeGradient = LinearGradient(
    colors: [Color(0xFFE92C04), Color(0xFFF06307), Color(0xFFFCC311)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const cardBorderColor = Color(0xFFEAEAEA);
  static const filterBorderColor = Color(0xFFDBDBDB);
  static const rentBadgeBg = Color(0xFFE1E1E1);
  static const brokerBadgeBg = Color(0xFFE5FDFF);
  static const inactiveTabBg = Color(0xFFF6F6F6);
  static const sectionBg = Color(0xFFF5F5F5);
}
