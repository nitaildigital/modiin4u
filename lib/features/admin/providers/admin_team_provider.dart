import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// Who may use the control centre.
///
/// A team member is an `admin_users` row: a profile (someone who already has
/// an account), a role from `admin_roles`, and `is_active`. `is_admin()`
/// answers true for an active row, so this table is the panel's front door —
/// the screen used to read and write `name`, `email` and `role`, none of
/// which are columns here, so nothing it saved could ever land.
final adminTeamProvider =
    StateNotifierProvider<
      AdminTeamNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminTeamNotifier();
    });

/// A change the panel refuses because it would lock someone out: the person
/// signed in, or the last active super admin. The message is for the screen.
class AdminTeamGuard implements Exception {
  final String message;
  const AdminTeamGuard(this.message);
  @override
  String toString() => message;
}

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
        ascending: true,
        hasStatus: false,
      );

  String? _query;

  /// The profile of whoever is signed in — their own row is the one they
  /// must not switch off.
  static String? get currentProfileId =>
      SupabaseConfig.client.auth.currentUser?.id;

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
  /// It cannot create the account: that happens when they sign up in the
  /// app, which is what puts the row in `profiles`. A profile that was a
  /// member before and was switched off is switched back on with the new
  /// role rather than inserted twice — `profile_id` is unique.
  Future<void> grant({
    required String profileId,
    required String roleId,
  }) async {
    final existing = await SupabaseConfig.client
        .from('admin_users')
        .select('id')
        .eq('profile_id', profileId)
        .maybeSingle();
    final fields = {'role_id': roleId, 'is_active': true};
    String? rowId;
    if (existing != null) {
      rowId = existing['id'] as String;
      await updateRow('admin_users', rowId, fields);
    } else {
      final inserted = await SupabaseConfig.client
          .from('admin_users')
          .insert({'profile_id': profileId, ...fields})
          .select('id')
          .maybeSingle();
      rowId = inserted?['id']?.toString();
    }
    await recordAdminAction(
      action: existing != null ? 'update' : 'create',
      table: 'admin_users',
      rowId: rowId,
      fields: fields,
    );
    await load();
  }

  /// Changes a member's role, unless that would leave the panel without a
  /// super admin or demote the person doing it.
  Future<void> changeRole(Map<String, dynamic> member, String roleId) async {
    final current = member['role_id'] as String?;
    if (current == roleId) return;
    if (member['profile_id'] == currentProfileId) {
      throw const AdminTeamGuard(
        'אי אפשר לשנות את התפקיד של עצמך. מנהל ראשי אחר יכול לעשות זאת.',
      );
    }
    if (await _isLastActiveSuperAdmin(member)) {
      throw const AdminTeamGuard(
        'זהו המנהל הראשי הפעיל היחיד. יש למנות מנהל ראשי נוסף לפני שינוי '
        'התפקיד, אחרת לא יישאר מי שינהל את הצוות.',
      );
    }
    await update(member['id'] as String, {'role_id': roleId});
  }

  /// Switches access on or off. Off keeps the row, so it can be switched
  /// back and the history of who did what still has a name.
  Future<void> setMemberActive(Map<String, dynamic> member, bool active) async {
    if (!active) {
      if (member['profile_id'] == currentProfileId) {
        throw const AdminTeamGuard(
          'אי אפשר להשבית את עצמך — היית ננעל מחוץ לממשק. '
          'מנהל ראשי אחר יכול לעשות זאת.',
        );
      }
      if (await _isLastActiveSuperAdmin(member)) {
        throw const AdminTeamGuard(
          'זהו המנהל הראשי הפעיל היחיד. השבתתו הייתה משאירה את הממשק ללא '
          'מנהל ראשי.',
        );
      }
    }
    await setActive(member['id'] as String, active);
  }

  /// Asked of the table, not the list on screen: a search narrows the list,
  /// and the answer must not depend on what someone typed.
  Future<bool> _isLastActiveSuperAdmin(Map<String, dynamic> member) async {
    final role = member['admin_roles'] as Map?;
    if (role?['name'] != 'super_admin' || member['is_active'] != true) {
      return false;
    }
    final rows = await SupabaseConfig.client
        .from('admin_users')
        .select('id')
        .eq('role_id', role!['id'] as String)
        .eq('is_active', true);
    return (rows as List).length <= 1;
  }
}

/// The roles, from `admin_roles` — the panel no longer carries its own list.
final adminRolesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final rows = await SupabaseConfig.client
      .from('admin_roles')
      .select('id, name, label, description, is_system')
      .order('label', ascending: true);
  return List<Map<String, dynamic>>.from(rows);
});

/// People with an account, for the picker when granting access.
final adminCandidateProfilesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final rows = await SupabaseConfig.client
          .from('profiles')
          .select('id, full_name, email')
          .order('full_name', ascending: true);
      return List<Map<String, dynamic>>.from(rows);
    });
