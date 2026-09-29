import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// What residents have reported, on the live table.
///
/// Nothing on the website or in the app files a report yet, so this list
/// stays empty until something does.
final adminReportsProvider =
    StateNotifierProvider<
      AdminReportsNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminReportsNotifier();
    });

/// The states a report moves through. `status` is free text; these are the
/// four the table was designed with (migration 00007).
const reportStatuses = ['open', 'reviewed', 'resolved', 'dismissed'];

class AdminReportsNotifier extends AdminTableNotifier {
  AdminReportsNotifier()
    : super(
        table: 'reports',
        // `reason` is an enum and cannot take `ilike`; the details are what a
        // moderator would type to find a report.
        searchColumns: const ['details', 'resolution'],
        columns: '*, profiles!reports_reporter_id_fkey(id, full_name)',
        orderBy: 'created_at',
      );

  void setEntityTypeFilter(String? type) =>
      setColumnFilter('entity_type', type);

  Future<void> markReviewed(String id) => updateStatus(id, 'reviewed');

  /// Closes the report and records what was decided, so the next moderator
  /// can see why rather than only that it is shut.
  Future<void> resolve(String id, [String? resolution]) =>
      _close(id, 'resolved', resolution);

  Future<void> dismiss(String id, [String? resolution]) =>
      _close(id, 'dismissed', resolution);

  /// Opens a closed report again.
  Future<void> reopen(String id) =>
      update(id, {'status': 'open', 'resolved_at': null, 'resolved_by': null});

  Future<void> _close(String id, String status, String? resolution) =>
      update(id, {
        'status': status,
        'resolved_at': DateTime.now().toUtc().toIso8601String(),
        // `resolved_by` points at `profiles`, whose id is the signed-in user.
        'resolved_by': SupabaseConfig.client.auth.currentUser?.id,
        'resolution': ?resolution,
      });
}
