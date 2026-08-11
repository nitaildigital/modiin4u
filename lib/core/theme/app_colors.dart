import 'package:flutter/material.dart';

class AppColors {
  static const navy = Color(0xFF0A1230);
  static const midBlue = Color(0xFF123A72);
  static const turquoise = Color(0xFF17A9D0);
  static const gold = Color(0xFFFAC775);
  static const white = Color(0xFFFFFFFF);
  static const grayText = Color(0xFF5F5E5A);
  static const grayLight = Color(0xFF888780);
  static const border = Color(0xFFE4E2D9);
  static const background = Color(0xFFF9F9F7);
  static const success = Color(0xFF2ECC71);
  static const error = Color(0xFFE74C3C);

  static const brandGradient = LinearGradient(
    colors: [navy, midBlue, turquoise],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
