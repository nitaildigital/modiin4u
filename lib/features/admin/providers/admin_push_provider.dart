import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// Push campaigns, on `push_campaigns`.
///
/// The panel saves a campaign as a draft or scheduled (now, or for a time);
/// `supabase/functions/push-dispatch` sends it when it is due and writes
/// `sent`, `sent_at` and the counts. The panel never marks one sent itself.
///
/// Who a campaign is for is `audience_type` plus `audience_filter`:
/// everyone, one neighbourhood (`{"neighborhood_id": …}`), or the devices
/// that opted in to one topic (`{"topic": "news"}` and so on — the
/// `notify_*` switches on `push_devices`, migration 00045).
///
/// The notifications sent to one person when someone replies to them
/// (`audience_type = 'profiles'`) are left out: one per approved reply would
/// bury the client's own campaigns, and they are not his to edit.
///
/// Cancelling marks the row `cancelled` (migration 00035 added the word to
/// `push_status`); it can be put back to draft.
final adminPushListProvider =
    StateNotifierProvider<
      AdminPushListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminPushListNotifier();
    });

class AdminPushListNotifier extends AdminTableNotifier {
  AdminPushListNotifier()
    : super(
        table: 'push_campaigns',
        searchColumns: const ['title', 'body'],
        columns: '*, businesses!push_campaigns_business_id_fkey(id, name)',
        orderBy: 'created_at',
        softDeleteStatus: 'cancelled',
        excluded: const {'audience_type': 'profiles'},
      );

  // Written directly rather than through [create] and [update]: those drop
  // every Map value as a joined row, and `audience_filter` is a jsonb Map.
  Future<void> createNotification(Map<String, dynamic> n) async {
    final inserted = await SupabaseConfig.client
        .from('push_campaigns')
        .insert(n)
        .select('id')
        .maybeSingle();
    await recordAdminAction(
      action: 'create',
      table: 'push_campaigns',
      rowId: inserted?['id']?.toString(),
      fields: n,
      label: n['title'] as String?,
    );
    await load();
  }

  Future<void> updateNotification(String id, Map<String, dynamic> f) async {
    final before = state.valueOrNull?.firstWhere(
      (r) => r['id'] == id,
      orElse: () => const {},
    );
    await updateRow('push_campaigns', id, f);
    await recordAdminAction(
      action: 'update',
      table: 'push_campaigns',
      rowId: id,
      fields: f,
      before: before,
      label: f['title'] as String?,
    );
    await load();
  }

  Future<void> cancelNotification(String id) => remove(id);
  Future<void> restoreToDraft(String id) => updateStatus(id, 'draft');
}
