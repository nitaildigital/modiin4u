import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// Categories, on the live table.
///
/// The directory and the restaurants screen both filter on these, so a
/// category edited here changes what a resident sees.
final adminCategoryListProvider =
    StateNotifierProvider<
      AdminCategoryListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminCategoryListNotifier();
    });

class AdminCategoryListNotifier extends AdminTableNotifier {
  AdminCategoryListNotifier()
    : super(
        table: 'categories',
        // How many rows are filed under each category, counted by the
        // database through the entity_categories foreign key. The list's
        // "items" column read an `item_count` no table has, so it said 0
        // for all forty.
        columns: '*, entity_categories(count)',
        readOnlyColumns: const {
          'id',
          'created_at',
          'updated_at',
          'entity_categories',
        },
        searchColumns: const ['name', 'slug'],
        orderBy: 'sort_order',
        ascending: true,
        hasStatus: false,
      );

  /// What the count column shows for one row.
  static int itemCount(Map<String, dynamic> row) {
    final agg = row['entity_categories'];
    if (agg is List && agg.isNotEmpty && agg.first is Map) {
      return ((agg.first as Map)['count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  String? _scope;

  /// Business, article or event — the three the app asks for separately.
  void setScopeFilter(String? scope) {
    _scope = scope;
    load();
  }

  @override
  Future<void> load() async {
    await super.load();
    final scope = _scope;

    state.whenData((rows) {
      final kept = scope == null || scope.isEmpty
          ? rows
          : rows.where((r) => r['scope'] == scope).toList();
      state = AsyncValue.data(_asTree(kept));
    });
  }

  /// Each parent followed by its children. The list indents a child, and
  /// sorted by `sort_order` alone the indented rows sat under whichever
  /// category happened to come before them rather than under their own.
  static List<Map<String, dynamic>> _asTree(List<Map<String, dynamic>> rows) {
    final ids = rows.map((r) => r['id']).toSet();
    final roots = rows
        .where((r) => r['parent_id'] == null || !ids.contains(r['parent_id']))
        .toList();
    final out = <Map<String, dynamic>>[];
    for (final root in roots) {
      out.add(root);
      out.addAll(rows.where((r) => r['parent_id'] == root['id']));
    }
    return out;
  }

  Future<void> createCategory(Map<String, dynamic> c) => create(c);
  Future<void> updateCategory(String id, Map<String, dynamic> f) =>
      update(id, f);

  /// Hidden rather than removed: a category with businesses in it would take
  /// their links with it.
  Future<void> deleteCategory(String id) => setActive(id, false);

  /// Flips whichever way the row currently sits.
  Future<void> toggleActive(String id) async {
    final row = state.valueOrNull?.firstWhere(
      (c) => c['id'] == id,
      orElse: () => const {},
    );
    await setActive(id, !((row?['is_active'] as bool?) ?? true));
  }
}

/// Top-level categories in one scope, for the parent picker. Only roots are
/// offered: the site reads two levels, a category and the trades under it.
///
/// Read from the table rather than from the list on screen, which a search
/// or a scope chip may have narrowed — the picker then lacked the parent a
/// category already had.
final categoryParentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      scope,
    ) async {
      final rows = await SupabaseConfig.client
          .from('categories')
          .select('id, name, parent_id, sort_order')
          .eq('scope', scope)
          .isFilter('parent_id', null)
          .order('sort_order', ascending: true);
      return List<Map<String, dynamic>>.from(rows);
    });

/// Whether any category sits under [id]. Asked of the table, not the list on
/// screen: a search for "שירותים" shows Services without its trades, and the
/// editor then offered to file Services under another category.
final categoryHasChildrenProvider = FutureProvider.family<bool, String>((
  ref,
  id,
) async {
  final rows = await SupabaseConfig.client
      .from('categories')
      .select('id')
      .eq('parent_id', id)
      .limit(1);
  return List<dynamic>.from(rows).isNotEmpty;
});
