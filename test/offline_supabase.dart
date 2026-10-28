import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A Supabase client that is set up but never reaches the network, with
/// nobody signed in.
///
/// The splash screen and the admin gate read the stored session straight
/// from the client (`SupabaseConfig.client.auth.currentSession`), so a test
/// that builds them needs one to exist. It points at an address that does
/// not exist rather than the real project, keeps no session, and does not
/// look for a sign-in link — so it never reads or writes the client's data.
Future<void> setUpOfflineSupabase() async {
  SharedPreferences.setMockInitialValues({});
  try {
    Supabase.instance;
    return; // already set up by an earlier test in this file
  } catch (_) {}
  await Supabase.initialize(
    url: 'https://offline.invalid',
    publishableKey: 'offline',
    authOptions: const FlutterAuthClientOptions(
      localStorage: EmptyLocalStorage(),
      detectSessionInUri: false,
      autoRefreshToken: false,
    ),
  );
}
