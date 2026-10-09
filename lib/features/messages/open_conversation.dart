import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/m_kit.dart';
import '../../shared/widgets/sign_in_action.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/widgets/m_account_widgets.dart';
import 'data/messages.dart';

/// A resident writes to a business — from its page, or from a job they
/// applied to ([jobId], which the conversation then shows as its subject).
/// There is one conversation per business and person (00069), so this finds
/// the one already there or opens it, then shows it.
Future<void> messageBusiness(
  BuildContext context,
  WidgetRef ref, {
  required String businessId,
  String? jobId,
}) async {
  if (ref.read(authProvider) == null) {
    // A conversation lives in an account; there is nowhere to keep it without.
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          mTr(context, 'Sign in to send a message', 'יש להתחבר כדי לשלוח הודעה'),
          style: mText(14, color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: signInAction(context),
      ),
    );
    return;
  }
  try {
    final id = await ref.read(messageRepositoryProvider).start(businessId: businessId, jobId: jobId);
    if (!context.mounted) return;
    await context.push('/messages/$id');
    ref.invalidate(conversationsProvider);
    ref.invalidate(unreadMessagesProvider);
  } catch (_) {
    if (context.mounted) {
      mToast(context, mTr(context, 'The conversation could not be opened.', 'לא ניתן היה לפתוח את השיחה.'), error: true);
    }
  }
}
