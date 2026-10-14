import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../providers/blocked_users_provider.dart';
import 'sign_in_action.dart';

/// "Block" on a comment, a review or a reply someone else wrote.
///
/// Apple's guideline 1.2 asks for a way to block an abusive user that takes
/// their content out of the feed at once and tells the developer; the Terms
/// (13.5) promise it. After asking, everything the person wrote disappears
/// from this phone's comments and reviews (blocked_users_provider), and a
/// report on the person goes to the panel's Reports (entity_type 'user',
/// which the panel already lists under "User"), whose first report on
/// someone notifies the moderators (00064). App only: a report needs an
/// account. Returns whether the person was blocked.
Future<bool> confirmBlockUser(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required String name,
  required String entityType,
  required String entityId,
}) async {
  final he = Localizations.localeOf(context).languageCode == 'he';
  String t(String en, String hebrew) => he ? hebrew : en;
  final messenger = ScaffoldMessenger.of(context);

  void toast(String message, {bool signIn = false}) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: AppFonts.inter)),
        behavior: SnackBarBehavior.floating,
        action: signIn ? signInAction(context) : null,
      ),
    );
  }

  final me = SupabaseConfig.client.auth.currentUser?.id;
  if (me == null) {
    toast(t('Sign in to block', 'יש להתחבר כדי לחסום'), signIn: true);
    return false;
  }
  if (userId.isEmpty || userId == me) return false;

  final ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        t('Block $name?', 'לחסום את $name?'),
        style: TextStyle(fontFamily: AppFonts.rubik, fontWeight: FontWeight.w700),
      ),
      content: Text(
        t(
          'You will no longer see their comments, reviews or replies. The Modiin4u team is told and reviews it within 24 hours. You can unblock them in Profile → Blocked users.',
          'לא תראו יותר את התגובות, הביקורות והתשובות שלהם. צוות מודיעין בשבילך מקבל הודעה ובודק תוך 24 שעות. אפשר לבטל את החסימה בפרופיל ← משתמשים חסומים.',
        ),
        style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14, height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(false),
          child: Text(
            t('Cancel', 'ביטול'),
            style: TextStyle(fontFamily: AppFonts.rubik, color: AppColors.grayMeta),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(true),
          child: Text(
            t('Block', 'חסימה'),
            style: TextStyle(fontFamily: AppFonts.rubik, fontWeight: FontWeight.w600, color: AppColors.error),
          ),
        ),
      ],
    ),
  );
  if (ok != true) return false;

  await ref.read(blockedUsersProvider.notifier).block(userId, name);
  toast(t('$name is blocked.', '$name נחסם/ה.'));

  // The block stands on this phone whatever happens here. One report per
  // person per item (00064), so blocking someone again after unblocking
  // finds theirs already in, and that is fine.
  try {
    await SupabaseConfig.client.from('reports').insert({
      'reporter_id': me,
      'entity_type': 'user',
      'entity_id': userId,
      'reason': 'other',
      'details': 'נחסם/ה על ידי תושב/ת · Blocked by a resident ($entityType $entityId)',
    });
  } catch (_) {}
  return true;
}
