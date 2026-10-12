import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// "Your password has been changed" — where a reset link opened in a browser
/// ends. The website has no resident accounts, so the person goes back to the
/// app to sign in; the page went straight to the site's home before, with
/// nothing saying where to go next (12 Oct).
class PasswordChangedView extends StatelessWidget {
  final bool hebrew;
  final VoidCallback onHome;
  const PasswordChangedView({super.key, required this.hebrew, required this.onHome});

  @override
  Widget build(BuildContext context) {
    String t(String en, String he) => hebrew ? he : en;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(color: Color(0x1F2ECC71), shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, size: 44, color: Color(0xFF2ECC71)),
        ),
        const SizedBox(height: 24),
        Text(
          t('Your password has been changed', 'הסיסמה שלכם שונתה'),
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black),
        ),
        const SizedBox(height: 10),
        Text(
          t(
            'Go back to the Modiin4U app and sign in with your new password.',
            'חזרו לאפליקציית מודיעין בשבילך והתחברו עם הסיסמה החדשה.',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 15, height: 1.5, color: const Color(0xFF555555)),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onHome,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.midBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            ),
            child: Text(t('Back to the website', 'חזרה לאתר'), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 15, fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }
}
