import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/notification_preferences.dart';

/// The signed-in person's notification and access choices.
///
/// Null until they are read, so the screen can tell "not loaded yet" from
/// "loaded, and everything is off".
final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, NotificationPreferences?>((ref) {
  return PreferencesNotifier(ref);
});

class PreferencesNotifier extends StateNotifier<NotificationPreferences?> {
  final SupabaseClient _client = SupabaseConfig.client;
  final Ref _ref;

  /// Toggling four switches quickly should be four state changes and one
  /// write, not four writes racing each other to the same row.
  Timer? _pending;

  PreferencesNotifier(this._ref) : super(null) {
    _ref.listen(
      authProvider,
      (_, next) => _load(next?.id),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _pending?.cancel();
    super.dispose();
  }

  Future<void> _load(String? profileId) async {
    if (profileId == null) {
      if (mounted) state = null;
      return;
    }
    try {
      final row = await _client
          .from('profiles')
          .select(
            'push_enabled, notify_news, notify_deals, notify_neighborhood, '
            'notify_realestate, location_enabled, health_enabled',
          )
          .eq('id', profileId)
          .maybeSingle();

      if (!mounted) return;
      state = row == null
          ? const NotificationPreferences()
          : NotificationPreferences.fromJson(row);
    } catch (_) {
      // Migration 00016 adds the topic columns. Without it the select fails,
      // and the defaults keep the screen usable rather than empty.
      if (mounted) state = const NotificationPreferences();
    }
  }

  /// Moves the switch straight away and writes shortly after.
  void update(NotificationPreferences next) {
    state = next;
    _pending?.cancel();
    _pending = Timer(const Duration(milliseconds: 600), _flush);
  }

  /// Writes now rather than waiting out the timer — for leaving the screen.
  Future<void> flushNow() async {
    _pending?.cancel();
    await _flush();
  }

  Future<void> _flush() async {
    final prefs = state;
    final profileId = _ref.read(authProvider)?.id;
    if (prefs == null || profileId == null) return;

    try {
      await _client.from('profiles').update(prefs.toJson()).eq('id', profileId);
    } catch (_) {
      // Left as the person set it; the next change tries again.
    }
  }
}
