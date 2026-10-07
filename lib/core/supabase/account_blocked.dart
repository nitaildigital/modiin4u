import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Whether a write the database refused was refused because the panel
/// blocked this account (Users → Block, 00054).
///
/// A blocked resident still reads and signs in; each write of theirs is
/// turned away by a restrictive rule, which reaches the app as an ordinary
/// "not allowed" (42501), like any other refused write. Asking the database
/// whether the caller is blocked tells the two apart, so the message can say
/// why instead of "please try again", which would never work.
Future<bool> refusedAsBlocked(Object error) async {
  final refused = error is PostgrestException &&
      (error.code == '42501' || error.message.contains('account-blocked'));
  if (!refused) return false;
  try {
    return await SupabaseConfig.client.rpc('is_banned_user') == true;
  } catch (_) {
    return false;
  }
}

/// Whether a write was refused because the profile it is for no longer
/// exists — the account was deleted while this phone kept its session. The
/// caller then asks the server, and signs out if the account is gone.
bool refusedForMissingProfile(Object error) =>
    error is PostgrestException &&
    error.code == '23503' &&
    '${error.message} ${error.details}'.contains('profile');

/// What someone whose account was deleted is told, in the app's language.
String accountGoneMessage(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'he'
    ? 'החשבון הזה כבר לא קיים. התחברו מחדש.'
    : 'This account no longer exists. Please sign in again.';

/// What a blocked resident is told, in the app's language.
String accountBlockedMessage(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'he'
    ? 'החשבון חסום. לבירור, פנו אלינו דרך עזרה ותמיכה.'
    : 'This account is blocked. To ask why, contact us from Help & Support.';
