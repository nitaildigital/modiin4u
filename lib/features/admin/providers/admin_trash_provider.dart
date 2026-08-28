import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminTrashListProvider = StateNotifierProvider<AdminTrashListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminTrashListNotifier();
});

class AdminTrashListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _allData = [];
  String? _entityFilter;

  AdminTrashListNotifier() : super(const AsyncValue.loading()) { load(); }

  Future<void> load() async {
    _allData = List<Map<String, dynamic>>.from(_mockTrash);
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_allData);
    if (_entityFilter != null && _entityFilter!.isNotEmpty) {
      filtered = filtered.where((t) => t['entity_type'] == _entityFilter).toList();
    }
    filtered.sort((a, b) => (b['deleted_at'] as String).compareTo(a['deleted_at'] as String));
    state = AsyncValue.data(filtered);
  }

  void setEntityFilter(String? f) { _entityFilter = f; _applyFilters(); }

  Future<void> restore(String id) async {
    _allData.removeWhere((t) => t['id'] == id);
    _applyFilters();
  }

  Future<void> permanentDelete(String id) async {
    _allData.removeWhere((t) => t['id'] == id);
    _applyFilters();
  }

  Future<void> emptyTrash() async {
    _allData.clear();
    state = const AsyncValue.data([]);
  }

  int daysUntilExpiry(String expiresAt) {
    final exp = DateTime.parse(expiresAt);
    return exp.difference(DateTime.now()).inDays;
  }
}

final _mockTrash = <Map<String, dynamic>>[
  {'id': 'tr_1', 'entity_type': 'business', 'entity_id': 'b_del_1', 'entity_title': 'מסעדת הקוסקוס של סבתא', 'entity_data': {'name': 'מסעדת הקוסקוס של סבתא', 'category': 'מסעדות', 'status': 'active', 'address': 'רח׳ הזית 5, מודיעין'}, 'deleted_by': 'u1', 'deleted_by_name': 'ניתאי לוי', 'deleted_at': '2026-08-25T14:30:00Z', 'expires_at': '2026-09-24T14:30:00Z'},
  {'id': 'tr_2', 'entity_type': 'article', 'entity_id': 'a_del_1', 'entity_title': 'עדכון: כביש 431 ייסגר לתנועה', 'entity_data': {'title': 'עדכון: כביש 431 ייסגר לתנועה', 'status': 'published', 'slug': 'road-431-closure', 'view_count': 890}, 'deleted_by': 'u1', 'deleted_by_name': 'ניתאי לוי', 'deleted_at': '2026-08-22T09:15:00Z', 'expires_at': '2026-09-21T09:15:00Z'},
  {'id': 'tr_3', 'entity_type': 'review', 'entity_id': 'r_del_1', 'entity_title': 'ביקורת של דני פרץ על פיצה פרגו', 'entity_data': {'text': 'אוכל גרוע, שירות איטי', 'rating': 1, 'user_name': 'דני פרץ', 'business_name': 'פיצה פרגו'}, 'deleted_by': 'u1', 'deleted_by_name': 'ניתאי לוי', 'deleted_at': '2026-08-20T16:45:00Z', 'expires_at': '2026-09-19T16:45:00Z'},
  {'id': 'tr_4', 'entity_type': 'event', 'entity_id': 'ev_del_1', 'entity_title': 'סדנת ציור לילדים — בוטל', 'entity_data': {'title': 'סדנת ציור לילדים', 'date': '2026-08-18', 'location': 'מתנ"ס מורשת', 'status': 'cancelled'}, 'deleted_by': 'u1', 'deleted_by_name': 'דנה מזרחי', 'deleted_at': '2026-08-18T11:20:00Z', 'expires_at': '2026-09-17T11:20:00Z'},
  {'id': 'tr_5', 'entity_type': 'business', 'entity_id': 'b_del_2', 'entity_title': 'חנות הספרים הישנה', 'entity_data': {'name': 'חנות הספרים הישנה', 'category': 'קמעונאות', 'status': 'closed', 'address': 'מרכז עזריאלי'}, 'deleted_by': 'u1', 'deleted_by_name': 'ניתאי לוי', 'deleted_at': '2026-08-10T08:00:00Z', 'expires_at': '2026-09-09T08:00:00Z'},
  {'id': 'tr_6', 'entity_type': 'article', 'entity_id': 'a_del_2', 'entity_title': 'טיוטה: ראיון עם ראש העיר (לא פורסם)', 'entity_data': {'title': 'ראיון עם ראש העיר', 'status': 'draft', 'slug': 'mayor-interview'}, 'deleted_by': 'u1', 'deleted_by_name': 'יוסי כהן', 'deleted_at': '2026-08-05T13:30:00Z', 'expires_at': '2026-09-04T13:30:00Z'},
  {'id': 'tr_7', 'entity_type': 'review', 'entity_id': 'r_del_2', 'entity_title': 'ביקורת ספאם — סופר פארם', 'entity_data': {'text': 'Buy cheap watches at www.spam.com', 'rating': 5, 'user_name': 'SpamBot123', 'business_name': 'סופר פארם מודיעין'}, 'deleted_by': 'u1', 'deleted_by_name': 'ניתאי לוי', 'deleted_at': '2026-08-02T10:00:00Z', 'expires_at': '2026-09-01T10:00:00Z'},
  {'id': 'tr_8', 'entity_type': 'business', 'entity_id': 'b_del_3', 'entity_title': 'מספרת טוני — נסגרה', 'entity_data': {'name': 'מספרת טוני', 'category': 'יופי וטיפוח', 'status': 'closed', 'address': 'רח׳ האורן 3'}, 'deleted_by': 'u1', 'deleted_by_name': 'ניתאי לוי', 'deleted_at': '2026-07-28T15:00:00Z', 'expires_at': '2026-08-27T15:00:00Z'},
];
