import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// Push campaigns, on the live table.
///
/// Composing and scheduling one works. **Sending does not**: that needs
/// Firebase and APNs credentials the client has not supplied, and the device
/// tokens migration 00016 adds. Until both, a campaign can be written and
/// queued but nothing leaves the building — which is why sending says so
/// rather than marking it sent.
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

  Future<void> createNotification(Map<String, dynamic> n) => create(n);
  Future<void> updateNotification(String id, Map<String, dynamic> f) =>
      update(id, f);
  Future<void> deleteNotification(String id) => remove(id);

  Future<void> scheduleNotification(String id, DateTime when) async {
    await SupabaseConfig.client
        .from('push_campaigns')
        .update({
          'status': 'scheduled',
          'scheduled_at': when.toIso8601String(),
        })
        .eq('id', id);
    await load();
  }

  /// Delivery is not built. Marking a campaign sent when nothing was sent
  /// would be worse than refusing.
  Future<void> sendNotification(String id) async {
    throw UnimplementedError(
      'push delivery needs Firebase and APNs credentials (D-push)',
    );
  }
}
