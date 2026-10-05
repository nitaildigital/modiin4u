import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// The app's own invitation, shown over onboarding before the phone's
/// question. The phone asks only once, ever — a "Don't Allow" there is
/// permanent — so this one comes first: "Not now" here costs nothing, and
/// the home screen asks again. True when they chose to allow.
Future<bool?> showPushInvite(BuildContext context) {
  final he = Localizations.localeOf(context).languageCode == 'he';
  String t(String en, String hebrew) => he ? hebrew : en;
  return _sheet(
    context,
    icon: IconsaxPlusLinear.notification,
    title: t('Stay up to date', 'להישאר מעודכנים'),
    body: t(
      'News, events and deals in Modiin as they happen. You choose the topics in Settings.',
      'חדשות, אירועים ומבצעים במודיעין ברגע שהם קורים. את הנושאים בוחרים בהגדרות.',
    ),
    primary: t('Allow notifications', 'לאפשר התראות'),
    secondary: t('Not now', 'לא עכשיו'),
  );
}

/// Said once, on the home screen, to someone who answered the phone's
/// question with "Don't Allow": only the phone's settings can undo that.
/// True when they chose to open them.
Future<bool?> showPushBlockedNote(BuildContext context) {
  final he = Localizations.localeOf(context).languageCode == 'he';
  String t(String en, String hebrew) => he ? hebrew : en;
  return _sheet(
    context,
    icon: IconsaxPlusLinear.notification_bing,
    title: t('Notifications are off', 'ההתראות כבויות'),
    body: t(
      'To get news, events and deals, turn notifications on for Modiin4U in your phone\'s settings.',
      'כדי לקבל חדשות, אירועים ומבצעים, הפעילו התראות עבור Modiin4U בהגדרות הטלפון.',
    ),
    primary: t('Open settings', 'לפתוח הגדרות'),
    secondary: t('Not now', 'לא עכשיו'),
  );
}

Future<bool?> _sheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String body,
  required String primary,
  required String secondary,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.turquoise.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: AppColors.turquoise),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 15,
                height: 1.5,
                color: AppColors.grayText,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.midBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(60),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  primary,
                  style: const TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                secondary,
                style: const TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 15,
                  color: AppColors.grayText,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
