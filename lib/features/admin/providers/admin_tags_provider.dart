import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminTagListProvider = StateNotifierProvider<AdminTagListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminTagListNotifier();
});

class AdminTagListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _allData = [];
  String? _search;
  String _sortBy = 'name';

  AdminTagListNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    _allData = List<Map<String, dynamic>>.from(_mockTags);
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_allData);
    if (_search != null && _search!.isNotEmpty) {
      final q = _search!.toLowerCase();
      filtered = filtered.where((t) =>
        (t['name'] as String).toLowerCase().contains(q) ||
        (t['slug'] as String).toLowerCase().contains(q)).toList();
    }
    if (_sortBy == 'usage') {
      filtered.sort((a, b) => (b['usage_count'] as int).compareTo(a['usage_count'] as int));
    } else {
      filtered.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    }
    state = AsyncValue.data(filtered);
  }

  void setSearch(String? search) { _search = search; _applyFilters(); }
  void setSortBy(String sortBy) { _sortBy = sortBy; _applyFilters(); }

  Future<void> createTag(Map<String, dynamic> tag) async {
    tag['id'] = 'tag_${DateTime.now().millisecondsSinceEpoch}';
    tag['usage_count'] = 0;
    tag['created_at'] = DateTime.now().toIso8601String();
    _allData.add(tag);
    _applyFilters();
  }

  Future<void> updateTag(String id, Map<String, dynamic> fields) async {
    final idx = _allData.indexWhere((t) => t['id'] == id);
    if (idx >= 0) { _allData[idx] = {..._allData[idx], ...fields}; _applyFilters(); }
  }

  Future<void> deleteTag(String id) async {
    _allData.removeWhere((t) => t['id'] == id);
    _applyFilters();
  }

  Future<void> mergeTags(String sourceId, String targetId) async {
    final source = _allData.firstWhere((t) => t['id'] == sourceId, orElse: () => {});
    final targetIdx = _allData.indexWhere((t) => t['id'] == targetId);
    if (source.isNotEmpty && targetIdx >= 0) {
      _allData[targetIdx]['usage_count'] = (_allData[targetIdx]['usage_count'] as int) + (source['usage_count'] as int);
      _allData.removeWhere((t) => t['id'] == sourceId);
      _applyFilters();
    }
  }
}

final _mockTags = <Map<String, dynamic>>[
  {'id': 'tag_1', 'name': 'פיצה', 'slug': 'pizza', 'usage_count': 12, 'created_at': '2024-03-15T10:00:00Z'},
  {'id': 'tag_2', 'name': 'איטלקי', 'slug': 'italian', 'usage_count': 8, 'created_at': '2024-03-15T10:00:00Z'},
  {'id': 'tag_3', 'name': 'כשר', 'slug': 'kosher', 'usage_count': 34, 'created_at': '2024-01-01T10:00:00Z'},
  {'id': 'tag_4', 'name': 'משלוחים', 'slug': 'delivery', 'usage_count': 28, 'created_at': '2024-01-01T10:00:00Z'},
  {'id': 'tag_5', 'name': 'כושר', 'slug': 'fitness', 'usage_count': 15, 'created_at': '2024-04-01T10:00:00Z'},
  {'id': 'tag_6', 'name': 'יוגה', 'slug': 'yoga', 'usage_count': 9, 'created_at': '2024-04-01T10:00:00Z'},
  {'id': 'tag_7', 'name': 'פארקים', 'slug': 'parks', 'usage_count': 18, 'created_at': '2024-02-01T10:00:00Z'},
  {'id': 'tag_8', 'name': 'עירייה', 'slug': 'municipality', 'usage_count': 22, 'created_at': '2024-01-01T10:00:00Z'},
  {'id': 'tag_9', 'name': 'ספורט', 'slug': 'sports', 'usage_count': 26, 'created_at': '2024-01-15T10:00:00Z'},
  {'id': 'tag_10', 'name': 'כדורגל', 'slug': 'soccer', 'usage_count': 11, 'created_at': '2024-05-01T10:00:00Z'},
  {'id': 'tag_11', 'name': 'ילדים', 'slug': 'kids', 'usage_count': 31, 'created_at': '2024-01-01T10:00:00Z'},
  {'id': 'tag_12', 'name': 'חינם', 'slug': 'free', 'usage_count': 19, 'created_at': '2024-02-01T10:00:00Z'},
  {'id': 'tag_13', 'name': 'מוזיקה', 'slug': 'music', 'usage_count': 14, 'created_at': '2024-03-01T10:00:00Z'},
  {'id': 'tag_14', 'name': 'תרבות', 'slug': 'culture', 'usage_count': 16, 'created_at': '2024-02-15T10:00:00Z'},
  {'id': 'tag_15', 'name': 'שוק', 'slug': 'market', 'usage_count': 7, 'created_at': '2024-06-01T10:00:00Z'},
  {'id': 'tag_16', 'name': 'בישול', 'slug': 'cooking', 'usage_count': 5, 'created_at': '2024-06-01T10:00:00Z'},
  {'id': 'tag_17', 'name': 'חניה', 'slug': 'parking', 'usage_count': 20, 'created_at': '2024-01-01T10:00:00Z'},
  {'id': 'tag_18', 'name': 'נגישות', 'slug': 'accessibility', 'usage_count': 17, 'created_at': '2024-01-01T10:00:00Z'},
  {'id': 'tag_19', 'name': 'WiFi', 'slug': 'wifi', 'usage_count': 13, 'created_at': '2024-02-01T10:00:00Z'},
  {'id': 'tag_20', 'name': 'שבת', 'slug': 'shabbat', 'usage_count': 24, 'created_at': '2024-01-01T10:00:00Z'},
  {'id': 'tag_21', 'name': 'טבעוני', 'slug': 'vegan', 'usage_count': 10, 'created_at': '2024-04-15T10:00:00Z'},
  {'id': 'tag_22', 'name': 'אורגני', 'slug': 'organic', 'usage_count': 6, 'created_at': '2024-05-01T10:00:00Z'},
  {'id': 'tag_23', 'name': 'משפחה', 'slug': 'family', 'usage_count': 29, 'created_at': '2024-01-01T10:00:00Z'},
  {'id': 'tag_24', 'name': 'בריאות', 'slug': 'health', 'usage_count': 21, 'created_at': '2024-01-15T10:00:00Z'},
  {'id': 'tag_25', 'name': 'יופי', 'slug': 'beauty', 'usage_count': 8, 'created_at': '2024-03-01T10:00:00Z'},
  {'id': 'tag_26', 'name': 'טכנולוגיה', 'slug': 'tech', 'usage_count': 4, 'created_at': '2024-07-01T10:00:00Z'},
  {'id': 'tag_27', 'name': 'רכב', 'slug': 'automotive', 'usage_count': 6, 'created_at': '2024-05-15T10:00:00Z'},
  {'id': 'tag_28', 'name': 'בית', 'slug': 'home', 'usage_count': 11, 'created_at': '2024-03-15T10:00:00Z'},
  {'id': 'tag_29', 'name': 'גינה', 'slug': 'garden', 'usage_count': 3, 'created_at': '2024-07-01T10:00:00Z'},
  {'id': 'tag_30', 'name': 'חינוך', 'slug': 'education', 'usage_count': 18, 'created_at': '2024-01-01T10:00:00Z'},
  {'id': 'tag_31', 'name': 'קפה', 'slug': 'coffee', 'usage_count': 15, 'created_at': '2024-02-01T10:00:00Z'},
  {'id': 'tag_32', 'name': 'סושי', 'slug': 'sushi', 'usage_count': 7, 'created_at': '2024-04-01T10:00:00Z'},
];
