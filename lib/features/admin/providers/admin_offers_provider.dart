import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// Offers, on the live table.
///
/// It has no rows, which is why the deals row on the home screen is still
/// three cards written into the screen. The first offer entered here is what
/// replaces them.
final adminOfferListProvider =
    StateNotifierProvider<
      AdminOfferListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminOfferListNotifier();
    });

class AdminOfferListNotifier extends AdminTableNotifier {
  AdminOfferListNotifier()
    : super(
        table: 'offers',
        searchColumns: const ['name', 'code'],
        columns: '*, businesses(id, name)',
        orderBy: 'created_at',
        softDeleteStatus: 'expired',
      );

  Future<void> createOffer(Map<String, dynamic> o) => create(o);
  Future<void> updateOffer(String id, Map<String, dynamic> f) => update(id, f);
  Future<void> deleteOffer(String id) => remove(id);
}

/// Businesses an offer can belong to.
final offerBusinessesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final rows = await SupabaseConfig.client
      .from('businesses')
      .select('id, name')
      .eq('status', 'active')
      .order('name', ascending: true);
  return List<Map<String, dynamic>>.from(rows);
});
