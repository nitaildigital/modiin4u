import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart' show recordAdminAction, updateRow;

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
/// `feature_flags` or `remote_config`, so switching one off records the
/// decision and changes nothing in the app. The panel says so on both tabs
/// rather than implying otherwise. Making the app honour them is a separate
/// piece of work.
///
/// Every write here throws when the database refuses it, and the screen
/// shows the reason; they used to fail silently. A write reloads quietly —
/// the rows stay on screen rather than flashing a spinner under the switch
/// that was just flipped.

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

  Future<void> load({bool quiet = false}) async {
    if (!quiet || !state.hasValue) state = const AsyncValue.loading();
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
    await updateRow('feature_flags', id, {
      ...fields,
      'updated_by': await _currentAdminId(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    await recordAdminAction(
      action: 'update',
      table: 'feature_flags',
      rowId: id,
      fields: fields,
      label: _flagLabel(id, fields),
    );
    await load(quiet: true);
  }

  /// The flag's key and what it was set to, for the audit log — neither
  /// `is_enabled` nor `rollout_pct` is a column the log keeps a value for.
  String? _flagLabel(String id, Map<String, dynamic> fields) {
    final row = state.valueOrNull?.firstWhere(
      (f) => f['id'] == id,
      orElse: () => const <String, dynamic>{},
    );
    final key = row?['key'] as String?;
    if (key == null) return null;
    return [
      key,
      for (final e in fields.entries) '${e.key}=${e.value}',
    ].join(' · ');
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
    final inserted = await SupabaseConfig.client
        .from('feature_flags')
        .insert({..._writable(flag), 'updated_by': await _currentAdminId()})
        .select('id')
        .maybeSingle();
    await recordAdminAction(
      action: 'create',
      table: 'feature_flags',
      rowId: inserted?['id']?.toString(),
      fields: _writable(flag),
      label: flag['key'] as String?,
    );
    await load(quiet: true);
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

  Future<void> load({bool quiet = false}) async {
    if (!quiet || !state.hasValue) state = const AsyncValue.loading();
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
    await updateRow('remote_config', id, {
      ..._writable(fields),
      'updated_by': await _currentAdminId(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    await recordAdminAction(
      action: 'update',
      table: 'remote_config',
      rowId: id,
      fields: _writable(fields),
      label: fields['key'] as String?,
    );
    await load(quiet: true);
  }

  Future<void> createConfig(Map<String, dynamic> config) async {
    final inserted = await SupabaseConfig.client
        .from('remote_config')
        .insert({..._writable(config), 'updated_by': await _currentAdminId()})
        .select('id')
        .maybeSingle();
    await recordAdminAction(
      action: 'create',
      table: 'remote_config',
      rowId: inserted?['id']?.toString(),
      fields: _writable(config),
      label: config['key'] as String?,
    );
    await load(quiet: true);
  }

  Future<void> deleteConfig(String id) async {
    final row = state.valueOrNull?.firstWhere(
      (c) => c['id'] == id,
      orElse: () => const <String, dynamic>{},
    );
    await SupabaseConfig.client.from('remote_config').delete().eq('id', id);
    await recordAdminAction(
      action: 'delete',
      table: 'remote_config',
      rowId: id,
      label: row?['key'] as String?,
    );
    await load(quiet: true);
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
