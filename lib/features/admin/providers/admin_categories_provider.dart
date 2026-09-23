import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        searchColumns: const ['name', 'slug'],
        orderBy: 'sort_order',
        ascending: true,
        hasStatus: false,
      );

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
    if (scope == null || scope.isEmpty) return;

    state.whenData((rows) {
      state = AsyncValue.data(
        rows.where((r) => r['scope'] == scope).toList(),
      );
    });
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

  /// Top-level categories in one scope, for the parent picker. A category
  /// cannot be its own parent's child, so only the roots are offered.
  List<Map<String, dynamic>> getParentsForScope(String scope) {
    return (state.valueOrNull ?? const [])
        .where((c) => c['scope'] == scope && c['parent_id'] == null)
        .toList();
  }
}
