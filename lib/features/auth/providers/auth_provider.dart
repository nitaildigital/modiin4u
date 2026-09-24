import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';
import '../models/user_model.dart';

/// The signed-in person, or null.
///
/// Backed by Supabase rather than by anything held in the app: the session is
/// restored from disk on launch, so whoever was signed in stays signed in, and
/// it goes away on every device when the account is deleted.
final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  return AuthNotifier(ref);
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) != null;
});

/// Set when someone arrives from a password-reset link.
///
/// The link signs them in, so without this the app would simply open as
/// though they had signed in normally and never ask for the new password.
final passwordResetPendingProvider = StateProvider<bool>((ref) => false);

/// True until the stored session has been read back.
///
/// A signed-in person is null for the first moments after launch, so a screen
/// that sends signed-out visitors to the sign-in page has to wait for this
/// rather than acting on that first null.
final authRestoringProvider = StateProvider<bool>((ref) => true);

class AuthNotifier extends StateNotifier<UserModel?> {
  final SupabaseClient _client = SupabaseConfig.client;
  final Ref _ref;
  StreamSubscription<AuthState>? _sub;

  /// Where Supabase sends someone back to after they follow a link in an
  /// email — confirming their address, or resetting a password.
  ///
  /// The web address, not the app's own scheme. A link in an email is opened
  /// by whatever reads the email, which is often a desktop browser where no
  /// app scheme exists at all; a web page works everywhere and needs no
  /// per-platform setup. The same build serves `/auth/callback`, so the page
  /// the link lands on is the app's own.
  ///
  /// The custom scheme stays registered on both platforms, so a link opened
  /// on the phone can be switched to it later without another release.
  ///
  /// Whatever this is set to must also be listed under Redirect URLs in the
  /// Supabase dashboard, or the link is refused.
  static const redirectUrl = String.fromEnvironment(
    'AUTH_REDIRECT_URL',
    defaultValue: 'https://app.modiin4u.co.il/auth/callback',
  );

  AuthNotifier(this._ref) : super(null) {
    _sub = _client.auth.onAuthStateChange.listen((event) async {
      // Arriving from a reset link signs the person in. The app has to stop
      // and ask for the new password rather than carrying on as normal.
      if (event.event == AuthChangeEvent.passwordRecovery) {
        Future.microtask(
          () => _ref.read(passwordResetPendingProvider.notifier).state = true,
        );
      }

      final user = event.session?.user;
      if (user == null) {
        if (mounted) state = null;
      } else {
        await _loadProfile(user);
      }
      _doneRestoring();
    });

    // Nothing stored means nothing to wait for, and the stream stays quiet
    // until someone signs in.
    if (_client.auth.currentSession == null) _doneRestoring();
  }

  /// Deferred, because Riverpod forbids writing another provider while this
  /// one is still being created — and the stored session resolves fast enough
  /// that this can land during the constructor.
  void _doneRestoring() {
    Future.microtask(() {
      if (!mounted) return;
      if (_ref.read(authRestoringProvider)) {
        _ref.read(authRestoringProvider.notifier).state = false;
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ── Signing in ──
  //
  // Email and password, as the design has it: the sign-in screen shows a
  // password field with "Remember Me" and "Forgot Password?", and sign-up
  // asks for a password and a confirmation.

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Creates the account.
  ///
  /// [data] is written to the account's metadata, where the trigger in
  /// migration 00015 reads `full_name` when it creates the profile row.
  ///
  /// Returns true when a session came back. It does not when the project
  /// requires the address to be confirmed first, and the screen then says to
  /// check the email rather than pretending to be signed in.
  Future<bool> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    final res = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: data,
      emailRedirectTo: redirectUrl,
    );
    return res.session != null;
  }

  /// Sends the confirmation email again.
  ///
  /// Someone who signs up and loses the email is otherwise stuck: they cannot
  /// sign in, and signing up again with the same address is refused.
  Future<void> resendConfirmation(String email) {
    return _client.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: redirectUrl,
    );
  }

  /// Sends the "forgot password" email.
  Future<void> sendPasswordReset(String email) {
    return _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectUrl,
    );
  }

  /// Sets a new password after following a reset link.
  ///
  /// The link puts a session in place, so no old password is asked for — that
  /// is the whole point of resetting one.
  Future<void> completePasswordReset(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Changes the password of whoever is signed in.
  ///
  /// Supabase has no "check the old one" step, so the screen verifies it by
  /// signing in with it first — otherwise a borrowed unlocked phone could
  /// change the password without knowing it.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _client.auth.currentUser?.email;
    if (email == null) throw AuthException('not signed in');

    await _client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> logout() async {
    await _client.auth.signOut();
    state = null;
  }

  // ── The profile row ──

  Future<void> _loadProfile(User user) async {
    try {
      final row = await _client
          .from('profiles')
          .select('*, neighborhoods(name)')
          .eq('id', user.id)
          .maybeSingle();

      if (row == null) {
        // The trigger in migration 00015 creates this row. If that migration
        // has not run, fall back to what the session already tells us so the
        // app is usable rather than stuck on a spinner.
        if (mounted) state = _fromSession(user);
        return;
      }
      if (mounted) state = _fromRow(row, user, isAdmin: await _isAdmin(user.id));
    } catch (_) {
      if (mounted) state = _fromSession(user);
    }
  }

  /// Asks the database rather than reading `admin_users` directly.
  ///
  /// `is_admin()` is SECURITY DEFINER, so it answers for an administrator
  /// whether or not that table is readable — and once migration 00014 makes
  /// it admin-only, a direct read would come back empty for everyone else
  /// anyway. This is also the same answer the row level security policies
  /// use, so the app and the database cannot disagree about who is an admin.
  Future<bool> _isAdmin(String id) async {
    try {
      return await _client.rpc('is_admin') as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  UserModel _fromSession(User user) => UserModel(
    id: user.id,
    name: (user.email ?? '').split('@').first,
    email: user.email ?? '',
    phone: user.phone ?? '',
    createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
  );

  UserModel _fromRow(
    Map<String, dynamic> row,
    User user, {
    required bool isAdmin,
  }) {
    final hood = row['neighborhoods'];
    return UserModel(
      id: user.id,
      name: (row['full_name'] as String?) ?? '',
      email: (row['email'] as String?) ?? user.email ?? '',
      phone: (row['phone'] as String?) ?? '',
      neighborhood: hood is Map ? hood['name'] as String? : null,
      avatarUrl: row['avatar_url'] as String?,
      points: (row['points'] as num?)?.toInt() ?? 0,
      isVerifiedResident: row['is_verified'] as bool? ?? false,
      isBanned: row['is_banned'] as bool? ?? false,
      role: isAdmin ? UserRole.admin : UserRole.user,
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
      lastLoginAt: DateTime.tryParse(row['last_login_at'] as String? ?? ''),
    );
  }

  /// Re-reads the row, for after an edit elsewhere.
  Future<void> refresh() async {
    final user = _client.auth.currentUser;
    if (user != null) await _loadProfile(user);
  }

  // ── Editing ──

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? neighborhood,
    String? avatarUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final patch = <String, dynamic>{
      'full_name': ?name,
      'phone': ?phone,
      'avatar_url': ?avatarUrl,
    };
    if (patch.isNotEmpty) {
      await _client.from('profiles').update(patch).eq('id', user.id);
    }

    // Held locally as a name, stored as an id, so it is resolved separately.
    if (neighborhood != null) await _setNeighborhood(user.id, neighborhood);

    state = state?.copyWith(
      name: name,
      phone: phone,
      neighborhood: neighborhood,
      avatarUrl: avatarUrl,
    );
  }

  Future<void> _setNeighborhood(String profileId, String name) async {
    try {
      final row = await _client
          .from('neighborhoods')
          .select('id')
          .eq('name', name)
          .maybeSingle();
      if (row == null) return;
      await _client
          .from('profiles')
          .update({'neighborhood_id': row['id']})
          .eq('id', profileId);
    } catch (_) {
      // Leave the stored value alone rather than clearing it.
    }
  }

  // ── Deleting the account ──

  /// Removes the account and everything keyed to it, then signs out. Required
  /// by both app stores, and asked for by the client.
  Future<void> deleteAccount() async {
    await _client.rpc('delete_own_account');
    await _client.auth.signOut();
    state = null;
  }
}
