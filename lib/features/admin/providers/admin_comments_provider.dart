import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminCommentsProvider = StateNotifierProvider<AdminCommentsNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminCommentsNotifier();
});

class AdminCommentsNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _all = [];
  String? _search;
  String? _statusFilter;
  String? _entityTypeFilter;

  AdminCommentsNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    _all = List<Map<String, dynamic>>.from(_mockComments);
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_all);
    if (_search != null && _search!.isNotEmpty) {
      final q = _search!.toLowerCase();
      filtered = filtered.where((c) {
        final body = (c['body'] as String? ?? '').toLowerCase();
        final user = (c['user_name'] as String? ?? '').toLowerCase();
        return body.contains(q) || user.contains(q);
      }).toList();
    }
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      filtered = filtered.where((c) => c['status'] == _statusFilter).toList();
    }
    if (_entityTypeFilter != null && _entityTypeFilter!.isNotEmpty) {
      filtered = filtered.where((c) => c['entity_type'] == _entityTypeFilter).toList();
    }
    state = AsyncValue.data(filtered);
  }

  void setSearch(String? s) { _search = s; _applyFilters(); }
  void setStatusFilter(String? s) { _statusFilter = s; _applyFilters(); }
  void setEntityTypeFilter(String? s) { _entityTypeFilter = s; _applyFilters(); }

  Future<void> toggleVisibility(String id) async {
    _all = [for (final c in _all) c['id'] == id ? {...c, 'status': (c['status'] == 'visible') ? 'hidden' : 'visible'} : c];
    _applyFilters();
  }

  Future<void> togglePin(String id) async {
    _all = [for (final c in _all) c['id'] == id ? {...c, 'is_pinned': !(c['is_pinned'] as bool? ?? false)} : c];
    _applyFilters();
  }

  Future<void> deleteComment(String id) async {
    _all.removeWhere((c) => c['id'] == id);
    _applyFilters();
  }
}

final _mockComments = <Map<String, dynamic>>[
  {'id': 'cmt_1', 'entity_type': 'article', 'entity_id': 'a1', 'entity_title': 'פארק ענבה — שדרוג חדש לתושבים', 'user_id': 'u3', 'user_name': 'מיכל לוי', 'body': 'סוף סוף! הילדים שלי מחכים לזה כבר חודשים. מתי צפוי להיגמר?', 'parent_id': null, 'status': 'visible', 'is_pinned': false, 'likes_count': 12, 'reports_count': 0, 'created_at': '2026-08-15T10:30:00Z'},
  {'id': 'cmt_2', 'entity_type': 'article', 'entity_id': 'a1', 'entity_title': 'פארק ענבה — שדרוג חדש לתושבים', 'user_id': 'u4', 'user_name': 'אחמד חליל', 'body': 'מקווה שגם יוסיפו מתקנים לנוער ולא רק לקטנים', 'parent_id': 'cmt_1', 'status': 'visible', 'is_pinned': false, 'likes_count': 8, 'reports_count': 0, 'created_at': '2026-08-15T11:15:00Z'},
  {'id': 'cmt_3', 'entity_type': 'article', 'entity_id': 'a1', 'entity_title': 'פארק ענבה — שדרוג חדש לתושבים', 'user_id': 'u5', 'user_name': 'שרה אברהם', 'body': 'לפי מה שאני שומעת, הפרויקט אמור להסתיים עד סוף אוקטובר', 'parent_id': 'cmt_1', 'status': 'visible', 'is_pinned': true, 'likes_count': 15, 'reports_count': 0, 'created_at': '2026-08-15T14:00:00Z'},
  {'id': 'cmt_4', 'entity_type': 'business', 'entity_id': 'b1', 'entity_title': 'פיצה פרגו', 'user_id': 'u3', 'user_name': 'מיכל לוי', 'body': 'הפיצה הכי טובה בעיר, ללא ספק. שירות מעולה', 'parent_id': null, 'status': 'visible', 'is_pinned': false, 'likes_count': 22, 'reports_count': 0, 'created_at': '2026-08-10T18:30:00Z'},
  {'id': 'cmt_5', 'entity_type': 'business', 'entity_id': 'b1', 'entity_title': 'פיצה פרגו', 'user_id': 'u6', 'user_name': 'דני פרץ', 'body': 'ממש ממוצע, לא הבנתי את ההייפ. יש הרבה יותר טוב בסביבה', 'parent_id': null, 'status': 'visible', 'is_pinned': false, 'likes_count': 3, 'reports_count': 2, 'created_at': '2026-08-11T20:00:00Z'},
  {'id': 'cmt_6', 'entity_type': 'business', 'entity_id': 'b3', 'entity_title': 'סטודיו שרה — יוגה ופילאטיס', 'user_id': 'u4', 'user_name': 'אחמד חליל', 'body': 'שרה מורה מדהימה, שיעורי הפילאטיס משנים חיים', 'parent_id': null, 'status': 'visible', 'is_pinned': false, 'likes_count': 18, 'reports_count': 0, 'created_at': '2026-08-09T09:00:00Z'},
  {'id': 'cmt_7', 'entity_type': 'article', 'entity_id': 'a2', 'entity_title': 'פתיחת מרכז מסחרי חדש במע"ר', 'user_id': 'u2', 'user_name': 'יוסי כהן', 'body': 'מצוין! העיר צריכה עוד מרכזי מסחר. מה יהיה שם?', 'parent_id': null, 'status': 'visible', 'is_pinned': false, 'likes_count': 9, 'reports_count': 0, 'created_at': '2026-08-12T12:00:00Z'},
  {'id': 'cmt_8', 'entity_type': 'article', 'entity_id': 'a3', 'entity_title': 'קבוצת הכדורגל העירונית עלתה ליגה', 'user_id': 'u6', 'user_name': 'דני פרץ', 'body': 'כל הכבוד! סוף סוף מודיעין על המפה הספורטיבית', 'parent_id': null, 'status': 'visible', 'is_pinned': false, 'likes_count': 31, 'reports_count': 0, 'created_at': '2026-08-10T15:30:00Z'},
  {'id': 'cmt_9', 'entity_type': 'article', 'entity_id': 'a3', 'entity_title': 'קבוצת הכדורגל העירונית עלתה ליגה', 'user_id': 'u3', 'user_name': 'מיכל לוי', 'body': 'מישהו יודע איפה קונים כרטיסים למשחקים?', 'parent_id': null, 'status': 'visible', 'is_pinned': false, 'likes_count': 5, 'reports_count': 0, 'created_at': '2026-08-10T16:45:00Z'},
  {'id': 'cmt_10', 'entity_type': 'business', 'entity_id': 'b2', 'entity_title': 'סופר פארם מודיעין', 'user_id': 'u4', 'user_name': 'אחמד חליל', 'body': 'שירות איטי מאוד, תמיד תורים ארוכים', 'parent_id': null, 'status': 'flagged', 'is_pinned': false, 'likes_count': 4, 'reports_count': 1, 'created_at': '2026-08-13T11:20:00Z'},
  {'id': 'cmt_11', 'entity_type': 'article', 'entity_id': 'a2', 'entity_title': 'פתיחת מרכז מסחרי חדש במע"ר', 'user_id': 'u5', 'user_name': 'שרה אברהם', 'body': 'מקווה שיהיה חניון גדול, כי אין חניה במע"ר', 'parent_id': 'cmt_7', 'status': 'visible', 'is_pinned': false, 'likes_count': 14, 'reports_count': 0, 'created_at': '2026-08-12T13:10:00Z'},
  {'id': 'cmt_12', 'entity_type': 'business', 'entity_id': 'b1', 'entity_title': 'פיצה פרגו', 'user_id': 'u_spam', 'user_name': 'חשבון ספאם', 'body': 'קנו עכשיו! מבצע מטורף! לחצו על הלינק: spam.example.com', 'parent_id': null, 'status': 'flagged', 'is_pinned': false, 'likes_count': 0, 'reports_count': 5, 'created_at': '2026-08-14T03:00:00Z'},
  {'id': 'cmt_13', 'entity_type': 'event', 'entity_id': 'ev_1', 'entity_title': 'הופעת שלמה ארצי', 'user_id': 'u3', 'user_name': 'מיכל לוי', 'body': 'מחכה כבר שבועות! מישהו יודע אם יש עוד כרטיסים?', 'parent_id': null, 'status': 'visible', 'is_pinned': false, 'likes_count': 7, 'reports_count': 0, 'created_at': '2026-08-13T09:30:00Z'},
  {'id': 'cmt_14', 'entity_type': 'event', 'entity_id': 'ev_5', 'entity_title': 'פסטיבל בירה מודיעין', 'user_id': 'u6', 'user_name': 'דני פרץ', 'body': 'אני מגיע עם כל החברה! מקווה שיהיו בירות מיוחדות', 'parent_id': null, 'status': 'visible', 'is_pinned': false, 'likes_count': 11, 'reports_count': 0, 'created_at': '2026-08-18T19:00:00Z'},
  {'id': 'cmt_15', 'entity_type': 'event', 'entity_id': 'ev_5', 'entity_title': 'פסטיבל בירה מודיעין', 'user_id': 'u5', 'user_name': 'שרה אברהם', 'body': 'יש כניסה לילדים? או שזה רק למבוגרים?', 'parent_id': null, 'status': 'visible', 'is_pinned': false, 'likes_count': 6, 'reports_count': 0, 'created_at': '2026-08-19T08:15:00Z'},
  {'id': 'cmt_16', 'entity_type': 'business', 'entity_id': 'b3', 'entity_title': 'סטודיו שרה — יוגה ופילאטיס', 'user_id': 'u_troll', 'user_name': 'משתמש אנונימי', 'body': 'מקום מבאס, בזבוז כסף מוחלט. לכו למקום אחר', 'parent_id': null, 'status': 'hidden', 'is_pinned': false, 'likes_count': 0, 'reports_count': 3, 'created_at': '2026-08-20T22:00:00Z'},
  {'id': 'cmt_17', 'entity_type': 'article', 'entity_id': 'a1', 'entity_title': 'פארק ענבה — שדרוג חדש לתושבים', 'user_id': 'u2', 'user_name': 'יוסי כהן', 'body': 'ראיתי את העבודות לאחרונה — נראה ממש מרשים! שווה לבוא לראות', 'parent_id': null, 'status': 'visible', 'is_pinned': false, 'likes_count': 20, 'reports_count': 0, 'created_at': '2026-08-22T16:30:00Z'},
  {'id': 'cmt_18', 'entity_type': 'business', 'entity_id': 'b4', 'entity_title': 'ביסטרו מודיעין', 'user_id': 'u3', 'user_name': 'מיכל לוי', 'body': 'מתי הם פותחים? שמעתי שהתפריט מעולה', 'parent_id': null, 'status': 'visible', 'is_pinned': false, 'likes_count': 4, 'reports_count': 0, 'created_at': '2026-08-25T11:00:00Z'},
  {'id': 'cmt_19', 'entity_type': 'event', 'entity_id': 'ev_3', 'entity_title': 'ישיבת מועצה פתוחה', 'user_id': 'u4', 'user_name': 'אחמד חליל', 'body': 'חובה להגיע! יש נושאים חשובים לדיון', 'parent_id': null, 'status': 'visible', 'is_pinned': true, 'likes_count': 16, 'reports_count': 0, 'created_at': '2026-08-17T08:00:00Z'},
  {'id': 'cmt_20', 'entity_type': 'article', 'entity_id': 'a4', 'entity_title': 'טיפים לקיץ בטוח — מדריך הורים', 'user_id': 'u5', 'user_name': 'שרה אברהם', 'body': 'מדריך מצוין! שיתפתי עם כל ההורים בקבוצת הווטסאפ של הגן', 'parent_id': null, 'status': 'visible', 'is_pinned': false, 'likes_count': 25, 'reports_count': 0, 'created_at': '2026-08-08T14:20:00Z'},
  {'id': 'cmt_21', 'entity_type': 'business', 'entity_id': 'b1', 'entity_title': 'פיצה פרגו', 'user_id': 'u2', 'user_name': 'יוסי כהן', 'body': 'הפיצה עם הזיתים — חובה! ממליץ בחום', 'parent_id': 'cmt_4', 'status': 'visible', 'is_pinned': false, 'likes_count': 10, 'reports_count': 0, 'created_at': '2026-08-10T19:45:00Z'},
];
