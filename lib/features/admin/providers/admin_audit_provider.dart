import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_table_notifier.dart';

/// What administrators have done, on the live table.
///
/// Read only by design: an audit trail that can be edited is not one.
final adminAuditProvider =
    StateNotifierProvider<
      AdminAuditNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminAuditNotifier();
    });

class AdminAuditNotifier extends AdminTableNotifier {
  AdminAuditNotifier()
    : super(
        table: 'audit_logs',
        searchColumns: const ['action', 'entity_type'],
        columns: '*, admin_users(id, profiles(full_name))',
        orderBy: 'created_at',
        hasStatus: false,
        limit: 300,
      );

  String? _action;
  String? _admin;
  String? _entityType;

  void setActionFilter(String? action) {
    _action = action;
    load();
  }

  void setAdminFilter(String? adminId) {
    _admin = adminId;
    load();
  }

  void setEntityTypeFilter(String? type) {
    _entityType = type;
    load();
  }

  @override
  Future<void> load() async {
    await super.load();
    if (_action == null && _admin == null && _entityType == null) return;

    state.whenData((rows) {
      state = AsyncValue.data(
        rows.where((r) {
          if (_action != null && _action!.isNotEmpty && r['action'] != _action) {
            return false;
          }
          if (_admin != null && _admin!.isNotEmpty && r['admin_id'] != _admin) {
            return false;
          }
          if (_entityType != null &&
              _entityType!.isNotEmpty &&
              r['entity_type'] != _entityType) {
            return false;
          }
          return true;
        }).toList(),
      );
    });
  }
}
