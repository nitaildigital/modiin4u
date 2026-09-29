import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
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
        // Businesses and residents filed under each one, counted by the
        // database through their foreign keys. The list's two count columns
        // read `business_count` and `resident_count`, which no table has, so
        // both said 0 everywhere.
        columns: '*, businesses(count), profiles(count)',
        readOnlyColumns: const {
          'id',
          'created_at',
          'updated_at',
          'businesses',
          'profiles',
        },
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

  /// A count the select above embedded, e.g. `count(row, 'businesses')`.
  static int count(Map<String, dynamic> row, String table) {
    final agg = row[table];
    if (agg is List && agg.isNotEmpty && agg.first is Map) {
      return ((agg.first as Map)['count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  /// Inserts the row and returns its id, which the gallery needs: its photos
  /// point at the neighbourhood by id.
  Future<String> createNeighborhood(Map<String, dynamic> n) async {
    final row = await SupabaseConfig.client
        .from('neighborhoods')
        .insert({
          for (final e in n.entries)
            if (!readOnlyColumns.contains(e.key)) e.key: e.value,
        })
        .select('id')
        .single();
    await load();
    return row['id'] as String;
  }

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
