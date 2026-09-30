import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_table_notifier.dart';

/// Municipal places (migration 00040) — what the Municipal page's service
/// tiles list: institutions and synagogues, clinics, schools and
/// kindergartens, train stations and bus stops, emergency numbers.
final adminMunicipalPlacesProvider =
    StateNotifierProvider<
      AdminMunicipalPlacesNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) => AdminMunicipalPlacesNotifier());

class AdminMunicipalPlacesNotifier extends AdminTableNotifier {
  AdminMunicipalPlacesNotifier()
    : super(
        table: 'municipal_places',
        searchColumns: const ['name', 'name_en', 'address', 'phone'],
        orderBy: 'sort_order',
        ascending: true,
        hasStatus: false,
      );

  String? _category;
  String? _activeFilter;

  /// Narrows the list to one category, or all of them with null.
  void setCategory(String? category) {
    _category = category;
    load();
  }

  /// 'active', 'inactive', or null for all.
  void setActiveFilter(String? filter) {
    _activeFilter = filter;
    load();
  }

  @override
  Future<void> load() async {
    await super.load();
    final rows = state.valueOrNull;
    if (rows == null) return;
    final category = _category;
    final active = _activeFilter;
    if ((category == null || category.isEmpty) &&
        (active == null || active.isEmpty)) {
      return;
    }
    state = AsyncValue.data(
      rows.where((r) {
        if (category != null && category.isNotEmpty &&
            r['category'] != category) {
          return false;
        }
        if (active != null && active.isNotEmpty &&
            (r['is_active'] as bool? ?? true) != (active == 'active')) {
          return false;
        }
        return true;
      }).toList(),
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
