import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// Push campaigns, on `push_campaigns`.
///
/// Composing and scheduling one works. **Sending does not**: that needs the
/// client's Firebase (and, for iPhones, APNs) credentials, which have not
/// been supplied, and nothing registers device tokens yet. So a campaign is
/// saved as a draft or as scheduled and stays that way — the panel never
/// marks one sent. It used to: "send now" wrote `status = 'sent'` and a
/// `sent_at` while nothing left the building, alongside an invented
/// recipient count (5,400 or 1,200) and columns the table does not have
/// (`type`, `target_audience`, `target_value`, `read_count`,
/// `total_recipients`), so the insert was refused anyway.
///
/// Who a campaign is for is `audience_type` plus `audience_filter`:
/// everyone, one neighbourhood (`{"neighborhood_id": …}`), or the residents
/// who opted in to one topic (`{"topic": "news"}` and so on — the four
/// `notify_*` switches on `profiles`). Whatever does the sending, once it
/// exists, reads those.
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
        columns: '*, businesses(id, name)',
        orderBy: 'created_at',
        softDeleteStatus: 'cancelled',
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
