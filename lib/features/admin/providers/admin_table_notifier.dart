import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show CountOption;

import '../../../core/supabase/supabase_config.dart';
import '../admin_language.dart';

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

  /// How many rows one page holds. `loadMore` raises the window rather than
  /// paging, because the tables sort and filter in place.
  final int limit;

  /// Rows the section never lists, as column → value: kept out in the query
  /// itself, so the counts leave them out too.
  final Map<String, Object> excluded;

  /// How many rows the table holds in total, which is not the same as how
  /// many were fetched. `articles` has 669 rows against a 500 limit, so the
  /// panel said "500 articles" and the oldest 169 could not be reached or
  /// edited — and nothing said so.
  int totalCount = 0;

  /// True while rows exist beyond the ones loaded.
  bool get hasMore => totalCount > _window;

  int _window = 0;

  /// Set while widening the window, so the rows already on screen stay put
  /// instead of being replaced by a spinner.
  bool _loadingMore = false;

  String? _search;
  String? _status;

  /// Exact-match filters a section adds beyond status — the kind of thing a
  /// comment was left on, say. Applied in the query, so they narrow the rows
  /// the database returns rather than a page already fetched.
  final Map<String, Object> _filters = {};

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
    this.excluded = const {},
  }) : super(const AsyncValue.loading()) {
    _window = limit;
    load();
  }

  /// Counts loads, so that one overtaken by a newer load — a search typed
  /// on while the previous one was still in flight — drops its answer
  /// instead of painting the older result over the newer. Typing "test" in
  /// Tags once showed a real tag because a broader search answered last.
  int _loadTicket = 0;

  Future<void> load() async {
    final ticket = ++_loadTicket;
    if (!_loadingMore) state = const AsyncValue.loading();
    try {
      var query = SupabaseConfig.client.from(table).select(columns);

      if (hasStatus && _status != null && _status!.isNotEmpty) {
        query = query.eq('status', _status!);
      }
      for (final f in _filters.entries) {
        query = query.eq(f.key, f.value);
      }
      for (final f in excluded.entries) {
        query = query.neq(f.key, f.value);
      }
      if (_search != null && _search!.trim().isNotEmpty) {
        // Commas and brackets are the grammar of `or`, so inside the text
        // they would be read as more clauses.
        final q = _search!.replaceAll(RegExp(r'[,()]'), ' ').trim();
        final clauses = searchClauses(q);
        if (clauses.isEmpty) {
          // Nothing the text could match: say so rather than ignore it.
          if (mounted && ticket == _loadTicket) {
            totalCount = 0;
            state = const AsyncValue.data([]);
          }
          return;
        }
        query = query.or(clauses.join(','));
      }

      final rows = await query
          .order(orderBy, ascending: ascending, nullsFirst: false)
          .limit(_window)
          .count(CountOption.exact);

      if (mounted && ticket == _loadTicket) {
        totalCount = rows.count;
        state = AsyncValue.data(List<Map<String, dynamic>>.from(rows.data));
      }
    } catch (e, st) {
      if (mounted && ticket == _loadTicket) state = AsyncValue.error(e, st);
    }
  }

  /// Widens the window by another page and reloads.
  Future<void> loadMore() async {
    _window += limit;
    _loadingMore = true;
    try {
      await load();
    } finally {
      _loadingMore = false;
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

  /// Narrows the list to rows whose [column] equals [value]; null or an empty
  /// string takes the filter off.
  void setColumnFilter(String column, Object? value) {
    if (value == null || (value is String && value.isEmpty)) {
      _filters.remove(column);
    } else {
      _filters[column] = value;
    }
    load();
  }

  /// The `or` clauses a search for [q] becomes: an `ilike` on each of
  /// [searchColumns]. A section whose columns cannot take `ilike` (an enum
  /// can't) overrides this.
  @protected
  List<String> searchClauses(String q) => [
    for (final c in searchColumns) '$c.ilike.%$q%',
  ];

  /// Drops anything the form carries that is not a column — joined objects
  /// arrive under their table's name and would be rejected on the way back.
  Map<String, dynamic> _writable(Map<String, dynamic> fields) => {
    for (final e in fields.entries)
      if (!readOnlyColumns.contains(e.key) && e.value is! Map) e.key: e.value,
  };

  Future<void> create(Map<String, dynamic> row) async {
    final fields = _writable(row);
    final inserted = await SupabaseConfig.client
        .from(table)
        .insert(fields)
        .select('id')
        .maybeSingle();
    await recordAdminAction(
      action: 'create',
      table: table,
      rowId: inserted?['id']?.toString(),
      fields: fields,
      label: _labelOf(fields),
    );
    await load();
  }

  Future<void> update(String id, Map<String, dynamic> fields) async {
    final writable = _writable(fields);
    final before = _rowById(id);
    await updateRow(table, id, writable);
    await recordAdminAction(
      action: auditActionFor(writable),
      table: table,
      rowId: id,
      fields: writable,
      before: before,
      label: _labelOf(writable) ?? _labelOf(before),
    );
    await load();
  }

  Future<void> remove(String id) async {
    if (softDeleteStatus != null) {
      await updateStatus(id, softDeleteStatus!);
      return;
    }
    final before = _rowById(id);
    await SupabaseConfig.client.from(table).delete().eq('id', id);
    await recordAdminAction(
      action: 'delete',
      table: table,
      rowId: id,
      label: _labelOf(before),
    );
    await load();
  }

  Future<void> updateStatus(String id, String status) async {
    final before = _rowById(id);
    final fields = {'status': status};
    await updateRow(table, id, fields);
    await recordAdminAction(
      action: auditActionFor(fields),
      table: table,
      rowId: id,
      fields: fields,
      before: before,
      label: _labelOf(before),
    );
    await load();
  }

  /// For the tables that mark a row active rather than carrying a status.
  Future<void> setActive(String id, bool isActive) async {
    final before = _rowById(id);
    final fields = {'is_active': isActive};
    await updateRow(table, id, fields);
    await recordAdminAction(
      action: 'update',
      table: table,
      rowId: id,
      fields: fields,
      before: before,
      label: _labelOf(before),
    );
    await load();
  }

  /// The row as it was loaded, for the audit log's "before".
  Map<String, dynamic>? _rowById(String id) {
    for (final r in state.valueOrNull ?? const <Map<String, dynamic>>[]) {
      if (r['id'] == id) return r;
    }
    return null;
  }

  /// A name for the row in the audit log, so an entry reads "category
  /// Cafés" rather than a bare id. People's own tables are left unnamed:
  /// the log is not a second copy of who they are.
  String? _labelOf(Map<String, dynamic>? row) {
    if (row == null || _unnamedTables.contains(table)) return null;
    for (final key in const ['title', 'name', 'label', 'code']) {
      final v = row[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  static const _unnamedTables = {
    'profiles',
    'admin_users',
    'comments',
    'reports',
  };
}

/// Updates one row and fails loudly when nothing was updated.
///
/// Row-level security does not refuse an update it disallows: the update
/// simply matches no rows and reports success, so the panel used to say
/// nothing while the change was lost. Asking for the updated ids back shows
/// whether the row was really written.
Future<void> updateRow(
  String table,
  String id,
  Map<String, dynamic> fields,
) async {
  final rows = await SupabaseConfig.client
      .from(table)
      .update(fields)
      .eq('id', id)
      .select('id');
  if (rows.isEmpty) {
    throw const AdminWriteRefused();
  }
}

/// An update that reached no row — refused by the database's permissions,
/// or the row is gone.
class AdminWriteRefused implements Exception {
  const AdminWriteRefused();

  @override
  String toString() => tr('השינוי לא נשמר — אין הרשאה או שהשורה לא נמצאה', 'The change was not saved — no permission, or the row was not found');
}

/// The columns whose values the audit log keeps. They are states — a status,
/// a switch — and say what was done. For every other column the log keeps
/// only the name: it records that a phone number or a price changed, not the
/// number itself.
const auditValueColumns = {'status', 'is_active', 'published'};

/// The `audit_action` a change amounts to, from what it writes.
String auditActionFor(Map<String, dynamic> fields) {
  if (fields['published'] == true) return 'publish';
  return switch (fields['status']) {
    'published' => 'publish',
    'archived' || 'trash' => 'archive',
    'approved' => 'approve',
    'rejected' => 'reject',
    _ => 'update',
  };
}

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// Writes one entry to `audit_logs` for a change an administrator made.
///
/// Who made it is filled in by the database from the signed-in user (a
/// trigger, migration 00031), so it is not taken on the client's word.
/// [fields] is what was written: the log keeps every column's name and the
/// values of [auditValueColumns] only; [before] supplies those same columns
/// as they were.
///
/// A failure here is reported to the console and swallowed: the change
/// itself has already gone through, and failing the action over its log
/// entry would tell the administrator it did not happen.
Future<void> recordAdminAction({
  required String action,
  required String table,
  String? rowId,
  Map<String, dynamic> fields = const {},
  Map<String, dynamic>? before,
  String? label,
}) async {
  final kept = {
    for (final k in auditValueColumns)
      if (fields.containsKey(k)) k: fields[k],
  };
  final was = {
    for (final k in auditValueColumns)
      if (before != null && fields.containsKey(k) && before.containsKey(k))
        k: before[k],
  };
  try {
    await SupabaseConfig.client.from('audit_logs').insert({
      'action': action,
      'entity_type': table,
      if (rowId != null && _uuid.hasMatch(rowId)) 'entity_id': rowId,
      if (was.isNotEmpty) 'before_data': was,
      'after_data': {
        if (fields.isNotEmpty) 'fields': fields.keys.toList(),
        ...kept,
        'label': ?label,
      },
    });
  } catch (e) {
    debugPrint('audit_logs: could not record $action on $table: $e');
  }
}
