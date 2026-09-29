import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';

/// The website's Share: a small menu under the button — WhatsApp, Facebook,
/// X, e-mail, and Copy link.
///
/// The browser's own share sheet would be the obvious thing, but it exists
/// only over https and only in some browsers; where it is missing
/// `share_plus` falls back to opening a mail client, which on most desktops
/// means nothing visible happens. Each of these is an ordinary link, so all
/// of them work on any page, secure or not.
///
/// [anchor] is the button's own context, so the menu opens beneath it.
Future<void> showWebShareMenu(
  BuildContext anchor, {
  required String title,
  required String link,
  required bool isHebrew,

  /// What the message says before the link: the title, a date, a place.
  String? message,
}) async {
  String t(String en, String he) => isHebrew ? he : en;
  // The menu opens in the app's own overlay, which is right to left whatever
  // the page says; each row takes the page's direction explicitly.
  final dir = isHebrew ? TextDirection.rtl : TextDirection.ltr;
  final text = [message ?? title, link].join('\n');
  final encoded = Uri.encodeComponent(text);

  final box = anchor.findRenderObject() as RenderBox?;
  final overlay = Overlay.of(anchor).context.findRenderObject() as RenderBox?;
  if (box == null || overlay == null) return;
  final topLeft = box.localToGlobal(Offset(0, box.size.height + 8), ancestor: overlay);
  final bottomRight = box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay);
  final position = RelativeRect.fromRect(
    Rect.fromPoints(topLeft, bottomRight),
    Offset.zero & overlay.size,
  );

  final choice = await showMenu<String>(
    context: anchor,
    position: position,
    color: Colors.white,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFE7E7E7)),
    ),
    items: [
      _item(dir, 'whatsapp', 'assets/web/news/share_whatsapp.svg', 'WhatsApp'),
      _item(dir, 'facebook', 'assets/web/news/share_facebook.svg', 'Facebook', iconWidth: 11),
      _item(dir, 'x', 'assets/web/news/share_x.svg', 'X'),
      _item(dir, 'mail', 'assets/web/news/share_mail.svg', t('Email', 'דוא"ל')),
      const PopupMenuDivider(height: 8),
      _item(dir, 'copy', null, t('Copy link', 'העתקת קישור')),
    ],
  );
  if (choice == null) return;

  final target = switch (choice) {
    'whatsapp' => 'https://wa.me/?text=$encoded',
    'facebook' => 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(link)}',
    'x' => 'https://twitter.com/intent/tweet?text=$encoded',
    'mail' => 'mailto:?subject=${Uri.encodeComponent(title)}&body=$encoded',
    _ => null,
  };
  if (target != null) {
    await launchUrl(Uri.parse(target), webOnlyWindowName: choice == 'mail' ? '_self' : '_blank');
    return;
  }

  try {
    await Clipboard.setData(ClipboardData(text: link));
  } catch (_) {
    // The browser's clipboard exists only on a secure page, and the site is
    // on plain http until its domain has a certificate. Show the link, ready
    // to select, rather than a "copied" that did not happen.
    if (!anchor.mounted) return;
    await showDialog<void>(
      context: anchor,
      builder: (context) => Directionality(
        textDirection: dir,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(t('Copy this link', 'העתיקו את הקישור'),
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.navy)),
          content: SizedBox(
            width: 480,
            child: SelectableText(link,
                textDirection: TextDirection.ltr,
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: AppColors.navy)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t('Close', 'סגירה'), style: TextStyle(fontFamily: AppFonts.inter, color: AppColors.midBlue)),
            ),
          ],
        ),
      ),
    );
    return;
  }
  if (!anchor.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(anchor);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(t('Link copied', 'הקישור הועתק'), textDirection: dir, style: TextStyle(fontFamily: AppFonts.inter)),
    behavior: SnackBarBehavior.floating,
    width: 280,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));
}

PopupMenuItem<String> _item(TextDirection dir, String value, String? icon, String label, {double iconWidth = 22}) {
  return PopupMenuItem<String>(
    value: value,
    height: 44,
    child: Row(
      textDirection: dir,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: icon == null
              ? const Icon(Icons.link_rounded, size: 22, color: AppColors.midBlue)
              : Center(child: SvgPicture.asset(icon, width: iconWidth, height: 22)),
        ),
        const SizedBox(width: 12),
        Text(label, textDirection: dir, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.navy)),
      ],
    ),
  );
}
