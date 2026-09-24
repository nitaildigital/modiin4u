import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// Who may use the control centre.
///
/// `admin_users` has no rows, so nobody is an administrator: `is_admin()`
/// answers false for everyone, the gate on /admin turns everyone away, and
/// once the security migration runs the panel can write nothing. The first
/// row created here is what gives the client his own access.
final adminTeamProvider =
    StateNotifierProvider<
      AdminTeamNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminTeamNotifier();
    });

class AdminTeamNotifier extends AdminTableNotifier {
  AdminTeamNotifier()
    : super(
        table: 'admin_users',
        // The name and address live on the profile, so the search runs
        // through the join rather than over this table's own columns.
        searchColumns: const [],
        columns:
            '*, profiles(id, full_name, email, avatar_url), '
            'admin_roles(id, name, label)',
        orderBy: 'created_at',
        hasStatus: false,
      );

  String? _query;

  @override
  void setSearch(String? search) {
    _query = search;
    load();
  }

  @override
  Future<void> load() async {
    await super.load();
    final q = _query?.trim().toLowerCase();
    if (q == null || q.isEmpty) return;

    state.whenData((rows) {
      state = AsyncValue.data(
        rows.where((r) {
          final p = r['profiles'];
          if (p is! Map) return false;
          final name = (p['full_name'] as String? ?? '').toLowerCase();
          final email = (p['email'] as String? ?? '').toLowerCase();
          return name.contains(q) || email.contains(q);
        }).toList(),
      );
    });
  }

  /// Grants access to someone who already has an account.
  ///
  /// It cannot create the account: that happens when they sign in to the app
  /// for the first time, which is what puts the row in `profiles`.
  Future<void> createUser(Map<String, dynamic> user) => create(user);

  Future<void> updateUser(String id, Map<String, dynamic> f) => update(id, f);

  /// Withdraws access rather than deleting the row, so the audit trail keeps
  /// showing who did what.
  Future<void> deleteUser(String id) => setActive(id, false);

  Future<void> toggleActive(String id) async {
    final row = state.valueOrNull?.firstWhere(
      (u) => u['id'] == id,
      orElse: () => const {},
    );
    await setActive(id, !((row?['is_active'] as bool?) ?? true));
  }

  // ── Roles ──

  Future<void> createRole(Map<String, dynamic> role) async {
    await SupabaseConfig.client.from('admin_roles').insert(role);
  }

  Future<void> updateRole(String id, Map<String, dynamic> fields) async {
    await SupabaseConfig.client.from('admin_roles').update(fields).eq('id', id);
  }

  /// Built-in roles cannot be removed; the column exists to say so.
  Future<void> deleteRole(String id) async {
    await SupabaseConfig.client
        .from('admin_roles')
        .delete()
        .eq('id', id)
        .eq('is_system', false);
  }
}

final adminRolesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final rows = await SupabaseConfig.client
      .from('admin_roles')
      .select('id, name, label, description, is_system')
      .order('name', ascending: true);
  return List<Map<String, dynamic>>.from(rows);
});

/// People with an account, for the picker when granting access.
final adminCandidateProfilesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
      final rows = await SupabaseConfig.client
          .from('profiles')
          .select('id, full_name, email')
          .order('full_name', ascending: true);
      return List<Map<String, dynamic>>.from(rows);
    });
