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

  String? _type;

  /// Apartment, penthouse, garden, duplex, villa or studio.
  void setTypeFilter(String? type) {
    _type = type;
    load();
  }

  @override
  Future<void> load() async {
    await super.load();
    final type = _type;
    if (type == null || type.isEmpty) return;

    state.whenData((rows) {
      state = AsyncValue.data(
        rows.where((r) => r['property_type'] == type).toList(),
      );
    });
  }

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
