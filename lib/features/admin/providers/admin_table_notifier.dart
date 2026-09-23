import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';

/// Reading and writing one table, for the admin panel.
///
/// Every section did the same four things against a list held in memory —
/// list with a search and a status filter, create, update, delete — so they
/// were nineteen copies of the same code with different invented rows in it.
/// This is that shape once, against the real table.
///
/// A section with more to it than this keeps its own notifier: businesses has
/// opening hours and categories, articles has a published date to fill in.
class AdminTableNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  /// The table this section edits.
  final String table;

  /// Columns a search runs across, as `ilike`.
  final List<String> searchColumns;

  /// Ordering for the list.
  final String orderBy;
  final bool ascending;

  /// What `select()` asks for — a join goes here, e.g.
  /// `'*, categories(name)'`.
  final String columns;

  /// Rows the form cannot write: keys the database owns.
  final Set<String> readOnlyColumns;

  /// Whether the table has a `status` column the filter chips act on.
  final bool hasStatus;

  /// Set when removing should mark the row rather than delete it — the
  /// client asked for a trash rather than anything permanent.
  final String? softDeleteStatus;

  final int limit;

  String? _search;
  String? _status;

  AdminTableNotifier({
    required this.table,
    this.searchColumns = const ['name'],
    this.orderBy = 'created_at',
    this.ascending = false,
    this.columns = '*',
    this.readOnlyColumns = const {'id', 'created_at', 'updated_at'},
    this.hasStatus = true,
    this.softDeleteStatus,
    this.limit = 500,
  }) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      var query = SupabaseConfig.client.from(table).select(columns);

      if (hasStatus && _status != null && _status!.isNotEmpty) {
        query = query.eq('status', _status!);
      }
      if (_search != null && _search!.isNotEmpty && searchColumns.isNotEmpty) {
        // A comma separates the clauses in `or`, so one inside the text would
        // be read as another clause.
        final q = _search!.replaceAll(',', ' ');
        query = query.or(searchColumns.map((c) => '$c.ilike.%$q%').join(','));
      }

      final rows = await query
          .order(orderBy, ascending: ascending, nullsFirst: false)
          .limit(limit);

      if (mounted) {
        state = AsyncValue.data(List<Map<String, dynamic>>.from(rows));
      }
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  void setSearch(String? search) {
    _search = search;
    load();
  }

  void setStatusFilter(String? status) {
    _status = status;
    load();
  }

  /// Drops anything the form carries that is not a column — joined objects
  /// arrive under their table's name and would be rejected on the way back.
  Map<String, dynamic> _writable(Map<String, dynamic> fields) => {
    for (final e in fields.entries)
      if (!readOnlyColumns.contains(e.key) && e.value is! Map) e.key: e.value,
  };

  Future<void> create(Map<String, dynamic> row) async {
    await SupabaseConfig.client.from(table).insert(_writable(row));
    await load();
  }

  Future<void> update(String id, Map<String, dynamic> fields) async {
    await SupabaseConfig.client
        .from(table)
        .update(_writable(fields))
        .eq('id', id);
    await load();
  }

  Future<void> remove(String id) async {
    if (softDeleteStatus != null) {
      await updateStatus(id, softDeleteStatus!);
      return;
    }
    await SupabaseConfig.client.from(table).delete().eq('id', id);
    await load();
  }

  Future<void> updateStatus(String id, String status) async {
    await SupabaseConfig.client
        .from(table)
        .update({'status': status})
        .eq('id', id);
    await load();
  }

  /// For the tables that mark a row active rather than carrying a status.
  Future<void> setActive(String id, bool isActive) async {
    await SupabaseConfig.client
        .from(table)
        .update({'is_active': isActive})
        .eq('id', id);
    await load();
  }
}
