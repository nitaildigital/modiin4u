import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// The directory, as the admin panel sees it.
///
/// This held twenty invented businesses in memory: an edit looked like it
/// worked and was gone on the next launch. It reads and writes the real table
/// now, so the panel is the way the client actually manages the directory.
final adminBusinessListProvider =
    StateNotifierProvider<
      AdminBusinessListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminBusinessListNotifier();
    });

/// Neighbourhoods for the picker, from the table rather than a list of
/// thirteen written into the file.
final neighborhoodsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final rows = await SupabaseConfig.client
      .from('neighborhoods')
      .select('id, name, slug, is_active, sort_order')
      .eq('is_active', true)
      .order('sort_order', ascending: true);
  return List<Map<String, dynamic>>.from(rows);
});

/// Business categories, likewise.
final businessCategoriesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final rows = await SupabaseConfig.client
      .from('categories')
      .select('id, name, slug, scope, parent_id, is_active, sort_order')
      .eq('scope', 'business')
      .eq('is_active', true)
      .order('sort_order', ascending: true);
  return List<Map<String, dynamic>>.from(rows);
});

/// What the list's category column says for each business, keyed by
/// business id: "Parent › Child" for a trade under a parent, the name alone
/// for a top-level category.
///
/// The column used to print the short description under a "category"
/// heading, because a business's categories are not on its row. They are
/// links in `entity_categories`, read here in one pass for the whole list
/// rather than once per row. Hidden categories are included: a business
/// filed under one is still filed there.
final adminBusinessCategoryNamesProvider =
    FutureProvider<Map<String, List<String>>>((ref) async {
      final client = SupabaseConfig.client;

      final cats = List<Map<String, dynamic>>.from(
        await client
            .from('categories')
            .select('id, name, parent_id, sort_order')
            .eq('scope', 'business'),
      );
      final byId = {for (final c in cats) c['id'] as String: c};

      String label(String id) {
        final c = byId[id];
        if (c == null) return '';
        final parent = byId[c['parent_id']];
        return parent == null
            ? c['name'] as String
            : '${parent['name']} › ${c['name']}';
      }

      // Paged, because PostgREST stops at 1000 rows and says nothing.
      final links = <Map<String, dynamic>>[];
      const page = 1000;
      for (var from = 0; ; from += page) {
        final rows = List<Map<String, dynamic>>.from(
          await client
              .from('entity_categories')
              .select('entity_id, category_id, is_primary')
              .eq('entity_type', 'business')
              .range(from, from + page - 1),
        );
        links.addAll(rows);
        if (rows.length < page) break;
      }

      // The primary one first, then in the categories' own order.
      int order(Map<String, dynamic> l) =>
          (byId[l['category_id']]?['sort_order'] as num?)?.toInt() ?? 0;
      links.sort((a, b) {
        final pa = a['is_primary'] == true ? 0 : 1;
        final pb = b['is_primary'] == true ? 0 : 1;
        return pa != pb ? pa - pb : order(a) - order(b);
      });

      final out = <String, List<String>>{};
      for (final l in links) {
        final name = label(l['category_id'] as String);
        if (name.isEmpty) continue;
        out.putIfAbsent(l['entity_id'] as String, () => []).add(name);
      }
      return out;
    });

/// The categories one business belongs to, as ids.
final businessCategoryIdsProvider = FutureProvider.family<List<String>, String>(
  (ref, businessId) async {
    final rows = await SupabaseConfig.client
        .from('entity_categories')
        .select('category_id')
        .eq('entity_type', 'business')
        .eq('entity_id', businessId);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map((r) => r['category_id'] as String).toList();
  },
);

/// One business's opening hours, keyed 1 = Monday .. 7 = Sunday.
///
/// The table stores 0 = Sunday, which is the convention the import used; the
/// app compares against Dart's `weekday`, so the two are converted here in
/// one place rather than at every call site.
final businessHoursProvider =
    FutureProvider.family<Map<int, Map<String, dynamic>>, String>((
      ref,
      businessId,
    ) async {
      final rows = await SupabaseConfig.client
          .from('business_hours')
          .select('id, day_of_week, open_time, close_time, is_closed')
          .eq('business_id', businessId);

      return {
        for (final r in List<Map<String, dynamic>>.from(rows))
          _toDartWeekday((r['day_of_week'] as num?)?.toInt() ?? 0): r,
      };
    });

int _toDartWeekday(int stored) => stored == 0 ? DateTime.sunday : stored;
int _toStoredDay(int weekday) => weekday == DateTime.sunday ? 0 : weekday;

class AdminBusinessListNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  String? _search;
  String? _status;

  AdminBusinessListNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      var query = SupabaseConfig.client
          .from('businesses')
          .select(
            '*, neighborhoods!businesses_neighborhood_id_fkey(id, name, slug)',
          );

      if (_status != null && _status!.isNotEmpty) {
        query = query.eq('status', _status!);
      }
      if (_search != null && _search!.isNotEmpty) {
        final q = _search!.replaceAll(',', ' ');
        query = query.or('name.ilike.%$q%,short_description.ilike.%$q%');
      }

      final rows = await query.order('created_at', ascending: false).limit(500);
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

  /// Columns the form does not own. `neighborhoods` arrives from the join and
  /// is not a column, and the rest are set by the database.
  static const _notColumns = {
    'neighborhoods',
    'id',
    'created_at',
    'updated_at',
    'rating',
    'review_count',
  };

  Map<String, dynamic> _columnsOnly(Map<String, dynamic> fields) {
    return {
      for (final e in fields.entries)
        if (!_notColumns.contains(e.key)) e.key: e.value,
    };
  }

  /// Inserts the row and returns its id, which the editor needs straight
  /// away: hours, categories, menu and gallery all hang off it, and were
  /// silently dropped on a new business while this returned nothing.
  Future<String> createBusiness(Map<String, dynamic> business) async {
    final fields = _columnsOnly(business);
    if (fields['status'] == 'closed') fields['closed_at'] = _now();
    final row = await SupabaseConfig.client
        .from('businesses')
        .insert(fields)
        .select('id')
        .single();
    final id = row['id'] as String;
    await recordAdminAction(
      action: 'create',
      table: 'businesses',
      rowId: id,
      fields: fields,
      label: fields['name'] as String?,
    );
    await load();
    return id;
  }

  Future<void> updateBusiness(String id, Map<String, dynamic> fields) async {
    final row = _columnsOnly(fields)..remove('closed_at');
    final status = row['status'];
    if (status is String && status != 'closed') row['closed_at'] = null;
    final before = _rowById(id);
    // `updateRow` throws when the database updated nothing, which is how a
    // refused write looks — it used to pass as saved.
    await updateRow('businesses', id, row);
    if (status == 'closed') await _stampClosed(id);
    await recordAdminAction(
      action: auditActionFor(row),
      table: 'businesses',
      rowId: id,
      fields: row,
      before: before,
      label: (row['name'] ?? before?['name']) as String?,
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

  /// Marks the business closed rather than removing the row.
  ///
  /// A delete would take its reviews and favourites with it, and the client
  /// asked for a trash rather than a permanent removal.
  Future<void> deleteBusiness(String id) async {
    await updateStatus(id, 'closed');
  }

  /// Sets the status, and `closed_at` with it: stamped when the business is
  /// closed, cleared when it is anything else. Closing never set it, so the
  /// column said no business had ever closed.
  Future<void> updateStatus(String id, String status) async {
    final before = _rowById(id);
    final fields = {
      'status': status,
      if (status != 'closed') 'closed_at': null,
    };
    await updateRow('businesses', id, fields);
    if (status == 'closed') await _stampClosed(id);
    await recordAdminAction(
      action: auditActionFor(fields),
      table: 'businesses',
      rowId: id,
      fields: fields,
      before: before,
      label: before?['name'] as String?,
    );
    await load();
  }

  /// The date it closed — only if it has none, so saving a business that
  /// closed last month does not move the date to today.
  Future<void> _stampClosed(String id) async {
    await SupabaseConfig.client
        .from('businesses')
        .update({'closed_at': _now()})
        .eq('id', id)
        .isFilter('closed_at', null);
  }

  static String _now() => DateTime.now().toUtc().toIso8601String();

  // ── Categories ──

  /// Makes a business's categories exactly [categoryIds].
  ///
  /// Only the difference is written. Deleting every link and inserting them
  /// again lost `is_primary`, which the import set on 156 of the 223 links,
  /// the first time anyone saved a business.
  Future<void> setCategories(
    String businessId,
    List<String> categoryIds,
  ) async {
    final client = SupabaseConfig.client;
    final current = List<Map<String, dynamic>>.from(
      await client
          .from('entity_categories')
          .select('category_id')
          .eq('entity_type', 'business')
          .eq('entity_id', businessId),
    ).map((r) => r['category_id'] as String).toSet();
    final wanted = categoryIds.toSet();

    final gone = current.difference(wanted);
    if (gone.isNotEmpty) {
      await client
          .from('entity_categories')
          .delete()
          .eq('entity_type', 'business')
          .eq('entity_id', businessId)
          .inFilter('category_id', gone.toList());
    }

    final added = wanted.difference(current);
    if (added.isEmpty) return;
    await client.from('entity_categories').insert([
      for (final id in added)
        {'entity_type': 'business', 'entity_id': businessId, 'category_id': id},
    ]);
  }

  // ── Opening hours ──

  /// Replaces the week's hours in one go.
  ///
  /// [week] is keyed 1 = Monday .. 7 = Sunday; a day left out, or marked
  /// closed, is stored as closed rather than dropped, so "closed on Monday"
  /// and "we never said" stay distinguishable.
  Future<void> setHours(
    String businessId,
    Map<int, ({String? open, String? close, bool closed})> week,
  ) async {
    final client = SupabaseConfig.client;
    await client.from('business_hours').delete().eq('business_id', businessId);

    final rows = [
      for (final entry in week.entries)
        {
          'business_id': businessId,
          'day_of_week': _toStoredDay(entry.key),
          'is_closed': entry.value.closed,
          'open_time': entry.value.closed ? null : entry.value.open,
          'close_time': entry.value.closed ? null : entry.value.close,
        },
    ];
    if (rows.isNotEmpty) await client.from('business_hours').insert(rows);
  }
}

/// The menu lines for one business, for the editor's Menu tab.
///
/// Migration 00023 adds the table. Before it, the app's Menu tab showed the
/// same invented menu on all 220 businesses, and there was nowhere to put a
/// real one.
final adminMenuItemsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      businessId,
    ) async {
      final rows = await SupabaseConfig.client
          .from('business_menu_items')
          .select()
          .eq('business_id', businessId)
          .order('sort_order', ascending: true);
      return List<Map<String, dynamic>>.from(rows);
    });

/// The columns of a menu line the editor owns.
const _menuColumns = [
  'section',
  'name',
  'description',
  'price_agorot',
  'is_available',
];

/// Makes a business's menu what the editor holds, writing only what
/// changed.
///
/// This deleted every line and inserted them again on every save of the
/// business, so each line got a new id and a new `created_at` whether or not
/// anyone had touched the menu. Now each line the editor loaded carries its
/// `id`: a line that is gone is deleted, a line that changed — its text or
/// its place — is updated in place, a new line is inserted, and a menu no
/// one touched is not written at all. The order the editor shows is still
/// the order stored.
Future<void> saveMenuItems(
  String businessId,
  List<Map<String, dynamic>> items,
) async {
  final client = SupabaseConfig.client;
  final stored = {
    for (final r in List<Map<String, dynamic>>.from(
      await client
          .from('business_menu_items')
          .select('id, sort_order, ${_menuColumns.join(', ')}')
          .eq('business_id', businessId),
    ))
      r['id'] as String: r,
  };

  final kept = {
    for (final m in items)
      if (m['id'] is String && stored.containsKey(m['id'])) m['id'] as String,
  };
  final gone = stored.keys.where((id) => !kept.contains(id)).toList();
  if (gone.isNotEmpty) {
    await client.from('business_menu_items').delete().inFilter('id', gone);
  }

  final added = <Map<String, dynamic>>[];
  for (var i = 0; i < items.length; i++) {
    final wanted = {
      for (final c in _menuColumns) c: items[i][c],
      'is_available': items[i]['is_available'] ?? true,
      'sort_order': i,
    };
    final id = items[i]['id'];
    final was = id is String ? stored[id] : null;
    if (was == null) {
      added.add({...wanted, 'business_id': businessId});
      continue;
    }
    final changed = {
      for (final e in wanted.entries)
        if (was[e.key] != e.value) e.key: e.value,
    };
    if (changed.isEmpty) continue;
    await client.from('business_menu_items').update(changed).eq('id', id);
  }
  if (added.isNotEmpty) {
    await client.from('business_menu_items').insert(added);
  }
}
