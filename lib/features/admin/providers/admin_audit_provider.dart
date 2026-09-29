import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_table_notifier.dart';

/// What administrators have done, on the live table.
///
/// Read only by design: an audit trail that can be edited is not one. The
/// entries are written by the shared [AdminTableNotifier] — every section
/// built on it records its creates, edits, status changes and removals — and
/// by the trash's restore.
final adminAuditProvider =
    StateNotifierProvider<
      AdminAuditNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminAuditNotifier();
    });

/// Hebrew names for the tables the panel edits, as the log shows them and as
/// its search matches them.
const auditTableLabels = <String, String>{
  'articles': 'כתבה',
  'businesses': 'עסק',
  'events': 'אירוע',
  'offers': 'הטבה',
  'listings': 'מודעת נדל״ן',
  'real_estate_agents': 'סוכן נדל״ן',
  'categories': 'קטגוריה',
  'neighborhoods': 'שכונה',
  'tags': 'תגית',
  'media': 'מדיה',
  'home_blocks': 'בלוק בדף הבית',
  'ad_placements': 'מיקום פרסום',
  'campaigns': 'קמפיין',
  'push_campaigns': 'הודעת פוש',
  'commercial_agreements': 'הסכם מסחרי',
  'revenue_transactions': 'הכנסה',
  'challenges': 'אתגר',
  'reviews': 'ביקורת',
  'comments': 'תגובה',
  'reports': 'דיווח',
  'profiles': 'משתמש',
  'admin_users': 'צוות ניהול',
  'parking_lots': 'חניון',
};

/// Hebrew names for the `audit_action` values the panel writes.
const auditActionLabels = <String, String>{
  'create': 'יצירה',
  'update': 'עריכה',
  'delete': 'מחיקה',
  'restore': 'שחזור',
  'approve': 'אישור',
  'reject': 'דחייה',
  'publish': 'פרסום',
  'unpublish': 'הסרת פרסום',
  'archive': 'העברה לארכיון',
};

final _uuidText = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

class AdminAuditNotifier extends AdminTableNotifier {
  AdminAuditNotifier()
    : super(
        table: 'audit_logs',
        searchColumns: const ['entity_type'],
        columns: '*, admin_users(id, profiles(full_name))',
        orderBy: 'created_at',
        hasStatus: false,
        limit: 300,
      );

  void setActionFilter(String? action) => setColumnFilter('action', action);

  void setAdminFilter(String? adminId) => setColumnFilter('admin_id', adminId);

  void setEntityTypeFilter(String? type) =>
      setColumnFilter('entity_type', type);

  /// `action` is an enum, which `ilike` cannot read — searching it was what
  /// made every search fail. The text is matched instead against the table
  /// name, the row's name as the log recorded it, the Hebrew names of tables
  /// and actions (an administrator types "כתבה", not "articles"), and a row
  /// id pasted whole.
  @override
  List<String> searchClauses(String q) {
    final lower = q.toLowerCase();
    final tables = [
      for (final e in auditTableLabels.entries)
        if (e.value.contains(q)) e.key,
    ];
    final actions = [
      for (final e in auditActionLabels.entries)
        if (e.value.contains(q) || e.key == lower) e.key,
    ];
    return [
      'entity_type.ilike.%$q%',
      'after_data->>label.ilike.%$q%',
      if (tables.isNotEmpty) 'entity_type.in.(${tables.join(',')})',
      if (actions.isNotEmpty) 'action.in.(${actions.join(',')})',
      if (_uuidText.hasMatch(q)) 'entity_id.eq.$q',
    ];
  }
}
