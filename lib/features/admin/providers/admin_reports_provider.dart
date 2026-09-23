import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import 'admin_table_notifier.dart';

/// What residents have reported, on the live table.
final adminReportsProvider =
    StateNotifierProvider<
      AdminReportsNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) {
      return AdminReportsNotifier();
    });

class AdminReportsNotifier extends AdminTableNotifier {
  AdminReportsNotifier()
    : super(
        table: 'reports',
        searchColumns: const ['reason', 'details'],
        columns: '*, profiles!reports_reporter_id_fkey(id, full_name)',
        orderBy: 'created_at',
      );

  String? _entityType;

  void setEntityTypeFilter(String? type) {
    _entityType = type;
    load();
  }

  @override
  Future<void> load() async {
    await super.load();
    final type = _entityType;
    if (type == null || type.isEmpty) return;

    state.whenData((rows) {
      state = AsyncValue.data(
        rows.where((r) => r['entity_type'] == type).toList(),
      );
    });
  }

  Future<void> markReviewed(String id) => updateStatus(id, 'reviewing');

  /// Closes the report and records what was decided, so the next moderator
  /// can see why rather than only that it is shut.
  Future<void> resolve(String id, [String? resolution]) =>
      _close(id, 'resolved', resolution);

  Future<void> dismiss(String id, [String? resolution]) =>
      _close(id, 'dismissed', resolution);

  Future<void> _close(String id, String status, String? resolution) async {
    await SupabaseConfig.client
        .from('reports')
        .update({
          'status': status,
          'resolved_at': DateTime.now().toIso8601String(),
          'resolved_by': SupabaseConfig.client.auth.currentUser?.id,
          if (resolution != null) 'resolution': resolution,
        })
        .eq('id', id);
    await load();
  }
}
