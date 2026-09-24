import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// Property listings, on the table migration 00018 adds.
///
/// The app carries nine real-estate screens and one of the five bottom tabs,
/// and until that migration runs there is nothing behind any of it. The
/// columns here are named as the form already names them, so nothing is
/// translated on the way in or out.
final adminListingListProvider =
    StateNotifierProvider<
      AdminListingListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminListingListNotifier();
    });

class AdminListingListNotifier extends AdminTableNotifier {
  AdminListingListNotifier()
    : super(
        table: 'listings',
        searchColumns: const ['title', 'address', 'description'],
        columns:
            '*, neighborhoods(id, name), '
            'real_estate_agents(id, name, agency, phone)',
        orderBy: 'created_at',
        softDeleteStatus: 'removed',
      );

  String? _kind;
  String? _propertyType;

  /// `sale` or `rent` — the `kind` column.
  ///
  /// This used to filter `property_type` against the same value, and
  /// `property_type` never holds 'sale' or 'rent' — it holds apartment,
  /// penthouse and so on. Both the "for sale" and "to let" chips therefore
  /// matched nothing and showed an empty table whatever was in it.
  void setKindFilter(String? kind) {
    _kind = kind;
    load();
  }

  /// Apartment, penthouse, garden, duplex, villa or studio.
  void setPropertyTypeFilter(String? type) {
    _propertyType = type;
    load();
  }

  @override
  Future<void> load() async {
    await super.load();
    if ((_kind == null || _kind!.isEmpty) &&
        (_propertyType == null || _propertyType!.isEmpty)) {
      return;
    }

    state.whenData((rows) {
      state = AsyncValue.data(
        rows.where((r) {
          final kindOk = _kind == null || _kind!.isEmpty || r['kind'] == _kind;
          final typeOk = _propertyType == null ||
              _propertyType!.isEmpty ||
              r['property_type'] == _propertyType;
          return kindOk && typeOk;
        }).toList(),
      );
    });
  }

  /// Approve a listing a resident posted, so it appears in the directory.
  Future<void> approve(String id) => updateStatus(id, 'active');

  /// Turn one down. `removed` rather than a delete, so the person who posted
  /// it still sees it in "My Apartments" — marked as turned down — instead of
  /// it silently disappearing.
  Future<void> reject(String id) => updateStatus(id, 'removed');

  Future<void> createListing(Map<String, dynamic> l) => create(l);
  Future<void> updateListing(String id, Map<String, dynamic> f) =>
      update(id, f);
  Future<void> deleteListing(String id) => remove(id);
}

/// Agents a listing can be credited to.
final realEstateAgentsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final rows = await SupabaseConfig.client
      .from('real_estate_agents')
      .select('id, name, agency, phone')
      .eq('is_active', true)
      .order('name');
  return List<Map<String, dynamic>>.from(rows);
});

/// The neighbourhoods a listing can be filed under.
///
/// The editor asked for the name as free text and wrote it to a column that
/// does not exist; a listing is filed by id against this table.
final adminNeighborhoodOptionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
      final rows = await SupabaseConfig.client
          .from('neighborhoods')
          .select('id, name')
          .eq('is_active', true)
          .order('sort_order');
      return List<Map<String, dynamic>>.from(rows);
    });
