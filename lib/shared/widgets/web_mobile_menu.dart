import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
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
      // The ☰ sits on the left of a right-to-left screen, so the menu comes
      // in from the left, under the thumb that pressed it.
      final offset = Tween(begin: const Offset(-1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
      return SlideTransition(position: offset, child: child);
    },
  );
}

class _MenuSheet extends StatelessWidget {
  const _MenuSheet();

  static const _items = <(String, IconData, String)>[
    ('דף הבית', IconsaxPlusLinear.home_2, '/'),
    ('חדשות', IconsaxPlusLinear.document_text, '/news'),
    ('אירועים', IconsaxPlusLinear.calendar_1, '/events'),
    ('מבצעים', IconsaxPlusLinear.discount_shape, '/deals'),
    ('עסקים', IconsaxPlusLinear.shop, '/businesses'),
    ('מסעדות', IconsaxPlusLinear.reserve, '/restaurants'),
    ('נדל״ן', IconsaxPlusLinear.building_3, '/realestate'),
    ('מפה', IconsaxPlusLinear.map_1, '/map'),
    ('עירייה', IconsaxPlusLinear.bank, '/municipal'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width * 0.8).clamp(0.0, 320.0);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Align(
        alignment: Alignment.centerLeft,
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'מודיעין בשבילך',
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
                        for (final (label, icon, route) in _items)
                          ListTile(
                            leading: Icon(icon, color: AppColors.midBlue, size: 22),
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
                      'צור קשר',
                      style: TextStyle(
                        fontFamily: AppFonts.rubik,
                        fontSize: 16,
                        color: const Color(0xFF1F1F1F),
                      ),
                    ),
                    onTap: () => launchUrl(
                      Uri(scheme: 'mailto', path: kContactEmail),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
