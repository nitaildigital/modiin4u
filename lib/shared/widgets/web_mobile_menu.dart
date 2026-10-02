import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../l10n/app_localizations.dart';
import 'web_chrome.dart' show kContactEmail;

/// The side menu a phone browser gets from the ☰.
///
/// On a narrow window the website draws the app's layout, and the app's ☰
/// opens the resident's profile. In a browser nobody is signed in — the
/// client has decided sign-in belongs to the app alone — so the profile sent
/// them straight to a sign-in screen, with the app's hero photograph wedged
/// under the form. The client pressed what looked like a menu and got a
/// login box. On a website a ☰ is a menu; this is one.
Future<void> showWebMobileMenu(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'menu',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, _, _) => const _MenuSheet(),
    transitionBuilder: (context, anim, _, child) {
      // The ☰ sits at the end of the header — the left in Hebrew, the right
      // in English — so the menu comes in from that side, under the thumb
      // that pressed it.
      final rtl = Directionality.of(context) == TextDirection.rtl;
      final offset = Tween(
        begin: Offset(rtl ? -1 : 1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
      return SlideTransition(position: offset, child: child);
    },
  );
}

class _MenuSheet extends StatelessWidget {
  const _MenuSheet();

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width * 0.8).clamp(0.0, 320.0);
    // In the language the page under it is drawn in; it was Hebrew whatever
    // the reader had chosen.
    final hebrew = Localizations.localeOf(context).languageCode == 'he';
    String t(String en, String he) => hebrew ? he : en;
    final items = <(String, IconData, String)>[
      (t('Home', 'דף הבית'), IconsaxPlusLinear.home_2, '/'),
      (t('News', 'חדשות'), IconsaxPlusLinear.document_text, '/news'),
      (t('Events', 'אירועים'), IconsaxPlusLinear.calendar_1, '/events'),
      (t('Deals', 'מבצעים'), IconsaxPlusLinear.discount_shape, '/deals'),
      (t('Businesses', 'עסקים'), IconsaxPlusLinear.shop, '/businesses'),
      (t('Restaurants', 'מסעדות'), IconsaxPlusLinear.reserve, '/restaurants'),
      (t('Real Estate', 'נדל״ן'), IconsaxPlusLinear.building_3, '/realestate'),
      (t('Map', 'מפה'), IconsaxPlusLinear.map_1, '/map'),
      (t('Municipal', 'עירייה'), IconsaxPlusLinear.bank, '/municipal'),
    ];

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Material(
        color: Colors.white,
        child: SizedBox(
          width: width,
          height: double.infinity,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 16, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          L.of(context).appName,
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 22),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      for (final (label, icon, route) in items)
                        ListTile(
                          leading: Icon(
                            icon,
                            color: AppColors.midBlue,
                            size: 22,
                          ),
                          title: Text(
                            label,
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 16,
                              color: const Color(0xFF1F1F1F),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            context.go(route);
                          },
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    IconsaxPlusLinear.sms,
                    color: AppColors.midBlue,
                    size: 22,
                  ),
                  title: Text(
                    t('Contact Us', 'צור קשר'),
                    style: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 16,
                      color: const Color(0xFF1F1F1F),
                    ),
                  ),
                  onTap: () =>
                      launchUrl(Uri(scheme: 'mailto', path: kContactEmail)),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
