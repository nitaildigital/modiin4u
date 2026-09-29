import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_table_notifier.dart';

/// Offers, on the live table.
///
/// The editor used to write `title`, `business_name`, `discount_type`,
/// `discount_value`, `original_price` and `discounted_price` — none of them
/// columns — and never the required `business_id`, so nothing could be
/// saved; the list read `title` where the column is `name`, and showed no
/// names at all. This writes the table's own columns.
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
        // Counted by the site as residents claim and redeem; a form that sent
        // them back would overwrite newer numbers with the ones it opened with.
        readOnlyColumns: const {
          'id',
          'created_at',
          'updated_at',
          'view_count',
          'claim_count',
          'redeem_count',
        },
      );

  Future<void> createOffer(Map<String, dynamic> o) => create(o);
  Future<void> updateOffer(String id, Map<String, dynamic> f) => update(id, f);

  /// Marks the offer expired rather than removing it (`softDeleteStatus`): it
  /// leaves the site and comes back by setting it active again.
  Future<void> deleteOffer(String id) => remove(id);
}
