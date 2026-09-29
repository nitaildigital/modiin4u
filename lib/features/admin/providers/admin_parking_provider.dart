import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_table_notifier.dart';

/// Parking lots (migration 00030) — the pins on the app map's Parkings layer.
final adminParkingListProvider =
    StateNotifierProvider<
      AdminParkingListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) => AdminParkingListNotifier());

class AdminParkingListNotifier extends AdminTableNotifier {
  AdminParkingListNotifier()
    : super(
        table: 'parking_lots',
        searchColumns: const ['name', 'name_en', 'address'],
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
    final rows = state.valueOrNull;
    if (rows == null) return;
    state = AsyncValue.data(
      rows.where((r) => (r['is_active'] as bool? ?? true) == wantActive).toList(),
    );
  }

  /// Hidden, never deleted: the client asked for removal he can undo.
  Future<void> toggleActive(String id) async {
    final row = state.valueOrNull?.firstWhere(
      (r) => r['id'] == id,
      orElse: () => const {},
    );
    await setActive(id, !((row?['is_active'] as bool?) ?? true));
  }
}
