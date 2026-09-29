import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';

/// The website's Contact: a small menu under the button with the number
/// itself, Call, WhatsApp and e-mail — whichever the place has.
///
/// Every Contact and Call Now button on the site went straight to `tel:`.
/// On a phone that dials; on most computers nothing visible happens, and the
/// visitor never even sees the number. The menu shows it, offers to copy it,
/// and still dials from a device that can.
///
/// [anchor] is the button's own context, so the menu opens beneath it.
Future<void> showWebContactMenu(
  BuildContext anchor, {
  required bool isHebrew,
  String? phone,

  /// A WhatsApp number, when the place has one. Not derived from [phone]:
  /// a landline has no WhatsApp.
  String? whatsapp,
  String? email,
}) async {
  String t(String en, String he) => isHebrew ? he : en;
  // The menu opens in the app's own overlay, which is right to left whatever
  // the page says; each row takes the page's direction explicitly.
  final dir = isHebrew ? TextDirection.rtl : TextDirection.ltr;

  final tel = _clean(phone);
  final wa = _waNumber(whatsapp);
  final mail = (email ?? '').trim();
  final options = <(String value, IconData icon, String label)>[
    if (tel != null) ('call', IconsaxPlusLinear.call, phone!.trim()),
    if (tel != null) ('copy', IconsaxPlusLinear.copy, t('Copy number', 'העתקת המספר')),
    if (wa != null) ('whatsapp', IconsaxPlusLinear.message, 'WhatsApp'),
    if (mail.isNotEmpty) ('mail', IconsaxPlusLinear.sms, mail),
  ];
  if (options.isEmpty) return;

  final box = anchor.findRenderObject() as RenderBox?;
  final overlay = Overlay.of(anchor).context.findRenderObject() as RenderBox?;
  if (box == null || overlay == null) return;
  // Under the button, or over it when the window has no room below — never
  // across it, where it would hide what was just clicked.
  final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
  final menuHeight = options.length * 48.0 + 16;
  final below = origin.dy + box.size.height + 8;
  final top = below + menuHeight <= overlay.size.height ? below : origin.dy - 8 - menuHeight;
  final width = box.size.width < 220 ? 220.0 : box.size.width;
  final left = isHebrew ? origin.dx + box.size.width - width : origin.dx;
  final at = Rect.fromLTWH(left, top, width, 0);

  final chosen = await showMenu<String>(
    context: anchor,
    color: Colors.white,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFE7E7E7)),
    ),
    constraints: BoxConstraints(minWidth: width, maxWidth: width),
    position: RelativeRect.fromRect(at, Offset.zero & overlay.size),
    items: [
      for (final (value, icon, label) in options)
        PopupMenuItem<String>(
          value: value,
          height: 48,
          child: Row(
            textDirection: dir,
            children: [
              Icon(icon, size: 20, color: AppColors.midBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  // A number reads left to right in either language.
                  textDirection: value == 'call' || value == 'mail' ? TextDirection.ltr : dir,
                  textAlign: isHebrew ? TextAlign.right : TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.navy),
                ),
              ),
            ],
          ),
        ),
    ],
  );

  switch (chosen) {
    case 'call':
      await launchUrl(Uri(scheme: 'tel', path: tel), mode: LaunchMode.externalApplication);
    case 'whatsapp':
      await launchUrl(Uri.parse('https://wa.me/$wa'), webOnlyWindowName: '_blank');
    case 'mail':
      await launchUrl(Uri(scheme: 'mailto', path: mail));
    case 'copy':
      var copied = true;
      try {
        await Clipboard.setData(ClipboardData(text: phone!.trim()));
      } catch (_) {
        // The browser's clipboard exists only on a secure page. The number
        // is on screen in the menu that just closed; say so rather than
        // claim a copy that did not happen.
        copied = false;
      }
      if (!anchor.mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(anchor);
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(SnackBar(
        content: Text(
          copied ? t('Number copied', 'המספר הועתק') : '${t('Number', 'מספר')}: ${phone!.trim()}',
          textDirection: dir,
          style: TextStyle(fontFamily: AppFonts.inter),
        ),
        behavior: SnackBarBehavior.floating,
        width: 320,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }
}

/// Digits and a leading +, or null when there is no number.
String? _clean(String? raw) {
  final s = (raw ?? '').replaceAll(RegExp(r'[^\d+]'), '');
  return s.length >= 7 ? s : null;
}

/// A number as wa.me wants it: digits only, with Israel's code in place of
/// the leading nought. Null when there are not enough digits to be one.
String? _waNumber(String? raw) {
  var digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0')) digits = '972${digits.substring(1)}';
  return digits.length >= 9 ? digits : null;
}
