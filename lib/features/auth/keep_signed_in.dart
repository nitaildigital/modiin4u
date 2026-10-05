import 'package:shared_preferences/shared_preferences.dart';

/// "Remember me" on the sign-in form, kept on the device.
///
/// The box did nothing: Supabase keeps a session until sign-out either way.
/// Unticked, the app now signs out the next time it starts (the splash reads
/// this). It starts ticked, so staying signed in remains the default.
const _key = 'keep_signed_in';

Future<void> saveKeepSignedIn(bool keep) async {
  try {
    await (await SharedPreferences.getInstance()).setBool(_key, keep);
  } catch (_) {}
}

bool keepSignedIn(SharedPreferences prefs) => prefs.getBool(_key) ?? true;
