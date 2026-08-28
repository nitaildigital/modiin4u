import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminHomeBuilderProvider = StateNotifierProvider<AdminHomeBuilderNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminHomeBuilderNotifier();
});

class AdminHomeBuilderNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _allData = [];

  AdminHomeBuilderNotifier() : super(const AsyncValue.loading()) { load(); }

  Future<void> load() async {
    _allData = List<Map<String, dynamic>>.from(_mockBlocks);
    _allData.sort((a, b) => (a['sort_order'] as int).compareTo(b['sort_order'] as int));
    state = AsyncValue.data(List.from(_allData));
  }

  Future<void> createBlock(Map<String, dynamic> block) async {
    block['id'] = 'hb_${DateTime.now().millisecondsSinceEpoch}';
    block['version'] = 1;
    block['published'] = false;
    block['created_at'] = DateTime.now().toIso8601String();
    _allData.add(block);
    _reorder();
  }

  Future<void> updateBlock(String id, Map<String, dynamic> fields) async {
    final idx = _allData.indexWhere((b) => b['id'] == id);
    if (idx >= 0) { _allData[idx] = {..._allData[idx], ...fields, 'version': (_allData[idx]['version'] as int) + 1, 'published': false}; _reorder(); }
  }

  Future<void> deleteBlock(String id) async {
    _allData.removeWhere((b) => b['id'] == id);
    _reorder();
  }

  Future<void> toggleActive(String id) async {
    final idx = _allData.indexWhere((b) => b['id'] == id);
    if (idx >= 0) {
      _allData[idx]['is_active'] = !(_allData[idx]['is_active'] as bool);
      _allData[idx]['published'] = false;
      state = AsyncValue.data(List.from(_allData));
    }
  }

  Future<void> reorder(String id, int newOrder) async {
    final idx = _allData.indexWhere((b) => b['id'] == id);
    if (idx >= 0) { _allData[idx]['sort_order'] = newOrder; _reorder(); }
  }

  Future<void> publishAll() async {
    for (final b in _allData) {
      b['published'] = true;
      b['published_at'] = DateTime.now().toIso8601String();
    }
    state = AsyncValue.data(List.from(_allData));
  }

  void _reorder() {
    _allData.sort((a, b) => (a['sort_order'] as int).compareTo(b['sort_order'] as int));
    state = AsyncValue.data(List.from(_allData));
  }
}

final _mockBlocks = <Map<String, dynamic>>[
  {'id': 'hb_1', 'block_type': 'hero_banner', 'title': 'באנר ראשי', 'config': {'items_count': 3, 'auto_scroll': true, 'interval_sec': 5}, 'sort_order': 1, 'is_active': true, 'neighborhoods': null, 'audience': 'all', 'start_at': null, 'end_at': null, 'version': 3, 'published': true, 'published_at': '2026-08-20T10:00:00Z', 'created_at': '2024-01-01T10:00:00Z'},
  {'id': 'hb_2', 'block_type': 'categories_grid', 'title': 'קטגוריות', 'config': {'columns': 4, 'show_icon': true}, 'sort_order': 2, 'is_active': true, 'neighborhoods': null, 'audience': 'all', 'start_at': null, 'end_at': null, 'version': 2, 'published': true, 'published_at': '2026-08-15T10:00:00Z', 'created_at': '2024-01-01T10:00:00Z'},
  {'id': 'hb_3', 'block_type': 'featured_businesses', 'title': 'עסקים מומלצים', 'config': {'items_count': 6, 'source': 'featured'}, 'sort_order': 3, 'is_active': true, 'neighborhoods': null, 'audience': 'all', 'start_at': null, 'end_at': null, 'version': 4, 'published': true, 'published_at': '2026-08-18T10:00:00Z', 'created_at': '2024-01-01T10:00:00Z'},
  {'id': 'hb_4', 'block_type': 'upcoming_events', 'title': 'אירועים קרובים', 'config': {'items_count': 4, 'source': 'upcoming'}, 'sort_order': 4, 'is_active': true, 'neighborhoods': null, 'audience': 'all', 'start_at': null, 'end_at': null, 'version': 2, 'published': true, 'published_at': '2026-08-15T10:00:00Z', 'created_at': '2024-02-01T10:00:00Z'},
  {'id': 'hb_5', 'block_type': 'deals', 'title': 'מבצעים חמים 🔥', 'config': {'items_count': 5, 'source': 'featured'}, 'sort_order': 5, 'is_active': true, 'neighborhoods': null, 'audience': 'all', 'start_at': null, 'end_at': null, 'version': 3, 'published': true, 'published_at': '2026-08-20T10:00:00Z', 'created_at': '2024-03-01T10:00:00Z'},
  {'id': 'hb_6', 'block_type': 'latest_articles', 'title': 'חדשות אחרונות', 'config': {'items_count': 5, 'source': 'latest'}, 'sort_order': 6, 'is_active': true, 'neighborhoods': null, 'audience': 'all', 'start_at': null, 'end_at': null, 'version': 2, 'published': true, 'published_at': '2026-08-15T10:00:00Z', 'created_at': '2024-01-01T10:00:00Z'},
  {'id': 'hb_7', 'block_type': 'map_preview', 'title': 'מפת העיר', 'config': {'default_zoom': 13, 'show_markers': true}, 'sort_order': 7, 'is_active': true, 'neighborhoods': null, 'audience': 'all', 'start_at': null, 'end_at': null, 'version': 1, 'published': true, 'published_at': '2026-08-10T10:00:00Z', 'created_at': '2024-04-01T10:00:00Z'},
  {'id': 'hb_8', 'block_type': 'stats_bar', 'title': 'המספרים שלנו', 'config': {'show_users': true, 'show_businesses': true, 'show_reviews': true}, 'sort_order': 8, 'is_active': false, 'neighborhoods': null, 'audience': 'all', 'start_at': null, 'end_at': null, 'version': 1, 'published': false, 'published_at': null, 'created_at': '2026-08-01T10:00:00Z'},
];
