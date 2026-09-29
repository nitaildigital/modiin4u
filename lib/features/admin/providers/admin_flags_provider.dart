import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';

/// Feature flags and remote config, on the tables that hold them.
///
/// Both notifiers used to keep a list in memory. A toggle flipped the copy in
/// the list, the row lit up, and the next reload put it back — so the client
/// could turn the community module off, watch it turn off, and find it on
/// again the following morning with nothing to explain why.
///
/// The invented rows also credited every change to "ניתאי לוי" on dates he
/// never touched anything, and named flags the database has never held
/// (DARK_MODE, PUSH_NOTIFICATIONS, STEPS_TRACKER) while hiding the eight it
/// does (AI_SEARCH, COMMUNITY, EVENTS, GAMES, MARKETPLACE, OFFERS,
/// REAL_ESTATE, STEPS).
///
/// **What a flag does today: nothing.** No screen outside this panel reads
/// `feature_flags`, so switching one off records the decision and changes
/// nothing in the app. The panel says so rather than implying otherwise.
/// Making the app honour them is a separate piece of work.

/// The `admin_users` row for whoever is signed in, which is what
/// `feature_flags.updated_by` points at — not the profile, and not a name.
Future<String?> _currentAdminId() async {
  final uid = SupabaseConfig.client.auth.currentUser?.id;
  if (uid == null) return null;
  final row = await SupabaseConfig.client
      .from('admin_users')
      .select('id')
      .eq('profile_id', uid)
      .maybeSingle();
  return row?['id'] as String?;
}

/// Two joins deep: the flag names an `admin_users` row, which names the
/// profile that carries the person's name.
const _flagColumns =
    '*, admin_users:updated_by(profiles:profile_id(full_name))';

/// Lifts the joined name to `updated_by_name`, leaving `updated_by` as the id
/// it is. Null where the row has never been edited through the panel, which
/// is every row today — the screen shows a dash rather than inventing one.
Map<String, dynamic> _withAuthor(Map<String, dynamic> row) {
  final admin = row['admin_users'] as Map<String, dynamic>?;
  final profile = admin?['profiles'] as Map<String, dynamic>?;
  return {...row, 'updated_by_name': profile?['full_name']};
}

final adminFeatureFlagListProvider =
    StateNotifierProvider<
      AdminFeatureFlagListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminFeatureFlagListNotifier();
    });

class AdminFeatureFlagListNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  AdminFeatureFlagListNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final rows = await SupabaseConfig.client
          .from('feature_flags')
          .select(_flagColumns)
          .order('key', ascending: true);
      if (!mounted) return;
      state = AsyncValue.data([
        for (final r in List<Map<String, dynamic>>.from(rows)) _withAuthor(r),
      ]);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  /// Writes the patch, stamps who and when, and reloads so what is on screen
  /// is what the table holds.
  Future<void> _patch(String id, Map<String, dynamic> fields) async {
    await SupabaseConfig.client
        .from('feature_flags')
        .update({
          ...fields,
          'updated_by': await _currentAdminId(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
    await load();
  }

  Future<void> toggleFlag(String id) async {
    final current = state.valueOrNull?.firstWhere(
      (f) => f['id'] == id,
      orElse: () => const <String, dynamic>{},
    );
    final enabled = current?['is_enabled'] as bool?;
    if (enabled == null) return;
    await _patch(id, {'is_enabled': !enabled});
  }

  Future<void> updateRollout(String id, int pct) =>
      _patch(id, {'rollout_pct': pct});

  Future<void> updateFlag(String id, Map<String, dynamic> fields) =>
      _patch(id, _writable(fields));

  Future<void> createFlag(Map<String, dynamic> flag) async {
    await SupabaseConfig.client.from('feature_flags').insert({
      ..._writable(flag),
      'updated_by': await _currentAdminId(),
    });
    await load();
  }

  /// Drops the keys the database owns, and the joined object that arrives
  /// under the table's name and would be rejected on the way back.
  Map<String, dynamic> _writable(Map<String, dynamic> fields) => {
    for (final e in fields.entries)
      if (!const {
            'id',
            'created_at',
            'updated_at',
            'updated_by',
            'updated_by_name',
            'admin_users',
          }.contains(e.key) &&
          e.value is! Map)
        e.key: e.value,
  };
}

final adminRemoteConfigProvider =
    StateNotifierProvider<
      AdminRemoteConfigNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminRemoteConfigNotifier();
    });

class AdminRemoteConfigNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  AdminRemoteConfigNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final rows = await SupabaseConfig.client
          .from('remote_config')
          .select('*, admin_users:updated_by(profiles:profile_id(full_name))')
          .order('key', ascending: true);
      if (!mounted) return;
      state = AsyncValue.data([
        for (final r in List<Map<String, dynamic>>.from(rows)) _withAuthor(r),
      ]);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateConfig(String id, Map<String, dynamic> fields) async {
    await SupabaseConfig.client
        .from('remote_config')
        .update({
          ..._writable(fields),
          'updated_by': await _currentAdminId(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
    await load();
  }

  Future<void> createConfig(Map<String, dynamic> config) async {
    await SupabaseConfig.client.from('remote_config').insert({
      ..._writable(config),
      'updated_by': await _currentAdminId(),
    });
    await load();
  }

  Future<void> deleteConfig(String id) async {
    await SupabaseConfig.client.from('remote_config').delete().eq('id', id);
    await load();
  }

  Map<String, dynamic> _writable(Map<String, dynamic> fields) => {
    for (final e in fields.entries)
      if (!const {
            'id',
            'created_at',
            'updated_at',
            'updated_by',
            'updated_by_name',
            'admin_users',
          }.contains(e.key) &&
          e.value is! Map)
        e.key: e.value,
  };
}
