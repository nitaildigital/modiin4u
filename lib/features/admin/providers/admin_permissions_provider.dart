import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';

/// What the signed-in administrator's role may open in the panel.
///
/// The client asked to limit roles (2 Oct). Each role's rights are rows in
/// `admin_role_permissions` — a module ('articles', 'businesses', …) and an
/// action — which the Team section shows and the client can change; until
/// now nothing read them, so every administrator saw every section. A
/// section is shown when the role may 'view' its module.
///
/// The main admin (`super_admin`) sees everything, whatever the rows say,
/// so the client can never lock himself out.
///
/// This decides what the panel shows; the database holds each module to
/// its role as well (00050). The main admin changes the rows in Team →
/// Roles & rights, and only the main admin may (00066).
class AdminPermissions {
  /// Null for the main admin: everything is allowed.
  final Set<String>? _modules;
  final String? roleName;

  const AdminPermissions._(this._modules, this.roleName);

  /// Everything, for the main admin, and while the role is still loading —
  /// the panel opens as it always did rather than flickering empty.
  static const all = AdminPermissions._(null, 'super_admin');

  /// Nothing but the overview and settings: what the panel shows when the
  /// role could not be read. It fails closed — a limited admin must not see
  /// every section because a request failed.
  static const none = AdminPermissions._({}, null);

  /// The rights to draw with: all while loading, none on an error.
  static AdminPermissions of(AsyncValue<AdminPermissions> value) =>
      value.hasError ? none : (value.valueOrNull ?? all);

  bool get isMainAdmin => _modules == null;

  /// Whether a section built on [module] may be opened. A null module is a
  /// section every administrator has (the overview, their own settings).
  bool canView(String? module) =>
      module == null || _modules == null || _modules.contains(module);
}

final adminPermissionsProvider = FutureProvider<AdminPermissions>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return const AdminPermissions._({}, null);

  final admin = await SupabaseConfig.client
      .from('admin_users')
      .select('role_id, is_active, admin_roles(name)')
      .eq('profile_id', user.id)
      .maybeSingle();
  if (admin == null || admin['is_active'] != true) {
    return const AdminPermissions._({}, null);
  }
  final role = admin['admin_roles'];
  final roleName = role is Map ? role['name'] as String? : null;
  if (roleName == 'super_admin') return AdminPermissions.all;

  final rows = await SupabaseConfig.client
      .from('admin_role_permissions')
      .select('module')
      .eq('role_id', admin['role_id'] as String)
      .eq('action', 'view')
      .eq('allowed', true);
  return AdminPermissions._(
    {for (final r in List<Map<String, dynamic>>.from(rows)) r['module'] as String},
    roleName,
  );
});
