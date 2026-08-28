import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminAuditProvider = StateNotifierProvider<AdminAuditNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminAuditNotifier();
});

class AdminAuditNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _all = [];
  String? _search;
  String? _actionFilter;
  String? _entityTypeFilter;
  String? _adminFilter;

  AdminAuditNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    _all = List<Map<String, dynamic>>.from(_mockAuditLogs);
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_all);
    if (_search != null && _search!.isNotEmpty) {
      final q = _search!.toLowerCase();
      filtered = filtered.where((e) {
        final title = (e['entity_title'] as String? ?? '').toLowerCase();
        final admin = (e['admin_name'] as String? ?? '').toLowerCase();
        return title.contains(q) || admin.contains(q);
      }).toList();
    }
    if (_actionFilter != null && _actionFilter!.isNotEmpty) {
      filtered = filtered.where((e) => e['action'] == _actionFilter).toList();
    }
    if (_entityTypeFilter != null && _entityTypeFilter!.isNotEmpty) {
      filtered = filtered.where((e) => e['entity_type'] == _entityTypeFilter).toList();
    }
    if (_adminFilter != null && _adminFilter!.isNotEmpty) {
      filtered = filtered.where((e) => e['admin_id'] == _adminFilter).toList();
    }
    state = AsyncValue.data(filtered);
  }

  void setSearch(String? s) { _search = s; _applyFilters(); }
  void setActionFilter(String? s) { _actionFilter = s; _applyFilters(); }
  void setEntityTypeFilter(String? s) { _entityTypeFilter = s; _applyFilters(); }
  void setAdminFilter(String? s) { _adminFilter = s; _applyFilters(); }
}

final _mockAuditLogs = <Map<String, dynamic>>[
  {'id': 'aud_1', 'admin_id': 'adm_1', 'admin_name': 'ניתאי לוי', 'action': 'login', 'entity_type': 'system', 'entity_id': null, 'entity_title': 'כניסה למערכת', 'before_data': null, 'after_data': null, 'ip_address': '84.109.22.15', 'user_agent': 'Chrome/126 macOS', 'created_at': '2026-08-28T08:30:00Z'},
  {'id': 'aud_2', 'admin_id': 'adm_1', 'admin_name': 'ניתאי לוי', 'action': 'create', 'entity_type': 'article', 'entity_id': 'a5', 'entity_title': 'כתבה חדשה — אירועי ספטמבר', 'before_data': null, 'after_data': {'title': 'אירועי ספטמבר במודיעין', 'status': 'draft'}, 'ip_address': '84.109.22.15', 'user_agent': 'Chrome/126 macOS', 'created_at': '2026-08-28T08:45:00Z'},
  {'id': 'aud_3', 'admin_id': 'adm_2', 'admin_name': 'יוסי כהן', 'action': 'login', 'entity_type': 'system', 'entity_id': null, 'entity_title': 'כניסה למערכת', 'before_data': null, 'after_data': null, 'ip_address': '77.126.45.88', 'user_agent': 'Chrome/126 Windows', 'created_at': '2026-08-27T14:22:00Z'},
  {'id': 'aud_4', 'admin_id': 'adm_2', 'admin_name': 'יוסי כהן', 'action': 'update', 'entity_type': 'article', 'entity_id': 'a1', 'entity_title': 'פארק ענבה — שדרוג חדש לתושבים', 'before_data': {'body': '(תוכן ישן...)'}, 'after_data': {'body': '(תוכן מעודכן...)'}, 'ip_address': '77.126.45.88', 'user_agent': 'Chrome/126 Windows', 'created_at': '2026-08-27T14:35:00Z'},
  {'id': 'aud_5', 'admin_id': 'adm_2', 'admin_name': 'יוסי כהן', 'action': 'status_change', 'entity_type': 'article', 'entity_id': 'a4', 'entity_title': 'טיפים לקיץ בטוח — מדריך הורים', 'before_data': {'status': 'draft'}, 'after_data': {'status': 'published'}, 'ip_address': '77.126.45.88', 'user_agent': 'Chrome/126 Windows', 'created_at': '2026-08-27T15:00:00Z'},
  {'id': 'aud_6', 'admin_id': 'adm_3', 'admin_name': 'שרה אברהם', 'action': 'login', 'entity_type': 'system', 'entity_id': null, 'entity_title': 'כניסה למערכת', 'before_data': null, 'after_data': null, 'ip_address': '82.80.120.55', 'user_agent': 'Safari/17 macOS', 'created_at': '2026-08-28T07:45:00Z'},
  {'id': 'aud_7', 'admin_id': 'adm_3', 'admin_name': 'שרה אברהם', 'action': 'create', 'entity_type': 'business', 'entity_id': 'b5', 'entity_title': 'קפה לנדוור מודיעין', 'before_data': null, 'after_data': {'name': 'קפה לנדוור מודיעין', 'status': 'pending'}, 'ip_address': '82.80.120.55', 'user_agent': 'Safari/17 macOS', 'created_at': '2026-08-28T08:00:00Z'},
  {'id': 'aud_8', 'admin_id': 'adm_3', 'admin_name': 'שרה אברהם', 'action': 'status_change', 'entity_type': 'business', 'entity_id': 'b4', 'entity_title': 'ביסטרו מודיעין', 'before_data': {'status': 'pending'}, 'after_data': {'status': 'active'}, 'ip_address': '82.80.120.55', 'user_agent': 'Safari/17 macOS', 'created_at': '2026-08-27T10:30:00Z'},
  {'id': 'aud_9', 'admin_id': 'adm_4', 'admin_name': 'דנה מזרחי', 'action': 'login', 'entity_type': 'system', 'entity_id': null, 'entity_title': 'כניסה למערכת', 'before_data': null, 'after_data': null, 'ip_address': '5.102.88.210', 'user_agent': 'Chrome/126 Windows', 'created_at': '2026-08-26T16:10:00Z'},
  {'id': 'aud_10', 'admin_id': 'adm_4', 'admin_name': 'דנה מזרחי', 'action': 'delete', 'entity_type': 'review', 'entity_id': 'r_spam', 'entity_title': 'ביקורת ספאם — פיצה פרגו', 'before_data': {'text': 'ספאם...', 'rating': 1}, 'after_data': null, 'ip_address': '5.102.88.210', 'user_agent': 'Chrome/126 Windows', 'created_at': '2026-08-26T16:30:00Z'},
  {'id': 'aud_11', 'admin_id': 'adm_4', 'admin_name': 'דנה מזרחי', 'action': 'status_change', 'entity_type': 'user', 'entity_id': 'u_spam', 'entity_title': 'חשבון ספאם — חסימה', 'before_data': {'is_banned': false}, 'after_data': {'is_banned': true}, 'ip_address': '5.102.88.210', 'user_agent': 'Chrome/126 Windows', 'created_at': '2026-08-26T16:35:00Z'},
  {'id': 'aud_12', 'admin_id': 'adm_1', 'admin_name': 'ניתאי לוי', 'action': 'update', 'entity_type': 'business', 'entity_id': 'b1', 'entity_title': 'פיצה פרגו — עדכון שעות', 'before_data': {'phone': '08-9712345'}, 'after_data': {'phone': '08-9712345', 'has_delivery': true}, 'ip_address': '84.109.22.15', 'user_agent': 'Chrome/126 macOS', 'created_at': '2026-08-26T12:00:00Z'},
  {'id': 'aud_13', 'admin_id': 'adm_1', 'admin_name': 'ניתאי לוי', 'action': 'create', 'entity_type': 'event', 'entity_id': 'ev_9', 'entity_title': 'מרתון מודיעין 2026', 'before_data': null, 'after_data': {'title': 'מרתון מודיעין 2026', 'status': 'draft'}, 'ip_address': '84.109.22.15', 'user_agent': 'Chrome/126 macOS', 'created_at': '2026-08-25T11:00:00Z'},
  {'id': 'aud_14', 'admin_id': 'adm_3', 'admin_name': 'שרה אברהם', 'action': 'update', 'entity_type': 'business', 'entity_id': 'b3', 'entity_title': 'סטודיו שרה — עדכון פרטים', 'before_data': {'description': '(ישן)'}, 'after_data': {'description': '(חדש)', 'is_featured': true}, 'ip_address': '82.80.120.55', 'user_agent': 'Safari/17 macOS', 'created_at': '2026-08-25T09:00:00Z'},
  {'id': 'aud_15', 'admin_id': 'adm_2', 'admin_name': 'יוסי כהן', 'action': 'create', 'entity_type': 'article', 'entity_id': 'a_new1', 'entity_title': 'מרכז ספורט חדש ברמת מודיעין', 'before_data': null, 'after_data': {'title': 'מרכז ספורט חדש ברמת מודיעין', 'status': 'draft'}, 'ip_address': '77.126.45.88', 'user_agent': 'Chrome/126 Windows', 'created_at': '2026-08-25T14:30:00Z'},
  {'id': 'aud_16', 'admin_id': 'adm_2', 'admin_name': 'יוסי כהן', 'action': 'status_change', 'entity_type': 'article', 'entity_id': 'a_new1', 'entity_title': 'מרכז ספורט חדש ברמת מודיעין', 'before_data': {'status': 'draft'}, 'after_data': {'status': 'published'}, 'ip_address': '77.126.45.88', 'user_agent': 'Chrome/126 Windows', 'created_at': '2026-08-25T16:00:00Z'},
  {'id': 'aud_17', 'admin_id': 'adm_1', 'admin_name': 'ניתאי לוי', 'action': 'delete', 'entity_type': 'business', 'entity_id': 'b_closed', 'entity_title': 'מסעדה שנסגרה', 'before_data': {'name': 'מסעדה שנסגרה', 'status': 'closed'}, 'after_data': null, 'ip_address': '84.109.22.15', 'user_agent': 'Chrome/126 macOS', 'created_at': '2026-08-24T15:00:00Z'},
  {'id': 'aud_18', 'admin_id': 'adm_3', 'admin_name': 'שרה אברהם', 'action': 'create', 'entity_type': 'business', 'entity_id': 'b6', 'entity_title': 'חנות ספרים — ספרא', 'before_data': null, 'after_data': {'name': 'ספרא — חנות ספרים', 'status': 'pending'}, 'ip_address': '82.80.120.55', 'user_agent': 'Safari/17 macOS', 'created_at': '2026-08-24T10:00:00Z'},
  {'id': 'aud_19', 'admin_id': 'adm_4', 'admin_name': 'דנה מזרחי', 'action': 'update', 'entity_type': 'user', 'entity_id': 'u6', 'entity_title': 'דני פרץ — עדכון פרופיל', 'before_data': {'neighborhood': null}, 'after_data': {'neighborhood': 'כפר הנוער'}, 'ip_address': '5.102.88.210', 'user_agent': 'Chrome/126 Windows', 'created_at': '2026-08-24T14:00:00Z'},
  {'id': 'aud_20', 'admin_id': 'adm_1', 'admin_name': 'ניתאי לוי', 'action': 'status_change', 'entity_type': 'event', 'entity_id': 'ev_1', 'entity_title': 'הופעת שלמה ארצי', 'before_data': {'status': 'draft'}, 'after_data': {'status': 'published'}, 'ip_address': '84.109.22.15', 'user_agent': 'Chrome/126 macOS', 'created_at': '2026-08-23T11:00:00Z'},
  {'id': 'aud_21', 'admin_id': 'adm_2', 'admin_name': 'יוסי כהן', 'action': 'update', 'entity_type': 'article', 'entity_id': 'a3', 'entity_title': 'קבוצת הכדורגל — עדכון תמונה', 'before_data': {'image': null}, 'after_data': {'image': 'football-promotion.jpg'}, 'ip_address': '77.126.45.88', 'user_agent': 'Chrome/126 Windows', 'created_at': '2026-08-23T09:30:00Z'},
  {'id': 'aud_22', 'admin_id': 'adm_3', 'admin_name': 'שרה אברהם', 'action': 'status_change', 'entity_type': 'business', 'entity_id': 'b2', 'entity_title': 'סופר פארם — מאומת', 'before_data': {'is_verified': false}, 'after_data': {'is_verified': true}, 'ip_address': '82.80.120.55', 'user_agent': 'Safari/17 macOS', 'created_at': '2026-08-23T08:00:00Z'},
  {'id': 'aud_23', 'admin_id': 'adm_1', 'admin_name': 'ניתאי לוי', 'action': 'export', 'entity_type': 'system', 'entity_id': null, 'entity_title': 'ייצוא דוח הכנסות — אוגוסט', 'before_data': null, 'after_data': {'format': 'csv', 'month': '2026-08'}, 'ip_address': '84.109.22.15', 'user_agent': 'Chrome/126 macOS', 'created_at': '2026-08-22T17:00:00Z'},
  {'id': 'aud_24', 'admin_id': 'adm_4', 'admin_name': 'דנה מזרחי', 'action': 'delete', 'entity_type': 'comment', 'entity_id': 'cmt_spam2', 'entity_title': 'תגובת ספאם נוספת', 'before_data': {'body': 'לינק ספאם...'}, 'after_data': null, 'ip_address': '5.102.88.210', 'user_agent': 'Chrome/126 Windows', 'created_at': '2026-08-22T14:00:00Z'},
  {'id': 'aud_25', 'admin_id': 'adm_1', 'admin_name': 'ניתאי לוי', 'action': 'create', 'entity_type': 'event', 'entity_id': 'ev_6', 'entity_title': 'סדנת בישול ילדים', 'before_data': null, 'after_data': {'title': 'סדנת בישול ילדים', 'status': 'published'}, 'ip_address': '84.109.22.15', 'user_agent': 'Chrome/126 macOS', 'created_at': '2026-08-22T10:00:00Z'},
  {'id': 'aud_26', 'admin_id': 'adm_3', 'admin_name': 'שרה אברהם', 'action': 'update', 'entity_type': 'business', 'entity_id': 'b1', 'entity_title': 'פיצה פרגו — עדכון הסכם', 'before_data': {'plan': 'basic'}, 'after_data': {'plan': 'premium'}, 'ip_address': '82.80.120.55', 'user_agent': 'Safari/17 macOS', 'created_at': '2026-08-22T08:30:00Z'},
  {'id': 'aud_27', 'admin_id': 'adm_2', 'admin_name': 'יוסי כהן', 'action': 'create', 'entity_type': 'article', 'entity_id': 'a_tips', 'entity_title': '10 מסעדות חדשות בעיר', 'before_data': null, 'after_data': {'title': '10 מסעדות חדשות בעיר', 'status': 'draft'}, 'ip_address': '77.126.45.88', 'user_agent': 'Chrome/126 Windows', 'created_at': '2026-08-21T11:00:00Z'},
  {'id': 'aud_28', 'admin_id': 'adm_1', 'admin_name': 'ניתאי לוי', 'action': 'login', 'entity_type': 'system', 'entity_id': null, 'entity_title': 'כניסה למערכת', 'before_data': null, 'after_data': null, 'ip_address': '84.109.22.15', 'user_agent': 'Chrome/126 macOS', 'created_at': '2026-08-21T08:00:00Z'},
  {'id': 'aud_29', 'admin_id': 'adm_4', 'admin_name': 'דנה מזרחי', 'action': 'status_change', 'entity_type': 'user', 'entity_id': 'u6', 'entity_title': 'דני פרץ — ביטול חסימה', 'before_data': {'is_banned': true}, 'after_data': {'is_banned': false}, 'ip_address': '5.102.88.210', 'user_agent': 'Chrome/126 Windows', 'created_at': '2026-08-21T10:00:00Z'},
  {'id': 'aud_30', 'admin_id': 'adm_3', 'admin_name': 'שרה אברהם', 'action': 'create', 'entity_type': 'business', 'entity_id': 'b_gym', 'entity_title': 'הולמס פלייס מודיעין', 'before_data': null, 'after_data': {'name': 'הולמס פלייס מודיעין', 'status': 'active'}, 'ip_address': '82.80.120.55', 'user_agent': 'Safari/17 macOS', 'created_at': '2026-08-20T09:00:00Z'},
  {'id': 'aud_31', 'admin_id': 'adm_2', 'admin_name': 'יוסי כהן', 'action': 'update', 'entity_type': 'article', 'entity_id': 'a2', 'entity_title': 'מרכז מסחרי — עדכון כותרת', 'before_data': {'title': 'מרכז חדש'}, 'after_data': {'title': 'פתיחת מרכז מסחרי חדש במע"ר'}, 'ip_address': '77.126.45.88', 'user_agent': 'Chrome/126 Windows', 'created_at': '2026-08-20T13:30:00Z'},
  {'id': 'aud_32', 'admin_id': 'adm_1', 'admin_name': 'ניתאי לוי', 'action': 'status_change', 'entity_type': 'business', 'entity_id': 'b3', 'entity_title': 'סטודיו שרה — featured', 'before_data': {'is_featured': false}, 'after_data': {'is_featured': true}, 'ip_address': '84.109.22.15', 'user_agent': 'Chrome/126 macOS', 'created_at': '2026-08-19T16:00:00Z'},
  {'id': 'aud_33', 'admin_id': 'adm_4', 'admin_name': 'דנה מזרחי', 'action': 'login', 'entity_type': 'system', 'entity_id': null, 'entity_title': 'כניסה למערכת', 'before_data': null, 'after_data': null, 'ip_address': '5.102.88.210', 'user_agent': 'Chrome/126 Windows', 'created_at': '2026-08-19T09:00:00Z'},
  {'id': 'aud_34', 'admin_id': 'adm_1', 'admin_name': 'ניתאי לוי', 'action': 'create', 'entity_type': 'event', 'entity_id': 'ev_7', 'entity_title': 'ריצת ערב קהילתית', 'before_data': null, 'after_data': {'title': 'ריצת ערב קהילתית', 'date': '2026-08-19'}, 'ip_address': '84.109.22.15', 'user_agent': 'Chrome/126 macOS', 'created_at': '2026-08-18T10:00:00Z'},
  {'id': 'aud_35', 'admin_id': 'adm_3', 'admin_name': 'שרה אברהם', 'action': 'update', 'entity_type': 'business', 'entity_id': 'b1', 'entity_title': 'פיצה פרגו — עדכון תמונות', 'before_data': {'images': 2}, 'after_data': {'images': 5}, 'ip_address': '82.80.120.55', 'user_agent': 'Safari/17 macOS', 'created_at': '2026-08-18T08:00:00Z'},
  {'id': 'aud_36', 'admin_id': 'adm_2', 'admin_name': 'יוסי כהן', 'action': 'status_change', 'entity_type': 'article', 'entity_id': 'a_old', 'entity_title': 'כתבה ישנה — ארכיון', 'before_data': {'status': 'published'}, 'after_data': {'status': 'archived'}, 'ip_address': '77.126.45.88', 'user_agent': 'Chrome/126 Windows', 'created_at': '2026-08-17T15:00:00Z'},
  {'id': 'aud_37', 'admin_id': 'adm_1', 'admin_name': 'ניתאי לוי', 'action': 'update', 'entity_type': 'system', 'entity_id': null, 'entity_title': 'עדכון Feature Flag — AI_SEARCH', 'before_data': {'is_enabled': false}, 'after_data': {'is_enabled': true, 'rollout_pct': 25}, 'ip_address': '84.109.22.15', 'user_agent': 'Chrome/126 macOS', 'created_at': '2026-08-17T11:00:00Z'},
  {'id': 'aud_38', 'admin_id': 'adm_3', 'admin_name': 'שרה אברהם', 'action': 'create', 'entity_type': 'business', 'entity_id': 'b_dent', 'entity_title': 'ד"ר שלום — רופא שיניים', 'before_data': null, 'after_data': {'name': 'ד"ר שלום — רופא שיניים', 'status': 'active'}, 'ip_address': '82.80.120.55', 'user_agent': 'Safari/17 macOS', 'created_at': '2026-08-16T09:00:00Z'},
  {'id': 'aud_39', 'admin_id': 'adm_4', 'admin_name': 'דנה מזרחי', 'action': 'status_change', 'entity_type': 'user', 'entity_id': 'u_spam', 'entity_title': 'חשבון ספאם — חסימה', 'before_data': {'is_banned': false}, 'after_data': {'is_banned': true}, 'ip_address': '5.102.88.210', 'user_agent': 'Chrome/126 Windows', 'created_at': '2026-08-14T08:00:00Z'},
  {'id': 'aud_40', 'admin_id': 'adm_1', 'admin_name': 'ניתאי לוי', 'action': 'login', 'entity_type': 'system', 'entity_id': null, 'entity_title': 'כניסה למערכת (מובייל)', 'before_data': null, 'after_data': null, 'ip_address': '84.109.22.15', 'user_agent': 'Safari/17 iOS', 'created_at': '2026-08-14T07:00:00Z'},
  {'id': 'aud_41', 'admin_id': 'adm_2', 'admin_name': 'יוסי כהן', 'action': 'create', 'entity_type': 'article', 'entity_id': 'a3', 'entity_title': 'קבוצת הכדורגל העירונית עלתה ליגה', 'before_data': null, 'after_data': {'title': 'קבוצת הכדורגל העירונית עלתה ליגה', 'status': 'published'}, 'ip_address': '77.126.45.88', 'user_agent': 'Chrome/126 Windows', 'created_at': '2026-08-10T09:00:00Z'},
  {'id': 'aud_42', 'admin_id': 'adm_1', 'admin_name': 'ניתאי לוי', 'action': 'export', 'entity_type': 'system', 'entity_id': null, 'entity_title': 'ייצוא רשימת משתמשים', 'before_data': null, 'after_data': {'format': 'csv', 'count': 248}, 'ip_address': '84.109.22.15', 'user_agent': 'Chrome/126 macOS', 'created_at': '2026-08-10T08:00:00Z'},
];
