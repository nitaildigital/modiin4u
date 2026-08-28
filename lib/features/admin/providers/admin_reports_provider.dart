import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminReportsProvider = StateNotifierProvider<AdminReportsNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminReportsNotifier();
});

class AdminReportsNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _all = [];
  String? _statusFilter;
  String? _entityTypeFilter;

  AdminReportsNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    _all = List<Map<String, dynamic>>.from(_mockReports);
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_all);
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      filtered = filtered.where((r) => r['status'] == _statusFilter).toList();
    }
    if (_entityTypeFilter != null && _entityTypeFilter!.isNotEmpty) {
      filtered = filtered.where((r) => r['entity_type'] == _entityTypeFilter).toList();
    }
    state = AsyncValue.data(filtered);
  }

  void setStatusFilter(String? s) { _statusFilter = s; _applyFilters(); }
  void setEntityTypeFilter(String? s) { _entityTypeFilter = s; _applyFilters(); }

  Future<void> resolve(String id, String actionTaken) async {
    _all = [for (final r in _all) r['id'] == id ? {...r, 'status': 'resolved', 'reviewed_by': 'ניתאי לוי', 'reviewed_at': DateTime.now().toIso8601String(), 'action_taken': actionTaken} : r];
    _applyFilters();
  }

  Future<void> dismiss(String id) async {
    _all = [for (final r in _all) r['id'] == id ? {...r, 'status': 'dismissed', 'reviewed_by': 'ניתאי לוי', 'reviewed_at': DateTime.now().toIso8601String(), 'action_taken': 'נדחה — לא נמצאה הפרה'} : r];
    _applyFilters();
  }

  Future<void> markReviewed(String id) async {
    _all = [for (final r in _all) r['id'] == id ? {...r, 'status': 'reviewed', 'reviewed_by': 'ניתאי לוי', 'reviewed_at': DateTime.now().toIso8601String()} : r];
    _applyFilters();
  }
}

final _mockReports = <Map<String, dynamic>>[
  {'id': 'rpt_1', 'entity_type': 'comment', 'entity_id': 'cmt_12', 'entity_title': 'תגובת ספאם על פיצה פרגו', 'reporter_id': 'u3', 'reporter_name': 'מיכל לוי', 'reason': 'spam', 'description': 'תגובת ספאם עם לינק חיצוני', 'status': 'pending', 'reviewed_by': null, 'reviewed_at': null, 'action_taken': null, 'created_at': '2026-08-14T03:30:00Z'},
  {'id': 'rpt_2', 'entity_type': 'comment', 'entity_id': 'cmt_12', 'entity_title': 'תגובת ספאם על פיצה פרגו', 'reporter_id': 'u4', 'reporter_name': 'אחמד חליל', 'reason': 'spam', 'description': 'ספאם ברור', 'status': 'pending', 'reviewed_by': null, 'reviewed_at': null, 'action_taken': null, 'created_at': '2026-08-14T04:00:00Z'},
  {'id': 'rpt_3', 'entity_type': 'review', 'entity_id': 'r_fake', 'entity_title': 'ביקורת מזויפת על סופר פארם', 'reporter_id': 'u5', 'reporter_name': 'שרה אברהם', 'reason': 'fake', 'description': 'נראה כמו ביקורת מזויפת, המשתמש לא קיים באמת', 'status': 'reviewed', 'reviewed_by': 'דנה מזרחי', 'reviewed_at': '2026-08-20T10:00:00Z', 'action_taken': null, 'created_at': '2026-08-18T15:00:00Z'},
  {'id': 'rpt_4', 'entity_type': 'comment', 'entity_id': 'cmt_16', 'entity_title': 'תגובה פוגענית על סטודיו שרה', 'reporter_id': 'u3', 'reporter_name': 'מיכל לוי', 'reason': 'inappropriate', 'description': 'תגובה פוגענית ושלילית ללא בסיס', 'status': 'resolved', 'reviewed_by': 'דנה מזרחי', 'reviewed_at': '2026-08-21T09:00:00Z', 'action_taken': 'הוסתרה התגובה', 'created_at': '2026-08-20T22:30:00Z'},
  {'id': 'rpt_5', 'entity_type': 'user', 'entity_id': 'u_troll', 'entity_title': 'משתמש אנונימי', 'reporter_id': 'u5', 'reporter_name': 'שרה אברהם', 'reason': 'harassment', 'description': 'משתמש שמטריל עסקים ומפרסם תגובות שליליות', 'status': 'pending', 'reviewed_by': null, 'reviewed_at': null, 'action_taken': null, 'created_at': '2026-08-21T10:00:00Z'},
  {'id': 'rpt_6', 'entity_type': 'business', 'entity_id': 'b_fake', 'entity_title': 'עסק שלא קיים בפועל', 'reporter_id': 'u4', 'reporter_name': 'אחמד חליל', 'reason': 'fake', 'description': 'רשום עסק שלא קיים בכתובת הזו', 'status': 'pending', 'reviewed_by': null, 'reviewed_at': null, 'action_taken': null, 'created_at': '2026-08-22T14:00:00Z'},
  {'id': 'rpt_7', 'entity_type': 'review', 'entity_id': 'r2', 'entity_title': 'ביקורת על פיצה פרגו', 'reporter_id': 'u2', 'reporter_name': 'יוסי כהן', 'reason': 'inappropriate', 'description': 'ביקורת מכילה שפה לא הולמת', 'status': 'dismissed', 'reviewed_by': 'אלון ברק', 'reviewed_at': '2026-08-16T11:00:00Z', 'action_taken': 'נדחה — לא נמצאה הפרה', 'created_at': '2026-08-15T09:30:00Z'},
  {'id': 'rpt_8', 'entity_type': 'comment', 'entity_id': 'cmt_5', 'entity_title': 'תגובה שלילית על פיצה פרגו', 'reporter_id': 'u2', 'reporter_name': 'יוסי כהן', 'reason': 'inappropriate', 'description': 'ביקורת שלילית לא מוצדקת', 'status': 'dismissed', 'reviewed_by': 'דנה מזרחי', 'reviewed_at': '2026-08-13T14:00:00Z', 'action_taken': 'נדחה — ביקורת לגיטימית', 'created_at': '2026-08-12T08:00:00Z'},
  {'id': 'rpt_9', 'entity_type': 'comment', 'entity_id': 'cmt_10', 'entity_title': 'תגובה מדווחת על סופר פארם', 'reporter_id': 'u_sp', 'reporter_name': 'נציג סופר פארם', 'reason': 'other', 'description': 'בקשה להסרת תגובה שלילית', 'status': 'pending', 'reviewed_by': null, 'reviewed_at': null, 'action_taken': null, 'created_at': '2026-08-25T16:00:00Z'},
  {'id': 'rpt_10', 'entity_type': 'user', 'entity_id': 'u_spam', 'entity_title': 'חשבון ספאם', 'reporter_id': 'u3', 'reporter_name': 'מיכל לוי', 'reason': 'spam', 'description': 'חשבון שמפרסם ספאם בתגובות', 'status': 'resolved', 'reviewed_by': 'ניתאי לוי', 'reviewed_at': '2026-08-14T08:00:00Z', 'action_taken': 'חשבון נחסם', 'created_at': '2026-08-14T04:30:00Z'},
  {'id': 'rpt_11', 'entity_type': 'review', 'entity_id': 'r_comp', 'entity_title': 'ביקורת של מתחרה', 'reporter_id': 'u5', 'reporter_name': 'שרה אברהם', 'reason': 'fake', 'description': 'חשוד שהביקורת הזו נכתבה על ידי בעל עסק מתחרה', 'status': 'pending', 'reviewed_by': null, 'reviewed_at': null, 'action_taken': null, 'created_at': '2026-08-26T10:00:00Z'},
  {'id': 'rpt_12', 'entity_type': 'business', 'entity_id': 'b_dup', 'entity_title': 'כפילות — סופר פארם מודיעין', 'reporter_id': 'u4', 'reporter_name': 'אחמד חליל', 'reason': 'other', 'description': 'העסק הזה כפול, כבר קיים תחת שם אחר', 'status': 'reviewed', 'reviewed_by': 'שרה אברהם', 'reviewed_at': '2026-08-27T09:00:00Z', 'action_taken': null, 'created_at': '2026-08-26T15:00:00Z'},
];
