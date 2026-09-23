import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_table_notifier.dart';

/// Paid banner campaigns, on the live table.
final adminCampaignListProvider =
    StateNotifierProvider<
      AdminCampaignListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminCampaignListNotifier();
    });

class AdminCampaignListNotifier extends AdminTableNotifier {
  AdminCampaignListNotifier()
    : super(
        table: 'campaigns',
        searchColumns: const ['name'],
        columns: '*, businesses(id, name), ad_placements(id, label)',
        orderBy: 'start_at',
        softDeleteStatus: 'cancelled',
      );

  Future<void> createCampaign(Map<String, dynamic> c) => create(c);
  Future<void> updateCampaign(String id, Map<String, dynamic> f) =>
      update(id, f);
  Future<void> deleteCampaign(String id) => remove(id);
}
