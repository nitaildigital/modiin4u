import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Opens the system share sheet with [text], from where [context] sits on
/// the screen.
///
/// iOS presents the sheet as a popover anchored to a point, and share_plus
/// refuses a share without one (`sharePositionOrigin`) on an iPad and on
/// iOS 26 — the article's Share and the step group's Invite did nothing on
/// the client's iPhone (TestFlight, 11 Oct). The widget that was tapped, or
/// else the middle of the screen, is the anchor.
Future<void> shareText(BuildContext context, String text, {String? subject}) {
  Rect? origin;
  final box = context.findRenderObject();
  if (box is RenderBox && box.hasSize && box.attached) {
    origin = box.localToGlobal(Offset.zero) & box.size;
  }
  if (origin == null || origin.isEmpty) {
    final size = MediaQuery.sizeOf(context);
    origin = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: 1,
      height: 1,
    );
  }
  return Share.share(text, subject: subject, sharePositionOrigin: origin);
}
