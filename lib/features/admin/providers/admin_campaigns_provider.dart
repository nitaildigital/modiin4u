import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// Paid banner campaigns, on the live table.
///
/// The slot and the business arrive through their joins
/// (`ad_placements`, `businesses`) — the table holds only their ids, so the
/// list's old `placement_label` / `business_name` were always blank.
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
        columns:
            '*, businesses(id, name), '
            'ad_placements(id, code, label, is_active)',
        // Newest first, so a campaign just booked is at the top of the list.
        orderBy: 'created_at',
        // What "remove" means here: off the site, kept in the list.
        softDeleteStatus: 'ended',
      );

  Future<void> createCampaign(Map<String, dynamic> c) => create(c);
  Future<void> updateCampaign(String id, Map<String, dynamic> f) =>
      update(id, f);

  /// Takes the banner off the site and keeps the campaign, to bring back
  /// with "activate".
  ///
  /// The client asked for nothing to be deleted outright. This used to set
  /// status `cancelled`, which `campaign_status` does not have, so the
  /// database refused it; `ended` is the enum's own word for it.
  Future<void> endCampaign(String id) => updateStatus(id, 'ended');
}

/// The slots a campaign can be booked into, for the form's picker.
final adminCampaignSlotOptionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final rows = await SupabaseConfig.client
          .from('ad_placements')
          .select('id, code, label, is_active, max_banners, allowed_sizes')
          .order('sort_order', ascending: true);
      return List<Map<String, dynamic>>.from(rows);
    });

/// Every business, by name, for the form's picker. A campaign need not have
/// one — `business_id` is optional — but when it does it is a real row.
final adminCampaignBusinessOptionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final rows = await SupabaseConfig.client
          .from('businesses')
          .select('id, name, status')
          .order('name', ascending: true)
          .limit(5000);
      return List<Map<String, dynamic>>.from(rows);
    });

/// The team, for "salesperson": `campaigns.salesperson_id` points at an
/// `admin_users` row, whose name is on its profile.
final adminCampaignSalespeopleProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final rows = await SupabaseConfig.client
          .from('admin_users')
          .select('id, is_active, profiles(full_name, email)')
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(rows);
    });
