import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminAdPlacementListProvider = StateNotifierProvider<AdminAdPlacementListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminAdPlacementListNotifier();
});

class AdminAdPlacementListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _allData = [];

  AdminAdPlacementListNotifier() : super(const AsyncValue.loading()) { load(); }

  Future<void> load() async {
    _allData = List<Map<String, dynamic>>.from(_mockPlacements);
    _allData.sort((a, b) => (a['sort_order'] as int).compareTo(b['sort_order'] as int));
    state = AsyncValue.data(_allData);
  }

  Future<void> createPlacement(Map<String, dynamic> p) async {
    p['id'] = 'pl_${DateTime.now().millisecondsSinceEpoch}';
    p['active_campaigns_count'] = 0;
    p['created_at'] = DateTime.now().toIso8601String();
    _allData.add(p);
    state = AsyncValue.data(List.from(_allData));
  }

  Future<void> updatePlacement(String id, Map<String, dynamic> fields) async {
    final idx = _allData.indexWhere((p) => p['id'] == id);
    if (idx >= 0) { _allData[idx] = {..._allData[idx], ...fields}; state = AsyncValue.data(List.from(_allData)); }
  }

  Future<void> deletePlacement(String id) async {
    _allData.removeWhere((p) => p['id'] == id);
    state = AsyncValue.data(List.from(_allData));
  }

  Future<void> toggleActive(String id) async {
    final idx = _allData.indexWhere((p) => p['id'] == id);
    if (idx >= 0) {
      _allData[idx]['is_active'] = !(_allData[idx]['is_active'] as bool);
      state = AsyncValue.data(List.from(_allData));
    }
  }
}

final _mockPlacements = <Map<String, dynamic>>[
  {'id': 'pl_1', 'code': 'HOME_TOP', 'label': 'ראש עמוד הבית', 'description': 'באנר ראשי מעל הפיד', 'max_banners': 3, 'allowed_sizes': '728x90, 320x100', 'is_active': true, 'sort_order': 1, 'active_campaigns_count': 2, 'created_at': '2024-01-01T10:00:00Z'},
  {'id': 'pl_2', 'code': 'HOME_MIDDLE', 'label': 'אמצע עמוד הבית', 'description': 'באנר בין בלוקי התוכן', 'max_banners': 2, 'allowed_sizes': '728x90, 320x100', 'is_active': true, 'sort_order': 2, 'active_campaigns_count': 1, 'created_at': '2024-01-01T10:00:00Z'},
  {'id': 'pl_3', 'code': 'ARTICLE_INLINE', 'label': 'בתוך כתבה', 'description': 'באנר מוטמע באמצע הכתבה', 'max_banners': 1, 'allowed_sizes': '728x90, 300x250', 'is_active': true, 'sort_order': 3, 'active_campaigns_count': 1, 'created_at': '2024-01-01T10:00:00Z'},
  {'id': 'pl_4', 'code': 'ARTICLE_BOTTOM', 'label': 'תחתית כתבה', 'description': 'באנר בסוף הכתבה', 'max_banners': 2, 'allowed_sizes': '728x90, 300x250', 'is_active': true, 'sort_order': 4, 'active_campaigns_count': 0, 'created_at': '2024-01-01T10:00:00Z'},
  {'id': 'pl_5', 'code': 'BUSINESS_SIDEBAR', 'label': 'סייד-בר עסק', 'description': 'באנר בדף עסק — צד ימין', 'max_banners': 1, 'allowed_sizes': '300x250, 160x600', 'is_active': true, 'sort_order': 5, 'active_campaigns_count': 1, 'created_at': '2024-02-01T10:00:00Z'},
  {'id': 'pl_6', 'code': 'MAP_OVERLAY', 'label': 'מפה — overlay', 'description': 'באנר צף מעל המפה', 'max_banners': 1, 'allowed_sizes': '320x50', 'is_active': false, 'sort_order': 6, 'active_campaigns_count': 0, 'created_at': '2024-03-01T10:00:00Z'},
  {'id': 'pl_7', 'code': 'SEARCH_RESULTS', 'label': 'תוצאות חיפוש', 'description': 'תוצאה ממומנת בחיפוש', 'max_banners': 2, 'allowed_sizes': '728x90', 'is_active': true, 'sort_order': 7, 'active_campaigns_count': 1, 'created_at': '2024-04-01T10:00:00Z'},
  {'id': 'pl_8', 'code': 'DEALS_TOP', 'label': 'ראש עמוד מבצעים', 'description': 'באנר מעל רשימת המבצעים', 'max_banners': 1, 'allowed_sizes': '728x90, 320x100', 'is_active': true, 'sort_order': 8, 'active_campaigns_count': 0, 'created_at': '2024-05-01T10:00:00Z'},
];
