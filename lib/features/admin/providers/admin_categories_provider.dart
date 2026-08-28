import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminCategoryListProvider = StateNotifierProvider<
    AdminCategoryListNotifier,
    AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminCategoryListNotifier();
});

class AdminCategoryListNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _all = [];
  String? _search;
  String? _scopeFilter;

  AdminCategoryListNotifier()
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    _all = List<Map<String, dynamic>>.from(_mockCategories);
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_all);
    if (_search != null && _search!.isNotEmpty) {
      final q = _search!.toLowerCase();
      filtered = filtered
          .where((c) =>
              (c['name'] as String).toLowerCase().contains(q) ||
              (c['slug'] as String).toLowerCase().contains(q))
          .toList();
    }
    if (_scopeFilter != null && _scopeFilter!.isNotEmpty) {
      filtered =
          filtered.where((c) => c['scope'] == _scopeFilter).toList();
    }
    // Sort: parents first by sort_order, then children under their parent
    filtered.sort((a, b) {
      final aParent = a['parent_id'] as String?;
      final bParent = b['parent_id'] as String?;
      if (aParent == null && bParent == null) {
        return (a['sort_order'] as int).compareTo(b['sort_order'] as int);
      }
      if (aParent == null) return -1;
      if (bParent == null) return 1;
      if (aParent == bParent) {
        return (a['sort_order'] as int).compareTo(b['sort_order'] as int);
      }
      return 0;
    });
    state = AsyncValue.data(filtered);
  }

  void setSearch(String? search) {
    _search = search;
    _applyFilters();
  }

  void setScopeFilter(String? scope) {
    _scopeFilter = scope;
    _applyFilters();
  }

  void toggleActive(String id) {
    _all = [
      for (final c in _all)
        if (c['id'] == id)
          {...c, 'is_active': !(c['is_active'] as bool? ?? true)}
        else
          c
    ];
    _applyFilters();
  }

  Future<void> createCategory(Map<String, dynamic> data) async {
    _all.add({
      'id': 'cat_${DateTime.now().millisecondsSinceEpoch}',
      'created_at': DateTime.now().toIso8601String(),
      'item_count': 0,
      ...data,
    });
    _applyFilters();
  }

  Future<void> updateCategory(
      String id, Map<String, dynamic> fields) async {
    _all = [
      for (final c in _all)
        if (c['id'] == id) {...c, ...fields} else c
    ];
    _applyFilters();
  }

  Future<void> deleteCategory(String id) async {
    _all.removeWhere((c) => c['id'] == id);
    // Also remove children
    _all.removeWhere((c) => c['parent_id'] == id);
    _applyFilters();
  }

  List<Map<String, dynamic>> getParentsForScope(String scope) {
    return _all
        .where(
            (c) => c['scope'] == scope && c['parent_id'] == null)
        .toList();
  }
}

final _mockCategories = <Map<String, dynamic>>[
  // ─── Business Categories ───
  {'id': 'bc1', 'name': 'מסעדות', 'slug': 'restaurants', 'scope': 'business', 'parent_id': null, 'icon': '🍽️', 'description': 'מסעדות, בתי קפה ואוכל', 'sort_order': 1, 'is_active': true, 'item_count': 18, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'bc1a', 'name': 'פיצה', 'slug': 'pizza', 'scope': 'business', 'parent_id': 'bc1', 'icon': '🍕', 'description': '', 'sort_order': 1, 'is_active': true, 'item_count': 5, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'bc1b', 'name': 'סושי', 'slug': 'sushi', 'scope': 'business', 'parent_id': 'bc1', 'icon': '🍣', 'description': '', 'sort_order': 2, 'is_active': true, 'item_count': 3, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'bc1c', 'name': 'בשרים', 'slug': 'meat', 'scope': 'business', 'parent_id': 'bc1', 'icon': '🥩', 'description': '', 'sort_order': 3, 'is_active': true, 'item_count': 4, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'bc1d', 'name': 'קפה', 'slug': 'cafe', 'scope': 'business', 'parent_id': 'bc1', 'icon': '☕', 'description': '', 'sort_order': 4, 'is_active': true, 'item_count': 6, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'bc2', 'name': 'בריאות', 'slug': 'health', 'scope': 'business', 'parent_id': null, 'icon': '🏥', 'description': 'רפואה, בריאות ופארם', 'sort_order': 2, 'is_active': true, 'item_count': 12, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'bc3', 'name': 'ספורט', 'slug': 'sports', 'scope': 'business', 'parent_id': null, 'icon': '⚽', 'description': 'חדרי כושר, סטודיו, ספורט', 'sort_order': 3, 'is_active': true, 'item_count': 8, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'bc4', 'name': 'חינוך', 'slug': 'education', 'scope': 'business', 'parent_id': null, 'icon': '📚', 'description': 'חינוך, שיעורים פרטיים, קורסים', 'sort_order': 4, 'is_active': true, 'item_count': 6, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'bc5', 'name': 'שירותים', 'slug': 'services', 'scope': 'business', 'parent_id': null, 'icon': '🔧', 'description': 'שירותים מקצועיים', 'sort_order': 5, 'is_active': true, 'item_count': 15, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'bc6', 'name': 'קמעונאות', 'slug': 'retail', 'scope': 'business', 'parent_id': null, 'icon': '🛍️', 'description': 'חנויות ומסחר', 'sort_order': 6, 'is_active': true, 'item_count': 22, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'bc7', 'name': 'יופי וטיפוח', 'slug': 'beauty', 'scope': 'business', 'parent_id': null, 'icon': '💅', 'description': 'מספרות, קוסמטיקה, ספא', 'sort_order': 7, 'is_active': true, 'item_count': 9, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'bc8', 'name': 'רכב', 'slug': 'auto', 'scope': 'business', 'parent_id': null, 'icon': '🚗', 'description': 'מוסכים, רכב, הסעות', 'sort_order': 8, 'is_active': true, 'item_count': 7, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'bc9', 'name': 'בית וגינה', 'slug': 'home-garden', 'scope': 'business', 'parent_id': null, 'icon': '🏠', 'description': 'שיפוצים, ריהוט, גינון', 'sort_order': 9, 'is_active': true, 'item_count': 11, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'bc10', 'name': 'טכנולוגיה', 'slug': 'tech', 'scope': 'business', 'parent_id': null, 'icon': '💻', 'description': 'מחשבים, סלולר, IT', 'sort_order': 10, 'is_active': true, 'item_count': 5, 'created_at': '2024-01-01T00:00:00Z'},

  // ─── Article Categories ───
  {'id': 'ac1', 'name': 'עירייה', 'slug': 'municipal', 'scope': 'article', 'parent_id': null, 'icon': '🏛️', 'description': 'חדשות עירייה ומועצה', 'sort_order': 1, 'is_active': true, 'item_count': 24, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'ac2', 'name': 'ספורט', 'slug': 'sports-news', 'scope': 'article', 'parent_id': null, 'icon': '⚽', 'description': 'ספורט מקומי', 'sort_order': 2, 'is_active': true, 'item_count': 18, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'ac3', 'name': 'קהילה', 'slug': 'community', 'scope': 'article', 'parent_id': null, 'icon': '🤝', 'description': 'אירועים קהילתיים', 'sort_order': 3, 'is_active': true, 'item_count': 31, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'ac4', 'name': 'חינוך', 'slug': 'education-news', 'scope': 'article', 'parent_id': null, 'icon': '🎓', 'description': 'חדשות חינוך', 'sort_order': 4, 'is_active': true, 'item_count': 12, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'ac5', 'name': 'בטיחות', 'slug': 'safety', 'scope': 'article', 'parent_id': null, 'icon': '🛡️', 'description': 'בטיחות וחירום', 'sort_order': 5, 'is_active': true, 'item_count': 8, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'ac6', 'name': 'עסקים', 'slug': 'business-news', 'scope': 'article', 'parent_id': null, 'icon': '💼', 'description': 'חדשות עסקיות', 'sort_order': 6, 'is_active': true, 'item_count': 14, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'ac7', 'name': 'תרבות', 'slug': 'culture', 'scope': 'article', 'parent_id': null, 'icon': '🎭', 'description': 'תרבות ואמנות', 'sort_order': 7, 'is_active': true, 'item_count': 9, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'ac8', 'name': 'דעה', 'slug': 'opinion', 'scope': 'article', 'parent_id': null, 'icon': '💭', 'description': 'טורים ודעות', 'sort_order': 8, 'is_active': true, 'item_count': 6, 'created_at': '2024-01-01T00:00:00Z'},

  // ─── Event Categories ───
  {'id': 'ec1', 'name': 'מוזיקה', 'slug': 'music', 'scope': 'event', 'parent_id': null, 'icon': '🎵', 'description': 'הופעות ופסטיבלים', 'sort_order': 1, 'is_active': true, 'item_count': 15, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'ec2', 'name': 'ילדים ומשפחה', 'slug': 'kids-family', 'scope': 'event', 'parent_id': null, 'icon': '👨‍👩‍👧‍👦', 'description': 'פעילויות משפחתיות', 'sort_order': 2, 'is_active': true, 'item_count': 22, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'ec3', 'name': 'ספורט', 'slug': 'sports-events', 'scope': 'event', 'parent_id': null, 'icon': '🏃', 'description': 'ריצות, תחרויות, אירועי ספורט', 'sort_order': 3, 'is_active': true, 'item_count': 10, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'ec4', 'name': 'עירייה וקהילה', 'slug': 'municipal-events', 'scope': 'event', 'parent_id': null, 'icon': '🏛️', 'description': 'ישיבות, כנסים, אירועי עירייה', 'sort_order': 4, 'is_active': true, 'item_count': 8, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'ec5', 'name': 'תרבות', 'slug': 'culture-events', 'scope': 'event', 'parent_id': null, 'icon': '🎭', 'description': 'תיאטרון, סרטים, תערוכות', 'sort_order': 5, 'is_active': true, 'item_count': 7, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'ec6', 'name': 'חינוך', 'slug': 'education-events', 'scope': 'event', 'parent_id': null, 'icon': '📖', 'description': 'סדנאות, הרצאות, קורסים', 'sort_order': 6, 'is_active': true, 'item_count': 5, 'created_at': '2024-01-01T00:00:00Z'},
  {'id': 'ec7', 'name': 'קולינריה', 'slug': 'culinary', 'scope': 'event', 'parent_id': null, 'icon': '🍳', 'description': 'פסטיבלי אוכל, סדנאות בישול', 'sort_order': 7, 'is_active': true, 'item_count': 4, 'created_at': '2024-01-01T00:00:00Z'},
];
