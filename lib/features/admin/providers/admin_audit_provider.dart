import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_table_notifier.dart';
import '../admin_language.dart';

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
Map<String, String> get auditTableLabels => <String, String>{
  'articles': tr('כתבה', 'Article'),
  'businesses': tr('עסק', 'Business'),
  'events': tr('אירוע', 'Event'),
  'offers': tr('הטבה', 'Benefit'),
  'listings': tr('מודעת נדל״ן', 'Real estate listing'),
  'real_estate_agents': tr('סוכן נדל״ן', 'Real estate agent'),
  'categories': tr('קטגוריה', 'Category'),
  'neighborhoods': tr('שכונה', 'Neighbourhood'),
  'tags': tr('תגית', 'Tag'),
  'media': tr('מדיה', 'Media'),
  'home_blocks': tr('בלוק בדף הבית', 'Home page block'),
  'ad_placements': tr('מיקום פרסום', 'Ad placement'),
  'campaigns': tr('קמפיין', 'Campaign'),
  'push_campaigns': tr('הודעת פוש', 'Push notification'),
  'commercial_agreements': tr('הסכם מסחרי', 'Commercial agreement'),
  'revenue_transactions': tr('הכנסה', 'Revenue'),
  'challenges': tr('אתגר', 'Challenge'),
  'reviews': tr('ביקורת', 'Review'),
  'comments': tr('תגובה', 'Comment'),
  'reports': tr('דיווח', 'Report'),
  'profiles': tr('משתמש', 'User'),
  'admin_users': tr('צוות ניהול', 'Admin team'),
  'parking_lots': tr('חניון', 'Car park'),
};

/// Hebrew names for the `audit_action` values the panel writes.
Map<String, String> get auditActionLabels => <String, String>{
  'create': tr('יצירה', 'Create'),
  'update': tr('עריכה', 'Edit'),
  'delete': tr('מחיקה', 'Delete'),
  'restore': tr('שחזור', 'Restore'),
  'approve': tr('אישור', 'Approve'),
  'reject': tr('דחייה', 'Reject'),
  'publish': tr('פרסום', 'Publish'),
  'unpublish': tr('הסרת פרסום', 'Unpublish'),
  'archive': tr('העברה לארכיון', 'Move to archive'),
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
