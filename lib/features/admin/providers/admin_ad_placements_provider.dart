import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_table_notifier.dart';

/// The slots a banner can occupy, on the live table.
final adminAdPlacementListProvider =
    StateNotifierProvider<
      AdminAdPlacementListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminAdPlacementListNotifier();
    });

class AdminAdPlacementListNotifier extends AdminTableNotifier {
  AdminAdPlacementListNotifier()
    : super(
        table: 'ad_placements',
        searchColumns: const ['code', 'label'],
        orderBy: 'sort_order',
        ascending: true,
        hasStatus: false,
      );

  Future<void> createPlacement(Map<String, dynamic> p) => create(p);
  Future<void> updatePlacement(String id, Map<String, dynamic> f) =>
      update(id, f);

  /// Hidden rather than removed: campaigns point at it.
  Future<void> deletePlacement(String id) => setActive(id, false);

  Future<void> toggleActive(String id) async {
    final row = state.valueOrNull?.firstWhere(
      (p) => p['id'] == id,
      orElse: () => const {},
    );
    await setActive(id, !((row?['is_active'] as bool?) ?? true));
  }
}
