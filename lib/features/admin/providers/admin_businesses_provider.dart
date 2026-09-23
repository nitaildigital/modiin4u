import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';

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
      .order('sort_order');
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
      .order('sort_order');
  return List<Map<String, dynamic>>.from(rows);
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
          .select('*, neighborhoods!businesses_neighborhood_id_fkey(id, name, slug)');

      if (_status != null && _status!.isNotEmpty) {
        query = query.eq('status', _status!);
      }
      if (_search != null && _search!.isNotEmpty) {
        final q = _search!.replaceAll(',', ' ');
        query = query.or('name.ilike.%$q%,short_description.ilike.%$q%');
      }

      final rows = await query.order('created_at', ascending: false).limit(500);
      if (mounted) state = AsyncValue.data(List<Map<String, dynamic>>.from(rows));
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

  Future<void> createBusiness(Map<String, dynamic> business) async {
    await SupabaseConfig.client
        .from('businesses')
        .insert(_columnsOnly(business));
    await load();
  }

  Future<void> updateBusiness(String id, Map<String, dynamic> fields) async {
    await SupabaseConfig.client
        .from('businesses')
        .update(_columnsOnly(fields))
        .eq('id', id);
    await load();
  }

  /// Marks the business closed rather than removing the row.
  ///
  /// A delete would take its reviews and favourites with it, and the client
  /// asked for a trash rather than a permanent removal.
  Future<void> deleteBusiness(String id) async {
    await updateStatus(id, 'closed');
  }

  Future<void> updateStatus(String id, String status) async {
    await SupabaseConfig.client
        .from('businesses')
        .update({'status': status})
        .eq('id', id);
    await load();
  }

  // ── Categories ──

  /// Replaces the categories a business belongs to.
  Future<void> setCategories(String businessId, List<String> categoryIds) async {
    final client = SupabaseConfig.client;
    await client
        .from('entity_categories')
        .delete()
        .eq('entity_type', 'business')
        .eq('entity_id', businessId);

    if (categoryIds.isEmpty) return;
    await client.from('entity_categories').insert([
      for (final id in categoryIds)
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
