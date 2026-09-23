import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_table_notifier.dart';

/// Neighbourhoods, on the live table. A business points at one of these, and
/// the app narrows events and offers by them.
final adminNeighborhoodListProvider =
    StateNotifierProvider<
      AdminNeighborhoodListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminNeighborhoodListNotifier();
    });

class AdminNeighborhoodListNotifier extends AdminTableNotifier {
  AdminNeighborhoodListNotifier()
    : super(
        table: 'neighborhoods',
        searchColumns: const ['name', 'slug'],
        orderBy: 'sort_order',
        ascending: true,
        hasStatus: false,
      );

  String? _activeFilter;

  /// 'active', 'inactive', or null for all — the three chips on the screen.
  void setActiveFilter(String? filter) {
    _activeFilter = filter;
    load();
  }

  @override
  Future<void> load() async {
    await super.load();
    final filter = _activeFilter;
    if (filter == null || filter.isEmpty) return;

    final wantActive = filter == 'active';
    state.whenData((rows) {
      state = AsyncValue.data(
        rows
            .where((r) => (r['is_active'] as bool? ?? true) == wantActive)
            .toList(),
      );
    });
  }

  Future<void> createNeighborhood(Map<String, dynamic> n) => create(n);
  Future<void> updateNeighborhood(String id, Map<String, dynamic> f) =>
      update(id, f);

  /// Hidden rather than removed: businesses reference it.
  Future<void> deleteNeighborhood(String id) => setActive(id, false);

  Future<void> toggleActive(String id) async {
    final row = state.valueOrNull?.firstWhere(
      (n) => n['id'] == id,
      orElse: () => const {},
    );
    await setActive(id, !((row?['is_active'] as bool?) ?? true));
  }
}
